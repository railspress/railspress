class ApiToken < ApplicationRecord
  belongs_to :user
  
  # Roles
  ROLES = %w[public editor admin].freeze
  
  # Default permissions by role
  DEFAULT_PERMISSIONS = {
    'public' => {
      'posts' => ['read'],
      'pages' => ['read'],
      'categories' => ['read'],
      'tags' => ['read'],
      'comments' => ['read']
    },
    'editor' => {
      'posts' => ['read', 'create', 'update'],
      'pages' => ['read', 'create', 'update'],
      'categories' => ['read', 'create', 'update'],
      'tags' => ['read', 'create', 'update'],
      'comments' => ['read', 'create', 'update', 'delete'],
      'media' => ['read', 'create', 'update', 'delete']
    },
    'admin' => {
      'posts' => ['read', 'create', 'update', 'delete'],
      'pages' => ['read', 'create', 'update', 'delete'],
      'categories' => ['read', 'create', 'update', 'delete'],
      'tags' => ['read', 'create', 'update', 'delete'],
      'comments' => ['read', 'create', 'update', 'delete'],
      'media' => ['read', 'create', 'update', 'delete'],
      'users' => ['read', 'create', 'update', 'delete'],
      'settings' => ['read', 'update'],
      'ai_agents' => ['read', 'execute', 'create', 'update', 'delete'],
      'ai_providers' => ['read', 'create', 'update', 'delete']
    }
  }.freeze
  
  # Validations
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :token, presence: true, uniqueness: true
  validates :role, presence: true, inclusion: { in: ROLES }
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :expired, -> { where('expires_at < ?', Time.current) }
  scope :not_expired, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :by_role, ->(role) { where(role: role) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Callbacks
  before_validation :generate_token, on: :create
  before_validation :set_default_permissions, on: :create
  
  # Instance methods
  def expired?
    expires_at.present? && expires_at < Time.current
  end
  
  def valid_token?
    active && !expired?
  end
  
  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end
  
  def has_permission?(resource, action)
    return false unless valid_token?
    
    resource_permissions = permissions[resource.to_s] || []
    resource_permissions.include?(action.to_s)
  end
  
  def masked_token
    return nil unless token
    "#{token[0..7]}...#{token[-4..-1]}"
  end
  
  def display_role
    role.titleize
  end
  
  private
  
  def generate_token
    self.token ||= SecureRandom.base58(32)
  end
  
  def set_default_permissions
    self.permissions ||= DEFAULT_PERMISSIONS[role] || DEFAULT_PERMISSIONS['public']
  end
end