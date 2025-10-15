# Secure Headers configuration

SecureHeaders::Configuration.default do |config|
  config.x_frame_options = "SAMEORIGIN"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "0" # Deprecated, rely on CSP instead
  config.x_download_options = "noopen"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = %w(origin-when-cross-origin strict-origin-when-cross-origin)
  
  # Content Security Policy
  config.csp = {
    default_src: %w('self'),
    script_src: %w('self' 'unsafe-inline' 'unsafe-eval' http://localhost:3000 https://unpkg.com https://cdn.jsdelivr.net https://cdn.tailwindcss.com https://cdnjs.cloudflare.com blob:),
    style_src: %w('self' 'unsafe-inline' http://localhost:3000 https://unpkg.com https://cdn.jsdelivr.net https://cdnjs.cloudflare.com https://fonts.googleapis.com),
    img_src: %w('self' data: https:),
    font_src: %w('self' data: https://cdnjs.cloudflare.com https://fonts.gstatic.com https://cdn.jsdelivr.net),
    connect_src: %w('self' ws: wss: http://localhost:3000 https://unpkg.com https://cdn.jsdelivr.net https://cdn.tailwindcss.com),
    frame_src: %w('self' https://www.youtube.com https://player.vimeo.com),
    worker_src: %w('self' blob:),
    report_uri: %w(/csp-violation-report)
  }
end

