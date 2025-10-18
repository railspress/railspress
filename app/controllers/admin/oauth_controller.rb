class Admin::OauthController < Admin::BaseController
  before_action :ensure_admin

  # GET /admin/settings/oauth
  def index
    load_oauth_settings
  end

  # PATCH /admin/settings/oauth
  def update
    # Update OAuth settings
    if params[:settings]
      params[:settings].each do |key, value|
        SiteSetting.set(key, value, setting_type_for(key))
      end
    end

    # Update provider-specific settings
    update_provider_settings

    redirect_to admin_oauth_settings_path, notice: 'OAuth settings updated successfully.'
  end

  # POST /admin/settings/oauth/test_connection
  def test_connection
    provider = params[:provider]
    
    begin
      case provider
      when 'google'
        test_google_connection
      when 'github'
        test_github_connection
      when 'facebook'
        test_facebook_connection
      when 'twitter'
        test_twitter_connection
      else
        render json: { success: false, message: 'Unknown provider' }, status: :bad_request
        return
      end
    rescue => e
      render json: { 
        success: false, 
        message: "Connection test failed: #{e.message}" 
      }, status: :unprocessable_entity
    end
  end

  private

  def load_oauth_settings
    @settings = {
      # Google OAuth
      google_enabled: SiteSetting.get('google_oauth_enabled', false),
      google_client_id: SiteSetting.get('google_oauth_client_id', ''),
      google_client_secret: SiteSetting.get('google_oauth_client_secret', ''),
      google_redirect_uri: SiteSetting.get('google_oauth_redirect_uri', ''),
      google_tenant: SiteSetting.get('google_oauth_tenant', ''),

      # GitHub OAuth
      github_enabled: SiteSetting.get('github_oauth_enabled', false),
      github_client_id: SiteSetting.get('github_oauth_client_id', ''),
      github_client_secret: SiteSetting.get('github_oauth_client_secret', ''),
      github_redirect_uri: SiteSetting.get('github_oauth_redirect_uri', ''),

      # Facebook OAuth
      facebook_enabled: SiteSetting.get('facebook_oauth_enabled', false),
      facebook_app_id: SiteSetting.get('facebook_oauth_app_id', ''),
      facebook_app_secret: SiteSetting.get('facebook_oauth_app_secret', ''),
      facebook_redirect_uri: SiteSetting.get('facebook_oauth_redirect_uri', ''),

      # Twitter OAuth
      twitter_enabled: SiteSetting.get('twitter_oauth_enabled', false),
      twitter_api_key: SiteSetting.get('twitter_oauth_api_key', ''),
      twitter_api_secret: SiteSetting.get('twitter_oauth_api_secret', ''),
      twitter_redirect_uri: SiteSetting.get('twitter_oauth_redirect_uri', ''),

      # General OAuth settings
      oauth_auto_register: SiteSetting.get('oauth_auto_register', true),
      oauth_default_role: SiteSetting.get('oauth_default_role', 'subscriber'),
      oauth_require_email: SiteSetting.get('oauth_require_email', true),
      oauth_allow_existing_users: SiteSetting.get('oauth_allow_existing_users', true)
    }
  end

  def update_provider_settings
    # Update Google OAuth settings
    if params[:google_client_id].present?
      SiteSetting.set('google_oauth_client_id', params[:google_client_id], 'string')
    end
    if params[:google_client_secret].present?
      SiteSetting.set('google_oauth_client_secret', params[:google_client_secret], 'string')
    end
    if params[:google_redirect_uri].present?
      SiteSetting.set('google_oauth_redirect_uri', params[:google_redirect_uri], 'string')
    end
    if params[:google_tenant].present?
      SiteSetting.set('google_oauth_tenant', params[:google_tenant], 'string')
    end

    # Update GitHub OAuth settings
    if params[:github_client_id].present?
      SiteSetting.set('github_oauth_client_id', params[:github_client_id], 'string')
    end
    if params[:github_client_secret].present?
      SiteSetting.set('github_oauth_client_secret', params[:github_client_secret], 'string')
    end
    if params[:github_redirect_uri].present?
      SiteSetting.set('github_oauth_redirect_uri', params[:github_redirect_uri], 'string')
    end

    # Update Facebook OAuth settings
    if params[:facebook_app_id].present?
      SiteSetting.set('facebook_oauth_app_id', params[:facebook_app_id], 'string')
    end
    if params[:facebook_app_secret].present?
      SiteSetting.set('facebook_oauth_app_secret', params[:facebook_app_secret], 'string')
    end
    if params[:facebook_redirect_uri].present?
      SiteSetting.set('facebook_oauth_redirect_uri', params[:facebook_redirect_uri], 'string')
    end

    # Update Twitter OAuth settings
    if params[:twitter_api_key].present?
      SiteSetting.set('twitter_oauth_api_key', params[:twitter_api_key], 'string')
    end
    if params[:twitter_api_secret].present?
      SiteSetting.set('twitter_oauth_api_secret', params[:twitter_api_secret], 'string')
    end
    if params[:twitter_redirect_uri].present?
      SiteSetting.set('twitter_oauth_redirect_uri', params[:twitter_redirect_uri], 'string')
    end
  end

  def setting_type_for(key)
    boolean_settings = %w[
      google_oauth_enabled github_oauth_enabled facebook_oauth_enabled twitter_oauth_enabled
      oauth_auto_register oauth_require_email oauth_allow_existing_users
    ]
    
    if boolean_settings.include?(key)
      'boolean'
    else
      'string'
    end
  end

  def test_google_connection
    client_id = SiteSetting.get('google_oauth_client_id', '')
    client_secret = SiteSetting.get('google_oauth_client_secret', '')
    
    if client_id.blank? || client_secret.blank?
      render json: { success: false, message: 'Google OAuth credentials not configured' }
      return
    end

    begin
      # Test Google OAuth by making a request to Google's token info endpoint
      # This validates that the client_id and client_secret are valid
      require 'net/http'
      require 'uri'
      
      # Create a test token request to validate credentials
      uri = URI('https://oauth2.googleapis.com/token')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(uri)
      request.set_form_data({
        'client_id' => client_id,
        'client_secret' => client_secret,
        'grant_type' => 'authorization_code',
        'code' => 'test_code', # This will fail but we can check the error type
        'redirect_uri' => SiteSetting.get('google_oauth_redirect_uri', 'http://localhost:3000/auth/google/callback')
      })
      
      response = http.request(request)
      
      # If we get an "invalid_grant" error, it means the credentials are valid
      # but the authorization code is invalid (which is expected for a test)
      if response.code == '400'
        body = JSON.parse(response.body)
        if body['error'] == 'invalid_grant'
          render json: { 
            success: true, 
            message: 'Google OAuth credentials are valid' 
          }
        else
          render json: { 
            success: false, 
            message: "Google OAuth error: #{body['error_description'] || body['error']}" 
          }
        end
      else
        render json: { 
          success: false, 
          message: "Unexpected response from Google: #{response.code}" 
        }
      end
    rescue => e
      render json: { 
        success: false, 
        message: "Google OAuth connection test failed: #{e.message}" 
      }
    end
  end

  def test_github_connection
    client_id = SiteSetting.get('github_oauth_client_id', '')
    client_secret = SiteSetting.get('github_oauth_client_secret', '')
    
    if client_id.blank? || client_secret.blank?
      render json: { success: false, message: 'GitHub OAuth credentials not configured' }
      return
    end

    begin
      # Test GitHub OAuth by making a request to GitHub's API
      require 'net/http'
      require 'uri'
      
      # Create a test token request to validate credentials
      uri = URI('https://github.com/login/oauth/access_token')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(uri)
      request['Accept'] = 'application/json'
      request.set_form_data({
        'client_id' => client_id,
        'client_secret' => client_secret,
        'code' => 'test_code' # This will fail but we can check the error type
      })
      
      response = http.request(request)
      
      # If we get an "incorrect_client_credentials" error, it means the credentials are invalid
      # If we get an "bad_verification_code" error, it means the credentials are valid
      if response.code == '200'
        body = JSON.parse(response.body)
        if body['error'] == 'bad_verification_code'
          render json: { 
            success: true, 
            message: 'GitHub OAuth credentials are valid' 
          }
        else
          render json: { 
            success: false, 
            message: "GitHub OAuth error: #{body['error_description'] || body['error']}" 
          }
        end
      else
        render json: { 
          success: false, 
          message: "Unexpected response from GitHub: #{response.code}" 
        }
      end
    rescue => e
      render json: { 
        success: false, 
        message: "GitHub OAuth connection test failed: #{e.message}" 
      }
    end
  end

  def test_facebook_connection
    app_id = SiteSetting.get('facebook_oauth_app_id', '')
    app_secret = SiteSetting.get('facebook_oauth_app_secret', '')
    
    if app_id.blank? || app_secret.blank?
      render json: { success: false, message: 'Facebook OAuth credentials not configured' }
      return
    end

    begin
      # Test Facebook OAuth by making a request to Facebook's Graph API
      require 'net/http'
      require 'uri'
      
      # Create a test app token request to validate credentials
      uri = URI("https://graph.facebook.com/oauth/access_token")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(uri)
      request.set_form_data({
        'client_id' => app_id,
        'client_secret' => app_secret,
        'grant_type' => 'client_credentials'
      })
      
      response = http.request(request)
      
      if response.code == '200'
        body = JSON.parse(response.body)
        if body['access_token'].present?
          render json: { 
            success: true, 
            message: 'Facebook OAuth credentials are valid' 
          }
        else
          render json: { 
            success: false, 
            message: 'Facebook OAuth credentials are invalid' 
          }
        end
      else
        body = JSON.parse(response.body) rescue {}
        render json: { 
          success: false, 
          message: "Facebook OAuth error: #{body['error']&.dig('message') || 'Invalid credentials'}" 
        }
      end
    rescue => e
      render json: { 
        success: false, 
        message: "Facebook OAuth connection test failed: #{e.message}" 
      }
    end
  end

  def test_twitter_connection
    api_key = SiteSetting.get('twitter_oauth_api_key', '')
    api_secret = SiteSetting.get('twitter_oauth_api_secret', '')
    
    if api_key.blank? || api_secret.blank?
      render json: { success: false, message: 'Twitter OAuth credentials not configured' }
      return
    end

    begin
      # Test Twitter OAuth by making a request to Twitter's API
      require 'net/http'
      require 'uri'
      require 'base64'
      
      # Create a test bearer token request to validate credentials
      uri = URI('https://api.twitter.com/oauth2/token')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      # Create basic auth header
      credentials = Base64.strict_encode64("#{api_key}:#{api_secret}")
      
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Basic #{credentials}"
      request['Content-Type'] = 'application/x-www-form-urlencoded;charset=UTF-8'
      request.set_form_data({
        'grant_type' => 'client_credentials'
      })
      
      response = http.request(request)
      
      if response.code == '200'
        body = JSON.parse(response.body)
        if body['access_token'].present?
          render json: { 
            success: true, 
            message: 'Twitter OAuth credentials are valid' 
          }
        else
          render json: { 
            success: false, 
            message: 'Twitter OAuth credentials are invalid' 
          }
        end
      else
        body = JSON.parse(response.body) rescue {}
        render json: { 
          success: false, 
          message: "Twitter OAuth error: #{body['errors']&.first&.dig('message') || 'Invalid credentials'}" 
        }
      end
    rescue => e
      render json: { 
        success: false, 
        message: "Twitter OAuth connection test failed: #{e.message}" 
      }
    end
  end
end
