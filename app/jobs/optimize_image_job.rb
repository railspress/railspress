# Background job for image optimization
class OptimizeImageJob < ApplicationJob
  queue_as :default

  def perform(medium_id:, optimization_type: 'upload', request_context: {})
    medium = Medium.find_by(id: medium_id)
    return unless medium&.upload&.file&.attached?
    return unless medium.image?

    Rails.logger.info "Starting image optimization for medium #{medium_id}"
    
    # Use the ImageOptimizationService with logging
    optimization_service = ImageOptimizationService.new(
      medium, 
      optimization_type: optimization_type,
      request_context: request_context
    )
    
    # Optimize the main image
    if optimization_service.optimize!
      Rails.logger.info "Main image optimization completed for medium #{medium_id}"
    else
      Rails.logger.info "Main image optimization skipped for medium #{medium_id}"
    end
    
    Rails.logger.info "Image optimization process completed for medium #{medium_id}"
  rescue => e
    Rails.logger.error "Image optimization failed for medium #{medium_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end
