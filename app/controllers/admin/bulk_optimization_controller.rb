class Admin::BulkOptimizationController < Admin::BaseController
  before_action :ensure_admin
  
  # GET /admin/media/bulk_optimization
  def index
    @stats = calculate_optimization_stats
    @unoptimized_count = count_unoptimized_images
    
    # Load compression level information
    compression_level_name = SiteSetting.get('image_compression_level', 'lossy')
    compression_config = ImageOptimizationService.available_compression_levels[compression_level_name] || ImageOptimizationService.available_compression_levels['lossy']
    
    @compression_level_name = compression_config[:name]
    @compression_description = compression_config[:description]
    @expected_savings = compression_config[:expected_savings]
    @recommended_for = compression_config[:recommended_for]
  end
  
  # POST /admin/media/bulk_optimize
  def start_bulk_optimization
    # Get all unoptimized images
    unoptimized_uploads = get_unoptimized_uploads
    
    if unoptimized_uploads.empty?
      render json: { 
        success: false, 
        message: 'No unoptimized images found' 
      }
      return
    end
    
    # Queue optimization jobs
    job_count = 0
    unoptimized_uploads.find_each do |upload|
      upload.media.each do |medium|
        OptimizeImageJob.perform_later(medium_id: medium.id)
        job_count += 1
      end
    end
    
    # Store job tracking info
    Rails.cache.write('bulk_optimization_jobs', job_count, expires_in: 1.hour)
    Rails.cache.write('bulk_optimization_started', Time.current, expires_in: 1.hour)
    
    render json: { 
      success: true, 
      message: "Queued #{job_count} images for optimization",
      total_jobs: job_count
    }
  end
  
  # GET /admin/media/bulk_optimize_status
  def status
    total_jobs = Rails.cache.read('bulk_optimization_jobs') || 0
    started_at = Rails.cache.read('bulk_optimization_started')
    
    if total_jobs == 0
      render json: { 
        percentage: 100, 
        message: 'No optimization jobs running',
        completed: true
      }
      return
    end
    
    # Calculate progress based on completed optimizations
    completed_count = count_optimized_images
    percentage = total_jobs > 0 ? ((completed_count.to_f / total_jobs) * 100).round(1) : 0
    
    message = if percentage >= 100
                'Optimization complete!'
              elsif percentage > 0
                "Optimizing images... #{completed_count}/#{total_jobs} completed"
              else
                'Starting optimization...'
              end
    
    render json: {
      percentage: percentage,
      message: message,
      completed: percentage >= 100,
      completed_count: completed_count,
      total_jobs: total_jobs
    }
  end
  
  # POST /admin/media/regenerate_variants
  def regenerate_variants
    upload_id = params[:upload_id]
    
    if upload_id
      # Regenerate variants for specific upload
      upload = Upload.find(upload_id)
      medium = upload.media.first
      
      if medium
        OptimizeImageJob.perform_later(medium_id: medium.id)
        render json: { 
          success: true, 
          message: 'Variants regeneration queued' 
        }
      else
        render json: { 
          success: false, 
          message: 'No medium found for this upload' 
        }
      end
    else
      # Regenerate variants for all images
      optimized_uploads = Upload.joins(:file_attachment)
                                .where(active_storage_blobs: { content_type: ['image/jpeg', 'image/png', 'image/gif'] })
                                .where.not(variants: [nil, {}])
      
      job_count = 0
      optimized_uploads.find_each do |upload|
        upload.media.each do |medium|
          OptimizeImageJob.perform_later(medium_id: medium.id)
          job_count += 1
        end
      end
      
      render json: { 
        success: true, 
        message: "Queued #{job_count} images for variant regeneration" 
      }
    end
  end
  
  # DELETE /admin/media/clear_variants
  def clear_variants
    upload_id = params[:upload_id]
    
    if upload_id
      # Clear variants for specific upload
      upload = Upload.find(upload_id)
      clear_upload_variants(upload)
      
      render json: { 
        success: true, 
        message: 'Variants cleared for this image' 
      }
    else
      # Clear all variants (dangerous operation)
      render json: { 
        success: false, 
        message: 'Bulk variant clearing not implemented for safety' 
      }
    end
  end
  
  # GET /admin/media/optimization_report
  def report
    @stats = calculate_detailed_stats
    @recent_optimizations = get_recent_optimizations
    @space_saved = calculate_space_saved
  end
  
  private
  
  def calculate_optimization_stats
    total_images = Upload.joins(:file_attachment)
                         .where(active_storage_blobs: { content_type: ['image/jpeg', 'image/png', 'image/gif'] })
                         .count
    
    optimized_images = Upload.joins(:file_attachment)
                             .where(active_storage_blobs: { content_type: ['image/jpeg', 'image/png', 'image/gif'] })
                             .where.not(variants: [nil, {}])
                             .count
    
    webp_variants = Upload.where("variants LIKE ?", '%webp%').count
    avif_variants = Upload.where("variants LIKE ?", '%avif%').count
    
    {
      total_images: total_images,
      optimized_images: optimized_images,
      unoptimized_images: total_images - optimized_images,
      webp_variants: webp_variants,
      avif_variants: avif_variants,
      optimization_percentage: total_images > 0 ? ((optimized_images.to_f / total_images) * 100).round(1) : 0
    }
  end
  
  def count_unoptimized_images
    Upload.joins(:file_attachment)
          .where(active_storage_blobs: { content_type: ['image/jpeg', 'image/png', 'image/gif'] })
          .where(variants: [nil, {}])
          .count
  end
  
  def count_optimized_images
    Upload.joins(:file_attachment)
          .where(active_storage_blobs: { content_type: ['image/jpeg', 'image/png', 'image/gif'] })
          .where.not(variants: [nil, {}])
          .count
  end
  
  def get_unoptimized_uploads
    Upload.joins(:file_attachment)
          .where(active_storage_blobs: { content_type: ['image/jpeg', 'image/png', 'image/gif'] })
          .where(variants: [nil, {}])
  end
  
  def clear_upload_variants(upload)
    return unless upload.variants
    
    # Delete variant blobs
    upload.variants.each do |format, variant_data|
      blob_id = variant_data['blob_id']
      blob = ActiveStorage::Blob.find_by(id: blob_id)
      blob&.purge
    end
    
    # Clear variants from upload
    upload.update!(variants: {})
  end
  
  def calculate_detailed_stats
    stats = calculate_optimization_stats
    
    # Add more detailed statistics
    stats.merge({
      responsive_variants: count_responsive_variants,
      average_file_size: calculate_average_file_size,
      total_storage_used: calculate_total_storage_used
    })
  end
  
  def count_responsive_variants
    Upload.where("variants LIKE ?", '%_w%').count
  end
  
  def calculate_average_file_size
    Upload.joins(:file_attachment)
          .where(active_storage_blobs: { content_type: ['image/jpeg', 'image/png', 'image/gif'] })
          .average('active_storage_blobs.byte_size')
          &.round(2) || 0
  end
  
  def calculate_total_storage_used
    Upload.joins(:file_attachment)
          .where(active_storage_blobs: { content_type: ['image/jpeg', 'image/png', 'image/gif'] })
          .sum('active_storage_blobs.byte_size')
          &.round(2) || 0
  end
  
  def calculate_space_saved
    # Estimate space saved based on optimization
    total_images = calculate_optimization_stats[:total_images]
    optimized_images = calculate_optimization_stats[:optimized_images]
    
    # Assume 30% average savings per optimized image
    estimated_savings = (optimized_images * 0.3).round(2)
    
    {
      estimated_mb_saved: estimated_savings,
      estimated_percentage: total_images > 0 ? ((estimated_savings / total_images) * 100).round(1) : 0
    }
  end
  
  def get_recent_optimizations
    Upload.joins(:file_attachment)
          .where(active_storage_blobs: { content_type: ['image/jpeg', 'image/png', 'image/gif'] })
          .where.not(variants: [nil, {}])
          .order(updated_at: :desc)
          .limit(10)
  end
end
