class Tenant < ApplicationRecord
  # Serialization
  serialize :settings, coder: JSON, type: Hash
  
  # Validations
  validates :name, presence: true
  validates :domain, uniqueness: true, allow_nil: true
  validates :subdomain, uniqueness: true, allow_nil: true
  validates :theme, presence: true
  validates :storage_type, inclusion: { in: %w[local s3], message: "%{value} is not a valid storage type" }
  
  validate :must_have_domain_or_subdomain
  
  # Associations
  has_many :posts, dependent: :destroy
  has_many :pages, dependent: :destroy
  has_many :media, dependent: :destroy
  has_many :comments, dependent: :destroy
  # Taxonomies instead of separate categories/tags
  has_many :taxonomies, dependent: :destroy
  has_many :terms, through: :taxonomies
  has_many :menus, dependent: :destroy
  has_many :widgets, dependent: :destroy
  has_many :themes, dependent: :destroy
  has_many :site_settings, dependent: :destroy
  has_many :users, dependent: :nullify
  has_many :email_logs
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_domain, ->(domain) { where(domain: domain) }
  scope :by_subdomain, ->(subdomain) { where(subdomain: subdomain) }
  
  # Callbacks
  after_initialize :set_defaults, if: :new_record?
  after_create :create_default_settings
  
  # Class methods
  def self.find_by_request(request)
    find_by(domain: request.host) || find_by(subdomain: request.subdomains.first)
  end
  
  def self.current
    ActsAsTenant.current_tenant
  end
  
  # Instance methods
  def activate!
    update!(active: true)
  end
  
  def deactivate!
    update!(active: false)
  end
  
  def full_url
    if domain.present?
      "https://#{domain}"
    elsif subdomain.present?
      "https://#{subdomain}.#{default_domain}"
    else
      nil
    end
  end
  
  def default_domain
    ENV['APP_DOMAIN'] || 'railspress.app'
  end
  
  def locale_list
    (locales || 'en').split(',').map(&:strip)
  end
  
  def locale_list=(value)
    self.locales = Array(value).join(',')
  end
  
  # Storage methods
  def using_s3?
    storage_type == 's3'
  end
  
  def using_local_storage?
    storage_type == 'local'
  end
  
  def storage_configured?
    if using_s3?
      storage_bucket.present? && storage_region.present? && 
      storage_access_key.present? && storage_secret_key.present?
    else
      true # Local storage is always configured
    end
  end
  
  def storage_service
    if using_s3?
      :amazon
    else
      :local
    end
  end
  
  # Settings helpers
  def get_setting(key, default = nil)
    settings&.dig(key) || default
  end
  
  def set_setting(key, value)
    self.settings ||= {}
    self.settings[key] = value
    save
  end
  
  private
  
  def set_defaults
    self.theme ||= 'default'
    self.locales ||= 'en'
    self.active = true if self.active.nil?
    self.storage_type ||= 'local'
    self.settings ||= {}
  end
  
  def must_have_domain_or_subdomain
    if domain.blank? && subdomain.blank?
      errors.add(:base, "Must have either a domain or subdomain")
    end
  end
  
  def create_default_settings
    # Create default site settings for the tenant
    default_settings = {
      'site_title' => name,
      'site_tagline' => "Powered by #{name}",
      'posts_per_page' => 10,
      'default_post_status' => 'draft',
      'comments_enabled' => true
    }
    
    default_settings.each do |key, value|
      site_settings.find_or_create_by!(key: key) do |setting|
        setting.value = value.to_s
        setting.setting_type = value.is_a?(TrueClass) || value.is_a?(FalseClass) ? 'boolean' : 'string'
        setting.tenant = self
      end
    end
  end
end
