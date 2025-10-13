# Fluent Forms Controller
# Handles form submissions and frontend form rendering

class FluentFormsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:submit], if: -> { request.format.json? }
  before_action :set_form, only: [:show, :submit]
  
  # GET /fluent-forms/:id
  def show
    render plain: render_form(@form)
  end
  
  # POST /fluent-forms/submit
  def submit
    unless @form
      return respond_with_error('Form not found', 404)
    end
    
    # Check if form is active
    if @form[:status] != 'published'
      return respond_with_error('Form is not available', 403)
    end
    
    # Validate form data
    validation_result = validate_submission
    unless validation_result[:valid]
      return respond_with_error(validation_result[:errors].join(', '), 422)
    end
    
    # Check spam protection
    if spam_detected?
      log_spam_attempt
      return respond_with_success('Thank you for your submission!')
    end
    
    # Create submission
    submission_data = prepare_submission_data
    submission_id = FluentFormsPro.create_submission(
      @form[:id],
      submission_data,
      current_user&.id
    )
    
    if submission_id
      # Store entry details
      store_entry_details(submission_id)
      
      # Handle file uploads
      handle_file_uploads(submission_id) if has_file_uploads?
      
      # Process payment if required
      if @form[:has_payment]
        payment_result = process_payment(submission_id)
        return respond_with_error(payment_result[:error], 422) unless payment_result[:success]
      end
      
      respond_with_success(
        @form[:settings][:confirmation][:messageToShow] || 'Thank you for your submission!',
        submission_id
      )
    else
      respond_with_error('Failed to save submission', 500)
    end
  rescue => e
    Rails.logger.error "[Fluent Forms] Submission error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    respond_with_error('An error occurred while processing your submission', 500)
  end
  
  private
  
  def set_form
    form_id = params[:id] || params[:form_id]
    @form = get_form_data(form_id) if form_id
  end
  
  def get_form_data(form_id)
    plugin = FluentFormsPro.new
    plugin.get_form(form_id)
  end
  
  def render_form(form)
    FluentFormsRenderer.new(form).render
  end
  
  def validate_submission
    errors = []
    fields = @form[:form_fields][:fields] || []
    
    fields.each do |field|
      field_name = field.dig(:attributes, :name)
      next unless field_name
      
      validation_rules = field.dig(:settings, :validation_rules) || {}
      field_value = params[field_name]
      
      # Check required fields
      if validation_rules.dig(:required, :value)
        if field_value.blank?
          message = validation_rules.dig(:required, :message) || "#{field.dig(:settings, :label)} is required"
          errors << message
        end
      end
      
      # Email validation
      if validation_rules.dig(:email, :value) && field_value.present?
        unless valid_email?(field_value)
          message = validation_rules.dig(:email, :message) || 'Please enter a valid email'
          errors << message
        end
      end
      
      # Min/Max length
      if field_value.present?
        min_length = validation_rules.dig(:min_length, :value)
        max_length = validation_rules.dig(:max_length, :value)
        
        if min_length && field_value.length < min_length.to_i
          errors << validation_rules.dig(:min_length, :message) || "Minimum length is #{min_length}"
        end
        
        if max_length && field_value.length > max_length.to_i
          errors << validation_rules.dig(:max_length, :message) || "Maximum length is #{max_length}"
        end
      end
    end
    
    {
      valid: errors.empty?,
      errors: errors
    }
  end
  
  def valid_email?(email)
    email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
  end
  
  def spam_detected?
    plugin = FluentFormsPro.new
    
    # Honeypot check
    if plugin.setting_enabled?('honeypot_enabled')
      return true if params[:_ff_honeypot].present?
    end
    
    # reCAPTCHA check
    if plugin.setting_enabled?('recaptcha_enabled')
      recaptcha_token = params[:recaptcha_token]
      return true unless verify_recaptcha(recaptcha_token)
    end
    
    false
  end
  
  def verify_recaptcha(token)
    return true unless token
    
    plugin = FluentFormsPro.new
    secret_key = plugin.get_setting('recaptcha_secret_key')
    return true if secret_key.blank?
    
    # Verify with Google reCAPTCHA API
    uri = URI('https://www.google.com/recaptcha/api/siteverify')
    response = Net::HTTP.post_form(uri, {
      secret: secret_key,
      response: token,
      remoteip: request.remote_ip
    })
    
    result = JSON.parse(response.body)
    result['success'] == true
  rescue => e
    Rails.logger.error "[Fluent Forms] reCAPTCHA verification error: #{e.message}"
    true # Allow submission on verification error
  end
  
  def log_spam_attempt
    ActiveRecord::Base.connection.execute(
      "INSERT INTO ff_logs (form_id, log_type, title, description, created_at) 
       VALUES (?, ?, ?, ?, ?)",
      @form[:id],
      'spam',
      'Spam submission blocked',
      "IP: #{request.remote_ip}",
      Time.current
    )
  end
  
  def prepare_submission_data
    {
      response_data: collect_form_data,
      source_url: request.referrer || request.original_url,
      browser: request.user_agent,
      device: detect_device,
      ip_address: get_ip_address
    }
  end
  
  def collect_form_data
    data = {}
    fields = @form[:form_fields][:fields] || []
    
    fields.each do |field|
      field_name = field.dig(:attributes, :name)
      data[field_name] = params[field_name] if field_name && params.key?(field_name)
    end
    
    data
  end
  
  def detect_device
    user_agent = request.user_agent.to_s.downcase
    
    return 'mobile' if user_agent.include?('mobile')
    return 'tablet' if user_agent.include?('tablet') || user_agent.include?('ipad')
    'desktop'
  end
  
  def get_ip_address
    plugin = FluentFormsPro.new
    return nil if plugin.setting_enabled?('disable_ip_logging')
    
    request.remote_ip
  end
  
  def store_entry_details(submission_id)
    fields = @form[:form_fields][:fields] || []
    
    fields.each do |field|
      field_name = field.dig(:attributes, :name)
      next unless field_name && params.key?(field_name)
      
      ActiveRecord::Base.connection.execute(
        "INSERT INTO ff_entry_details (submission_id, form_id, field_name, field_value, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?)",
        submission_id,
        @form[:id],
        field_name,
        params[field_name].to_s,
        Time.current,
        Time.current
      )
    end
  end
  
  def has_file_uploads?
    params[:_files].present? || params.values.any? { |v| v.is_a?(ActionDispatch::Http::UploadedFile) }
  end
  
  def handle_file_uploads(submission_id)
    plugin = FluentFormsPro.new
    upload_folder = plugin.get_setting('upload_folder', 'form-uploads')
    max_size = plugin.get_setting('max_file_size', 10).to_i * 1024 * 1024 # Convert MB to bytes
    allowed_types = plugin.get_setting('allowed_file_types', '').split(',').map(&:strip)
    
    params.each do |key, value|
      next unless value.is_a?(ActionDispatch::Http::UploadedFile)
      
      # Validate file size
      if value.size > max_size
        next
      end
      
      # Validate file type
      extension = File.extname(value.original_filename).delete('.').downcase
      next unless allowed_types.include?(extension)
      
      # Save file
      upload_path = Rails.root.join('public', 'uploads', upload_folder, submission_id.to_s)
      FileUtils.mkdir_p(upload_path)
      
      filename = "#{Time.current.to_i}_#{value.original_filename}"
      filepath = upload_path.join(filename)
      
      File.open(filepath, 'wb') do |file|
        file.write(value.read)
      end
      
      # Update entry detail with file path
      file_url = "/uploads/#{upload_folder}/#{submission_id}/#{filename}"
      ActiveRecord::Base.connection.execute(
        "UPDATE ff_entry_details SET field_value = ? 
         WHERE submission_id = ? AND field_name = ?",
        file_url,
        submission_id,
        key
      )
    end
  rescue => e
    Rails.logger.error "[Fluent Forms] File upload error: #{e.message}"
  end
  
  def process_payment(submission_id)
    # Payment processing would be implemented here
    # Integrate with Stripe, PayPal, etc.
    {
      success: true,
      transaction_id: SecureRandom.hex(16)
    }
  end
  
  def respond_with_success(message, submission_id = nil)
    response = {
      success: true,
      message: message
    }
    response[:submission_id] = submission_id if submission_id
    
    if request.format.json?
      render json: response
    else
      flash[:success] = message
      redirect_back fallback_location: root_path
    end
  end
  
  def respond_with_error(message, status = 422)
    response = {
      success: false,
      message: message
    }
    
    if request.format.json?
      render json: response, status: status
    else
      flash[:error] = message
      redirect_back fallback_location: root_path
    end
  end
end


