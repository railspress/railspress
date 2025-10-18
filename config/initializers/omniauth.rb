# OmniAuth configuration for RailsPress
# This file configures OAuth providers for user authentication

# OmniAuth configuration
OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true

# Custom failure app for OmniAuth
class OmniAuthFailureApp < Devise::FailureApp
  def redirect
    if request.env['omniauth.error.type'] == :invalid_credentials
      # Determine redirect path based on request path
      redirect_path = request.path.include?('/admin/') ? new_admin_user_session_path : new_user_session_path
      redirect_to redirect_path, alert: 'Authentication failed. Please try again.'
    else
      super
    end
  end
end
