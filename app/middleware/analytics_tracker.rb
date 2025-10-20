class AnalyticsTracker
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)
    
    # Track pageview after response (non-blocking)
    track_pageview(env, status) if should_track?(env, status)
    
    [status, headers, response]
  end

  private

  def should_track?(env, status)
    request = Rack::Request.new(env)
    
    # Track successful GET and POST requests (for form submissions, etc.)
    return false unless (request.get? || request.post?) && status == 200
    
    # Skip admin, API, assets
    return false if skip_path?(request.path)
    
    # Skip if tracking disabled
    return false unless tracking_enabled?
    
    # Track everything else
    true
  end

  def skip_path?(path)
    skip_patterns = [
      /^\/admin/,
      /^\/api/,
      /^\/assets/,
      /^\/packs/,
      /^\/uploads/,
      /^\/rails/,
      /^\/cable/,
      /^\/up$/,
      /^\/analytics\/track/,  # Our own tracking endpoint
      /\.json$/,
      /\.xml$/,
      /\.js$/,
      /\.css$/,
      /\.png$/,
      /\.jpg$/,
      /\.gif$/,
      /\.ico$/
    ]
    
    skip_patterns.any? { |pattern| path.match?(pattern) }
  end

  def tracking_enabled?
    # Check if analytics is enabled in settings
    SiteSetting.get('analytics_enabled', 'true') == 'true'
  rescue
    true  # Default to enabled
  end
  
  def consent_required?
    SiteSetting.get('analytics_require_consent', 'true') == 'true'
  rescue
    true
  end
  
  def anonymize_ip?
    SiteSetting.get('analytics_anonymize_ip', 'true') == 'true'
  rescue
    true
  end
  
  def track_bots?
    SiteSetting.get('analytics_track_bots', 'false') == 'true'
  rescue
    false
  end

  def track_pageview(env, status)
    request = Rack::Request.new(env)
    
    # Skip if consent is required but not given
    if consent_required? && !check_consent(request)
      return
    end
    
    # Background job for tracking (non-blocking)
    # For now, track synchronously but could use Sidekiq
    Thread.new do
      begin
        Pageview.track(request, {
          title: extract_title(env),
          user_id: extract_user_id(env),
          session_id: extract_session_id(request),
          consented: check_consent(request) || !consent_required?,
          track_bots: track_bots?,
          anonymize_ip: anonymize_ip?
        })
      rescue => e
        Rails.logger.error "Analytics tracking error: #{e.message}"
      end
    end
  end

  def extract_title(env)
    # Try to extract page title from response
    # This is a simplified version
    nil
  end

  def extract_user_id(env)
    # Try to get current user from session
    session = env['rack.session']
    session['warden.user.user.key']&.first&.first
  rescue
    nil
  end

  def extract_session_id(request)
    # Use cookie-based session or generate new one
    request.cookies['_railspress_session_id'] ||
      Digest::SHA256.hexdigest("#{request.ip}-#{request.user_agent}-#{Date.today}")[0..31]
  end

  def check_consent(request)
    # Check if user has given analytics consent
    # Could be from cookie or session
    request.cookies['analytics_consent'] == 'true'
  end
end








