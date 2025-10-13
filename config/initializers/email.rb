# Email Configuration Initializer

Rails.application.config.after_initialize do
  begin
    # Register email logging interceptor
    ActionMailer::Base.register_interceptor(EmailLoggingInterceptor)
    
    # Configure action mailer based on settings
    configure_email_delivery
  rescue => e
    Rails.logger.warn "Email configuration initialization failed: #{e.message}"
  end
end

def configure_email_delivery
  return unless ActiveRecord::Base.connection.table_exists?('site_settings')
  
  provider = SiteSetting.get('email_provider', 'smtp')
  
  if provider == 'smtp'
    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.smtp_settings = {
      address: SiteSetting.get('smtp_host', 'smtp.gmail.com'),
      port: SiteSetting.get('smtp_port', 587).to_i,
      domain: SiteSetting.get('site_url', 'localhost'),
      user_name: SiteSetting.get('smtp_username', ''),
      password: SiteSetting.get('smtp_password', ''),
      authentication: 'plain',
      enable_starttls_auto: SiteSetting.get('smtp_encryption', 'tls') == 'tls',
      open_timeout: SiteSetting.get('smtp_timeout', 10).to_i,
      read_timeout: SiteSetting.get('smtp_timeout', 10).to_i
    }
  elsif provider == 'resend'
    # Configure Resend
    resend_api_key = SiteSetting.get('resend_api_key', '')
    
    if resend_api_key.present?
      Resend.api_key = resend_api_key
      ActionMailer::Base.add_delivery_method :resend, Resend::Rails::Mailer
      ActionMailer::Base.delivery_method = :resend
    end
  end
rescue => e
  Rails.logger.warn "Email configuration failed: #{e.message}"
end

# Set default from address
ActionMailer::Base.default from: -> {
  begin
    if ActiveRecord::Base.connection.table_exists?('site_settings')
      email = SiteSetting.get('default_from_email', 'noreply@railspress.com')
      name = SiteSetting.get('default_from_name', 'RailsPress')
      "#{name} <#{email}>"
    else
      'RailsPress <noreply@railspress.com>'
    end
  rescue
    'RailsPress <noreply@railspress.com>'
  end
}

