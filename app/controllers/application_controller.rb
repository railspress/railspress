class ApplicationController < ActionController::Base
  include Themeable
  include Pundit::Authorization
  
  # Set current tenant for multi-tenancy
  set_current_tenant_through_filter
  before_action :set_current_tenant
  
  # Prevent CSRF attacks by raising an exception
  protect_from_forgery with: :exception
  
  # Pundit authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  private
  
  def set_current_tenant
    tenant = nil
    
    # Priority 1: Use logged-in user's tenant
    if user_signed_in? && current_user.tenant
      tenant = current_user.tenant
    # Priority 2: Find tenant by domain or subdomain
    elsif request.host != 'localhost'
      tenant = Tenant.find_by(domain: request.host) ||
               Tenant.find_by(subdomain: request.subdomains.first)
    end
    
    # Fallback: always ensure a tenant exists (admin and non-admin)
    tenant ||= Tenant.first || Tenant.create!(
      name: 'RailsPress Default',
      domain: 'localhost',
      theme: 'nordic',
      storage_type: 'local'
    )

    # Set current tenant - use tenant_id to avoid acts_as_tenant issues
    if tenant
      ActsAsTenant.current_tenant = tenant
    end
    
    # Store tenant in instance variable for views
    @current_tenant = tenant
    
    # Log tenant context
    Rails.logger.info "Request tenant: #{tenant&.name || 'None (Global)'}" if tenant
  end
  
  helper_method :current_tenant
  
  def current_tenant
    @current_tenant || ActsAsTenant.current_tenant
  end
  
  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end
