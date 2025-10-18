module Railspress
  module PluginSystem
    class << self
      attr_accessor :plugins, :hooks, :filters, :admin_pages, :plugin_routes

      def initialize_system
        @plugins = {}
        @hooks = Hash.new { |hash, key| hash[key] = [] }
        @filters = Hash.new { |hash, key| hash[key] = [] }
        @admin_pages = Hash.new { |hash, key| hash[key] = [] }
        @plugin_routes = {}
        @plugin_admin_routes = {}
        @plugin_frontend_routes = {}
        
        # Enhanced plugin features
        @webhooks = Hash.new { |hash, key| hash[key] = [] }
        @event_listeners = Hash.new { |hash, key| hash[key] = [] }
        @middleware_stack = Hash.new { |hash, key| hash[key] = [] }
        @assets = Hash.new { |hash, key| hash[key] = [] }
        @api_endpoints = Hash.new { |hash, key| hash[key] = [] }
        @theme_templates = Hash.new { |hash, key| hash[key] = [] }
        @theme_assets = Hash.new { |hash, key| hash[key] = [] }
        @theme_settings = Hash.new { |hash, key| hash[key] = [] }
        @validators = Hash.new { |hash, key| hash[key] = [] }
        @commands = Hash.new { |hash, key| hash[key] = [] }
        @scheduled_tasks = Hash.new { |hash, key| hash[key] = [] }
        
        @initialized = true
      end

      # Register a plugin
      def register_plugin(name, plugin_class)
        @plugins[name] = plugin_class
        Rails.logger.info "Plugin registered: #{name}"
      end

      # Reload plugins (for development)
      def reload_plugins
        return unless Rails.env.development?
        
        # Clear existing state completely
        @plugins = {}
        @hooks = Hash.new { |hash, key| hash[key] = [] }
        
        # Reload all active plugins
        load_plugins
        
        Rails.logger.info "Plugins reloaded: #{loaded_plugins.join(', ')}"
        puts "✅ Plugins reloaded: #{loaded_plugins.join(', ')}"
      end
      
      # Load all active plugins from database
      def load_plugins
        initialize_system unless @plugins
        
        # Skip loading plugins if database tables don't exist yet (e.g., during migrations)
        return unless ActiveRecord::Base.connection.table_exists?('plugins')
        
        Plugin.active.find_each do |plugin_record|
          # Use dynamic plugin discovery to find the correct plugin file
          plugin_path = find_plugin_file(plugin_record.name)
          
          if plugin_path && File.exist?(plugin_path)
            begin
              # Use load instead of require for development reloading
              load_method = Rails.env.development? ? :load : :require
              send(load_method, plugin_path)
              
              # Find and instantiate the plugin class
              plugin_instance = instantiate_plugin(plugin_record.name)
              if plugin_instance
                # Call the activate method to register hooks
                plugin_instance.activate
                @plugins[plugin_record.name] = plugin_instance
                Rails.logger.info "Loaded, instantiated, and activated plugin: #{plugin_record.name}"
              else
                Rails.logger.warn "Failed to instantiate plugin: #{plugin_record.name}"
              end
            rescue => e
              Rails.logger.error "Failed to load plugin #{plugin_record.name}: #{e.message}"
            end
          else
            Rails.logger.warn "Plugin file not found for: #{plugin_record.name}"
          end
        end
      end
      
      # Find plugin file using dynamic discovery
      def find_plugin_file(plugin_name)
        plugins_dir = Rails.root.join('lib', 'plugins')
        return nil unless Dir.exist?(plugins_dir)
        
        Dir.glob(File.join(plugins_dir, '*')).each do |plugin_dir|
          next unless File.directory?(plugin_dir)
          
          candidate_name = File.basename(plugin_dir)
          plugin_file = File.join(plugin_dir, "#{candidate_name}.rb")
          
          next unless File.exist?(plugin_file)
          
          begin
            # Load the plugin file to check if it matches our plugin
            load plugin_file
            plugin_class_name = candidate_name.classify
            plugin_class = plugin_class_name.constantize rescue nil
            
            if plugin_class && plugin_class.ancestors.include?(Railspress::PluginBase)
              # Create a temporary instance to check the name
              temp_instance = plugin_class.new
              if temp_instance.name == plugin_name
                return plugin_file
              end
            end
          rescue => e
            # Continue to next plugin if this one fails
            next
          end
        end
        
        nil
      end
      
      # Instantiate a plugin by name
      def instantiate_plugin(plugin_name)
        plugins_dir = Rails.root.join('lib', 'plugins')
        return nil unless Dir.exist?(plugins_dir)
        
        Dir.glob(File.join(plugins_dir, '*')).each do |plugin_dir|
          next unless File.directory?(plugin_dir)
          
          candidate_name = File.basename(plugin_dir)
          plugin_file = File.join(plugin_dir, "#{candidate_name}.rb")
          
          next unless File.exist?(plugin_file)
          
          begin
            plugin_class_name = candidate_name.classify
            plugin_class = plugin_class_name.constantize rescue nil
            
            if plugin_class && plugin_class.ancestors.include?(Railspress::PluginBase)
              # Create a temporary instance to check the name
              temp_instance = plugin_class.new
              if temp_instance.name == plugin_name
                return temp_instance
              end
            end
          rescue => e
            # Continue to next plugin if this one fails
            next
          end
        end
        
        nil
      end

      # Add an action hook
      def add_action(hook_name, callback, priority = 10, plugin_name = nil)
        @hooks ||= Hash.new { |hash, key| hash[key] = [] }
        @hooks[hook_name] << { 
          callback: callback, 
          priority: priority, 
          plugin_name: plugin_name 
        }
        @hooks[hook_name].sort_by! { |h| h[:priority] }
      end

      # Execute action hooks
      def do_action(hook_name, *args)
        return unless @hooks[hook_name]
        
        results = []
        @hooks[hook_name].each do |hook|
          # Skip hooks from deactivated plugins
          next unless plugin_active?(hook[:plugin_name])
          
          begin
            if hook[:callback].respond_to?(:call)
              result = hook[:callback].call(*args)
              results << result if result
            elsif hook[:callback].is_a?(Symbol) || hook[:callback].is_a?(String)
              # If it's a method name, try to call it
              method_name = hook[:callback].to_sym
              if self.respond_to?(method_name)
                result = self.send(method_name, *args)
                results << result if result
              end
            end
          rescue => e
            Rails.logger.error "Error executing hook #{hook_name} from plugin #{hook[:plugin_name]}: #{e.message}"
          end
        end
        
        # Return the results joined together (for HTML output)
        results.join.html_safe
      end

      # Add a filter hook
      def add_filter(filter_name, callback, priority = 10)
        @filters ||= Hash.new { |hash, key| hash[key] = [] }
        @filters[filter_name] << { callback: callback, priority: priority }
        @filters[filter_name].sort_by! { |f| f[:priority] }
      end

      # Apply filters
      def apply_filters(filter_name, value, *args)
        return value unless @filters[filter_name]
        
        @filters[filter_name].reduce(value) do |filtered_value, filter|
          begin
            if filter[:callback].respond_to?(:call)
              filter[:callback].call(filtered_value, *args)
            else
              filtered_value
            end
          rescue => e
            Rails.logger.error "Error applying filter #{filter_name}: #{e.message}"
            filtered_value
          end
        end
      end

      # Check if plugin is loaded
      def plugin_loaded?(name)
        @plugins.key?(name)
      end

      # Get plugin instance
      def get_plugin(name)
        @plugins[name]
      end

      # Get all loaded plugins
      def loaded_plugins
        @plugins.keys
      end
      
      # Check if a plugin is active
      def plugin_active?(plugin_name)
        return true unless plugin_name # Allow hooks without plugin names (backward compatibility)
        
        # Check if plugin exists and is active in the database
        return false unless ActiveRecord::Base.connection.table_exists?('plugins')
        
        Plugin.exists?(name: plugin_name, active: true)
      end
      
      # Register admin page for a plugin
      def register_admin_page(plugin_identifier, page_config)
        @admin_pages ||= Hash.new { |hash, key| hash[key] = [] }
        @admin_pages[plugin_identifier] << page_config
        Rails.logger.info "Registered admin page for #{plugin_identifier}: #{page_config[:title]}"
      end
      
      # Get all admin pages for a plugin
      def get_plugin_admin_pages(plugin_identifier)
        @admin_pages&.dig(plugin_identifier) || []
      end
      
      # Register plugin routes
      def register_plugin_routes(plugin_identifier, routes_block)
        @plugin_routes ||= {}
        @plugin_routes[plugin_identifier] = routes_block
        Rails.logger.info "Registered routes for plugin: #{plugin_identifier}"
      end
      
      # Register admin routes for a plugin
      def register_plugin_admin_routes(plugin_identifier, routes_block)
        @plugin_admin_routes ||= {}
        @plugin_admin_routes[plugin_identifier] = routes_block
        Rails.logger.info "Registered admin routes for plugin: #{plugin_identifier}"
      end
      
      # Register frontend routes for a plugin
      def register_plugin_frontend_routes(plugin_identifier, routes_block)
        @plugin_frontend_routes ||= {}
        @plugin_frontend_routes[plugin_identifier] = routes_block
        Rails.logger.info "Registered frontend routes for plugin: #{plugin_identifier}"
      end
      
      # Get all plugin admin pages
      def all_plugin_admin_pages
        @admin_pages&.values&.flatten || []
      end
      
      # Get all plugin routes
      def all_plugin_routes
        @plugin_routes || {}
      end
      
      # Load all plugin routes into the Rails router
      # Called from config/initializers/plugin_system.rb after plugins are loaded
      def load_plugin_routes!
        total_routes = 0
        total_routes += @plugin_admin_routes&.size || 0
        total_routes += @plugin_frontend_routes&.size || 0
        total_routes += @plugin_routes&.size || 0
        
        return if total_routes == 0
        
        Rails.logger.info "Loading routes for #{total_routes} plugin route blocks..."
        
        Rails.application.routes.append do
          # Load admin routes (scoped under /admin for security)
          if @plugin_admin_routes&.any?
            Rails.logger.info "Loading admin routes..."
            namespace :admin do
              @plugin_admin_routes.each do |plugin_identifier, routes_block|
                begin
                  Rails.logger.info "  → Loading admin routes for: #{plugin_identifier}"
                  
                  # Wrap each plugin's routes in a namespace for isolation
                  namespace plugin_identifier.underscore.to_sym do
                    instance_eval(&routes_block) if routes_block
                  end
                  
                rescue => e
                  Rails.logger.error "  ✗ Failed to load admin routes for #{plugin_identifier}: #{e.message}"
                  Rails.logger.error e.backtrace.first(5).join("\n")
                end
              end
            end
          end
          
          # Load frontend routes (scoped under /plugins for security)
          if @plugin_frontend_routes&.any?
            Rails.logger.info "Loading frontend routes..."
            scope '/plugins' do
              @plugin_frontend_routes.each do |plugin_identifier, routes_block|
                begin
                  Rails.logger.info "  → Loading frontend routes for: #{plugin_identifier}"
                  
                  # Wrap each plugin's routes in a scope for isolation
                  scope plugin_identifier.underscore do
                    instance_eval(&routes_block) if routes_block
                  end
                  
                rescue => e
                  Rails.logger.error "  ✗ Failed to load frontend routes for #{plugin_identifier}: #{e.message}"
                  Rails.logger.error e.backtrace.first(5).join("\n")
                end
              end
            end
          end
          
          # Load legacy routes (backward compatibility - treated as admin routes)
          if @plugin_routes&.any?
            Rails.logger.info "Loading legacy routes (as admin routes)..."
            namespace :admin do
              @plugin_routes.each do |plugin_identifier, routes_block|
                begin
                  Rails.logger.info "  → Loading legacy routes for: #{plugin_identifier}"
                  
                  namespace plugin_identifier.underscore.to_sym do
                    instance_eval(&routes_block) if routes_block
                  end
                  
                rescue => e
                  Rails.logger.error "  ✗ Failed to load legacy routes for #{plugin_identifier}: #{e.message}"
                  Rails.logger.error e.backtrace.first(5).join("\n")
                end
              end
            end
          end
        end
        
        Rails.logger.info "✓ Plugin routes loaded successfully"
      rescue => e
        Rails.logger.error "Failed to load plugin routes: #{e.message}"
        Rails.logger.error e.backtrace.first(10).join("\n")
      end
      
      # ========================================
      # WEBHOOK SYSTEM
      # ========================================
      
      def register_webhook(plugin_identifier, webhook)
        @webhooks[plugin_identifier] << webhook
        Rails.logger.info "Registered webhook for #{plugin_identifier}: #{webhook[:event]}"
      end
      
      def trigger_webhook(plugin_identifier, event_name, data)
        webhooks = @webhooks[plugin_identifier].select { |w| w[:event] == event_name && w[:active] }
        
        webhooks.each do |webhook|
          WebhookJob.perform_later(webhook, data)
        end
        
        Rails.logger.info "Triggered #{webhooks.size} webhooks for #{plugin_identifier}:#{event_name}"
      end
      
      # ========================================
      # EVENT SYSTEM
      # ========================================
      
      def register_event_listener(plugin_identifier, event)
        @event_listeners[plugin_identifier] << event
        Rails.logger.info "Registered event listener for #{plugin_identifier}: #{event[:name]}"
      end
      
      def emit_event(event_name, data = {})
        listeners = []
        @event_listeners.each do |plugin_id, events|
          events.select { |e| e[:name] == event_name }.each do |event|
            listeners << { plugin: plugin_id, callback: event[:callback] }
          end
        end
        
        listeners.sort_by { |l| l[:priority] || 10 }.each do |listener|
          begin
            listener[:callback].call(data)
          rescue => e
            Rails.logger.error "Event listener error in #{listener[:plugin]}: #{e.message}"
          end
        end
        
        Rails.logger.info "Emitted event #{event_name} to #{listeners.size} listeners"
      end
      
      # ========================================
      # MIDDLEWARE SYSTEM
      # ========================================
      
      def register_middleware(plugin_identifier, middleware)
        @middleware_stack[plugin_identifier] << middleware
        Rails.logger.info "Registered middleware for #{plugin_identifier}: #{middleware[:class]}"
      end
      
      def load_plugin_middleware
        @middleware_stack.each do |plugin_id, middleware_list|
          middleware_list.each do |middleware|
            begin
              Rails.application.middleware.use middleware[:class], *middleware[:args], &middleware[:block]
              Rails.logger.info "Loaded middleware for #{plugin_id}: #{middleware[:class]}"
            rescue => e
              Rails.logger.error "Failed to load middleware for #{plugin_id}: #{e.message}"
            end
          end
        end
      end
      
      # ========================================
      # ASSET MANAGEMENT
      # ========================================
      
      def register_asset(plugin_identifier, asset)
        @assets[plugin_identifier] << asset
        Rails.logger.info "Registered asset for #{plugin_identifier}: #{asset[:path]}"
      end
      
      def get_plugin_assets(plugin_identifier, type = nil, context = :all)
        assets = @assets[plugin_identifier]
        
        assets = assets.select { |a| a[:type] == type } if type
        assets = assets.select { |a| a[:admin_only] == true } if context == :admin
        assets = assets.select { |a| a[:frontend_only] == true } if context == :frontend
        
        assets.sort_by { |a| a[:priority] || 10 }
      end
      
      # ========================================
      # API ENDPOINTS
      # ========================================
      
      def register_api_endpoint(plugin_identifier, endpoint)
        @api_endpoints[plugin_identifier] << endpoint
        Rails.logger.info "Registered API endpoint for #{plugin_identifier}: #{endpoint[:method]} #{endpoint[:path]}"
      end
      
      def load_plugin_api_routes
        return unless @api_endpoints.any?
        
        Rails.application.routes.append do
          namespace :api do
            @api_endpoints.each do |plugin_id, endpoints|
              namespace plugin_id.underscore.to_sym do
                endpoints.each do |endpoint|
                  begin
                    send(endpoint[:method].downcase, endpoint[:path], 
                         to: "#{endpoint[:controller]}##{endpoint[:action]}",
                         defaults: { plugin: plugin_id })
                  rescue => e
                    Rails.logger.error "Failed to register API route for #{plugin_id}: #{e.message}"
                  end
                end
              end
            end
          end
        end
      end
      
      # ========================================
      # THEME SYSTEM
      # ========================================
      
      def register_theme_template(plugin_identifier, template)
        @theme_templates[plugin_identifier] << template
        Rails.logger.info "Registered theme template for #{plugin_identifier}: #{template[:name]}"
      end
      
      def register_theme_asset(plugin_identifier, asset)
        @theme_assets[plugin_identifier] << asset
        Rails.logger.info "Registered theme asset for #{plugin_identifier}: #{asset[:path]}"
      end
      
      def register_theme_setting(plugin_identifier, setting)
        @theme_settings[plugin_identifier] << setting
        Rails.logger.info "Registered theme setting for #{plugin_identifier}: #{setting[:key]}"
      end
      
      # ========================================
      # VALIDATORS
      # ========================================
      
      def register_validator(plugin_identifier, validator)
        @validators[plugin_identifier] << validator
        Rails.logger.info "Registered validator for #{plugin_identifier}: #{validator[:name]}"
      end
      
      # ========================================
      # COMMANDS
      # ========================================
      
      def register_command(plugin_identifier, command)
        @commands[plugin_identifier] << command
        Rails.logger.info "Registered command for #{plugin_identifier}: #{command[:name]}"
      end
      
      def load_plugin_commands
        @commands.each do |plugin_id, commands|
          commands.each do |command|
            begin
              Rake::Task.define_task("#{plugin_id}:#{command[:name]}") do |t|
                puts "Running #{plugin_id}:#{command[:name]} - #{command[:description]}"
                command[:block].call
              end
            rescue => e
              Rails.logger.error "Failed to register command for #{plugin_id}: #{e.message}"
            end
          end
        end
      end
      
      # ========================================
      # NOTIFICATIONS
      # ========================================
      
      def notify_admin(plugin_identifier, message, type, options = {})
        # Create admin notification
        AdminNotification.create!(
          plugin: plugin_identifier,
          message: message,
          notification_type: type,
          metadata: options
        )
        Rails.logger.info "Admin notification sent from #{plugin_identifier}: #{message}"
      end
      
      def notify_user(plugin_identifier, user_id, message, type, options = {})
        # Create user notification
        UserNotification.create!(
          plugin: plugin_identifier,
          user_id: user_id,
          message: message,
          notification_type: type,
          metadata: options
        )
        Rails.logger.info "User notification sent from #{plugin_identifier} to user #{user_id}: #{message}"
      end
      
      # ========================================
      # SCHEDULER
      # ========================================
      
      def schedule_task(plugin_identifier, task)
        @scheduled_tasks[plugin_identifier] << task
        Rails.logger.info "Scheduled task for #{plugin_identifier}: #{task[:name]}"
        
        # Schedule with cron job system
        if defined?(Sidekiq)
          Sidekiq::Cron::Job.create(
            name: "#{plugin_identifier}:#{task[:name]}",
            cron: task[:cron],
            class: 'PluginTaskWorker',
            args: [plugin_identifier, task[:name]]
          )
        end
      end
      
      # ========================================
      # DATABASE HELPERS
      # ========================================
      
      def create_plugin_migration(plugin_identifier, table_name, &block)
        timestamp = Time.current.strftime('%Y%m%d%H%M%S')
        filename = "#{timestamp}_create_#{plugin_identifier}_#{table_name}.rb"
        
        migration_path = Rails.root.join('db', 'migrate', filename)
        
        migration_content = <<~RUBY
          class Create#{plugin_identifier.classify}#{table_name.classify} < ActiveRecord::Migration[7.1]
            def change
              create_table :#{plugin_identifier}_#{table_name} do |t|
                #{block ? block.call : '# Add columns here'}
                t.timestamps
              end
            end
          end
        RUBY
        
        File.write(migration_path, migration_content)
        Rails.logger.info "Created migration: #{filename}"
        
        migration_path
      end
      
      def add_plugin_column(plugin_identifier, table_name, column_name, type, options = {})
        timestamp = Time.current.strftime('%Y%m%d%H%M%S')
        filename = "#{timestamp}_add_#{column_name}_to_#{plugin_identifier}_#{table_name}.rb"
        
        migration_path = Rails.root.join('db', 'migrate', filename)
        
        migration_content = <<~RUBY
          class Add#{column_name.classify}To#{plugin_identifier.classify}#{table_name.classify} < ActiveRecord::Migration[7.1]
            def change
              add_column :#{plugin_identifier}_#{table_name}, :#{column_name}, :#{type}#{options.empty? ? '' : ', ' + options.inspect}
            end
          end
        RUBY
        
        File.write(migration_path, migration_content)
        Rails.logger.info "Created column migration: #{filename}"
        
        migration_path
      end
    end
  end
end

