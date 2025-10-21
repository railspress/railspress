class HomeController < ApplicationController
  include Themeable
  
  def index
    # Get the active theme
    active_theme = Theme.active.first
    unless active_theme
      render html: "<h1>No active theme found</h1>", status: :internal_server_error
      return
    end
    
    # Ensure theme has a published version
    active_theme.ensure_published_version_exists!
    published_version = active_theme.published_version
    
    unless published_version
      render html: "<h1>Failed to create published theme version</h1>", status: :internal_server_error
      return
    end
    
    # Prepare context data
    featured_posts = Post.published.recent.limit(3).to_a
    recent_posts = Post.published.recent.limit(6).to_a
    categories = Term.for_taxonomy('category').limit(10).to_a
    
    context = {
      'featured_posts' => featured_posts,
      'recent_posts' => recent_posts,
      'posts' => recent_posts,  # Add posts for Nordic theme
      'collections' => {
        'posts' => recent_posts  # Add collections.posts for Nordic theme
      },
      'categories' => categories,
      'template' => 'index',
      'page' => {
        'title' => SiteSetting.get('site_title', 'RailsPress'),
        'seo_title' => SiteSetting.get('site_title', 'RailsPress'),
        'url' => request.url,
        'featured_image' => nil
      },
      'site' => {
        'title' => SiteSetting.get('site_title', 'RailsPress'),
        'description' => SiteSetting.get('site_description', 'Built with RailsPress'),
        'settings' => {
          'comments_enabled' => SiteSetting.get('comments_enabled', true),
          'comments_moderation' => SiteSetting.get('comments_moderation', true),
          'comment_registration_required' => SiteSetting.get('comment_registration_required', false),
          'close_comments_after_days' => SiteSetting.get('close_comments_after_days', 0),
          'show_avatars' => SiteSetting.get('show_avatars', true),
          'akismet_enabled' => SiteSetting.get('akismet_enabled', false),
          'akismet_api_key' => SiteSetting.get('akismet_api_key', '')
        }
      },
      'request' => {
        'url' => request.url,
        'params' => request.params
      },
      'current_user' => user_signed_in? ? current_user : nil
    }
    
    
    # Use FrontendRendererService for proper rendering
    renderer = FrontendRendererService.new(published_version)
    
    begin
      # Check if user is logged in for admin bar
      show_admin_bar = user_signed_in?
      
      # Add admin bar to context if user is logged in
      if show_admin_bar
        context['show_admin_bar'] = true
        context['current_user'] = current_user
      end
      
      # Use FrontendRendererService to render the complete page
      html = renderer.render_template('index', context)
      assets = renderer.assets
      
      # Inject admin bar and assets into the rendered HTML
      if show_admin_bar
        # Add admin bar at the top
        admin_bar_html = render_to_string(partial: 'shared/admin_bar')
        
        # Add admin bar CSS
        admin_bar_css = <<~CSS
          <style>
            body { padding-top: 32px; } /* Make room for admin bar */
          </style>
        CSS
        
        # Inject admin bar CSS into head
        html = html.gsub(/<\/head>/i, "#{admin_bar_css}</head>")
        
        # Inject admin bar after opening body tag
        html = html.gsub(/<body[^>]*>/i) { |match| "#{match}\n#{admin_bar_html}" }
      end
      
      # Inject theme assets if not already present
      if assets[:css].present? && !html.include?('</style>')
        css_injection = "<style>#{assets[:css]}</style>"
        html = html.gsub(/<\/head>/i, "#{css_injection}</head>")
      end
      
      if assets[:js].present? && !html.include?('</script>')
        js_injection = "<script>#{assets[:js]}</script>"
        html = html.gsub(/<\/body>/i, "#{js_injection}</body>")
      end
      
      # Render the complete HTML directly
            render html: html.html_safe
    rescue => e
      Rails.logger.error "Homepage rendering failed: #{e.message}"
      render html: "<h1>Rendering Error: #{e.message}</h1>", status: :internal_server_error
    end
  end
end
