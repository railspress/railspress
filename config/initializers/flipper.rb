# Flipper feature flags configuration

Rails.application.configure do
  # Initialize Flipper with ActiveRecord adapter
  config.flipper.adapter = -> {
    Flipper::Adapters::ActiveRecord.new
  }
end

# Enable Flipper UI in admin
# Access at /admin/flipper




