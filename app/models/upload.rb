class Upload < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant)
  
  belongs_to :user
  belongs_to :storage_provider, optional: true
  
  # ActiveStorage for file attachment
  has_one_attached :file
  
  # Relationships
  has_many :media, dependent: :destroy
  
  # Validations
  validates :title, presence: true
  validates :file, presence: true
  
  # Scopes
  scope :quarantined, -> { where(quarantined: true) }
  scope :approved, -> { where(quarantined: [false, nil]) }
  
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
  
  private
  
  def configure_storage
    # Configure storage based on current settings
    storage_config = StorageConfigurationService.new
    storage_config.configure_active_storage
  end
  
  def trigger_upload_hooks
    Railspress::PluginSystem.do_action('upload_created', self) if saved_change_to_id?
    Railspress::PluginSystem.do_action('upload_updated', self)
  end
end
