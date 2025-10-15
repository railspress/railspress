require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Explicitly require discard gem
require 'discard'

# Explicitly require liquid gem
require 'liquid'

# Require custom middleware
require_relative '../app/middleware/redirect_handler'
require_relative '../app/middleware/analytics_tracker'
require_relative '../app/middleware/headless_mode_handler'
require_relative '../app/middleware/allow_iframe_for_logs'

module Railspress
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil
    
    # Don't autoload themes directory (has non-standard structure)
    config.autoload_paths.delete(Rails.root.join('app', 'themes').to_s)
    
    # Middleware for Rack Attack
    config.middleware.use Rack::Attack
    
    # Middleware for Headless Mode (must come first)
    config.middleware.insert_before Rack::Attack, HeadlessModeHandler
    
    # Middleware for URL Redirects
    config.middleware.use RedirectHandler
    
    # Middleware for Analytics Tracking
    config.middleware.use AnalyticsTracker
    
    # Middleware for Logster iframe support
    config.middleware.use AllowIframeForLogs
  end
end
