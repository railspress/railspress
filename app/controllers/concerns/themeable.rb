module Themeable
  extend ActiveSupport::Concern

  included do
    before_action :load_theme
    helper_method :current_theme, :theme_option, :theme_config
  end

  private

  def load_theme
    # Theme is already loaded by initializer, but we can add controller-specific logic here
    @current_theme = Railspress::ThemeLoader.current_theme
  end

  def current_theme
    @current_theme || Railspress::ThemeLoader.current_theme
  end

  def theme_option(key, default = nil)
    config = theme_config
    config.dig('settings', key) || default
  end

  def theme_config
    @theme_config ||= Railspress::ThemeLoader.theme_config
  end

  def theme_name
    theme_config['name'] || 'Default Theme'
  end

  def theme_version
    theme_config['version'] || '1.0.0'
  end

  def theme_supports?(feature)
    theme_config.dig('features')&.include?(feature.to_s) || false
  end
end




