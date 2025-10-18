class OauthAccount < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant)
  
  # Associations
  belongs_to :user
  
  # Validations
  validates :provider, presence: true
  validates :uid, presence: true
  validates :email, presence: true
  validates :name, presence: true
  validates :uid, uniqueness: { scope: [:provider, :tenant_id] }
  
  # Scopes
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :active, -> { joins(:user).where(users: { active: true }) }
  
  # Class methods
  def self.find_by_provider_and_uid(provider, uid)
    find_by(provider: provider, uid: uid)
  end
  
  def self.find_by_provider_and_email(provider, email)
    find_by(provider: provider, email: email)
  end
  
  # Instance methods
  def provider_display_name
    case provider
    when 'google_oauth2'
      'Google'
    when 'github'
      'GitHub'
    when 'facebook'
      'Facebook'
    when 'twitter'
      'Twitter'
    else
      provider.humanize
    end
  end
  
  def provider_icon
    case provider
    when 'google_oauth2'
      'https://developers.google.com/identity/images/g-logo.png'
    when 'github'
      'https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png'
    when 'facebook'
      'https://facebookbrand.com/wp-content/uploads/2019/04/f_logo_RGB-Hex-Blue_512.png'
    when 'twitter'
      'https://abs.twimg.com/icons/apple-touch-icon-192x192.png'
    else
      nil
    end
  end

  def provider_color
    case provider
    when 'google_oauth2'
      '#4285F4'
    when 'github'
      '#333333'
    when 'facebook'
      '#1877F2'
    when 'twitter'
      '#1DA1F2'
    else
      '#6B7280'
    end
  end
  
  def linked_at
    created_at
  end
  
  def last_used_at
    updated_at
  end
  
  # Check if this OAuth account is still valid
  def valid_oauth_account?
    user.present? && user.active?
  end
  
  # Unlink this OAuth account
  def unlink!
    destroy!
  end
  
  # Update OAuth account information
  def update_oauth_info(email: nil, name: nil, avatar_url: nil)
    update!(
      email: email || self.email,
      name: name || self.name,
      avatar_url: avatar_url || self.avatar_url
    )
  end
end
