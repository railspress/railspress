require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  #CACHE
  config.action_controller.perform_caching = true
  config.action_controller.enable_fragment_cache_logging = true
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    # Use Redis for caching in development when enabled
    # config.cache_store = :redis_cache_store, RedisConfig.cache_options
    config.cache_store = :memory_store
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end
  
  # NO CACHE HEADERS FOR ASSETS IN DEVELOPMENT
  config.public_file_server.headers = {
    "Cache-Control" => "no-cache, no-store, must-revalidate",
    "Pragma" => "no-cache",
    "Expires" => "0"
  }

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false
  
  # Devise configuration
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true
  
  # Simple asset configuration for development
  config.assets.compile = true
  config.assets.debug = true
  config.assets.digest = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true
  config.action_cable.mount_path = "/cable"
  config.action_cable.disable_request_forgery_protection = true
  config.action_cable.allowed_request_origins = [ /http:\/\/localhost:\d+/ ]

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = false
  
  # Hot reloading for CSS/JS changes
  config.middleware.insert_after ActionDispatch::Static, Hotwire::Livereload::Middleware
  config.hotwire_livereload.reload_method = :turbo_stream
  config.hotwire_livereload.listen_paths += [
    Rails.root.join("app/assets/stylesheets"),
    Rails.root.join("app/assets/javascripts"),
    Rails.root.join("app/javascript"),
    Rails.root.join("app/views"),
    Rails.root.join("app/assets/builds")
  ]
end
