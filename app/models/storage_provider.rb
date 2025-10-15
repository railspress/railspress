class StorageProvider < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant)
  
  # Validations
  validates :name, presence: true
  validates :provider_type, presence: true, inclusion: { in: %w[local s3 gcs azure] }
  validates :config, presence: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }
  scope :by_type, ->(type) { where(provider_type: type) }
  
  # Serialization
  serialize :config, JSON
  
  # Callbacks
  before_validation :set_default_position
  after_update :update_active_storage_config, if: :saved_change_to_active?
  
  # Methods
  def local?
    provider_type == 'local'
  end
  
  def s3?
    provider_type == 's3'
  end
  
  def gcs?
    provider_type == 'gcs'
  end
  
  def azure?
    provider_type == 'azure'
  end
  
  def active_storage_service
    case provider_type
    when 'local'
      :local
    when 's3'
      :amazon
    when 'gcs'
      :google
    when 'azure'
      :microsoft
    else
      :local
    end
  end
  
  def active_storage_config
    case provider_type
    when 'local'
      {
        service: :local,
        root: config['local_path'] || Rails.root.join('storage')
      }
    when 's3'
      {
        service: :amazon,
        access_key_id: config['access_key_id'],
        secret_access_key: config['secret_access_key'],
        region: config['region'],
        bucket: config['bucket'],
        endpoint: config['endpoint']
      }.compact
    when 'gcs'
      {
        service: :google,
        project: config['project'],
        bucket: config['bucket'],
        credentials: config['credentials']
      }.compact
    when 'azure'
      {
        service: :microsoft,
        storage_account_name: config['storage_account_name'],
        storage_access_key: config['storage_access_key'],
        container: config['container']
      }.compact
    else
      { service: :local, root: Rails.root.join('storage') }
    end
  end
  
  private
  
  def set_default_position
    self.position ||= (StorageProvider.maximum(:position) || 0) + 1
  end
  
  def update_active_storage_config
    if active?
      # Deactivate other providers
      StorageProvider.where.not(id: id).update_all(active: false)
      
      # Update Rails storage configuration
      Rails.application.configure do
        config.active_storage.variant_processor = :mini_magick
        config.active_storage.service = name.underscore.to_sym
        
        config.active_storage.services[name.underscore.to_sym] = active_storage_config
      end
    end
  end
end
