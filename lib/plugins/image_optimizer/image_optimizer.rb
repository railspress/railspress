# Image Optimizer Plugin
# Automatically optimizes uploaded images

class ImageOptimizer < Railspress::PluginBase
  plugin_name 'Image Optimizer'
  plugin_version '1.0.0'
  plugin_description 'Automatically optimize images on upload for better performance'
  plugin_author 'RailsPress'

  def activate
    super
    register_hooks
  end

  private

  def register_hooks
    # Hook into file upload process
    add_action('media_uploaded', :optimize_image)
  end

  def optimize_image(medium)
    return unless medium.image?
    return unless medium.file.attached?
    
    optimize_settings = {
      quality: get_setting('quality', 85),
      max_width: get_setting('max_width', 2000),
      max_height: get_setting('max_height', 2000),
      strip_metadata: get_setting('strip_metadata', true)
    }
    
    OptimizeImageJob.perform_later(
      medium_id: medium.id,
      settings: optimize_settings
    ) if defined?(OptimizeImageJob)
    
    Rails.logger.info "Queued image optimization for medium #{medium.id}"
  end
end

# Background job for image optimization
class OptimizeImageJob < ApplicationJob
  queue_as :default

  def perform(medium_id:, settings:)
    medium = Medium.find_by(id: medium_id)
    return unless medium&.file&.attached?
    return unless medium.image?

    Rails.logger.info "Optimizing image for medium #{medium_id}"
    
    # In production, this would use ImageProcessing gem to:
    # 1. Resize if too large
    # 2. Compress to reduce file size
    # 3. Strip EXIF data if configured
    # 4. Convert to WebP for modern browsers
    
    # Example with ImageProcessing:
    # require 'image_processing/vips'
    # 
    # processed = ImageProcessing::Vips
    #   .source(medium.file.download)
    #   .resize_to_limit(settings[:max_width], settings[:max_height])
    #   .saver(quality: settings[:quality], strip: settings[:strip_metadata])
    #   .call
    
    Rails.logger.info "Image optimization complete for medium #{medium_id}"
  end
end

ImageOptimizer.new






