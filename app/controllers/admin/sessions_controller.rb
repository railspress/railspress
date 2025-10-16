class Admin::SessionsController < Devise::SessionsController
  layout 'admin_login'
  helper AppearanceHelper

    
  # Temporarily disable CSRF protection for admin login to fix the issue
  skip_before_action :verify_authenticity_token, only: [:create]

  
  # Override after_sign_in to check admin access
  def after_sign_in_path_for(resource)
    # Check if user has admin access
    unless resource.author? || resource.editor? || resource.administrator?
      sign_out(resource)
      flash[:alert] = 'You do not have permission to access the admin area.'
      new_admin_user_session_path
    else
      admin_root_path
    end
  end
  
  # Override to redirect to admin login after logout
  def after_sign_out_path_for(resource_or_scope)
    new_admin_user_session
  end
end
