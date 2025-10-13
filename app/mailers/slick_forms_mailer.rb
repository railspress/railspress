# FluentFormsMailer
# Handles email notifications for form submissions

class FluentFormsMailer < ApplicationMailer
  default from: -> { default_from_email }
  
  # Admin notification email
  def admin_notification(to:, subject:, form:, submission:)
    @form = form
    @submission = submission
    @subject = subject
    
    mail(
      to: to,
      subject: subject,
      template_path: 'fluent_forms_mailer',
      template_name: 'admin_notification'
    )
  end
  
  # User notification email (autoresponder)
  def user_notification(to:, subject:, message:, form:, submission:)
    @form = form
    @submission = submission
    @message = message
    @subject = subject
    
    mail(
      to: to,
      subject: subject,
      template_path: 'fluent_forms_mailer',
      template_name: 'user_notification'
    )
  end
  
  private
  
  def default_from_email
    plugin = FluentFormsPro.new
    from_email = plugin.get_setting('default_from_email')
    from_name = plugin.get_setting('default_from_name')
    
    if from_name.present?
      "#{from_name} <#{from_email}>"
    else
      from_email || 'noreply@example.com'
    end
  end
end

