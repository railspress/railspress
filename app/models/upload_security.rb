class UploadSecurity < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant)
  
  # Serialization
  serialize :allowed_extensions, JSON
  serialize :blocked_extensions, JSON
  serialize :allowed_mime_types, JSON
  serialize :blocked_mime_types, JSON
  
  # Validations
  validates :max_file_size, presence: true, numericality: { greater_than: 0 }
  
  # Callbacks
  before_validation :set_defaults
  after_update :update_global_settings
  
  # Default values
  DEFAULT_ALLOWED_EXTENSIONS = %w[jpg jpeg png gif webp pdf doc docx txt csv xlsx ppt pptx zip].freeze
  DEFAULT_BLOCKED_EXTENSIONS = %w[exe bat cmd sh php js html htm asp aspx jsp].freeze
  DEFAULT_ALLOWED_MIME_TYPES = %w[
    image/jpeg image/png image/gif image/webp
    application/pdf
    text/plain text/csv
    application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.ms-powerpoint application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/zip
  ].freeze
  DEFAULT_BLOCKED_MIME_TYPES = %w[
    application/x-executable application/x-msdownload
    application/x-sh application/x-bat
    text/html text/javascript
    application/x-php application/x-asp
  ].freeze
  
  # Class methods
  def self.current
    find_by(tenant: ActsAsTenant.current_tenant) || create_default!
  end
  
  def self.create_default!
    create!(
      max_file_size: 10.megabytes,
      allowed_extensions: DEFAULT_ALLOWED_EXTENSIONS,
      blocked_extensions: DEFAULT_BLOCKED_EXTENSIONS,
      allowed_mime_types: DEFAULT_ALLOWED_MIME_TYPES,
      blocked_mime_types: DEFAULT_BLOCKED_MIME_TYPES,
      scan_for_viruses: false,
      quarantine_suspicious: true,
      auto_approve_trusted: false,
      tenant: ActsAsTenant.current_tenant
    )
  end
  
  # Instance methods
  def max_file_size_human
    ActiveSupport::NumberHelper.number_to_human_size(max_file_size)
  end
  
  def max_file_size_human=(value)
    self.max_file_size = parse_file_size(value)
  end
  
  def allowed_extensions_list
    Array(allowed_extensions).join(', ')
  end
  
  def allowed_extensions_list=(value)
    self.allowed_extensions = value.split(',').map(&:strip).map(&:downcase).reject(&:blank?)
  end
  
  def blocked_extensions_list
    Array(blocked_extensions).join(', ')
  end
  
  def blocked_extensions_list=(value)
    self.blocked_extensions = value.split(',').map(&:strip).map(&:downcase).reject(&:blank?)
  end
  
  def allowed_mime_types_list
    Array(allowed_mime_types).join(', ')
  end
  
  def allowed_mime_types_list=(value)
    self.allowed_mime_types = value.split(',').map(&:strip).reject(&:blank?)
  end
  
  def blocked_mime_types_list
    Array(blocked_mime_types).join(', ')
  end
  
  def blocked_mime_types_list=(value)
    self.blocked_mime_types = value.split(',').map(&:strip).reject(&:blank?)
  end
  
  # Security validation methods
  def file_allowed?(file)
    return false if file.nil?
    
    # Check file size
    return false if file.size > max_file_size
    
    # Get file extension
    extension = File.extname(file.original_filename).downcase.gsub('.', '')
    
    # Check blocked extensions first (more restrictive)
    return false if Array(blocked_extensions).include?(extension)
    
    # Check allowed extensions if specified
    if allowed_extensions.present?
      return false unless Array(allowed_extensions).include?(extension)
    end
    
    # Check MIME type if available
    if file.content_type.present?
      # Check blocked MIME types first
      return false if Array(blocked_mime_types).include?(file.content_type)
      
      # Check allowed MIME types if specified
      if allowed_mime_types.present?
        return false unless Array(allowed_mime_types).include?(file.content_type)
      end
    end
    
    true
  end
  
  def file_suspicious?(file)
    return false unless quarantine_suspicious?
    
    # Check for suspicious patterns
    filename = file.original_filename.downcase
    
    # Double extensions (e.g., file.jpg.exe)
    return true if filename.match?(/\..*\..*\./)
    
    # Executable extensions disguised as images
    suspicious_patterns = [
      /\.(jpg|jpeg|png|gif)\.(exe|bat|cmd|sh)$/,
      /\.(pdf|doc)\.(exe|bat|cmd|sh)$/,
      /\.(zip|rar)\.(exe|bat|cmd|sh)$/
    ]
    
    return true if suspicious_patterns.any? { |pattern| filename.match?(pattern) }
    
    false
  end
  
  private
  
  def set_defaults
    self.max_file_size ||= 10.megabytes
    self.allowed_extensions ||= DEFAULT_ALLOWED_EXTENSIONS
    self.blocked_extensions ||= DEFAULT_BLOCKED_EXTENSIONS
    self.allowed_mime_types ||= DEFAULT_ALLOWED_MIME_TYPES
    self.blocked_mime_types ||= DEFAULT_BLOCKED_MIME_TYPES
    self.scan_for_viruses = false if scan_for_viruses.nil?
    self.quarantine_suspicious = true if quarantine_suspicious.nil?
    self.auto_approve_trusted = false if auto_approve_trusted.nil?
  end
  
  def parse_file_size(value)
    case value.to_s.downcase
    when /(\d+)\s*mb?/
      $1.to_i.megabytes
    when /(\d+)\s*gb?/
      $1.to_i.gigabytes
    when /(\d+)\s*kb?/
      $1.to_i.kilobytes
    when /(\d+)\s*b?/
      $1.to_i.bytes
    else
      value.to_i
    end
  end
  
  def update_global_settings
    # Update global upload security settings
    Rails.application.config.upload_security = {
      max_file_size: max_file_size,
      allowed_extensions: allowed_extensions,
      blocked_extensions: blocked_extensions,
      allowed_mime_types: allowed_mime_types,
      blocked_mime_types: blocked_mime_types,
      scan_for_viruses: scan_for_viruses,
      quarantine_suspicious: quarantine_suspicious,
      auto_approve_trusted: auto_approve_trusted
    }
  end
end
