# SlickForms Public Submissions Controller
# Handles public form submissions

class Plugins::SlickForms::SubmissionsController < ApplicationController
  protect_from_forgery with: :null_session
  
  def create
    form_id = params[:form_id]
    form_data = submission_params
    
    # Get the form to validate
    @form = get_form_by_id(form_id)
    
    unless @form
      render json: { error: 'Form not found' }, status: :not_found
      return
    end
    
    # Process the submission
    if process_submission(form_id, form_data)
      render json: { 
        success: true, 
        message: 'Thank you for your submission!',
        redirect_url: @form[:settings]['success_redirect_url']
      }
    else
      render json: { 
        success: false, 
        error: 'Failed to process submission'
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def submission_params
    params.except(:controller, :action, :form_id).permit!
  end
  
  def get_form_by_id(id)
    return nil unless table_exists?('slick_forms')
    result = ActiveRecord::Base.connection.execute(
      "SELECT * FROM slick_forms WHERE id = #{id} AND active = 1"
    ).first
    result&.symbolize_keys
  end
  
  def process_submission(form_id, data)
    # Get the plugin instance to use its processing logic
    plugin = Railspress::PluginSystem.get_plugin('slick_forms')
    
    if plugin
      # Use plugin's spam protection and validation
      return false if plugin.send(:detect_spam, data)
      return false unless plugin.send(:validate_unique_entries, data)
    end
    
    # Save submission to database
    save_submission(form_id, data)
    
    # Send email notification if configured
    send_notification(form_id, data) if should_send_notification?
    
    true
  rescue => e
    Rails.logger.error "Failed to process submission: #{e.message}"
    false
  end
  
  def save_submission(form_id, data)
    return false unless table_exists?('slick_form_submissions')
    
    ActiveRecord::Base.connection.execute(
      "INSERT INTO slick_form_submissions (slick_form_id, data, ip_address, user_agent, referrer, spam, created_at, updated_at) VALUES (#{form_id}, '#{data.to_json}', '#{request.remote_ip}', '#{request.user_agent}', '#{request.referer}', 0, NOW(), NOW())"
    )
    
    # Update form submission count
    ActiveRecord::Base.connection.execute(
      "UPDATE slick_forms SET submissions_count = submissions_count + 1 WHERE id = #{form_id}"
    ) if table_exists?('slick_forms')
    
    true
  end
  
  def send_notification(form_id, data)
    # This would integrate with the plugin's notification system
    Rails.logger.info "Sending notification for form #{form_id}"
  end
  
  def should_send_notification?
    # Check plugin settings for email notifications
    plugin = Railspress::PluginSystem.get_plugin('slick_forms')
    return false unless plugin
    
    plugin.get_setting(:enable_notifications, true)
  end
  
  def table_exists?(table_name)
    ActiveRecord::Base.connection.table_exists?(table_name)
  end
end
