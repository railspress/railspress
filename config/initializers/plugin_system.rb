# Plugin System Initializer
# Load and configure the plugin system

require Rails.root.join('lib', 'railspress', 'plugin_system')
require Rails.root.join('lib', 'railspress', 'plugin_base')

Rails.application.config.after_initialize do
  # Initialize the plugin system
  Railspress::PluginSystem.initialize_system
  
  # Load all active plugins
  Railspress::PluginSystem.load_plugins
  
  # Load plugin routes dynamically
  Railspress::PluginSystem.load_plugin_routes!
  
  Rails.logger.info "Plugin system initialized. Loaded plugins: #{Railspress::PluginSystem.loaded_plugins.join(', ')}"
end

# Reload plugins in development (disabled to prevent multiple instances)
# Use Railspress::PluginSystem.reload_plugins manually when needed
# if Rails.env.development?
#   Rails.application.config.to_prepare do
#     Railspress::PluginSystem.reload_plugins
#   end
# end




