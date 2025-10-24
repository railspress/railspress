class Upload < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant)
  
  belongs_to :user
  belongs_to :storage_provider, optional: true
  
  # ActiveStorage for file attachment
  has_one_attached :file
  
  # Serialization
  serialize :variants, coder: JSON, type: Hash
  
  # Relationships
  has_many :media, dependent: :destroy
  
  # Validations
  validates :title, presence: true
  validates :file, presence: true
  
  # Scopes
  scope :quarantined, -> { where(quarantined: true) }
  scope :approved, -> { where(quarantined: [false, nil]) }
  scope :temporary, -> { where(temporary: true) }
  scope :permanent, -> { where(temporary: [false, nil]) }
  scope :expired, -> { where('expires_at < ?', Time.current) }
  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  
  # Callbacks
  after_commit :trigger_upload_hooks, on: [:create, :update], if: -> { file.attached? }
  before_validation :configure_storage, on: :create
  
  # Scopes
  scope :images, -> { joins(file_attachment: :blob).where(active_storage_blobs: { content_type: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'] }) }
  scope :videos, -> { joins(file_attachment: :blob).where(active_storage_blobs: { content_type: ['video/mp4', 'video/webm'] }) }
  scope :documents, -> { joins(file_attachment: :blob).where(active_storage_blobs: { content_type: ['application/pdf', 'application/msword'] }) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Methods
  def image?
    file.attached? && file.content_type&.start_with?('image/')
  end
  
  def video?
    file.attached? && file.content_type&.start_with?('video/')
  end
  
  def document?
    file.attached? && file.content_type&.start_with?('application/')
  end
  
  def file_size
    file.attached? ? file.byte_size : 0
  end
  
  def content_type
    file.attached? ? file.content_type : nil
  end
  
  def filename
    file.attached? ? file.filename.to_s : nil
  end
  
  def url
    return nil unless file.attached?
    
    # Check if CDN is enabled
    storage_config = StorageConfigurationService.new
    if storage_config.cdn_enabled?
      # Return CDN URL
      cdn_base = storage_config.cdn_url.chomp('/')
      "#{cdn_base}#{Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)}"
    else
      # Return regular Rails blob path
      Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
    end
  end
  
  def quarantined?
    quarantined == true
  end
  
  def approved?
    !quarantined?
  end
  
  def approve!
    update!(quarantined: false, quarantine_reason: nil)
  end
  
  def reject!
    destroy!
  end
  
  def temporary?
    temporary == true
  end
  
  def expired?
    expires_at.present? && expires_at < Time.current
  end
  
  def active?
    !expired?
  end
  
  def mark_temporary!(duration = 24.hours)
    update!(temporary: true, expires_at: Time.current + duration)
  end
  
  def mark_permanent!
    update!(temporary: false, expires_at: nil)
  end
  
  # Variant methods
  def has_variant?(format)
    variants&.key?(format.to_s)
  end
  
  def variant_url(format)
    return nil unless has_variant?(format)
    
    blob_id = variants[format.to_s]['blob_id']
    blob = ActiveStorage::Blob.find_by(id: blob_id)
    return nil unless blob
    
    storage_config = StorageConfigurationService.new
    if storage_config.cdn_enabled?
      cdn_base = storage_config.cdn_url.chomp('/')
      "#{cdn_base}#{Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)}"
    else
      Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
    end
  end
  
  def webp_url
    variant_url('webp')
  end
  
  def avif_url
    variant_url('avif')
  end
  
  def optimized_url
    # Return the best available format based on browser support
    # This would typically be handled by a helper or view
    avif_url || webp_url || url
  end
  
  # Responsive variant methods
  def responsive_variant_url(format, width)
    return nil unless variants&.dig("#{format}_#{width}w")
    
    blob_id = variants["#{format}_#{width}w"]['blob_id']
    blob = ActiveStorage::Blob.find_by(id: blob_id)
    return nil unless blob
    
    storage_config = StorageConfigurationService.new
    if storage_config.cdn_enabled?
      cdn_base = storage_config.cdn_url.chomp('/')
      "#{cdn_base}#{Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)}"
    else
      Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
    end
  end
  
  def responsive_webp_url(width)
    responsive_variant_url('webp', width)
  end
  
  def responsive_avif_url(width)
    responsive_variant_url('avif', width)
  end
  
  def responsive_original_url(width)
    responsive_variant_url('original', width)
  end
  
  # Generate srcset for responsive images
  def generate_srcset(format = 'auto', breakpoints = [320, 640, 768, 1024, 1200, 1920])
    srcset_parts = []
    
    breakpoints.each do |width|
      url = case format
            when 'avif'
              responsive_avif_url(width) || avif_url
            when 'webp'
              responsive_webp_url(width) || webp_url
            when 'original'
              responsive_original_url(width) || url
            else # auto
              responsive_avif_url(width) || responsive_webp_url(width) || responsive_original_url(width) || url
            end
      
      srcset_parts << "#{url} #{width}w" if url
    end
    
    srcset_parts.join(', ')
  end
  
  # Get available responsive variants
  def available_responsive_variants
    return {} unless variants
    
    variants.select { |key, _| key.include?('_') && key.include?('w') }
  end
  
  # Core image optimization method for uploads
  def optimize_image_if_needed
    return unless image?
    return unless file&.attached?
    
    # Check if optimization is enabled in settings
    storage_config = StorageConfigurationService.new
    return unless storage_config.auto_optimize_enabled?
    
    # Check media settings
    return unless SiteSetting.get('auto_optimize_images', false)
    
    # Find associated medium or create one for optimization
    medium = media.first
    if medium
      # Use existing medium
      OptimizeImageJob.perform_later(medium_id: medium.id)
    else
      # Create a temporary medium for optimization
      temp_medium = Medium.create!(
        title: title,
        description: description,
        alt_text: alt_text,
        user: user,
        upload: self
      )
      OptimizeImageJob.perform_later(medium_id: temp_medium.id)
    end
    
    Rails.logger.info "Queued image optimization for upload #{id} (core system)"
  end
  
  def trigger_upload_hooks
    Railspress::PluginSystem.do_action('upload_created', self) if saved_change_to_id?
    Railspress::PluginSystem.do_action('upload_updated', self)
    
    # Core image optimization for uploads (baked into system)
    optimize_image_if_needed if saved_change_to_id?
  end
  
  private
  
  def configure_storage
    # Configure storage based on current settings
    storage_config = StorageConfigurationService.new
    storage_config.configure_active_storage
  end
end
