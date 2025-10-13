module LiquidRenderable
  extend ActiveSupport::Concern

  included do
    before_action :setup_liquid_renderer
  end

  private

  def setup_liquid_renderer
    @liquid_renderer = LiquidTemplateRenderer.new(current_theme_name)
  end

  def current_theme_name
    Railspress::ThemeLoader.current_theme || 'nordic'
  end

  def render_liquid(template, assigns = {}, options = {})
    layout = options[:layout].nil? ? 'theme' : options[:layout]
    
    assigns_with_context = assigns.merge(
      current_user: current_user,
      request_path: request.path,
      flash: flash.to_hash,
      params: params.to_unsafe_h
    )

    html = @liquid_renderer.render(template, assigns_with_context, layout)
    
    # Inject admin bar for logged-in users
    if user_signed_in? && html.include?('<body')
      admin_bar_html = render_to_string(
        partial: 'shared/admin_bar',
        layout: false,
        formats: [:html]
      )
      
      # Inject right after <body> tag
      html = html.sub(/(<body[^>]*>)/i, "\\1\n#{admin_bar_html}")
    end
    
    render html: html.html_safe, layout: false, status: options[:status] || :ok
  end

  def render_liquid_error(status_code)
    template = case status_code
    when 404
      '404'
    when 500
      '500'
    else
      'error'
    end

    render_liquid(template, { status_code: status_code }, layout: 'error', status: status_code)
  end
end
