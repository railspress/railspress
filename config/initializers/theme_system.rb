# Theme System Initializer
# Load and configure the theme system

require Rails.root.join('lib', 'railspress', 'theme_loader')

Rails.application.config.after_initialize do
  # Initialize the theme loader
  Railspress::ThemeLoader.initialize_loader
  
  # Include theme helper in all controllers
  ActiveSupport.on_load(:action_controller) do
    helper_method :theme_option, :theme_name, :theme_version, :theme_supports?, :render_widget_area
  end
  
  # Load theme helpers
  theme_helpers = Railspress::ThemeLoader.theme_helpers
  theme_helpers.each do |helper_module|
    ApplicationController.helper(helper_module)
  end
end

# Reload theme on changes in development
if Rails.env.development?
  Rails.application.config.to_prepare do
    Railspress::ThemeLoader.load_active_theme
  end
end




