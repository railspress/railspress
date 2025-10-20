class Admin::ImageOptimizationAnalyticsController < Admin::BaseController
  before_action :ensure_admin
  
  # GET /admin/media/optimization_analytics
  def index
    @stats = calculate_overview_stats
    @recent_optimizations = ImageOptimizationLog.recent.limit(50).includes(:medium, :upload, :user)
    @compression_level_stats = ImageOptimizationLog.compression_level_stats
    @optimization_type_stats = ImageOptimizationLog.optimization_type_stats
    @daily_stats = ImageOptimizationLog.daily_stats(30)
  end
  
  # GET /admin/media/optimization_analytics/report
  def report
    start_date = params[:start_date]&.to_date || 30.days.ago.to_date
    end_date = params[:end_date]&.to_date || Date.current
    
    @report = ImageOptimizationLog.generate_report(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
    
    respond_to do |format|
      format.html
      format.json { render json: @report }
      format.csv do
        csv_data = ImageOptimizationLog.export_to_csv(start_date, end_date)
        send_data csv_data, 
                  filename: "image_optimization_report_#{start_date}_to_#{end_date}.csv",
                  type: 'text/csv'
      end
    end
  end
  
  # GET /admin/media/optimization_analytics/failed
  def failed
    @failed_optimizations = ImageOptimizationLog.failed_optimizations
                                               .includes(:medium, :upload, :user)
                                               .page(params[:page])
                                               .per(20)
  end
  
  # GET /admin/media/optimization_analytics/top_savings
  def top_savings
    @top_savings = ImageOptimizationLog.top_savings(50).includes(:medium, :upload, :user)
  end
  
  # GET /admin/media/optimization_analytics/user_stats
  def user_stats
    @user_stats = ImageOptimizationLog.user_stats
    @top_users = @user_stats.sort_by { |_, count| -count }.first(20)
  end
  
  # GET /admin/media/optimization_analytics/tenant_stats
  def tenant_stats
    @tenant_stats = ImageOptimizationLog.tenant_stats
    @top_tenants = @tenant_stats.sort_by { |_, count| -count }.first(20)
  end
  
  # GET /admin/media/optimization_analytics/compression_levels
  def compression_levels
    @compression_levels = ImageOptimizationService.available_compression_levels
    @level_stats = ImageOptimizationLog.compression_level_stats
  end
  
  # GET /admin/media/optimization_analytics/performance
  def performance
    @avg_processing_time = ImageOptimizationLog.average_processing_time
    @avg_size_reduction = ImageOptimizationLog.average_size_reduction
    @total_processing_time = ImageOptimizationLog.total_processing_time
    @total_bytes_saved = ImageOptimizationLog.total_bytes_saved
  end
  
  # DELETE /admin/media/optimization_analytics/clear_logs
  def clear_logs
    if params[:confirm] == 'yes'
      ImageOptimizationLog.delete_all
      redirect_to admin_image_optimization_analytics_index_path, 
                  notice: 'All optimization logs have been cleared.'
    else
      redirect_to admin_image_optimization_analytics_index_path, 
                  alert: 'Log clearing cancelled. Use confirm=yes to clear logs.'
    end
  end
  
  # GET /admin/media/optimization_analytics/export
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
