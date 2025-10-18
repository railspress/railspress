class OauthProviderService
  def self.configure_providers
    # This method will be called to configure OAuth providers dynamically
    # It will be used by the OAuth controller when settings are updated
    
    # Clear existing providers
    Rails.application.config.middleware.delete(OmniAuth::Builder)
    
    # Add new providers based on current settings
    Rails.application.config.middleware.use OmniAuth::Builder do
      # Google OAuth
      if SiteSetting.get('google_oauth_enabled', false) && 
         SiteSetting.get('google_oauth_client_id', '').present? && 
         SiteSetting.get('google_oauth_client_secret', '').present?
        
        provider :google_oauth2,
          SiteSetting.get('google_oauth_client_id', ''),
          SiteSetting.get('google_oauth_client_secret', ''),
          {
            name: 'google',
            scope: 'email,profile',
            prompt: 'select_account',
            access_type: 'offline',
            hd: SiteSetting.get('google_oauth_tenant', '').presence
          }
      end

      # GitHub OAuth
      if SiteSetting.get('github_oauth_enabled', false) && 
         SiteSetting.get('github_oauth_client_id', '').present? && 
         SiteSetting.get('github_oauth_client_secret', '').present?
        
        provider :github,
          SiteSetting.get('github_oauth_client_id', ''),
          SiteSetting.get('github_oauth_client_secret', ''),
          {
            scope: 'user:email'
          }
      end

      # Facebook OAuth
      if SiteSetting.get('facebook_oauth_enabled', false) && 
         SiteSetting.get('facebook_oauth_app_id', '').present? && 
         SiteSetting.get('facebook_oauth_app_secret', '').present?
        
        provider :facebook,
          SiteSetting.get('facebook_oauth_app_id', ''),
          SiteSetting.get('facebook_oauth_app_secret', ''),
          {
            scope: 'email',
            info_fields: 'email,name'
          }
      end

      # Twitter OAuth
      if SiteSetting.get('twitter_oauth_enabled', false) && 
         SiteSetting.get('twitter_oauth_api_key', '').present? && 
         SiteSetting.get('twitter_oauth_api_secret', '').present?
        
        provider :twitter,
          SiteSetting.get('twitter_oauth_api_key', ''),
          SiteSetting.get('twitter_oauth_api_secret', '')
      end
    end
  end

  def self.get_available_providers
    providers = []
    
    providers << 'google' if SiteSetting.get('google_oauth_enabled', false) && 
                           SiteSetting.get('google_oauth_client_id', '').present?
    
    providers << 'github' if SiteSetting.get('github_oauth_enabled', false) && 
                           SiteSetting.get('github_oauth_client_id', '').present?
    
    providers << 'facebook' if SiteSetting.get('facebook_oauth_enabled', false) && 
                             SiteSetting.get('facebook_oauth_app_id', '').present?
    
    providers << 'twitter' if SiteSetting.get('twitter_oauth_enabled', false) && 
                            SiteSetting.get('twitter_oauth_api_key', '').present?
    
    providers
  end

  def self.provider_enabled?(provider)
    case provider
    when 'google'
      SiteSetting.get('google_oauth_enabled', false) && 
      SiteSetting.get('google_oauth_client_id', '').present?
    when 'github'
      SiteSetting.get('github_oauth_enabled', false) && 
      SiteSetting.get('github_oauth_client_id', '').present?
    when 'facebook'
      SiteSetting.get('facebook_oauth_enabled', false) && 
      SiteSetting.get('facebook_oauth_app_id', '').present?
    when 'twitter'
      SiteSetting.get('twitter_oauth_enabled', false) && 
      SiteSetting.get('twitter_oauth_api_key', '').present?
    else
      false
    end
  end
end
