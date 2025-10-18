class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Handle Google OAuth callback
  def google_oauth2
    handle_oauth_callback('google_oauth2')
  end

  # Handle GitHub OAuth callback
  def github
    handle_oauth_callback('github')
  end

  # Handle Facebook OAuth callback
  def facebook
    handle_oauth_callback('facebook')
  end

  # Handle Twitter OAuth callback
  def twitter
    handle_oauth_callback('twitter')
  end

  private

  def handle_oauth_callback(provider)
    auth_data = request.env['omniauth.auth']
    
    if auth_data.blank?
      # Determine redirect path based on request path
      redirect_path = request.path.include?('/admin/') ? new_admin_user_session_path : new_user_session_path
      redirect_to redirect_path, alert: 'Authentication failed. Please try again.'
      return
    end

    # Find or create user based on OAuth data
    user = find_or_create_user_from_oauth(auth_data, provider)
    
    if user.persisted?
      sign_in_and_redirect user, event: :authentication
      set_flash_message(:notice, :success, kind: provider.humanize) if is_navigational_format?
    else
      session["devise.#{provider}_data"] = auth_data.except('extra')
      # Determine redirect path based on request path
      redirect_path = request.path.include?('/admin/') ? new_admin_user_session_path : new_user_registration_path
      redirect_to redirect_path, alert: user.errors.full_messages.join(', ')
    end
  end

  def find_or_create_user_from_oauth(auth_data, provider)
    # Extract user information from OAuth data
    email = extract_email(auth_data)
    name = extract_name(auth_data)
    uid = auth_data.uid
    
    # Check if OAuth requires email and we don't have one
    if SiteSetting.get('oauth_require_email', true) && email.blank?
      return User.new.tap { |u| u.errors.add(:email, 'Email is required for OAuth authentication') }
    end

    # Try to find existing user by email first
    user = User.find_by(email: email) if email.present?
    
    if user
      # User exists - check if we should allow linking
      if SiteSetting.get('oauth_allow_existing_users', true)
        # Link OAuth account to existing user
        link_oauth_account(user, auth_data, provider)
        return user
      else
        return User.new.tap { |u| u.errors.add(:base, 'OAuth authentication not allowed for existing users') }
      end
    end

    # Try to find user by OAuth provider and UID
    oauth_account = OauthAccount.find_by(provider: provider, uid: uid)
    if oauth_account
      return oauth_account.user
    end

    # Create new user if auto-registration is enabled
    if SiteSetting.get('oauth_auto_register', true)
      create_user_from_oauth(auth_data, provider, email, name, uid)
    else
      User.new.tap { |u| u.errors.add(:base, 'Auto-registration is disabled') }
    end
  end

  def create_user_from_oauth(auth_data, provider, email, name, uid)
    # Generate a random password for OAuth users
    password = Devise.friendly_token[0, 20]
    
    user = User.new(
      email: email,
      name: name,
      password: password,
      password_confirmation: password,
      role: SiteSetting.get('oauth_default_role', 'subscriber')
    )

    if user.save
      # Create OAuth account record
      OauthAccount.create!(
        user: user,
        provider: provider,
        uid: uid,
        email: email,
        name: name,
        avatar_url: extract_avatar_url(auth_data)
      )
      
      user
    else
      user
    end
  end

  def link_oauth_account(user, auth_data, provider)
    uid = auth_data.uid
    email = extract_email(auth_data)
    name = extract_name(auth_data)
    
    # Check if OAuth account already exists
    oauth_account = OauthAccount.find_by(provider: provider, uid: uid)
    
    if oauth_account.nil?
      # Create new OAuth account link
      OauthAccount.create!(
        user: user,
        provider: provider,
        uid: uid,
        email: email,
        name: name,
        avatar_url: extract_avatar_url(auth_data)
      )
    end
  end

  def extract_email(auth_data)
    auth_data.info.email.presence
  end

  def extract_name(auth_data)
    name = auth_data.info.name.presence
    name ||= "#{auth_data.info.first_name} #{auth_data.info.last_name}".strip.presence
    name ||= auth_data.info.nickname.presence
    name ||= 'OAuth User'
  end

  def extract_avatar_url(auth_data)
    auth_data.info.image.presence
  end
end
