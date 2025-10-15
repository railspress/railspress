class Uploadcare < Railspress::PluginBase
  plugin_name 'Uploadcare'
  plugin_version '1.0.0'
  plugin_description 'Professional media management and CDN with Uploadcare'
  plugin_author 'RailsPress Team'
  
  # Define comprehensive settings schema
  settings_schema do
    section 'API Configuration', description: 'Your Uploadcare API credentials' do
      text 'public_key', 'Public Key',
        description: 'Your Uploadcare public key (starts with your project ID)',
        required: true,
        placeholder: 'demopublickey',
        pattern: /\A[a-zA-Z0-9]+\z/
      
      text 'secret_key', 'Secret Key',
        description: 'Your Uploadcare secret key (keep this private!)',
        required: false,
        placeholder: 'demoprivatekey'
    end
    
    section 'Upload Widget', description: 'Configure the Uploadcare upload widget' do
      checkbox 'enable_widget', 'Enable Upload Widget',
        description: 'Show Uploadcare widget in admin media section',
        default: true
      
      select 'widget_theme', 'Widget Theme',
        [
          ['Light', 'light'],
          ['Dark', 'dark'],
          ['Minimal', 'minimal']
        ],
        description: 'Visual theme for the upload widget',
        default: 'light'
      
      checkbox 'multiple_files', 'Multiple File Upload',
        description: 'Allow uploading multiple files at once',
        default: true
      
      number 'max_file_size', 'Max File Size (MB)',
        description: 'Maximum file size for uploads',
        default: 25,
        min: 1,
        max: 100
    end
    
    section 'File Sources', description: 'Choose where users can upload files from' do
      checkbox 'source_local', 'Local Files',
        description: 'Upload from computer',
        default: true
      
      checkbox 'source_url', 'From URL',
        description: 'Import from URL',
        default: true
      
      checkbox 'source_camera', 'Camera',
        description: 'Capture from camera/webcam',
        default: true
      
      checkbox 'source_dropbox', 'Dropbox',
        description: 'Import from Dropbox',
        default: false
      
      checkbox 'source_gdrive', 'Google Drive',
        description: 'Import from Google Drive',
        default: false
      
      checkbox 'source_instagram', 'Instagram',
        description: 'Import from Instagram',
        default: false
      
      checkbox 'source_facebook', 'Facebook',
        description: 'Import from Facebook',
        default: false
    end
    
    section 'Image Processing', description: 'Automatic image transformations' do
      checkbox 'auto_crop', 'Auto Crop',
        description: 'Automatically crop images to focus area',
        default: false
      
      checkbox 'auto_rotate', 'Auto Rotate',
        description: 'Automatically rotate images based on EXIF',
        default: true
      
      select 'image_quality', 'Image Quality',
        [
          ['Normal', 'normal'],
          ['Better', 'better'],
          ['Best', 'best'],
          ['Lighter', 'lighter']
        ],
        description: 'Balance between quality and file size',
        default: 'normal'
      
      checkbox 'progressive_jpeg', 'Progressive JPEG',
        description: 'Convert JPEGs to progressive format',
        default: true
      
      checkbox 'strip_metadata', 'Strip Metadata',
        description: 'Remove EXIF data for privacy/smaller files',
        default: false
    end
    
    section 'CDN & Performance', description: 'Content delivery optimization' do
      checkbox 'use_cdn', 'Enable CDN',
        description: 'Serve files through Uploadcare CDN',
        default: true
      
      checkbox 'lazy_loading', 'Lazy Loading',
        description: 'Load images only when visible',
        default: true
      
      checkbox 'responsive_images', 'Responsive Images',
        description: 'Generate multiple sizes for different screens',
        default: true
      
      text 'cdn_base', 'Custom CDN Domain',
        description: 'Custom CNAME for CDN (leave blank for default)',
        placeholder: 'cdn.example.com'
    end
    
    section 'Dashboard', description: 'Uploadcare dashboard integration' do
      checkbox 'show_dashboard', 'Show Dashboard',
        description: 'Embed Uploadcare dashboard in admin',
        default: true
      
      radio 'dashboard_view', 'Default View',
        [
          ['Files', 'files'],
          ['Gallery', 'gallery'],
          ['Analytics', 'analytics']
        ],
        description: 'Default view when opening dashboard',
        default: 'files'
    end
    
    section 'Advanced', description: 'Advanced configuration options' do
      number 'retry_count', 'Upload Retry Count',
        description: 'Number of retry attempts for failed uploads',
        default: 3,
        min: 0,
        max: 10
      
      checkbox 'store_files', 'Store Files Permanently',
        description: 'Store files instead of deleting after 24 hours',
        default: true
      
      checkbox 'secure_signature', 'Secure Upload Signature',
        description: 'Require signed uploads (more secure)',
        default: false
      
      code 'custom_css', 'Custom Widget CSS',
        description: 'Custom CSS for the upload widget',
        language: 'css',
        placeholder: '.uploadcare-widget { border-radius: 8px; }'
    end
  end
  
  def initialize
    super
    setup_uploadcare if enabled?
  end
  
  def activate
    super
    Rails.logger.info "Uploadcare plugin activated"
    validate_api_credentials
  end
  
  def enabled?
    get_setting('enable_widget', true) && 
    get_setting('public_key').present?
  end
  
  # Get widget configuration
  def widget_config
    sources = []
    sources << 'local' if get_setting('source_local', true)
    sources << 'url' if get_setting('source_url', true)
    sources << 'camera' if get_setting('source_camera', true)
    sources << 'dropbox' if get_setting('source_dropbox', false)
    sources << 'gdrive' if get_setting('source_gdrive', false)
    sources << 'instagram' if get_setting('source_instagram', false)
    sources << 'facebook' if get_setting('source_facebook', false)
    
    {
      publicKey: get_setting('public_key'),
      multiple: get_setting('multiple_files', true),
      imagesOnly: false,
      previewStep: true,
      imageShrink: get_setting('responsive_images', true) ? '1024x1024' : false,
      multipleMax: get_setting('multiple_files', true) ? 10 : 1,
      tabs: sources.join(' '),
      systemDialog: false,
      locale: 'en',
      theme: get_setting('widget_theme', 'light'),
      crop: get_setting('auto_crop', false) ? 'free' : false
    }
  end
  
  # Get CDN URL for file
  def cdn_url(uuid, transformations = {})
    base = get_setting('cdn_base').presence || 'https://ucarecdn.com'
    url = "#{base}/#{uuid}/"
    
    if transformations.any?
      operations = []
      operations << "quality/#{transformations[:quality]}" if transformations[:quality]
      operations << "resize/#{transformations[:width]}x#{transformations[:height]}" if transformations[:width]
      operations << "crop/#{transformations[:crop]}" if transformations[:crop]
      operations << 'progressive/yes' if get_setting('progressive_jpeg', true)
      operations << 'autorotate/yes' if get_setting('auto_rotate', true)
      
      url += "#{operations.join('/')}/" if operations.any?
    end
    
    url
  end
  
  # Dashboard URL
  def dashboard_url
    project_id = get_setting('public_key')&.split('_')&.first
    return nil unless project_id
    
    view = get_setting('dashboard_view', 'files')
    "https://uploadcare.com/dashboard/#{project_id}/#{view}/"
  end
  
  private
  
  def setup_uploadcare
    # Register filters to inject Uploadcare widget
    add_filter('admin_head', 10) do |content|
      content + uploadcare_widget_script
    end
    
    # Register action to process uploaded files
    add_action('media_uploaded', 20) do |media|
      process_uploadcare_file(media)
    end
  end
  
  def uploadcare_widget_script
    return '' unless enabled?
    
    config = widget_config.to_json
    
    <<~HTML
      <!-- Uploadcare Widget -->
      <script>
        UPLOADCARE_PUBLIC_KEY = '#{get_setting('public_key')}';
        UPLOADCARE_TABS = '#{widget_config[:tabs]}';
        UPLOADCARE_LOCALE = 'en';
      </script>
      <script src="https://ucarecdn.com/libs/widget/3.x/uploadcare.full.min.js"></script>
      <link rel="stylesheet" href="https://ucarecdn.com/libs/widget/3.x/uploadcare.min.css" />
      
      #{custom_widget_css}
    HTML
  end
  
  def custom_widget_css
    css = get_setting('custom_css')
    return '' if css.blank?
    
    <<~HTML
      <style>
        #{css}
      </style>
    HTML
  end
  
  def process_uploadcare_file(media)
    # Store file permanently if setting is enabled
    if get_setting('store_files', true)
      store_file(media.uploadcare_uuid)
    end
    
    # Apply transformations
    if media.image? && get_setting('responsive_images', true)
      generate_responsive_versions(media)
    end
  end
  
  def store_file(uuid)
    # Call Uploadcare API to store file permanently
    return unless get_setting('secret_key').present?
    
    Rails.logger.info "Storing Uploadcare file: #{uuid}"
    # TODO: Implement actual API call
  end
  
  def generate_responsive_versions(media)
    # Generate responsive image versions
    Rails.logger.info "Generating responsive versions for: #{media.id}"
    # Handled by Uploadcare CDN on-the-fly
  end
  
  def validate_api_credentials
    public_key = get_setting('public_key')
    
    if public_key.blank?
      Rails.logger.warn "Uploadcare: No public key configured"
      return false
    end
    
    # TODO: Test API connection
    Rails.logger.info "Uploadcare: API credentials configured"
    true
  end
end

# Auto-initialize if active
if Plugin.exists?(name: 'Uploadcare', active: true)
  Uploadcare.new
end








