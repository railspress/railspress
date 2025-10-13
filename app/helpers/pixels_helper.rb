# frozen_string_literal: true

module PixelsHelper
  # Render all active pixels for a specific position
  #
  # @param position [Symbol] The position (:head, :body_start, :body_end)
  # @return [String] Rendered HTML
  def render_pixels(position)
    return '' if admin_page?
    
    pixels = Pixel.active.by_position(position).ordered
    return '' if pixels.empty?
    
    output = []
    output << "<!-- RailsPress Tracking Pixels - #{position.to_s.titleize} -->"
    
    pixels.each do |pixel|
      next unless pixel.configured?
      
      output << "<!-- #{pixel.name} (#{pixel.pixel_type.titleize}) -->"
      output << pixel.render_code
    end
    
    output << "<!-- End RailsPress Tracking Pixels -->"
    output.join("\n").html_safe
  end
  
  # Check if we're on an admin page
  def admin_page?
    controller_path.start_with?('admin/')
  end
  
  # Get pixel statistics
  def pixel_stats
    {
      total: Pixel.count,
      active: Pixel.active.count,
      by_position: Pixel.active.group(:position).count
    }
  end
end





