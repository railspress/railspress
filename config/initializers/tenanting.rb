# Multi-Tenancy Configuration

# Routing constraint for tenant-based routing
class TenantByDomain
  def self.matches?(request)
    tenant = Tenant.find_by(domain: request.host) || 
             Tenant.find_by(subdomain: request.subdomains.first)
    tenant.present? && tenant.active?
  end
end

# Set acts_as_tenant config
ActsAsTenant.configure do |config|
  config.require_tenant = false # Allow requests without tenant (for admin/auth)
  config.pkey = :tenant_id
end

Rails.application.config.after_initialize do
  # Log tenant system status
  if ActiveRecord::Base.connection.table_exists?('tenants')
    tenant_count = Tenant.count
    Rails.logger.info "Multi-tenancy enabled: #{tenant_count} tenant(s) configured"
  end
end




