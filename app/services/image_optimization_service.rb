class ImageOptimizationService
  include ActiveSupport::Configurable
  
  # Configuration defaults
  config_accessor :quality, :max_width, :max_height, :strip_metadata, :enable_webp, :enable_avif, :compression_level
  
  # Default values
  self.quality = 85
  self.max_width = 2000
  self.max_height = 2000
  self.strip_metadata = true
  self.enable_webp = true
  self.enable_avif = true
  self.compression_level = 6
  
  # Supported image formats
  SUPPORTED_FORMATS = {
    # Traditional formats
    'jpeg' => { mime: 'image/jpeg', extension: 'jpg', modern: false },
    'png' => { mime: 'image/png', extension: 'png', modern: false },
    'gif' => { mime: 'image/gif', extension: 'gif', modern: false },
    'bmp' => { mime: 'image/bmp', extension: 'bmp', modern: false },
    'tiff' => { mime: 'image/tiff', extension: 'tiff', modern: false },
    
    # Modern formats
    'webp' => { mime: 'image/webp', extension: 'webp', modern: true, compression: 'excellent' },
    'avif' => { mime: 'image/avif', extension: 'avif', modern: true, compression: 'excellent' },
    'heic' => { mime: 'image/heic', extension: 'heic', modern: true, compression: 'excellent' },
    'heif' => { mime: 'image/heif', extension: 'heif', modern: true, compression: 'excellent' },
    'jxl' => { mime: 'image/jxl', extension: 'jxl', modern: true, compression: 'excellent' },
    'jp2' => { mime: 'image/jp2', extension: 'jp2', modern: true, compression: 'good' },
    'j2k' => { mime: 'image/j2k', extension: 'j2k', modern: true, compression: 'good' }
  }.freeze
  
  # Compression level configurations (inspired by Smush)
  COMPRESSION_LEVELS = {
    'lossless' => {
      name: 'Lossless',
      description: 'Maximum quality, minimal compression',
      quality: 95,
      compression_level: 1,
      lossy: false,
      expected_savings: '5-15%',
      recommended_for: 'Professional photography, high-quality images'
    },
    'lossy' => {
      name: 'Lossy',
      description: 'Balanced quality and compression',
      quality: 85,
      compression_level: 6,
      lossy: true,
      expected_savings: '25-40%',
      recommended_for: 'General web images, blog posts'
    },
    'ultra' => {
      name: 'Ultra',
      description: 'Maximum compression, slight quality loss',
      quality: 75,
      compression_level: 9,
      lossy: true,
      expected_savings: '40-60%',
      recommended_for: 'High-traffic sites, mobile optimization'
    },
    'custom' => {
      name: 'Custom',
      description: 'User-defined settings',
      quality: 85, # Default fallback
      compression_level: 6, # Default fallback
      lossy: true, # Default fallback
      expected_savings: 'Variable',
      recommended_for: 'Advanced users'
    }
  }.freeze
  
  def initialize(medium, optimization_type: 'upload', request_context: {})
    @medium = medium
    @upload = medium&.upload
    @storage_config = StorageConfigurationService.new
    @optimization_type = optimization_type
    @request_context = request_context
    @start_time = Time.current
    @log_entry = nil
    load_settings
  end
  
  # Main optimization method
  def optimize!
    return false unless should_optimize?
    
    Rails.logger.info "Starting image optimization for medium #{@medium.id}"
    
    # Create log entry
    create_log_entry
    
    begin
      # Get original file
      original_file = @upload.file.download
      original_size = original_file.size
      
      # Process the image
      processed_file = process_image(original_file)
      
      if processed_file && processed_file.size < original_size
        # Replace the original file with optimized version
        replace_file(processed_file)
        
        # Generate variants (WebP, AVIF, HEIC, JXL, etc.)
        variants_generated = []
        responsive_variants_generated = []
        
        if variants_enabled?
          variants_generated = generate_all_variants(original_file)
          responsive_variants_generated = generate_responsive_variants!(original_file)
        end
        
        # Update log entry with success
        update_log_entry(
          status: 'success',
          original_size: original_size,
          optimized_size: processed_file.size,
          variants_generated: variants_generated,
          responsive_variants_generated: responsive_variants_generated
        )
        
        Rails.logger.info "Image optimization completed for medium #{@medium.id}. Size reduced from #{original_size} to #{processed_file.size} bytes"
        true
      else
        # Update log entry with skipped status
        update_log_entry(
          status: 'skipped',
          original_size: original_size,
          optimized_size: original_size,
          error_message: 'No size reduction achieved'
        )
        
        Rails.logger.info "Image optimization skipped for medium #{@medium.id} - no size reduction achieved"
        false
      end
    rescue => e
      # Update log entry with error
      update_log_entry(
        status: 'failed',
        original_size: original_file&.size || 0,
        optimized_size: original_file&.size || 0,
        error_message: e.message
      )
      
      Rails.logger.error "Image optimization failed for medium #{@medium.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      false
    end
  end
  
  # Generate all modern format variants
  def generate_all_variants(original_file)
    variants_generated = []
    
    # Generate WebP variant
    if enable_webp
      webp_file = generate_format_variant(original_file, 'webp')
      if webp_file
        store_variant(webp_file, 'webp')
        variants_generated << 'webp'
      end
    end
    
    # Generate AVIF variant
    if enable_avif
      avif_file = generate_format_variant(original_file, 'avif')
      if avif_file
        store_variant(avif_file, 'avif')
        variants_generated << 'avif'
      end
    end
    
    # Generate HEIC variant (if enabled)
    if SiteSetting.get('enable_heic_variants', false)
      heic_file = generate_format_variant(original_file, 'heic')
      if heic_file
        store_variant(heic_file, 'heic')
        variants_generated << 'heic'
      end
    end
    
    # Generate JXL variant (if enabled)
    if SiteSetting.get('enable_jxl_variants', false)
      jxl_file = generate_format_variant(original_file, 'jxl')
      if jxl_file
        store_variant(jxl_file, 'jxl')
        variants_generated << 'jxl'
      end
    end
    
    variants_generated
  end
  
  # Generate optimized variants (legacy method for compatibility)
  def generate_variants!
    return false unless variants_enabled?
    
    Rails.logger.info "Generating image variants for medium #{@medium.id}"
    
    begin
      original_file = @upload.file.download
      variants_generated = generate_all_variants(original_file)
      
      # Generate responsive breakpoint variants
      generate_responsive_variants!(original_file)
      
      Rails.logger.info "Image variants generated for medium #{@medium.id}: #{variants_generated.join(', ')}"
      true
    rescue => e
      Rails.logger.error "Variant generation failed for medium #{@medium.id}: #{e.message}"
      false
    end
  end
  
  # Generate responsive variants for different breakpoints
  def generate_responsive_variants!(original_file)
    return false unless SiteSetting.get('enable_responsive_variants', true)
    
    breakpoints = SiteSetting.get('responsive_breakpoints', '320,640,768,1024,1200,1920').split(',').map(&:to_i)
    responsive_variants_generated = []
    
    breakpoints.each do |width|
      # Generate WebP responsive variants
      if enable_webp
        webp_responsive = generate_responsive_variant(original_file, width, 'webp')
        if webp_responsive
          store_responsive_variant(webp_responsive, 'webp', width)
          responsive_variants_generated << "webp_#{width}w"
        end
      end
      
      # Generate AVIF responsive variants
      if enable_avif
        avif_responsive = generate_responsive_variant(original_file, width, 'avif')
        if avif_responsive
          store_responsive_variant(avif_responsive, 'avif', width)
          responsive_variants_generated << "avif_#{width}w"
        end
      end
      
      # Generate original format responsive variants
      original_responsive = generate_responsive_variant(original_file, width, 'original')
      if original_responsive
        store_responsive_variant(original_responsive, 'original', width)
        responsive_variants_generated << "original_#{width}w"
      end
    end
    
    responsive_variants_generated
  end
  
  # Get compression level information
  def compression_level_info
    @compression_config || COMPRESSION_LEVELS['lossy']
  end
  
  def compression_level_name
    @compression_level_name || 'lossy'
  end
  
  def expected_savings
    compression_level_info[:expected_savings]
  end
  
  def recommended_for
    compression_level_info[:recommended_for]
  end
  
  # Class method to get all available compression levels
  def self.available_compression_levels
    COMPRESSION_LEVELS
  end
  
  # Class method to get all supported formats
  def self.supported_formats
    SUPPORTED_FORMATS
  end
  
  # Class method to get modern formats only
  def self.modern_formats
    SUPPORTED_FORMATS.select { |_, config| config[:modern] }
  end
  
  # Class method to get traditional formats only
  def self.traditional_formats
    SUPPORTED_FORMATS.select { |_, config| !config[:modern] }
  end
  
  # Class method to check if format is supported
  def self.supports_format?(format)
    SUPPORTED_FORMATS.key?(format.to_s.downcase)
  end
  
  # Class method to check if format is modern
  def self.modern_format?(format)
    SUPPORTED_FORMATS[format.to_s.downcase]&.dig(:modern) == true
  end
  
  # Instance methods for compression level info
  def compression_level_info
    @compression_config || COMPRESSION_LEVELS['lossy']
  end
  
  def compression_level_name
    @compression_level_name || 'lossy'
  end
  
  def expected_savings
    compression_level_info[:expected_savings]
  end
  
  def recommended_for
    compression_level_info[:recommended_for]
  end
  
  private
  
  def should_optimize?
    return false unless @medium.image?
    return false unless @upload.file.attached?
    return false unless @storage_config.auto_optimize_enabled?
    
    # Check if optimization is enabled in media settings
    SiteSetting.get('auto_optimize_images', false)
  end
  
  def load_settings
    # Get compression level setting
    compression_level_name = SiteSetting.get('image_compression_level', 'lossy')
    compression_config = COMPRESSION_LEVELS[compression_level_name] || COMPRESSION_LEVELS['lossy']
    
    # Apply compression level settings
    if compression_config[:quality]
      self.quality = compression_config[:quality]
    else
      # Use custom settings for custom level
      self.quality = SiteSetting.get('image_quality', 85).to_i
    end
    
    if compression_config[:compression_level]
      self.compression_level = compression_config[:compression_level]
    else
      # Use custom settings for custom level
      self.compression_level = SiteSetting.get('image_compression_level_value', 6).to_i
    end
    
    # Other settings
    self.max_width = SiteSetting.get('image_max_width', 2000).to_i
    self.max_height = SiteSetting.get('image_max_height', 2000).to_i
    self.strip_metadata = SiteSetting.get('strip_image_metadata', true)
    self.enable_webp = SiteSetting.get('enable_webp_variants', true)
    self.enable_avif = SiteSetting.get('enable_avif_variants', true)
    
    # Store compression level info
    @compression_level_name = compression_level_name
    @compression_config = compression_config
  end
  
  def process_image(file_data)
    require 'image_processing/vips'
    
    # Create a temporary file for processing
    temp_file = Tempfile.new(['original_input', '.jpg'])
    temp_file.binmode
    temp_file.write(file_data)
    temp_file.rewind
    
    processed = ImageProcessing::Vips
      .source(temp_file.path)
      .resize_to_limit(max_width, max_height)
      .saver(
        quality: quality,
        strip: strip_metadata,
        optimize: true,
        compression_level: compression_level # Apply compression level
      )
    
    result = processed.call
    File.read(result.path)
  rescue => e
    Rails.logger.warn "Image processing failed: #{e.message}"
    nil
  ensure
    temp_file&.close
    temp_file&.unlink
    File.unlink(result.path) if result && File.exist?(result.path)
  end
  
  def generate_format_variant(image_data, format)
    return nil unless image_data
    
    begin
      require 'image_processing/vips'
      
      temp_file = Tempfile.new(['variant_input', '.jpg'])
      temp_file.binmode
      temp_file.write(image_data)
      temp_file.rewind
      
      processed = ImageProcessing::Vips
        .source(temp_file.path)
        .convert(format)
        .saver(
          quality: quality,
          strip: strip_metadata,
          lossless: false,
          compression_level: compression_level
        )
      
      result = processed.call
      File.read(result.path)
    rescue => e
      Rails.logger.warn "#{format.upcase} variant generation failed: #{e.message}"
      nil
    ensure
      temp_file&.close
      temp_file&.unlink
      File.unlink(result.path) if result && File.exist?(result.path)
    end
  end
  
  def replace_file(new_file_data)
    # Delete old blob
    @upload.file.purge
    
    # Attach new blob
    @upload.file.attach(
      io: StringIO.new(new_file_data),
      filename: @upload.file.filename.to_s,
      content_type: @upload.file.content_type
    )
    
    # Update file size
    @upload.update!(file_size: new_file_data.size)
  end
  
  def store_variant(variant_data, format)
    return unless variant_data
    
    # Create variant blob
    variant_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(variant_data),
      filename: "#{@upload.file.filename.base}.#{format}",
      content_type: "image/#{format}"
    )
    
    # Store variant metadata in upload
    variants = @upload.variants || {}
    variants[format] = {
      blob_id: variant_blob.id,
      size: variant_data.size,
      created_at: Time.current
    }
    @upload.update!(variants: variants)
  end
  
  def generate_responsive_variant(image_data, width, format)
    return nil unless image_data
    
    begin
      require 'image_processing/vips'
      
      temp_file = Tempfile.new(['responsive_input', '.jpg'])
      temp_file.binmode
      temp_file.write(image_data)
      temp_file.rewind
      
      processed = ImageProcessing::Vips
        .source(temp_file.path)
        .resize_to_limit(width, width * 2) # Allow 2:1 aspect ratio
        .saver(
          quality: quality,
          strip: strip_metadata,
          optimize: true
        )
      
      # Convert to specific format if needed
      if format == 'webp'
        processed = processed.convert('webp').saver(lossless: false)
      elsif format == 'avif'
        processed = processed.convert('avif').saver(lossless: false)
      end
      
      result = processed.call
      File.read(result.path)
    rescue => e
      Rails.logger.warn "Responsive variant generation failed (#{format}, #{width}px): #{e.message}"
      nil
    ensure
      temp_file&.close
      temp_file&.unlink
      File.unlink(result.path) if result && File.exist?(result.path)
    end
  end
  
  def store_responsive_variant(variant_data, format, width)
    return unless variant_data
    
    # Create responsive variant blob
    extension = format == 'original' ? @upload.file.filename.extension : format
    variant_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(variant_data),
      filename: "#{@upload.file.filename.base}_#{width}w.#{extension}",
      content_type: format == 'original' ? @upload.file.content_type : "image/#{format}"
    )
    
    # Store responsive variant metadata in upload
    variants = @upload.variants || {}
    responsive_key = "#{format}_#{width}w"
    variants[responsive_key] = {
      blob_id: variant_blob.id,
      size: variant_data.size,
      width: width,
      format: format,
      created_at: Time.current
    }
    @upload.update!(variants: variants)
  end
  
  # Logging methods
  def create_log_entry
    @log_entry = ImageOptimizationLog.create!(
      medium: @medium,
      upload: @upload,
      user: @medium.user,
      tenant: @medium.tenant,
      filename: @upload.filename,
      content_type: @upload.content_type,
      compression_level: compression_level_name,
      quality: quality,
      strip_metadata: strip_metadata,
      enable_webp: enable_webp,
      enable_avif: enable_avif,
      optimization_type: @optimization_type,
      status: 'processing',
      processing_time: 0,
      storage_provider: @upload.storage_provider&.name,
      cdn_enabled: @storage_config.cdn_enabled?,
      user_agent: @request_context[:user_agent],
      ip_address: @request_context[:ip_address]
    )
  rescue => e
    Rails.logger.error "Failed to create log entry: #{e.message}"
    @log_entry = nil
  end
  
  def update_log_entry(attributes)
    return unless @log_entry
    
    processing_time = Time.current - @start_time
    
    @log_entry.update!(
      attributes.merge(
        processing_time: processing_time
      )
    )
  rescue => e
    Rails.logger.error "Failed to update log entry: #{e.message}"
  end
  
  def log_warning(message)
    return unless @log_entry
    
    warnings = @log_entry.warnings || []
    warnings << message
    @log_entry.update!(warnings: warnings)
  rescue => e
    Rails.logger.error "Failed to log warning: #{e.message}"
  end
end