class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

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
  
  has_many :posts, dependent: :destroy
  has_many :pages, dependent: :destroy
  has_many :media, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :api_tokens, dependent: :destroy

  # Editor preference
  EDITOR_OPTIONS = %w[blocknote trix ckeditor editorjs].freeze
  validates :editor_preference, inclusion: { in: EDITOR_OPTIONS }, allow_nil: true
  
  def preferred_editor
    editor_preference.presence || 'blocknote' # Default to BlockNote
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

  private

  def set_default_role
    self.role ||= :subscriber
  end
  
  def generate_api_token
    self.api_token = generate_token
    self.api_requests_count = 0
    self.api_requests_reset_at = 1.hour.from_now
  end
  
  def generate_token
    loop do
      token = SecureRandom.hex(32)
      break token unless User.exists?(api_token: token)
    end
  end
end
