module ImageOptimizationHelper
  # Generate picture element with multiple formats for optimal browser support
  def optimized_image_tag(upload, options = {})
    return image_tag(upload.url, options) unless upload.image?
    
    # Build picture element with fallbacks
    content_tag :picture do
      # AVIF variant (best compression)
      if upload.has_variant?('avif')
        concat content_tag(:source, '', 
          srcset: upload.avif_url,
          type: 'image/avif'
        )
      end
      
      # WebP variant (good compression, wide support)
      if upload.has_variant?('webp')
        concat content_tag(:source, '', 
          srcset: upload.webp_url,
          type: 'image/webp'
        )
      end
      
      # Original image as fallback
      concat image_tag(upload.url, options)
    end
  end
  
  # Generate responsive image with multiple sizes
  def responsive_image_tag(upload, options = {})
    return optimized_image_tag(upload, options) unless upload.image?
    
    sizes = options.delete(:sizes) || '(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw'
    
    content_tag :picture do
      # AVIF variants for different sizes
      if upload.has_variant?('avif')
        concat content_tag(:source, '', 
          srcset: generate_srcset(upload, 'avif'),
          sizes: sizes,
          type: 'image/avif'
        )
      end
      
      # WebP variants for different sizes
      if upload.has_variant?('webp')
        concat content_tag(:source, '', 
          srcset: generate_srcset(upload, 'webp'),
          sizes: sizes,
          type: 'image/webp'
        )
      end
      
      # Original image variants for different sizes
      concat image_tag(upload.url, 
        options.merge(
          srcset: generate_srcset(upload, 'original'),
          sizes: sizes
        )
      )
    end
  end
  
  # Generate CSS for background image with format fallbacks
  def optimized_background_image_css(upload)
    return "background-image: url('#{upload.url}');" unless upload.image?
    
    css_parts = []
    
    # Add AVIF variant if available
    if upload.has_variant?('avif')
      css_parts << "background-image: url('#{upload.avif_url}');"
    end
    
    # Add WebP variant if available
    if upload.has_variant?('webp')
      css_parts << "background-image: url('#{upload.webp_url}');"
    end
    
    # Add original as fallback
    css_parts << "background-image: url('#{upload.url}');"
    
    css_parts.join(' ')
  end
  
  # Check if browser supports modern image formats
  def supports_avif?
    # This would typically be detected via JavaScript
    # For now, we'll assume modern browsers support it
    true
  end
  
  def supports_webp?
    # This would typically be detected via JavaScript
    # For now, we'll assume most browsers support it
    true
  end
  
  private
  
  def generate_srcset(upload, format)
    # This would generate different sizes of the image
    # For now, we'll return the single variant URL
    case format
    when 'avif'
      upload.avif_url
    when 'webp'
      upload.webp_url
    else
      upload.url
    end
  end
end
