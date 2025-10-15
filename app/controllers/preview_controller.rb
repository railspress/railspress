class PreviewController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_published_version
  before_action :set_renderer

  # GET /preview/:template_name
  def show
    template_name = params[:template_name] || 'index'
    
    begin
      @preview_html = @renderer.render_template(template_name, preview_context)
      @assets = @renderer.assets
      
      render layout: 'preview'
    rescue => e
      Rails.logger.error "Preview rendering failed: #{e.message}"
      @preview_html = "<div style='padding: 20px; color: red;'>Preview Error: #{e.message}</div>"
      @assets = { css: '', js: '' }
      render layout: 'preview'
    end
  end

  private

  def set_published_version
    # Get the latest PublishedThemeVersion for the active theme
    @active_theme = Theme.active_theme
    return render_404 unless @active_theme

    @published_version = PublishedThemeVersion.where(theme_name: @active_theme.name.underscore).latest.first
    return render_404 unless @published_version
  end

  def set_renderer
    @renderer = FrontendRendererService.new(@published_version)
  end

  def preview_context
    {
      current_user: current_user,
      request: request
    }
  end

  def render_404
    render plain: 'Theme not found', status: :not_found
  end
end
