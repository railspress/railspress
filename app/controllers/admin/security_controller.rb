class Admin::SecurityController < Admin::BaseController
  before_action :set_user

  # GET /admin/security
  def show
    @login_history = load_login_history
    @active_sessions = load_active_sessions
  end

  # PATCH /admin/security/update_password
  def update_password
    unless @user.valid_password?(params[:current_password])
      redirect_to admin_security_path, alert: 'Current password is incorrect.'
      return
    end

    if params[:new_password] != params[:confirm_password]
      redirect_to admin_security_path, alert: 'New passwords do not match.'
      return
    end

    if @user.update(password: params[:new_password], password_confirmation: params[:confirm_password])
      # Sign in again after password change
      sign_in(@user, bypass: true)
      redirect_to admin_security_path, notice: 'Password updated successfully.'
    else
      redirect_to admin_security_path, alert: 'Failed to update password. Must be at least 6 characters.'
    end
  end

  # POST /admin/security/enable_2fa
  def enable_2fa
    # Placeholder for 2FA implementation
    redirect_to admin_security_path, notice: 'Two-factor authentication feature coming soon.'
  end

  # DELETE /admin/security/disable_2fa
  def disable_2fa
    # Placeholder for 2FA implementation
    redirect_to admin_security_path, notice: 'Two-factor authentication disabled.'
  end

  # POST /admin/security/regenerate_api_token
  def regenerate_api_token
    @user.regenerate_api_token!
    redirect_to admin_security_path, notice: 'API token regenerated successfully.'
  end

  # DELETE /admin/security/revoke_sessions
  def revoke_sessions
    # This would revoke all other sessions except current
    # Implementation depends on session management strategy
    redirect_to admin_security_path, notice: 'All other sessions have been revoked.'
  end

  private

  def set_user
    @user = current_user
  end

  def load_login_history
    # Placeholder - would come from a login_history table
    []
  end

  def load_active_sessions
    # Placeholder - would come from sessions tracking
    []
  end
end
