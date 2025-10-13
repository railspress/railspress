class HeadlessModeHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    
    # Check if headless mode is enabled
    headless_enabled = SiteSetting.get('headless_mode', false)
    
    if headless_enabled && is_frontend_route?(request)
      return render_headless_error(request)
    end
    
    @app.call(env)
  end

  private

  def is_frontend_route?(request)
    path = request.path
    
    # Exclude admin, API, auth, and asset routes
    return false if path.start_with?('/admin')
    return false if path.start_with?('/api')
    return false if path.start_with?('/auth')
    return false if path.start_with?('/themes')
    return false if path.start_with?('/graphql')
    return false if path.start_with?('/assets')
    return false if path.start_with?('/rails')
    return false if path.start_with?('/__')
    return false if path == '/up' # Health check
    return false if path == '/csp-violation-report'
    
    # These are frontend routes
    true
  end

  def render_headless_error(request)
    # Try to use theme's error.liquid template
    begin
      renderer = LiquidTemplateRenderer.new(SiteSetting.get('active_theme', 'nordic'))
      html = renderer.render('headless', {
        'site' => {
          'name' => SiteSetting.get('site_title', 'RailsPress')
        },
        'request_path' => request.path
      }, 'error')
    rescue
      # Fallback to simple HTML
      html = render_simple_headless_error(request)
    end

    [
      503,
      {
        'Content-Type' => 'text/html',
        'Content-Length' => html.bytesize.to_s
      },
      [html]
    ]
  end

  def render_simple_headless_error(request)
    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Headless Mode Enabled</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
            background: #f5f5f5;
            color: #333;
          }
          .container {
            max-width: 600px;
            padding: 40px;
            background: white;
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
          }
          h1 {
            font-size: 2.5rem;
            margin: 0 0 16px;
            color: #0E7C86;
          }
          p {
            font-size: 1.125rem;
            line-height: 1.6;
            margin: 16px 0;
            color: #666;
          }
          code {
            background: #f5f5f5;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: 'Monaco', 'Courier New', monospace;
          }
          .endpoints {
            margin: 24px 0;
            text-align: left;
            background: #f9f9f9;
            padding: 20px;
            border-radius: 8px;
          }
          .endpoints h3 {
            margin: 0 0 12px;
            font-size: 1.25rem;
          }
          .endpoints ul {
            list-style: none;
            padding: 0;
            margin: 0;
          }
          .endpoints li {
            padding: 8px 0;
            border-bottom: 1px solid #eee;
          }
          .endpoints li:last-child {
            border-bottom: none;
          }
          a {
            color: #0E7C86;
            text-decoration: none;
          }
          a:hover {
            text-decoration: underline;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🚀 Headless Mode</h1>
          <p>This RailsPress installation is running in <strong>Headless CMS mode</strong>.</p>
          <p>The frontend is disabled. Access your content via our powerful APIs:</p>
          
          <div class="endpoints">
            <h3>📡 Available APIs</h3>
            <ul>
              <li><strong>GraphQL:</strong> <code>POST #{request.base_url}/graphql</code></li>
              <li><strong>REST API:</strong> <code>#{request.base_url}/api/v1</code></li>
              <li><strong>GraphiQL Explorer:</strong> <a href="#{request.base_url}/graphiql">#{request.base_url}/graphiql</a></li>
            </ul>
          </div>
          
          <p style="margin-top: 32px;">
            <strong>Need to access the admin panel?</strong><br>
            <a href="#{request.base_url}/admin">Go to Admin Panel →</a>
          </p>
        </div>
      </body>
      </html>
    HTML
  end
end



