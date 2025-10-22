class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable,
         omniauth_providers: [:google_oauth2, :github, :facebook, :twitter]

  # WordPress-like roles
  enum role: {
    subscriber: 0,
    contributor: 1,
    author: 2,
    editor: 3,
    administrator: 4
  }

  # Associations
  # ActiveStorage for avatar
  has_one_attached :avatar
  
  # Multi-tenancy - users belong to tenants (many-to-one)
  belongs_to :tenant, optional: true
  
  has_many :posts, dependent: :destroy
  has_many :pages, dependent: :destroy
  has_many :media, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :api_tokens, dependent: :destroy
  has_many :ai_usages, dependent: :destroy
  has_many :oauth_accounts, dependent: :destroy
  
  # GDPR-related associations
  has_many :personal_data_export_requests, dependent: :destroy
  has_many :personal_data_erasure_requests, dependent: :destroy
  has_many :user_consents, dependent: :destroy
  
  # Meta fields for plugin extensibility
  has_many :meta_fields, as: :metable, dependent: :destroy
  include Metable

  # Editor preference
  EDITOR_OPTIONS = %w[trix ckeditor5 editorjs].freeze
  validates :editor_preference, inclusion: { in: EDITOR_OPTIONS }, allow_nil: true
  
  
  
  # Monaco Editor theme preference
  MONACO_THEMES = %w[auto dark light blue].freeze
  validates :monaco_theme, inclusion: { in: MONACO_THEMES }, allow_nil: true
  
  # API Key
  validates :api_key, uniqueness: true, allow_nil: true
  
  def preferred_monaco_theme
    monaco_theme.presence || 'auto' # Default to auto
  end
  
  # Sidebar order preference
  def sidebar_order
    if super.present?
      JSON.parse(super)
    else
      ['post', 'categories-tags', 'content-channels', 'seo-meta', 'excerpt', 'plugin-blocks']
    end
  rescue JSON::ParserError
    ['post', 'categories-tags', 'content-channels', 'seo-meta', 'excerpt', 'plugin-blocks']
  end
  
  def sidebar_order=(order)
    super(order.is_a?(Array) ? order.to_json : order)
  end
  
  # Validations
  validates :role, presence: true

  # Callbacks
  after_initialize :set_default_role, if: :new_record?
  before_create :generate_api_token

  # Role helper methods
  def admin?
    administrator?
  end

  def can_publish?
    author? || editor? || administrator?
  end

  def can_edit_others_posts?
    editor? || administrator?
  end

  def can_delete_posts?
    administrator?
  end
  
  # API methods
  def regenerate_api_token!
    update(api_token: generate_token)
  end
  
  def rate_limit_exceeded?
    return false unless api_requests_reset_at
    
    if api_requests_reset_at < Time.current
      update(api_requests_count: 0, api_requests_reset_at: 1.hour.from_now)
      return false
    end
    
    (api_requests_count || 0) >= 1000 # 1000 requests per hour
  end
  
  def increment_api_request!
    self.api_requests_reset_at = 1.hour.from_now if api_requests_reset_at.nil? || api_requests_reset_at < Time.current
    increment!(:api_requests_count)
  end
  
  # Admin bar permission checks
  def can_manage_plugins?
    administrator? || role == 'editor'
  end
  
  def can_manage_themes?
    administrator?
  end
  
  def can_manage_settings?
    administrator?
  end
  
  def can_manage_users?
    administrator?
  end
  
  def can_create_posts?
    ['administrator', 'editor', 'author'].include?(role)
  end
  
  def can_create_pages?
    ['administrator', 'editor'].include?(role)
  end
  
  def can_upload_media?
    ['administrator', 'editor', 'author'].include?(role)
  end
  
  def can_upload_files?
    ['administrator', 'editor', 'author'].include?(role)
  end
  
  # API Key methods
  def generate_api_key
    loop do
      key = "sk-#{SecureRandom.hex(32)}"
      break key unless User.exists?(api_key: key)
    end
  end
  
  def regenerate_api_key!
    self.api_key = generate_api_key
    save!
  end

  private

  def set_default_role
    self.role ||= :subscriber
  end
  
  def generate_api_token
    self.api_token = generate_token
    self.api_key = generate_api_key
    self.api_requests_count = 0
    self.api_requests_reset_at = 1.hour.from_now
  end
  
  def generate_token
    loop do
      token = SecureRandom.hex(32)
      break token unless User.exists?(api_token: token)
    end
  end
  
  def create_user_tenant
    # Create a tenant for this user if they don't have one
    return if tenant_id.present?
    
    # Generate a unique subdomain based on email
    base_subdomain = email.split('@').first.gsub(/[^a-z0-9]/, '')
    subdomain = base_subdomain
    counter = 1
    
    # Ensure subdomain is unique
    while Tenant.exists?(subdomain: subdomain)
      subdomain = "#{base_subdomain}#{counter}"
      counter += 1
    end
    
    # Create the tenant
    user_tenant = Tenant.create!(
      name: "#{email.split('@').first.humanize}'s Site",
      subdomain: subdomain,
      domain: nil, # Will be set later if needed
      theme: 'nordic',
      storage_type: 'local'
    )
    
    self.tenant = user_tenant
  end
end
