class Api::V1::ImageOptimizationController < Api::V1::BaseController
  before_action :authenticate_user!
  
  # GET /api/v1/image_optimization/analytics
  def analytics
    @stats = calculate_overview_stats
    @recent_optimizations = ImageOptimizationLog.recent.limit(50).includes(:medium, :upload, :user)
    @compression_level_stats = ImageOptimizationLog.compression_level_stats
    @optimization_type_stats = ImageOptimizationLog.optimization_type_stats
    
    render json: {
      success: true,
      data: {
        overview: @stats,
        recent_optimizations: @recent_optimizations.map(&:api_response),
        compression_level_stats: @compression_level_stats,
        optimization_type_stats: @optimization_type_stats
      }
    }
  end
  
  # GET /api/v1/image_optimization/report
  def report
    start_date = params[:start_date]&.to_date || 30.days.ago.to_date
    end_date = params[:end_date]&.to_date || Date.current
    
    @report = ImageOptimizationLog.generate_report(start_date, end_date)
    
    render json: {
      success: true,
      data: {
        report: @report,
        date_range: {
          start_date: start_date,
          end_date: end_date
        }
      }
    }
  end
  
  # GET /api/v1/image_optimization/failed
  def failed
    @failed_optimizations = ImageOptimizationLog.failed_optimizations
                                               .includes(:medium, :upload, :user)
                                               .page(params[:page])
                                               .per(params[:per_page] || 20)
    
    render json: {
      success: true,
      data: {
        failed_optimizations: @failed_optimizations.map(&:api_response),
        pagination: {
          current_page: @failed_optimizations.current_page,
          total_pages: @failed_optimizations.total_pages,
          total_count: @failed_optimizations.total_count
        }
      }
    }
  end
  
  # GET /api/v1/image_optimization/top_savings
  def top_savings
    limit = params[:limit]&.to_i || 50
    @top_savings = ImageOptimizationLog.top_savings(limit).includes(:medium, :upload, :user)
    
    render json: {
      success: true,
      data: {
        top_savings: @top_savings.map(&:api_response)
      }
    }
  end
  
  # GET /api/v1/image_optimization/user_stats
  def user_stats
    @user_stats = ImageOptimizationLog.user_stats
    @top_users = @user_stats.sort_by { |_, count| -count }.first(20)
    
    render json: {
      success: true,
      data: {
        user_stats: @user_stats,
        top_users: @top_users
      }
    }
  end
  
  # GET /api/v1/image_optimization/compression_levels
  def compression_levels
    @compression_levels = ImageOptimizationService.available_compression_levels
    @level_stats = ImageOptimizationLog.compression_level_stats
    
    render json: {
      success: true,
      data: {
        available_levels: @compression_levels,
        usage_stats: @level_stats
      }
    }
  end
  
  # GET /api/v1/image_optimization/performance
  def performance
    @avg_processing_time = ImageOptimizationLog.average_processing_time
    @avg_size_reduction = ImageOptimizationLog.average_size_reduction
    @total_processing_time = ImageOptimizationLog.total_processing_time
    @total_bytes_saved = ImageOptimizationLog.total_bytes_saved
    
    render json: {
      success: true,
      data: {
        average_processing_time: @avg_processing_time,
        average_size_reduction: @avg_size_reduction,
        total_processing_time: @total_processing_time,
        total_bytes_saved: @total_bytes_saved,
        total_size_saved_mb: (@total_bytes_saved / 1024.0 / 1024.0).round(2)
      }
    }
  end
  
  # POST /api/v1/image_optimization/bulk_optimize
  def bulk_optimize
    # Get all unoptimized images
    unoptimized_uploads = Upload.joins(:media)
                               .where(media: { id: Medium.where.not(id: ImageOptimizationLog.select(:medium_id)) })
                               .where.not(file: nil)
    
    if unoptimized_uploads.empty?
      render json: {
        success: true,
        message: 'No unoptimized images found',
        data: { queued_count: 0 }
      }
      return
    end
    
    # Queue optimization jobs
    queued_count = 0
    unoptimized_uploads.limit(100).each do |upload|
      medium = upload.media.first
      if medium
        OptimizeImageJob.perform_later(
          medium_id: medium.id,
          optimization_type: 'bulk',
          request_context: {
            user_agent: request.user_agent,
            ip_address: request.remote_ip
          }
        )
        queued_count += 1
      end
    end
    
    render json: {
      success: true,
      message: "Queued #{queued_count} images for optimization",
      data: { queued_count: queued_count }
    }
  end
  
  # POST /api/v1/image_optimization/regenerate_variants
  def regenerate_variants
    medium_id = params[:medium_id]
    
    if medium_id
      medium = Medium.find(medium_id)
      OptimizeImageJob.perform_later(
        medium_id: medium.id,
        optimization_type: 'regenerate',
        request_context: {
          user_agent: request.user_agent,
          ip_address: request.remote_ip
        }
      )
      
      render json: {
        success: true,
        message: "Queued variant regeneration for medium #{medium_id}",
        data: { medium_id: medium_id }
      }
    else
      render json: {
        success: false,
        message: 'medium_id parameter is required'
      }, status: 400
    end
  end
  
  # DELETE /api/v1/image_optimization/clear_logs
  def clear_logs
    if params[:confirm] == 'yes'
      ImageOptimizationLog.delete_all
      render json: {
        success: true,
        message: 'All optimization logs have been cleared'
      }
    else
      render json: {
        success: false,
        message: 'Log clearing cancelled. Use confirm=yes to clear logs.'
      }, status: 400
    end
  end
  
  # GET /api/v1/image_optimization/export
  def export
    start_date = params[:start_date]&.to_date || 30.days.ago.to_date
    end_date = params[:end_date]&.to_date || Date.current
    
    csv_data = ImageOptimizationLog.export_to_csv(start_date, end_date)
    
    send_data csv_data, 
              filename: "image_optimization_export_#{start_date}_to_#{end_date}.csv",
              type: 'text/csv'
  end
  
  private
  
  def calculate_overview_stats
    total_bytes_saved = ImageOptimizationLog.total_bytes_saved || 0
    avg_reduction = ImageOptimizationLog.average_size_reduction || 0
    avg_processing = ImageOptimizationLog.average_processing_time || 0
    
    {
      total_optimizations: ImageOptimizationLog.count,
      successful_optimizations: ImageOptimizationLog.successful.count,
      failed_optimizations: ImageOptimizationLog.failed.count,
      skipped_optimizations: ImageOptimizationLog.skipped.count,
      total_bytes_saved: total_bytes_saved,
      total_size_saved_mb: (total_bytes_saved / 1024.0 / 1024.0).round(2),
      average_size_reduction: avg_reduction.round(2),
      average_processing_time: avg_processing.round(3),
      today_optimizations: ImageOptimizationLog.today.count,
      this_week_optimizations: ImageOptimizationLog.this_week.count,
      this_month_optimizations: ImageOptimizationLog.this_month.count
    }
  end
end
