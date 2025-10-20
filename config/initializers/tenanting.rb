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
  # Use the tenant model primary key (default: :id). Setting this incorrectly to
  # :tenant_id causes `acts_as_tenant` to call `current_tenant.tenant_id`, which
  # is not defined on `Tenant` and triggers errors in queries.
  config.pkey = :id
end

Rails.application.config.after_initialize do
  # Log tenant system status
  if ActiveRecord::Base.connection.table_exists?('tenants')
    tenant_count = Tenant.count
    Rails.logger.info "Multi-tenancy enabled: #{tenant_count} tenant(s) configured"
  end
end








