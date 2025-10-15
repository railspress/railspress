# Configure acts_as_tenant gem
ActsAsTenant.configure do |config|
  # Don't require tenant on all models
  config.require_tenant = false
end
