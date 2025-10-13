module Railspress
  class PluginBase
    class << self
      # DSL for plugin metadata (WordPress-style)
      def plugin_name(name = nil)
        @plugin_name = name if name
        @plugin_name
      end
      
      def plugin_version(version = nil)
        @plugin_version = version if version
        @plugin_version
      end
      
      def plugin_description(description = nil)
        @plugin_description = description if description
        @plugin_description
      end
      
      def plugin_author(author = nil)
        @plugin_author = author if author
        @plugin_author
      end
      
      def plugin_url(url = nil)
        @plugin_url = url if url
        @plugin_url
      end
      
      def plugin_license(license = nil)
        @plugin_license = license if license
        @plugin_license
      end
    end
    
    attr_reader :settings_schema, :admin_pages, :routes_block
    
    def initialize
      @settings_schema = []
      @admin_pages = []
      @routes_block = nil
      @admin_routes_block = nil
      @frontend_routes_block = nil
      
      # Enhanced plugin features
      @webhooks = []
      @events = []
      @middleware = []
      @assets = []
      @commands = []
      @validators = []
      @api_endpoints = []
      @theme_templates = []
      @theme_assets = []
      @theme_settings = []
      
      # Copy class-level metadata to instance
      @name = self.class.plugin_name
      @version = self.class.plugin_version
      @description = self.class.plugin_description
      @author = self.class.plugin_author
      @url = self.class.plugin_url
      @license = self.class.plugin_license
      
      setup if respond_to?(:setup, true)
    end
    
    # Accessors for metadata
    def name
      @name || self.class.name.demodulize
    end
    
    def version
      @version || '1.0.0'
    end
    
    def description
      @description || ''
    end
    
    def author
      @author || ''
    end
    
    # Activation hook - called when plugin is activated
    def activate
      log("Activating #{name} v#{version}")
      # Override in subclass
    end
    
    # Deactivation hook - called when plugin is deactivated
    def deactivate
      log("Deactivating #{name}")
      # Override in subclass
    end
    
    # Uninstall hook - called when plugin is deleted
    def uninstall
      log("Uninstalling #{name}")
      # Remove all plugin settings
      PluginSetting.where(plugin_name: plugin_identifier).destroy_all
      # Override in subclass for additional cleanup
    end
    
    # ========================================
    # SETTINGS SYSTEM
    # ========================================
    
    # Define plugin setting with schema
    # Example:
    #   define_setting :api_key, 
    #     type: 'string',
    #     default: '',
    #     label: 'API Key',
    #     description: 'Your API key',
    #     required: true,
    #     placeholder: 'sk-...'
    def define_setting(key, options = {})
      @settings_schema << {
        key: key.to_s,
        type: options[:type] || 'string',
        default: options[:default],
        label: options[:label] || key.to_s.titleize,
        description: options[:description],
        required: options[:required] || false,
        options: options[:options], # For select/radio types
        placeholder: options[:placeholder],
        min: options[:min],
        max: options[:max],
        rows: options[:rows], # For textarea
        group: options[:group] # For organizing settings
      }
    end
    
    # Get plugin setting value
    def get_setting(key, default = nil)
      setting = PluginSetting.find_by(plugin_name: plugin_identifier, key: key.to_s)
      return parse_setting_value(setting.value, setting.setting_type) if setting
      
      # Return default from schema
      schema_setting = @settings_schema.find { |s| s[:key] == key.to_s }
      schema_setting&.dig(:default) || default
    end
    
    # Set plugin setting value
    def set_setting(key, value)
      # Determine setting type from schema
      schema = @settings_schema.find { |s| s[:key] == key.to_s }
      setting_type = schema ? schema[:type] : 'string'
      
      PluginSetting.find_or_create_by!(
        plugin_name: plugin_identifier,
        key: key.to_s
      ) do |setting|
        setting.value = value.to_s
        setting.setting_type = setting_type
      end.tap do |setting|
        setting.update(value: value.to_s, setting_type: setting_type)
      end
    end
    
    # Get all plugin settings as hash
    def get_all_settings
      hash = {}
      @settings_schema.each do |schema|
        hash[schema[:key]] = get_setting(schema[:key])
      end
      hash
    end
    
    # Update multiple settings at once
    def update_settings(settings_hash)
      settings_hash.each do |key, value|
        set_setting(key, value)
      end
    end
    
    # Check if plugin has settings
    def has_settings?
      @settings_schema.any?
    end
    
    # Check if setting is enabled (for boolean settings)
    def setting_enabled?(key)
      value = get_setting(key)
      value == true || value == 'true' || value == '1'
    end
    
    # ========================================
    # ADMIN PAGES SYSTEM
    # ========================================
    
    # Register an admin page for this plugin
    # Example:
    #   register_admin_page(
    #     slug: 'dashboard',
    #     title: 'My Plugin Dashboard',
    #     menu_title: 'Dashboard',
    #     icon: 'chart-bar',
    #     position: 10,
    #     parent: 'plugins' # Optional parent menu
    #   )
    def register_admin_page(options = {})
      page = {
        plugin: plugin_identifier,
        slug: options[:slug] || 'settings',
        path: "admin/plugins/#{plugin_identifier}/#{options[:slug] || 'settings'}",
        title: options[:title] || "#{name} Settings",
        menu_title: options[:menu_title] || name,
        capability: options[:capability] || 'administrator',
        icon: options[:icon] || 'puzzle',
        position: options[:position] || 100,
        parent: options[:parent], # 'plugins', 'tools', 'settings', or nil for top-level
        callback: options[:callback] # Method to call for rendering
      }
      
      @admin_pages << page
      
      # Store in global registry for sidebar rendering
      Railspress::PluginSystem.register_admin_page(plugin_identifier, page)
      
      log("Registered admin page: #{page[:path]}")
    end
    
    # Render default settings page
    def render_settings_page
      {
        title: "#{name} Settings",
        settings: @settings_schema,
        current_values: get_all_settings,
        save_url: "/admin/plugins/#{plugin_identifier}/settings",
        plugin_info: metadata
      }
    end
    
    # Get all admin pages for this plugin
    def admin_pages
      @admin_pages
    end
    
    # Check if plugin has admin pages
    def has_admin_pages?
      @admin_pages.any?
    end
    
    # ========================================
    # ROUTES SYSTEM
    # ========================================
    
    # Register routes for this plugin
    # Example:
    #   register_routes do
    #     get '/my-plugin/action', to: 'my_plugin#action'
    #     namespace :admin do
    #       resources :my_plugin
    #     end
    #   end
    def register_routes(&block)
      @routes_block = block
      Railspress::PluginSystem.register_plugin_routes(plugin_identifier, block)
      log("Routes registered for #{name}", :debug)
    end
    
    # Register admin routes for this plugin
    def register_admin_routes(&block)
      @admin_routes_block = block
      Railspress::PluginSystem.register_plugin_admin_routes(plugin_identifier, block)
      log("Admin routes registered for #{name}", :debug)
    end
    
    # Register frontend routes for this plugin
    def register_frontend_routes(&block)
      @frontend_routes_block = block
      Railspress::PluginSystem.register_plugin_frontend_routes(plugin_identifier, block)
      log("Frontend routes registered for #{name}", :debug)
    end
    
    # Check if plugin has routes
    def has_routes?
      @routes_block.present? || @admin_routes_block.present? || @frontend_routes_block.present?
    end
    
    # ========================================
    # WEBHOOK SYSTEM
    # ========================================
    
    # Register a webhook endpoint
    def register_webhook(event_name, url, options = {})
      webhook = {
        event: event_name,
        url: url,
        method: options[:method] || 'POST',
        headers: options[:headers] || {},
        secret: options[:secret],
        retry_count: options[:retry_count] || 3,
        timeout: options[:timeout] || 30,
        active: options[:active] != false
      }
      
      @webhooks << webhook
      Railspress::PluginSystem.register_webhook(plugin_identifier, webhook)
      log("Registered webhook for event: #{event_name}", :debug)
    end
    
    # Trigger a webhook
    def trigger_webhook(event_name, data = {})
      Railspress::PluginSystem.trigger_webhook(plugin_identifier, event_name, data)
    end
    
    # ========================================
    # EVENT SYSTEM
    # ========================================
    
    # Register an event listener
    def on(event_name, &block)
      event = {
        name: event_name,
        callback: block,
        priority: 10
      }
      
      @events << event
      Railspress::PluginSystem.register_event_listener(plugin_identifier, event)
      log("Registered event listener for: #{event_name}", :debug)
    end
    
    # Emit an event
    def emit(event_name, data = {})
      Railspress::PluginSystem.emit_event(event_name, data)
    end
    
    # ========================================
    # MIDDLEWARE SYSTEM
    # ========================================
    
    # Add middleware to the application
    def add_middleware(middleware_class, *args, &block)
      middleware = {
        class: middleware_class,
        args: args,
        block: block
      }
      
      @middleware << middleware
      Railspress::PluginSystem.register_middleware(plugin_identifier, middleware)
      log("Registered middleware: #{middleware_class}", :debug)
    end
    
    # ========================================
    # ASSET MANAGEMENT
    # ========================================
    
    # Register plugin assets (CSS, JS, images)
    def register_asset(path, type = :javascript, options = {})
      asset = {
        path: path,
        type: type,
        admin_only: options[:admin_only] || false,
        frontend_only: options[:frontend_only] || false,
        priority: options[:priority] || 10,
        dependencies: options[:dependencies] || []
      }
      
      @assets << asset
      Railspress::PluginSystem.register_asset(plugin_identifier, asset)
      log("Registered #{type} asset: #{path}", :debug)
    end
    
    # Register CSS asset
    def register_stylesheet(path, options = {})
      register_asset(path, :stylesheet, options)
    end
    
    # Register JavaScript asset
    def register_javascript(path, options = {})
      register_asset(path, :javascript, options)
    end
    
    # Register image asset
    def register_image(path, options = {})
      register_asset(path, :image, options)
    end
    
    # ========================================
    # API ENDPOINTS
    # ========================================
    
    # Register API endpoint
    def register_api_endpoint(method, path, controller_action, options = {})
      endpoint = {
        method: method.to_s.upcase,
        path: path,
        controller: controller_action[:controller],
        action: controller_action[:action],
        authentication: options[:authentication] || :token,
        rate_limit: options[:rate_limit],
        version: options[:version] || 'v1'
      }
      
      @api_endpoints << endpoint
      Railspress::PluginSystem.register_api_endpoint(plugin_identifier, endpoint)
      log("Registered API endpoint: #{method.upcase} #{path}", :debug)
    end
    
    # ========================================
    # THEME SYSTEM
    # ========================================
    
    # Register theme template
    def register_theme_template(name, content, options = {})
      template = {
        name: name,
        content: content,
        type: options[:type] || :page,
        theme: options[:theme] || 'default',
        variables: options[:variables] || []
      }
      
      @theme_templates << template
      Railspress::PluginSystem.register_theme_template(plugin_identifier, template)
      log("Registered theme template: #{name}", :debug)
    end
    
    # Register theme asset
    def register_theme_asset(path, type, options = {})
      asset = {
        path: path,
        type: type,
        theme: options[:theme] || 'default',
        public: options[:public] || false
      }
      
      @theme_assets << asset
      Railspress::PluginSystem.register_theme_asset(plugin_identifier, asset)
      log("Registered theme asset: #{path}", :debug)
    end
    
    # Register theme setting
    def register_theme_setting(key, type, options = {})
      setting = {
        key: key,
        type: type,
        default: options[:default],
        label: options[:label],
        description: options[:description],
        theme: options[:theme] || 'default'
      }
      
      @theme_settings << setting
      Railspress::PluginSystem.register_theme_setting(plugin_identifier, setting)
      log("Registered theme setting: #{key}", :debug)
    end
    
    # ========================================
    # CUSTOM VALIDATORS
    # ========================================
    
    # Register custom validator
    def register_validator(name, &block)
      validator = {
        name: name,
        block: block
      }
      
      @validators << validator
      Railspress::PluginSystem.register_validator(plugin_identifier, validator)
      log("Registered custom validator: #{name}", :debug)
    end
    
    # ========================================
    # CUSTOM COMMANDS
    # ========================================
    
    # Register custom rake task
    def register_command(name, description, &block)
      command = {
        name: name,
        description: description,
        block: block
      }
      
      @commands << command
      Railspress::PluginSystem.register_command(plugin_identifier, command)
      log("Registered custom command: #{name}", :debug)
    end
    
    # ========================================
    # CACHE SYSTEM
    # ========================================
    
    # Cache data with plugin-specific key
    def cache(key, data = nil, expires_in: 1.hour)
      cache_key = "#{plugin_identifier}:#{key}"
      
      if data
        Rails.cache.write(cache_key, data, expires_in: expires_in)
        data
      else
        Rails.cache.read(cache_key)
      end
    end
    
    # Clear plugin cache
    def clear_cache(pattern = nil)
      if pattern
        Rails.cache.delete_matched("#{plugin_identifier}:#{pattern}")
      else
        Rails.cache.delete_matched("#{plugin_identifier}:*")
      end
    end
    
    # ========================================
    # NOTIFICATION SYSTEM
    # ========================================
    
    # Send notification to admin users
    def notify_admin(message, type = :info, options = {})
      Railspress::PluginSystem.notify_admin(plugin_identifier, message, type, options)
    end
    
    # Send notification to specific user
    def notify_user(user_id, message, type = :info, options = {})
      Railspress::PluginSystem.notify_user(plugin_identifier, user_id, message, type, options)
    end
    
    # ========================================
    # SCHEDULER SYSTEM
    # ========================================
    
    # Schedule a recurring task
    def schedule_task(name, cron_expression, &block)
      task = {
        name: name,
        cron: cron_expression,
        block: block
      }
      
      Railspress::PluginSystem.schedule_task(plugin_identifier, task)
      log("Scheduled task: #{name} (#{cron_expression})", :debug)
    end
    
    # ========================================
    # DATABASE HELPERS
    # ========================================
    
    # Create table for plugin
    def create_table(table_name, &block)
      migration = Railspress::PluginSystem.create_plugin_migration(plugin_identifier, table_name, &block)
      log("Created table migration: #{table_name}", :debug)
      migration
    end
    
    # Add column to existing table
    def add_column(table_name, column_name, type, options = {})
      Railspress::PluginSystem.add_plugin_column(plugin_identifier, table_name, column_name, type, options)
      log("Added column: #{table_name}.#{column_name}", :debug)
    end
    
    # ========================================
    # UTILITY METHODS
    # ========================================
    
    # Get plugin root path
    def plugin_path
      @plugin_path ||= Rails.root.join('lib', 'plugins', plugin_identifier)
    end
    
    # Get plugin public URL
    def plugin_url(path = '')
      "/plugins/#{plugin_identifier}/#{path}".gsub(/\/+/, '/')
    end
    
    # Get plugin admin URL
    def admin_url(path = '')
      "/admin/#{plugin_identifier}/#{path}".gsub(/\/+/, '/')
    end
    
    # Check if feature is enabled
    def feature_enabled?(feature_name)
      get_setting("feature_#{feature_name}", false)
    end
    
    # Enable/disable feature
    def set_feature(feature_name, enabled)
      set_setting("feature_#{feature_name}", enabled)
    end
    
    # ========================================
    # HOOKS & FILTERS
    # ========================================
    
    # Add an action hook
    def add_action(hook_name, method_name, priority = 10)
      Railspress::PluginSystem.add_action(hook_name, -> (*args) {
        self.send(method_name, *args)
      }, priority)
    end
    
    # Add a filter hook
    def add_filter(filter_name, method_name, priority = 10)
      Railspress::PluginSystem.add_filter(filter_name, -> (value, *args) {
        self.send(method_name, value, *args)
      }, priority)
    end
    
    # ========================================
    # BACKGROUND JOBS
    # ========================================
    
    # Create a background job for the plugin
    def create_job(job_name, &block)
      job_class_name = "#{plugin_identifier.camelize}::#{job_name}"
      
      # Define job class dynamically
      job_class = Class.new(ApplicationJob) do
        queue_as :default
        class_eval(&block) if block_given?
      end
      
      # Set constant in plugin module
      plugin_module_name = plugin_identifier.camelize
      unless Object.const_defined?(plugin_module_name)
        Object.const_set(plugin_module_name, Module.new)
      end
      plugin_module = plugin_module_name.constantize
      plugin_module.const_set(job_name, job_class)
      
      log("Created job: #{job_class_name}")
      job_class
    end
    
    # Enqueue a job to run immediately
    def enqueue_job(job_class, *args)
      job_class.perform_later(*args)
      log("Enqueued job: #{job_class.name}")
    end
    
    # Schedule a job to run at specific time
    def schedule_job(job_class, run_at, *args)
      job_class.set(wait_until: run_at).perform_later(*args)
      log("Scheduled job: #{job_class.name} at #{run_at}")
    end
    
    # Schedule a job to run after delay
    def schedule_job_in(job_class, delay, *args)
      job_class.set(wait: delay).perform_later(*args)
      log("Scheduled job: #{job_class.name} in #{delay}")
    end
    
    # Schedule recurring job (using Sidekiq-cron if available)
    def schedule_recurring_job(job_name, cron_expression, job_class, *args)
      return unless defined?(Sidekiq::Cron)
      
      Sidekiq::Cron::Job.create(
        name: "#{plugin_identifier}_#{job_name}",
        cron: cron_expression,
        class: job_class.name,
        args: args.to_json
      )
      
      log("Scheduled recurring job: #{job_name} (#{cron_expression})")
    end
    
    # Remove recurring job
    def remove_recurring_job(job_name)
      return unless defined?(Sidekiq::Cron)
      
      Sidekiq::Cron::Job.destroy("#{plugin_identifier}_#{job_name}")
      log("Removed recurring job: #{job_name}")
    end
    
    # Get all recurring jobs for this plugin
    def recurring_jobs
      return [] unless defined?(Sidekiq::Cron)
      
      prefix = "#{plugin_identifier}_"
      Sidekiq::Cron::Job.all.select { |job| job.name.start_with?(prefix) }
    end
    
    # ========================================
    # UTILITY METHODS
    # ========================================
    
    # Get plugin identifier (snake_case name)
    def plugin_identifier
      name.underscore.gsub(/\s+/, '_').gsub(/[^a-z0-9_]/, '')
    end
    
    # Get plugin directory path
    def plugin_path
      Rails.root.join('lib', 'plugins', plugin_identifier)
    end
    
    # Load a plugin view
    def plugin_view(view_name)
      "plugins/#{plugin_identifier}/#{view_name}"
    end
    
    # Plugin asset URL
    def plugin_asset_url(asset_name)
      "/plugins/#{plugin_identifier}/assets/#{asset_name}"
    end
    
    # Log plugin message
    def log(message, level = :info)
      Rails.logger.send(level, "[#{name}] #{message}")
    end
    
    # Check if plugin meets requirements
    def check_requirements
      # Override in subclass to check dependencies
      # Return array of error messages, or empty array if all OK
      []
    end
    
    # Plugin metadata for display
    def metadata
      {
        name: name,
        version: version,
        description: description,
        author: author,
        url: @url,
        license: @license,
        identifier: plugin_identifier,
        has_settings: has_settings?,
        has_admin_pages: has_admin_pages?,
        settings_count: @settings_schema.length,
        admin_pages_count: @admin_pages.length
      }
    end
    
    # ========================================
    # CONTENT TYPE HELPERS
    # ========================================
    
    # Get all active content types
    def get_content_types
      ContentType.active.ordered
    end
    
    # Get a specific content type by identifier
    def get_content_type(ident)
      ContentType.find_by_ident(ident)
    end
    
    # Register a new content type
    def register_content_type(ident, options = {})
      ContentType.find_or_create_by!(ident: ident) do |ct|
        ct.label = options[:label] || ident.titleize
        ct.singular = options[:singular] || ct.label
        ct.plural = options[:plural] || ct.label.pluralize
        ct.description = options[:description]
        ct.icon = options[:icon] || 'document-text'
        ct.public = options.fetch(:public, true)
        ct.hierarchical = options.fetch(:hierarchical, false)
        ct.has_archive = options.fetch(:has_archive, true)
        ct.menu_position = options[:menu_position]
        ct.supports = options[:supports] || ['title', 'editor', 'excerpt', 'thumbnail']
        ct.capabilities = options[:capabilities] || {}
        ct.rest_base = options[:rest_base]
        ct.active = options.fetch(:active, true)
      end
      
      log("Registered content type: #{ident}", :debug)
    end
    
    # Unregister a content type (marks as inactive)
    def unregister_content_type(ident)
      ct = ContentType.find_by_ident(ident)
      if ct
        ct.update(active: false)
        log("Unregistered content type: #{ident}", :debug)
      end
    end
    
    # Get posts of a specific content type
    def get_posts_by_type(ident, limit: nil)
      ct = get_content_type(ident)
      return Post.none unless ct
      
      posts = Post.where(content_type: ct)
      posts = posts.limit(limit) if limit
      posts
    end
    
    private
    
    # Parse setting value based on type
    def parse_setting_value(value, type)
      case type
      when 'boolean'
        value == 'true' || value == '1' || value == true
      when 'integer', 'number'
        value.to_i
      when 'float'
        value.to_f
      when 'array', 'json'
        JSON.parse(value) rescue []
      else
        value
      end
    end
  end
end
