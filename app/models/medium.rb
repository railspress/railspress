class Medium < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  belongs_to :user
  
  # ActiveStorage for file attachment
  has_one_attached :file
  
  # Validations
  validates :title, presence: true
  validates :file, presence: true
  
  # Callbacks
  after_commit :set_file_metadata, on: [:create, :update], if: -> { file.attached? }
  after_create :trigger_media_uploaded_hook
  
  # Scopes
  scope :images, -> { where(file_type: ['image/jpeg', 'image/png', 'image/gif', 'image/webp']) }
  scope :videos, -> { where(file_type: ['video/mp4', 'video/webm']) }
  scope :documents, -> { where(file_type: ['application/pdf', 'application/msword']) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Methods
  def image?
    file_type&.start_with?('image/')
  end
  
  def video?
    file_type&.start_with?('video/')
  end
  
  def url
    file.attached? ? Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true) : nil
  end
  
  private
  
  def set_file_metadata
    if file.attached?
      self.file_type = file.content_type
      self.file_size = file.byte_size
      save if changed?
    end
  end
  
  def trigger_media_uploaded_hook
    Railspress::PluginSystem.do_action('media_uploaded', self)
  end
end
