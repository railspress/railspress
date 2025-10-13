class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin_access
  
  layout 'admin'
  
  private
  
  def authenticate_user!
    unless user_signed_in?
      redirect_to new_admin_user_session_path, alert: 'Please sign in to access the admin area.'
      return
    end
    
    super
  rescue ActionController::InvalidAuthenticityToken
    redirect_to new_admin_user_session_path, alert: 'Please sign in to access the admin area.'
  end
  
  def ensure_admin_access
    unless current_user&.author? || current_user&.editor? || current_user&.administrator?
      redirect_to root_path, alert: 'You do not have permission to access the admin area.'
    end
  end
  
  def ensure_editor_access
    unless current_user&.editor? || current_user&.administrator?
      redirect_to admin_root_path, alert: 'You do not have permission to perform this action.'
    end
  end
  
  def ensure_admin
    unless current_user&.administrator?
      redirect_to admin_root_path, alert: 'Only administrators can perform this action.'
    end
  end
end




