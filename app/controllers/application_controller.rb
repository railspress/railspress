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
    # Find tenant by domain or subdomain
    tenant = Tenant.find_by(domain: request.host) ||
             Tenant.find_by(subdomain: request.subdomains.first)
    
    # Set current tenant (or nil for non-tenant requests)
    ActsAsTenant.current_tenant = tenant
    
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
