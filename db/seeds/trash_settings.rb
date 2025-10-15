# Create default trash settings for each tenant
puts "Creating trash settings..."

# Get all tenants or create a default one
tenants = Tenant.all
if tenants.empty?
  default_tenant = Tenant.create!(
    name: 'RailsPress Default',
    domain: 'localhost',
    theme: 'nordic'
  )
  tenants = [default_tenant]
end

tenants.each do |tenant|
  TrashSetting.create!(
    auto_cleanup_enabled: true,
    cleanup_after_days: 30,
    tenant: tenant
  ) unless TrashSetting.exists?(tenant: tenant)
end

puts "Trash settings created successfully!"
