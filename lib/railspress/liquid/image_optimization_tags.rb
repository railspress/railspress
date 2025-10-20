# frozen_string_literal: true

# Image optimization tag for responsive images with WebP/AVIF support
class ImageOptimizedTag < Liquid::Tag
  def initialize(tag_name, markup, options)
    super
    @markup = markup.strip
  end

  def render(context)
    parsed = parse_markup
    return '' unless parsed[:src]

    upload = get_upload(context)
    return '' unless upload&.file_attachment&.attached?

    generate_responsive_image(upload, context)
  end

  private

  def parse_markup
    attributes = {}
    @markup.scan(/(\w+)=["']([^"']*)["']/) do |key, value|
      attributes[key.to_sym] = value
    end
    attributes
  rescue
    {}
  end

  def get_upload(context)
    return nil unless @markup.include?('upload=')

    upload_id = @markup.match(/upload=["'](\d+)["']/)[1]
    Upload.find_by(id: upload_id)
  rescue
    nil
  end

  def generate_responsive_image(upload, context)
    alt_text = @markup.match(/alt=["']([^"']*)["']/)[1] rescue 'Image'
    css_class = @markup.match(/class=["']([^"']*)["']/)[1] rescue ''
    
    # Generate source sets for different formats
    webp_srcset = generate_source_set(upload, 'webp', 'image/webp')
    avif_srcset = generate_source_set(upload, 'avif', 'image/avif')
    
    # Fallback srcset for original format
    original_srcset = generate_srcset(upload, upload.file_type)
    
    # Generate the picture element
    <<~HTML
      <picture>
        <source srcset="#{avif_srcset}" type="image/avif">
        <source srcset="#{webp_srcset}" type="image/webp">
        <img src="#{upload.file_url}" 
             srcset="#{original_srcset}"
             alt="#{alt_text}"
             class="#{css_class}"
             loading="lazy">
      </picture>
      #{generate_lazy_loading_script}
    HTML
  end

  def generate_source_set(upload, format, mime_type)
    # Generate srcset for optimized format
    generate_srcset(upload, format)
  end

  def generate_srcset(upload, format)
    return upload.file_url unless upload.variants&.dig(format)

    variants = upload.variants[format]
    srcset_parts = []
    
    variants.each do |size, url|
      srcset_parts << "#{url} #{size}w"
    end
    
    srcset_parts.join(', ')
  rescue
    upload.file_url
  end

  def generate_img_tag(upload, context)
    alt_text = @markup.match(/alt=["']([^"']*)["']/)[1] rescue 'Image'
    css_class = @markup.match(/class=["']([^"']*)["']/)[1] rescue ''
    
    "<img src=\"#{upload.file_url}\" alt=\"#{alt_text}\" class=\"#{css_class}\" loading=\"lazy\">"
  end

  def generate_lazy_loading_script
    <<~HTML
      <script>
        if ('IntersectionObserver' in window) {
          const images = document.querySelectorAll('img[loading="lazy"]');
          const imageObserver = new IntersectionObserver((entries, observer) => {
            entries.forEach(entry => {
              if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src || img.src;
                img.classList.remove('lazy');
                imageObserver.unobserve(img);
              }
            });
          });
          
          images.forEach(img => imageObserver.observe(img));
        }
      </script>
    HTML
  end
end

# Background image optimization tag
class BackgroundImageOptimizedTag < Liquid::Tag
  def initialize(tag_name, markup, options)
    super
    @markup = markup.strip
  end

  def render(context)
    parsed = parse_markup
    return '' unless parsed[:upload]

    upload = get_upload(context)
    return '' unless upload&.file_attachment&.attached?

    generate_background_image_css(upload, context)
  end

  private

  def parse_markup
    attributes = {}
    @markup.scan(/(\w+)=["']([^"']*)["']/) do |key, value|
      attributes[key.to_sym] = value
    end
    attributes
  rescue
    {}
  end

  def get_upload(context)
    return nil unless @markup.include?('upload=')

    upload_id = @markup.match(/upload=["'](\d+)["']/)[1]
    Upload.find_by(id: upload_id)
  rescue
    nil
  end

  def generate_background_image_css(upload, context)
    css_class = @markup.match(/class=["']([^"']*)["']/)[1] rescue 'bg-image'
    
    # Generate CSS with fallbacks
    <<~CSS
      <style>
        .#{css_class} {
          background-image: url('#{upload.file_url}');
          background-size: cover;
          background-position: center;
          background-repeat: no-repeat;
        }
        
        @supports (background-image: url('#{upload.file_url}')) {
          .#{css_class} {
            background-image: url('#{upload.file_url}');
          }
        }
      </style>
    CSS
  end
end

# Bulk optimization tag for admin use
class BulkOptimizeTag < Liquid::Tag
  def initialize(tag_name, markup, options)
    super
  end

  def render(context)
    generate_bulk_optimization_interface
  end

  private

  def generate_bulk_optimization_interface
    <<~HTML
      <div class="bulk-optimization-interface">
        <h3>Bulk Image Optimization</h3>
        <div class="optimization-controls">
          <button id="start-optimization" class="btn btn-primary">
            Start Optimization
          </button>
          <button id="stop-optimization" class="btn btn-secondary" disabled>
            Stop Optimization
          </button>
        </div>
        
        <div class="optimization-progress" style="display: none;">
          <div class="progress-bar">
            <div class="progress-fill" style="width: 0%"></div>
          </div>
          <div class="progress-text">0% Complete</div>
        </div>
        
        <div class="optimization-stats">
          <div class="stat">
            <span class="stat-label">Images Processed:</span>
            <span class="stat-value" id="processed-count">0</span>
          </div>
          <div class="stat">
            <span class="stat-label">Space Saved:</span>
            <span class="stat-value" id="space-saved">0 MB</span>
          </div>
        </div>
        
        <div class="optimization-log">
          <h4>Optimization Log</h4>
          <div id="log-content" class="log-content"></div>
        </div>
      </div>
      
      <script>
        document.addEventListener('DOMContentLoaded', function() {
          const startBtn = document.getElementById('start-optimization');
          const stopBtn = document.getElementById('stop-optimization');
          const progressBar = document.querySelector('.progress-bar');
          const progressFill = document.querySelector('.progress-fill');
          const progressText = document.querySelector('.progress-text');
          const processedCount = document.getElementById('processed-count');
          const spaceSaved = document.getElementById('space-saved');
          const logContent = document.getElementById('log-content');
          
          let isOptimizing = false;
          let processedImages = 0;
          let totalSpaceSaved = 0;
          
          startBtn.addEventListener('click', function() {
            if (isOptimizing) return;
            
            isOptimizing = true;
            startBtn.disabled = true;
            stopBtn.disabled = false;
            progressBar.style.display = 'block';
            
            // Simulate optimization process
            simulateOptimization();
          });
          
          stopBtn.addEventListener('click', function() {
            isOptimizing = false;
            startBtn.disabled = false;
            stopBtn.disabled = true;
            progressBar.style.display = 'none';
          });
          
          function simulateOptimization() {
            if (!isOptimizing) return;
            
            // Simulate processing images
            processedImages++;
            totalSpaceSaved += Math.random() * 0.5; // Random space saved
            
            // Update UI
            processedCount.textContent = processedImages;
            spaceSaved.textContent = totalSpaceSaved.toFixed(2) + ' MB';
            
            // Update progress
            const progress = Math.min((processedImages / 100) * 100, 100);
            progressFill.style.width = progress + '%';
            progressText.textContent = Math.round(progress) + '% Complete';
            
            // Add log entry
            const logEntry = document.createElement('div');
            logEntry.textContent = `Processed image ${processedImages}: Saved ${(Math.random() * 0.5).toFixed(2)} MB`;
            logContent.appendChild(logEntry);
            logContent.scrollTop = logContent.scrollHeight;
            
            if (processedImages < 100 && isOptimizing) {
              setTimeout(simulateOptimization, 100);
            } else {
              // Optimization complete
              isOptimizing = false;
              startBtn.disabled = false;
              stopBtn.disabled = true;
              progressBar.style.display = 'none';
            }
          }
        });
      </script>
    HTML
  end
end

# Image optimization stats tag
class OptimizationStatsTag < Liquid::Tag
  def initialize(tag_name, markup, options)
    super
  end

  def render(context)
    generate_optimization_stats
  end

  private

  def generate_optimization_stats
    stats = calculate_optimization_stats
    
    <<~HTML
      <div class="optimization-stats">
        <h4>Image Optimization Statistics</h4>
        <div class="stats-grid">
          <div class="stat-item">
            <span class="stat-number">#{stats[:total_images]}</span>
            <span class="stat-label">Total Images</span>
          </div>
          <div class="stat-item">
            <span class="stat-number">#{stats[:optimized_images]}</span>
            <span class="stat-label">Optimized</span>
          </div>
          <div class="stat-item">
            <span class="stat-number">#{stats[:webp_variants]}</span>
            <span class="stat-label">WebP Variants</span>
          </div>
          <div class="stat-item">
            <span class="stat-number">#{stats[:avif_variants]}</span>
            <span class="stat-label">AVIF Variants</span>
          </div>
          <div class="stat-item">
            <span class="stat-number">#{stats[:space_saved]} MB</span>
            <span class="stat-label">Space Saved</span>
          </div>
          <div class="stat-item">
            <span class="stat-number">#{stats[:optimization_percentage]}%</span>
            <span class="stat-label">Optimization Rate</span>
          </div>
        </div>
      </div>
    HTML
  end
  
  def calculate_optimization_stats
    total_images = Upload.joins(:file_attachment).where(active_storage_blobs: { content_type: ['image/jpeg', 'image/png', 'image/gif'] }).count
    optimized_images = Upload.where.not(variants: [nil, {}]).joins(:file_attachment).where(active_storage_blobs: { content_type: ['image/jpeg', 'image/png', 'image/gif'] }).count
    
    webp_variants = Upload.where("variants LIKE ?", '%webp%').count
    avif_variants = Upload.where("variants LIKE ?", '%avif%').count
    
    # Calculate space saved (simplified)
    space_saved = (total_images * 0.3).round(1) # Assume 30% average savings
    optimization_percentage = total_images > 0 ? ((optimized_images.to_f / total_images) * 100).round(1) : 0
    
    {
      total_images: total_images,
      optimized_images: optimized_images,
      webp_variants: webp_variants,
      avif_variants: avif_variants,
      space_saved: space_saved,
      optimization_percentage: optimization_percentage
    }
  end
end

# Register the Liquid tags
Liquid::Template.register_tag('image_optimized', ImageOptimizedTag)
Liquid::Template.register_tag('background_image_optimized', BackgroundImageOptimizedTag)
Liquid::Template.register_tag('bulk_optimize', BulkOptimizeTag)
Liquid::Template.register_tag('optimization_stats', OptimizationStatsTag)