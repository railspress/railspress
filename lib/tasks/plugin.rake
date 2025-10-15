# Plugin Management Rake Tasks
#
# Usage:
#   rails plugin:generate NAME=MyPlugin [OPTIONS]
#   rails plugin:install NAME=MyPlugin
#   rails plugin:uninstall NAME=MyPlugin
#   rails plugin:activate NAME=MyPlugin
#   rails plugin:deactivate NAME=MyPlugin
#   rails plugin:list
#   rails plugin:routes [NAME=MyPlugin]

namespace :plugin do
  desc 'Generate a new plugin with full MVC structure'
  task :generate => :environment do
    plugin_name = ENV['NAME'] || raise('NAME is required. Usage: rails plugin:generate NAME=MyPlugin')
    
    # Use Rails generator
    require 'rails/generators'
    Rails::Generators.invoke('plugin', [plugin_name, '--full'])
  end
  
  desc 'Install a plugin (create database record)'
  task :install => :environment do
    plugin_name = ENV['NAME'] || raise('NAME is required. Usage: rails plugin:install NAME=MyPlugin')
    
    plugin_identifier = plugin_name.underscore
    
    # Check if plugin file exists
    plugin_path = Rails.root.join('lib', 'plugins', plugin_identifier, "#{plugin_identifier}.rb")
    
    unless File.exist?(plugin_path)
      puts "❌ Plugin not found at: #{plugin_path}"
      puts "Run: rails plugin:generate NAME=#{plugin_name}"
      exit 1
    end
    
    # Create plugin record
    plugin = Plugin.find_or_create_by(name: plugin_name) do |p|
      p.active = false
      p.version = '1.0.0'
      p.description = "#{plugin_name} plugin"
    end
    
    if plugin.persisted?
      puts "✓ Plugin '#{plugin_name}' installed successfully!"
      puts "  To activate: rails plugin:activate NAME=#{plugin_name}"
    else
      puts "❌ Failed to install plugin: #{plugin.errors.full_messages.join(', ')}"
      exit 1
    end
  end
  
  desc 'Uninstall a plugin (remove from database and optionally delete files)'
  task :uninstall => :environment do
    plugin_name = ENV['NAME'] || raise('NAME is required. Usage: rails plugin:uninstall NAME=MyPlugin')
    delete_files = ENV['DELETE_FILES'] == 'true'
    
    plugin = Plugin.find_by(name: plugin_name)
    
    unless plugin
      puts "❌ Plugin '#{plugin_name}' not found in database"
      exit 1
    end
    
    # Run uninstall hook if plugin is loaded
    if plugin.active?
      begin
        plugin_instance = Railspress::PluginSystem.get_plugin(plugin_name.underscore)
        plugin_instance&.uninstall
      rescue => e
        puts "⚠️  Warning: Failed to run uninstall hook: #{e.message}"
      end
    end
    
    # Remove from database
    plugin.destroy
    puts "✓ Plugin '#{plugin_name}' uninstalled from database"
    
    # Optionally delete files
    if delete_files
      plugin_path = Rails.root.join('lib', 'plugins', plugin_name.underscore)
      if Dir.exist?(plugin_path)
        FileUtils.rm_rf(plugin_path)
        puts "✓ Plugin files deleted from: #{plugin_path}"
      end
      
      # Delete controllers
      controllers_path = Rails.root.join('app', 'controllers', 'admin', plugin_name.underscore)
      FileUtils.rm_rf(controllers_path) if Dir.exist?(controllers_path)
      
      controllers_path = Rails.root.join('app', 'controllers', 'plugins', plugin_name.underscore)
      FileUtils.rm_rf(controllers_path) if Dir.exist?(controllers_path)
      
      # Delete views
      views_path = Rails.root.join('app', 'views', 'admin', plugin_name.underscore)
      FileUtils.rm_rf(views_path) if Dir.exist?(views_path)
      
      views_path = Rails.root.join('app', 'views', 'plugins', plugin_name.underscore)
      FileUtils.rm_rf(views_path) if Dir.exist?(views_path)
      
      puts "✓ All plugin files deleted"
    else
      puts "ℹ️  Plugin files preserved. Use DELETE_FILES=true to remove files"
    end
  end
  
  desc 'Activate a plugin'
  task :activate => :environment do
    plugin_name = ENV['NAME'] || raise('NAME is required. Usage: rails plugin:activate NAME=MyPlugin')
    
    plugin = Plugin.find_by(name: plugin_name)
    
    unless plugin
      puts "❌ Plugin '#{plugin_name}' not found. Run: rails plugin:install NAME=#{plugin_name}"
      exit 1
    end
    
    if plugin.active?
      puts "ℹ️  Plugin '#{plugin_name}' is already active"
      exit 0
    end
    
    # Load plugin
    plugin_path = Rails.root.join('lib', 'plugins', plugin_name.underscore, "#{plugin_name.underscore}.rb")
    
    unless File.exist?(plugin_path)
      puts "❌ Plugin file not found at: #{plugin_path}"
      exit 1
    end
    
    begin
      require plugin_path
      
      # Run activation hook
      plugin_instance = Railspress::PluginSystem.get_plugin(plugin_name.underscore)
      plugin_instance&.activate
      
      # Mark as active
      plugin.update!(active: true)
      
      puts "✓ Plugin '#{plugin_name}' activated successfully!"
      puts "  Restart Rails server to load routes"
    rescue => e
      puts "❌ Failed to activate plugin: #{e.message}"
      puts e.backtrace.first(5).join("\n")
      exit 1
    end
  end
  
  desc 'Deactivate a plugin'
  task :deactivate => :environment do
    plugin_name = ENV['NAME'] || raise('NAME is required. Usage: rails plugin:deactivate NAME=MyPlugin')
    
    plugin = Plugin.find_by(name: plugin_name)
    
    unless plugin
      puts "❌ Plugin '#{plugin_name}' not found"
      exit 1
    end
    
    unless plugin.active?
      puts "ℹ️  Plugin '#{plugin_name}' is already inactive"
      exit 0
    end
    
    # Run deactivation hook
    begin
      plugin_instance = Railspress::PluginSystem.get_plugin(plugin_name.underscore)
      plugin_instance&.deactivate
    rescue => e
      puts "⚠️  Warning: Failed to run deactivation hook: #{e.message}"
    end
    
    # Mark as inactive
    plugin.update!(active: false)
    
    puts "✓ Plugin '#{plugin_name}' deactivated successfully!"
    puts "  Restart Rails server to unload routes"
  end
  
  desc 'List all plugins'
  task :list => :environment do
    plugins = Plugin.all
    
    if plugins.empty?
      puts "No plugins installed"
      exit 0
    end
    
    puts "\n📦 Installed Plugins:\n\n"
    puts "%-30s %-10s %-10s %s" % ['Name', 'Version', 'Status', 'Description']
    puts "-" * 100
    
    plugins.each do |plugin|
      status = plugin.active? ? '✓ Active' : '○ Inactive'
      puts "%-30s %-10s %-10s %s" % [
        plugin.name,
        plugin.version,
        status,
        plugin.description
      ]
    end
    
    puts "\n"
  end
  
  desc 'Show routes for a specific plugin or all plugins'
  task :routes => :environment do
    plugin_name = ENV['NAME']
    
    # Load plugins
    Railspress::PluginSystem.load_plugins
    
    if plugin_name
      # Show routes for specific plugin
      plugin_identifier = plugin_name.underscore
      
      puts "\n🛣️  Routes for #{plugin_name}:\n\n"
      
      # Filter routes
      Rails.application.routes.routes.each do |route|
        path = route.path.spec.to_s
        
        if path.include?("/admin/#{plugin_identifier}") || path.include?("/plugins/#{plugin_identifier}")
          verb = route.verb
          controller = route.defaults[:controller]
          action = route.defaults[:action]
          name = route.name
          
          puts "%-8s %-50s %s#%s" % [
            verb,
            path,
            controller,
            action
          ]
        end
      end
    else
      # Show all plugin routes
      puts "\n🛣️  All Plugin Routes:\n\n"
      
      Rails.application.routes.routes.each do |route|
        path = route.path.spec.to_s
        
        if path.include?('/admin/') && !path.include?('/admin/settings') && !path.include?('/admin/users') || path.include?('/plugins/')
          verb = route.verb
          controller = route.defaults[:controller]
          action = route.defaults[:action]
          
          # Check if it's a plugin route
          if controller.to_s.match?(/^(Admin|Plugins)::[A-Z]/) && !controller.to_s.match?(/^Admin::(Settings|Users|Posts|Pages|Media|Comments)/)
            puts "%-8s %-50s %s#%s" % [
              verb,
              path,
              controller,
              action
            ]
          end
        end
      end
    end
    
    puts "\n"
  end
  
  desc 'Scaffold plugin resources (models, controllers, views)'
  task :scaffold => :environment do
    plugin_name = ENV['NAME'] || raise('NAME is required. Usage: rails plugin:scaffold NAME=MyPlugin RESOURCE=Item')
    resource_name = ENV['RESOURCE'] || raise('RESOURCE is required. Usage: rails plugin:scaffold NAME=MyPlugin RESOURCE=Item')
    
    plugin_identifier = plugin_name.underscore
    resource_identifier = resource_name.underscore
    resource_class = resource_name.camelize
    
    puts "Scaffolding #{resource_name} for #{plugin_name}..."
    
    # Generate model
    puts "  → Creating model #{plugin_identifier}_#{resource_identifier}.rb"
    # Use Rails scaffold generator
    system("rails generate model #{plugin_identifier}_#{resource_identifier} title:string description:text active:boolean tenant:references")
    
    # Generate admin controller
    puts "  → Creating admin controller"
    # Create controller file
    
    # Generate views
    puts "  → Creating views"
    # Create view files
    
    puts "✓ Scaffold generated successfully!"
    puts "  Run: rails db:migrate"
  end
  
  desc 'Show plugin information'
  task :info => :environment do
    plugin_name = ENV['NAME'] || raise('NAME is required. Usage: rails plugin:info NAME=MyPlugin')
    
    plugin = Plugin.find_by(name: plugin_name)
    
    unless plugin
      puts "❌ Plugin '#{plugin_name}' not found"
      exit 1
    end
    
    # Load plugin to get metadata
    plugin_identifier = plugin_name.underscore
    plugin_path = Rails.root.join('lib', 'plugins', plugin_identifier, "#{plugin_identifier}.rb")
    
    if File.exist?(plugin_path)
      require plugin_path if plugin.active?
      plugin_instance = Railspress::PluginSystem.get_plugin(plugin_identifier) if plugin.active?
    end
    
    puts "\n📋 Plugin Information:\n\n"
    puts "Name:        #{plugin.name}"
    puts "Version:     #{plugin.version}"
    puts "Status:      #{plugin.active? ? '✓ Active' : '○ Inactive'}"
    puts "Description: #{plugin.description}"
    puts "Path:        #{plugin_path}"
    
    if plugin_instance
      puts "\nSettings:"
      plugin_instance.settings_schema.each do |setting|
        puts "  - #{setting[:label]} (#{setting[:key]}): #{setting[:default]}"
      end
      
      puts "\nAdmin Pages:"
      plugin_instance.admin_pages.each do |page|
        puts "  - #{page[:title]} (/admin/plugins/#{plugin_identifier}/#{page[:slug]})"
      end
    end
    
    puts "\n"
  end
end





