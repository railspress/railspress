# Rack::Attack configuration for rate limiting and security

class Rack::Attack
  # Throttle all requests by IP
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?('/assets')
  end

  # Throttle API requests
  throttle('api/ip', limit: 100, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/api/')
  end

  # Throttle login attempts (frontend)
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/auth/sign_in' && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email (frontend)
  throttle('logins/email', limit: 5, period: 20.seconds) do |req|
    if req.path == '/auth/sign_in' && req.post?
      req.params['email'].to_s.downcase.gsub(/\s+/, "").presence
    end
  end

  # Throttle admin login attempts
  throttle('admin_logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/admin/sign_in' && req.post?
      req.ip
    end
  end

  # Throttle admin login attempts by email
  throttle('admin_logins/email', limit: 5, period: 20.seconds) do |req|
    if req.path == '/admin/sign_in' && req.post?
      req.params['email'].to_s.downcase.gsub(/\s+/, "").presence
    end
  end

  # Block suspicious requests
  blocklist('block suspicious IPs') do |req|
    # Example: Block specific IPs
    # ['1.2.3.4', '5.6.7.8'].include?(req.ip)
    false
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |env|
    [
      429,
      {'Content-Type' => 'application/json'},
      [{ error: 'Rate limit exceeded. Please try again later.' }.to_json]
    ]
  end
end




