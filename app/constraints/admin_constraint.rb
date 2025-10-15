class AdminConstraint
    def matches?(request)
      # Get session data
      session = request.session
      
      # Check if admin user ID exists in session
      admin_user_id = session[:admin_user_id]
      return false unless admin_user_id
  
      # Verify user exists and is active
      begin
        user = User.find_by(id: admin_user_id, is_active: true)
        return false unless user
  
        # Check if user has admin access
        user.root? || user.account_access_level&.can_manage_account?
      rescue => e
        Rails.logger.error "Admin constraint error: #{e.message}"
        false
      end
    end
  end