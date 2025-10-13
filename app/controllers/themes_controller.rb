class ThemesController < ApplicationController
  # GET /themes/preview?theme=theme_name (public preview)
  def preview
    @theme_name = params[:theme]
    @is_preview = true
    
    # Temporarily override theme for this request only
    @preview_theme = @theme_name
    
    # Load theme config
    config_path = Rails.root.join('app', 'themes', @theme_name, 'config.yml')
    @theme_config = File.exist?(config_path) ? YAML.load_file(config_path) : {}
    
    # Temporarily set view paths for preview
    theme_views_path = Rails.root.join('app', 'themes', @theme_name, 'views')
    if Dir.exist?(theme_views_path)
      prepend_view_path(theme_views_path)
    end
    
    # Render homepage with preview theme
    @featured_posts = Post.published.order(published_at: :desc).limit(3)
    @recent_posts = Post.published.order(published_at: :desc).limit(6)
    @categories = Term.for_taxonomy('category').root_terms.limit(5)
    
    render 'home/index', layout: 'application'
  end
  
  # POST /themes/switch (if you want public theme switching)
  def switch
    theme_name = params[:theme]
    
    # Only allow admins to switch themes
    unless current_user&.administrator?
      redirect_back fallback_location: root_path, alert: 'Permission denied'
      return
    end
    
    if Railspress::ThemeLoader.activate_theme(theme_name)
      redirect_back fallback_location: root_path, notice: "Theme switched to #{theme_name.titleize}"
    else
      redirect_back fallback_location: root_path, alert: "Failed to switch theme"
    end
  end
end



