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
    return unless medium.upload&.file&.attached?
    
    # Check if optimization is enabled in settings
    storage_config = StorageConfigurationService.new
    return unless storage_config.auto_optimize_enabled?
    
    # Check media settings
    return unless SiteSetting.get('auto_optimize_images', false)
    
    # Queue optimization job
    OptimizeImageJob.perform_later(medium_id: medium.id)
    
    Rails.logger.info "Queued image optimization for medium #{medium.id}"
  end
end

ImageOptimizer.new








