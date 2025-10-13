class RedirectHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    
    # Skip redirect handling for:
    # - Admin requests
    # - API requests
    # - Asset requests
    # - Healthcheck requests
    return @app.call(env) if skip_redirect?(request)
    
    # Check for matching redirect
    redirect = find_redirect_for_path(request.path)
    
    if redirect
      # Record the hit
      redirect.record_hit! rescue nil
      
      # Get the destination
      destination = redirect.destination_for(request.path)
      
      # Preserve query string
      if request.query_string.present?
        destination += "?#{request.query_string}"
      end
      
      # Return redirect response
      status = redirect.http_status_code
      headers = {
        'Location' => destination,
        'Content-Type' => 'text/html',
        'Content-Length' => '0'
      }
      
      # Add cache headers for permanent redirects
      if redirect.permanent?
        headers['Cache-Control'] = 'max-age=31536000, public'
      else
        headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
      end
      
      body = ['']
      
      [status, headers, body]
    else
      # No redirect found, continue to app
      @app.call(env)
    end
  end

  private

  def skip_redirect?(request)
    path = request.path
    
    # Skip admin paths
    return true if path.start_with?('/admin')
    
    # Skip API paths
    return true if path.start_with?('/api')
    
    # Skip asset paths
    return true if path.start_with?('/assets', '/packs', '/uploads')
    
    # Skip Rails paths
    return true if path.start_with?('/rails')
    
    # Skip cable/action_cable
    return true if path.start_with?('/cable')
    
    # Skip healthcheck
    return true if path == '/up'
    
    # Skip if already redirecting (prevent loops)
    return true if request.env['HTTP_X_REDIRECTED'] == 'true'
    
    false
  end

  def find_redirect_for_path(path)
    # Normalize path
    path = path.chomp('/') if path.length > 1
    
    # Try to find exact match first
    redirect = Redirect.active.find_by(from_path: path)
    return redirect if redirect
    
    # Check for wildcard matches
    Redirect.active.each do |redirect|
      return redirect if redirect.matches?(path)
    end
    
    nil
  end
end





