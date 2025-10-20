class Medium < ApplicationRecord
  include Railspress::ChannelDetection
  # Multi-tenancy
  acts_as_tenant(:tenant)
  
  # Trash functionality
  include Trashable
  
  belongs_to :user
  belongs_to :upload
  
  # Channels
  has_and_belongs_to_many :channels
  
  # Validations
  validates :title, presence: true
  
  # Callbacks
  after_create :trigger_media_uploaded_hook
  
  # Scopes
  scope :images, -> { joins(:upload).merge(Upload.images) }
  scope :videos, -> { joins(:upload).merge(Upload.videos) }
  scope :documents, -> { joins(:upload).merge(Upload.documents) }
  scope :recent, -> { order(created_at: :desc) }
  scope :approved, -> { joins(:upload).merge(Upload.approved) }
  scope :quarantined, -> { joins(:upload).merge(Upload.quarantined) }
  
  # File methods - delegate to upload
  def image?
    upload&.image?
  end
  
  def video?
    upload&.video?
  end
  
  def document?
    upload&.document?
  end
  
  def file_size
    upload&.file_size || 0
  end
  
  def content_type
    upload&.content_type
  end
  
  def filename
    upload&.filename
  end
  
  def url
    upload&.url
  end
  
  def file_attached?
    upload&.file&.attached?
  end
  
  def quarantined?
    upload&.quarantined?
  end
  
  def approved?
    upload&.approved?
  end
  
  def quarantine_reason
    upload&.quarantine_reason
  end
  
  # API serialization helpers
  def api_attributes
    {
      id: id,
      title: title,
      description: description,
      alt_text: alt_text,
      filename: filename,
      content_type: content_type,
      file_size: file_size,
      url: url,
      image: image?,
      video: video?,
      document: document?,
      quarantined: quarantined?,
      quarantine_reason: quarantine_reason,
      created_at: created_at,
      updated_at: updated_at,
      user: {
        id: user.id,
        name: user.name,
        email: user.email
      },
      upload: {
        id: upload.id,
        title: upload.title,
        storage_provider: {
          id: upload.storage_provider.id,
          name: upload.storage_provider.name,
          type: upload.storage_provider.provider_type
        }
      }
    }
  end
  
  # Class methods for API
  def self.with_file_info
    includes(:upload, :user, upload: :storage_provider)
  end
  
  def self.by_type(type)
    case type.to_s
    when 'image'
      images
    when 'video'
      videos
    when 'document'
      documents
    else
      all
    end
  end
  
  def trigger_media_uploaded_hook
    # Trigger plugin hooks
    Railspress::PluginSystem.do_action('media_uploaded', self)
    
    # Core image optimization (baked into system)
    optimize_image_if_needed
  end
  
  # Core image optimization method
  def optimize_image_if_needed
    return unless image?
    return unless upload&.file&.attached?
    
    # Check if optimization is enabled in settings
    storage_config = StorageConfigurationService.new
    return unless storage_config.auto_optimize_enabled?
    
    # Check media settings
    return unless SiteSetting.get('auto_optimize_images', false)
    
    # Queue optimization job
    OptimizeImageJob.perform_later(medium_id: id)
    
    Rails.logger.info "Queued image optimization for medium #{id} (core system)"
  end
  
  private
end
