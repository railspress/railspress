# Development Plugin Auto-Reload
# Automatically restarts the server when plugins are activated/deactivated

if Rails.env.development?
  # Load the plugin reload service
  require Rails.root.join('app', 'services', 'plugin_reload_service')
  
  # Start the plugin watcher
  require Rails.root.join('lib', 'development_plugin_watcher')
  
  Rails.application.config.after_initialize do
    # Start watching for plugin changes
    DevelopmentPluginWatcher.start_watching
    
    Rails.logger.info "🔄 Plugin auto-reload watcher started"
  end
  
  # Add a console helper for manual plugin reloading
  Rails.application.console do
    def reload_plugins!
      puts "🔄 Reloading plugins..."
      Railspress::PluginSystem.reload_plugins
      puts "✅ Plugins reloaded!"
    end
    
    def restart_for_plugins!
      puts "🔄 Restarting server for plugin changes..."
      PluginReloadService.reload_app_for_plugin_change('manual', 'restart')
    end
  end
end


