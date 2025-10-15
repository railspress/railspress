class ThemesController < ApplicationController
  # GET /themes/preview?theme=theme_name (public preview)
  def preview
    @theme_id = params[:id]
    @theme = Theme.find(@theme_id)
    @theme_name = @theme.name
    @theme_config = load_theme_config(@theme_name)
    
    # Ensure theme has a published version
    @theme.ensure_published_version_exists!
    published_version = @theme.published_version
    
    # If still no published version, create one
    unless published_version
      @theme.ensure_published_version_exists!
      published_version = @theme.published_version
    end
    
    if published_version
      # Use FrontendRendererService for proper rendering
      renderer = FrontendRendererService.new(published_version)
      template_type = params[:template] || 'index'
      
      begin
        @preview_html = renderer.render_template(template_type, preview_context)
        @assets = renderer.assets
      rescue => e
        Rails.logger.error "Theme preview rendering failed: #{e.message}"
        @preview_html = "<div style='padding: 20px; color: red;'>Preview Error: #{e.message}</div>"
        @assets = { css: '', js: '' }
      end
    else
      @preview_html = "<div style='padding: 20px; color: red;'>No published version found for #{@theme_name}</div>"
      @assets = { css: '', js: '' }
    end
    
    # Render homepage with preview theme
    @featured_posts = Post.published.order(published_at: :desc).limit(3)
    @recent_posts = Post.published.order(published_at: :desc).limit(6)
    @categories = Term.for_taxonomy('category').root_terms.limit(5)
    render 'preview', layout: false
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
  
  
  private
  
  def load_theme_config(theme_name)
    config_path = Rails.root.join('app', 'themes', theme_name, 'config.yml')
    File.exist?(config_path) ? YAML.load_file(config_path) : {}
  end
  
  def preview_context
    {
      featured_posts: @featured_posts,
      recent_posts: @recent_posts,
      categories: @categories
    }
  end
end



