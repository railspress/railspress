class Admin::PasswordsController < Devise::PasswordsController
  layout 'admin_login'
  helper AppearanceHelper
  
  # Override to redirect to admin login after password reset
  def after_resetting_password_path_for(resource)
    new_admin_user_session_path
  end
end
