# Logster configuration
if defined?(Logster)
    begin
      # Set environments where Logster should run
      Logster.set_environments([:development, :production])
      
      # Initialize Logster configuration
      Logster.config ||= Logster::Configuration.new
      
      # Use memory store for development to avoid Redis dependency
      Logster.store = Logster::RedisStore.new(RedisConfig.connection_options)
      Rails.logger.info "Logster configured with Redis store"
      
      # Disable JavaScript error reporting to stop XMLHttpRequest errors
      Logster.config.enable_js_error_reporting = false
      
      # Set subdirectory for the web interface (default is /logs)
      Logster.config.subdirectory = "/logs"
      
      Rails.logger.info "Logster JavaScript error reporting disabled"
      Rails.logger.info "Logster store: #{Logster.store.class}"
    rescue => e
      Rails.logger.error "Failed to configure Logster: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  else
    Rails.logger.info "Logster gem not available - skipping configuration"
  end
  