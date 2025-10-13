# FluentFormsNotificationJob
# Sends email notifications when forms are submitted

class FluentFormsNotificationJob < ApplicationJob
  queue_as :default
  
  def perform(submission_id)
    @submission = fetch_submission(submission_id)
    return unless @submission
    
    @form = fetch_form(@submission[:form_id])
    return unless @form
    
    # Send admin notification
    send_admin_notification if admin_notification_enabled?
    
    # Send user notification (autoresponder)
    send_user_notification if user_notification_enabled?
    
    # Log notification
    log_notification(submission_id, 'Notifications sent successfully')
    
  rescue => e
    Rails.logger.error "[Fluent Forms] Notification error: #{e.message}"
    log_notification(submission_id, "Notification failed: #{e.message}")
  end
  
  private
  
  def fetch_submission(submission_id)
    result = ActiveRecord::Base.connection.execute(
      "SELECT * FROM ff_submissions WHERE id = ? LIMIT 1",
      submission_id
    ).first
    
    return nil unless result
    
    {
      id: result[0],
      form_id: result[1],
      serial_number: result[2],
      response_data: JSON.parse(result[3] || '{}'),
      source_url: result[4],
      user_id: result[5],
      browser: result[6],
      device: result[7],
      ip_address: result[8],
      created_at: result[14]
    }
  end
  
  def fetch_form(form_id)
    result = ActiveRecord::Base.connection.execute(
      "SELECT * FROM ff_forms WHERE id = ? LIMIT 1",
      form_id
    ).first
    
    return nil unless result
    
    {
      id: result[0],
      title: result[1],
      settings: JSON.parse(result[3] || '{}')
    }
  end
  
  def admin_notification_enabled?
    notifications = @form[:settings].dig(:notifications, :admin)
    notifications && notifications[:enabled]
  end
  
  def user_notification_enabled?
    notifications = @form[:settings].dig(:notifications, :user)
    notifications && notifications[:enabled]
  end
  
  def send_admin_notification
    plugin = FluentFormsPro.new
    
    admin_email = @form[:settings].dig(:notifications, :admin, :email) || 
                  plugin.get_setting('default_from_email')
    subject = @form[:settings].dig(:notifications, :admin, :subject) || 
              "New form submission: #{@form[:title]}"
    
    return unless admin_email.present?
    
    FluentFormsMailer.admin_notification(
      to: admin_email,
      subject: subject,
      form: @form,
      submission: @submission
    ).deliver_now
  end
  
  def send_user_notification
    plugin = FluentFormsPro.new
    
    # Find email field in submission
    user_email = find_email_in_submission
    return unless user_email.present?
    
    subject = @form[:settings].dig(:notifications, :user, :subject) || 
              "Thank you for your submission"
    message = @form[:settings].dig(:notifications, :user, :message) || 
              "We have received your submission."
    
    FluentFormsMailer.user_notification(
      to: user_email,
      subject: subject,
      message: message,
      form: @form,
      submission: @submission
    ).deliver_now
  end
  
  def find_email_in_submission
    @submission[:response_data].values.find { |v| v.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i) }
  end
  
  def log_notification(submission_id, message)
    ActiveRecord::Base.connection.execute(
      "INSERT INTO ff_logs (submission_id, form_id, log_type, title, description, created_at) 
       VALUES (?, ?, ?, ?, ?, ?)",
      submission_id,
      @submission[:form_id],
      'notification',
      'Email Notification',
      message,
      Time.current
    )
  rescue => e
    Rails.logger.error "[Fluent Forms] Log error: #{e.message}"
  end
end

