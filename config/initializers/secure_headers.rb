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
    script_src: %w('self' 'unsafe-inline' 'unsafe-eval' https://unpkg.com https://cdn.jsdelivr.net https://cdn.tailwindcss.com https://cdnjs.cloudflare.com),
    style_src: %w('self' 'unsafe-inline' https://unpkg.com https://cdn.jsdelivr.net https://cdnjs.cloudflare.com https://fonts.googleapis.com),
    img_src: %w('self' data: https:),
    font_src: %w('self' data: https://cdnjs.cloudflare.com https://fonts.gstatic.com),
    connect_src: %w('self' https://unpkg.com https://cdn.jsdelivr.net https://cdn.tailwindcss.com),
    frame_src: %w('self' https://www.youtube.com https://player.vimeo.com),
    report_uri: %w(/csp-violation-report)
  }
end

