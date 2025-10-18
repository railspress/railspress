class StorageConfigurationService
  attr_reader :storage_settings, :tenant

  def initialize(tenant = nil)
    @tenant = tenant || ActsAsTenant.current_tenant
    @storage_settings = load_storage_settings
  end

  # Configure ActiveStorage based on storage settings
  def configure_active_storage
    case storage_settings[:storage_type]
    when 's3'
      configure_s3_storage
    when 'local'
      configure_local_storage
    else
      configure_local_storage # Default fallback
    end
  end

  # Get the appropriate storage service name
  def storage_service_name
    case storage_settings[:storage_type]
    when 's3'
      'amazon'
    when 'local'
      'local'
    else
      'local'
    end
  end

  # Get the storage root path for local storage
  def local_storage_root
    storage_settings[:local_storage_path] || Rails.root.join('storage').to_s
  end

  # Check if CDN is enabled
  def cdn_enabled?
    storage_settings[:enable_cdn] && storage_settings[:cdn_url].present?
  end

  # Get CDN URL
  def cdn_url
    storage_settings[:cdn_url] if cdn_enabled?
  end

  # Check if auto-optimization is enabled
  def auto_optimize_enabled?
    storage_settings[:auto_optimize_uploads]
  end

  # Get max file size in bytes
  def max_file_size_bytes
    storage_settings[:max_file_size] * 1024 * 1024 # Convert MB to bytes
  end

  # Get allowed file types as array
  def allowed_file_types
    return [] unless storage_settings[:allowed_file_types].present?
    storage_settings[:allowed_file_types].split(',').map(&:strip).map(&:downcase)
  end

  # Validate file against storage settings
  def file_allowed?(file)
    return false if file.nil?

    # Check file size
    return false if file.size > max_file_size_bytes

    # Check file extension
    extension = File.extname(file.original_filename).downcase.gsub('.', '')
    return false unless allowed_file_types.include?(extension)

    true
  end

  # Get S3 configuration
  def s3_config
    return {} unless storage_settings[:storage_type] == 's3'

    {
      service: 'S3',
      access_key_id: storage_settings[:storage_access_key],
      secret_access_key: storage_settings[:storage_secret_key],
      region: storage_settings[:storage_region] || 'us-east-1',
      bucket: storage_settings[:storage_bucket],
      endpoint: storage_settings[:storage_endpoint],
      path: storage_settings[:storage_path]
    }.compact
  end

  # Update storage.yml configuration
  def update_storage_config
    storage_yml_path = Rails.root.join('config', 'storage.yml')
    
    # Read current configuration
    current_config = File.exist?(storage_yml_path) ? YAML.load_file(storage_yml_path) : {}
    
    # Update configuration based on storage type
    case storage_settings[:storage_type]
    when 's3'
      current_config['amazon'] = s3_config
      current_config['local'] = {
        'service' => 'Disk',
        'root' => local_storage_root
      }
    when 'local'
      current_config['local'] = {
        'service' => 'Disk',
        'root' => local_storage_root
      }
    end

    # Write updated configuration
    File.write(storage_yml_path, current_config.to_yaml)
    
    # Reload ActiveStorage configuration
    Rails.application.config.active_storage.service = storage_service_name.to_sym
  end

  private

  def load_storage_settings
    # Get current tenant storage settings if available
    tenant_settings = {}
    if @tenant
      tenant_settings = {
        storage_type: @tenant.storage_type || 'local',
        storage_bucket: @tenant.storage_bucket,
        storage_region: @tenant.storage_region,
        storage_access_key: @tenant.storage_access_key,
        storage_secret_key: @tenant.storage_secret_key,
        storage_endpoint: @tenant.storage_endpoint,
        storage_path: @tenant.storage_path
      }
    end

    # Merge with SiteSetting values
    {
      # Storage Type
      storage_type: tenant_settings[:storage_type] || SiteSetting.get('storage_type', 'local'),
      
      # Local Storage Configuration
      local_storage_path: SiteSetting.get('local_storage_path', Rails.root.join('storage').to_s),
      
      # S3 Configuration
      storage_bucket: tenant_settings[:storage_bucket] || SiteSetting.get('storage_bucket', ''),
      storage_region: tenant_settings[:storage_region] || SiteSetting.get('storage_region', 'us-east-1'),
      storage_access_key: tenant_settings[:storage_access_key] || SiteSetting.get('storage_access_key', ''),
      storage_secret_key: tenant_settings[:storage_secret_key] || SiteSetting.get('storage_secret_key', ''),
      storage_endpoint: tenant_settings[:storage_endpoint] || SiteSetting.get('storage_endpoint', ''),
      storage_path: tenant_settings[:storage_path] || SiteSetting.get('storage_path', ''),
      
      # General Storage Settings
      enable_cdn: SiteSetting.get('enable_cdn', false),
      cdn_url: SiteSetting.get('cdn_url', ''),
      auto_optimize_uploads: SiteSetting.get('auto_optimize_uploads', true),
      max_file_size: SiteSetting.get('max_file_size', 10).to_i, # MB
      allowed_file_types: SiteSetting.get('allowed_file_types', 'jpg,jpeg,png,gif,pdf,doc,docx,mp4,mp3')
    }
  end

  def configure_s3_storage
    # S3 configuration is handled by the s3_config method
    # This could be extended to set up S3-specific settings
  end

  def configure_local_storage
    # Ensure local storage directory exists
    storage_path = local_storage_root
    FileUtils.mkdir_p(storage_path) unless File.directory?(storage_path)
    
    # Set proper permissions
    FileUtils.chmod(0755, storage_path)
  end
end
