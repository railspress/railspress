class EmailLoggingInterceptor
  def self.delivering_email(message)
    return unless ActiveRecord::Base.connection.table_exists?('email_logs')
    return unless ActiveRecord::Base.connection.table_exists?('site_settings')
    
    # Only log if logging is enabled
    return unless SiteSetting.get('email_logging_enabled', true)
    
    provider = SiteSetting.get('email_provider', 'smtp')
    
    # Log the email
    EmailLog.log_email(
      from: extract_email(message.from),
      to: extract_email(message.to),
      subject: message.subject,
      body: message.body&.raw_source || message.body.to_s,
      provider: provider,
      status: 'pending',
      metadata: {
        cc: message.cc,
        bcc: message.bcc,
        reply_to: message.reply_to,
        message_id: message.message_id,
        content_type: message.content_type
      }
    )
  rescue => e
    Rails.logger.error "Failed to log email: #{e.message}"
  end

  def self.extract_email(email_field)
    return nil if email_field.nil?
    
    if email_field.is_a?(Array)
      email_field.first.to_s
    else
      email_field.to_s
    end
  end
end

