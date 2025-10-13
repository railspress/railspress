# Admin::FluentFormsController
# Admin interface for managing forms, entries, and settings

class Admin::FluentFormsController < Admin::BaseController
  before_action :set_form, only: [:edit, :update, :destroy, :duplicate, :toggle_status]
  before_action :set_plugin, only: [:index, :new, :create, :settings, :update_settings]
  
  # GET /admin/fluent-forms
  def index
    @forms = fetch_all_forms
    @stats = calculate_stats
  end
  
  # GET /admin/fluent-forms/new
  def new
    @form_templates = form_templates
  end
  
  # POST /admin/fluent-forms/create
  def create
    template_type = params[:template_type] || 'blank'
    
    form_data = {
      title: params[:title] || 'Untitled Form',
      form_fields: get_template_fields(template_type).to_json,
      settings: default_form_settings.to_json,
      appearance_settings: default_appearance_settings.to_json,
      status: 'draft',
      form_type: 'form',
      has_payment: false,
      conditions: {}.to_json,
      created_by: current_user.id
    }
    
    ActiveRecord::Base.connection.execute(
      "INSERT INTO ff_forms (title, form_fields, settings, appearance_settings, status, form_type, 
       has_payment, conditions, created_by, created_at, updated_at) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
      form_data[:title],
      form_data[:form_fields],
      form_data[:settings],
      form_data[:appearance_settings],
      form_data[:status],
      form_data[:form_type],
      form_data[:has_payment],
      form_data[:conditions],
      form_data[:created_by],
      Time.current,
      Time.current
    )
    
    form_id = ActiveRecord::Base.connection.last_inserted_row_id
    
    redirect_to edit_admin_fluent_form_path(form_id), notice: 'Form created successfully!'
  rescue => e
    Rails.logger.error "[Fluent Forms Admin] Create error: #{e.message}"
    redirect_to admin_fluent_forms_path, alert: 'Failed to create form'
  end
  
  # GET /admin/fluent-forms/:id/edit
  def edit
    @form = @form_data
    @field_types = field_types
    @integrations = available_integrations
  end
  
  # PATCH /admin/fluent-forms/:id
  def update
    update_params = {
      title: params[:title],
      form_fields: params[:form_fields],
      settings: params[:settings],
      appearance_settings: params[:appearance_settings],
      status: params[:status],
      has_payment: params[:has_payment],
      conditions: params[:conditions]
    }
    
    sql_parts = []
    sql_values = []
    
    update_params.each do |key, value|
      next if value.nil?
      sql_parts << "#{key} = ?"
      sql_values << value
    end
    
    sql_values << Time.current
    sql_parts << "updated_at = ?"
    
    sql_values << params[:id]
    
    ActiveRecord::Base.connection.execute(
      "UPDATE ff_forms SET #{sql_parts.join(', ')} WHERE id = ?",
      *sql_values
    )
    
    if request.xhr?
      render json: { success: true, message: 'Form updated successfully!' }
    else
      redirect_to edit_admin_fluent_form_path(params[:id]), notice: 'Form updated successfully!'
    end
  rescue => e
    Rails.logger.error "[Fluent Forms Admin] Update error: #{e.message}"
    
    if request.xhr?
      render json: { success: false, message: 'Failed to update form' }, status: 422
    else
      redirect_to edit_admin_fluent_form_path(params[:id]), alert: 'Failed to update form'
    end
  end
  
  # DELETE /admin/fluent-forms/:id
  def destroy
    ActiveRecord::Base.connection.execute("DELETE FROM ff_forms WHERE id = ?", params[:id])
    
    redirect_to admin_fluent_forms_path, notice: 'Form deleted successfully!'
  rescue => e
    Rails.logger.error "[Fluent Forms Admin] Delete error: #{e.message}"
    redirect_to admin_fluent_forms_path, alert: 'Failed to delete form'
  end
  
  # POST /admin/fluent-forms/:id/duplicate
  def duplicate
    new_title = "#{@form_data[:title]} (Copy)"
    
    ActiveRecord::Base.connection.execute(
      "INSERT INTO ff_forms (title, form_fields, settings, appearance_settings, status, form_type, 
       has_payment, conditions, created_by, created_at, updated_at) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
      new_title,
      @form_data[:form_fields].to_json,
      @form_data[:settings].to_json,
      @form_data[:appearance_settings].to_json,
      'draft',
      @form_data[:form_type],
      @form_data[:has_payment],
      @form_data[:conditions].to_json,
      current_user.id,
      Time.current,
      Time.current
    )
    
    redirect_to admin_fluent_forms_path, notice: 'Form duplicated successfully!'
  rescue => e
    Rails.logger.error "[Fluent Forms Admin] Duplicate error: #{e.message}"
    redirect_to admin_fluent_forms_path, alert: 'Failed to duplicate form'
  end
  
  # POST /admin/fluent-forms/:id/toggle-status
  def toggle_status
    new_status = @form_data[:status] == 'published' ? 'draft' : 'published'
    
    ActiveRecord::Base.connection.execute(
      "UPDATE ff_forms SET status = ?, updated_at = ? WHERE id = ?",
      new_status,
      Time.current,
      params[:id]
    )
    
    render json: { success: true, status: new_status }
  rescue => e
    render json: { success: false, message: e.message }, status: 422
  end
  
  # GET /admin/fluent-forms/entries
  def entries
    @form_id = params[:form_id]
    @entries = fetch_entries(@form_id)
    @forms = fetch_all_forms
    @filters = {
      status: params[:status],
      date_range: params[:date_range],
      search: params[:search]
    }
  end
  
  # GET /admin/fluent-forms/entries/:id
  def entry_details
    @entry = fetch_entry_details(params[:id])
    @form = fetch_form(@entry[:form_id])
  end
  
  # POST /admin/fluent-forms/entries/:id/mark-read
  def mark_entry_read
    update_entry_status(params[:id], 'read')
    render json: { success: true }
  end
  
  # POST /admin/fluent-forms/entries/:id/favorite
  def toggle_favorite
    entry = fetch_entry_details(params[:id])
    new_favorite = !entry[:is_favorite]
    
    ActiveRecord::Base.connection.execute(
      "UPDATE ff_submissions SET is_favorite = ?, updated_at = ? WHERE id = ?",
      new_favorite,
      Time.current,
      params[:id]
    )
    
    render json: { success: true, is_favorite: new_favorite }
  end
  
  # DELETE /admin/fluent-forms/entries/:id
  def delete_entry
    ActiveRecord::Base.connection.execute("DELETE FROM ff_submissions WHERE id = ?", params[:id])
    redirect_to admin_fluent_forms_entries_path, notice: 'Entry deleted successfully!'
  end
  
  # GET /admin/fluent-forms/entries/export
  def export_entries
    form_id = params[:form_id]
    format = params[:format] || 'csv'
    
    entries = fetch_entries(form_id, limit: nil)
    
    case format
    when 'csv'
      send_data generate_csv(entries), filename: "entries-#{form_id}-#{Time.current.to_i}.csv"
    when 'json'
      send_data entries.to_json, filename: "entries-#{form_id}-#{Time.current.to_i}.json"
    else
      redirect_to admin_fluent_forms_entries_path, alert: 'Invalid export format'
    end
  end
  
  # GET /admin/fluent-forms/analytics
  def analytics
    @form_id = params[:form_id]
    @date_range = params[:date_range] || '30_days'
    @analytics_data = calculate_analytics(@form_id, @date_range)
    @forms = fetch_all_forms
  end
  
  # GET /admin/fluent-forms/integrations
  def integrations
    @integrations = available_integrations
    @active_integrations = get_active_integrations
  end
  
  # POST /admin/fluent-forms/integrations/:integration/toggle
  def toggle_integration
    integration_name = params[:integration]
    # Toggle integration logic here
    render json: { success: true }
  end
  
  # GET /admin/fluent-forms/settings
  def settings
    @settings = @plugin.get_all_settings
    @tabs = ['general', 'email', 'payments', 'spam_protection', 'file_uploads', 'integrations']
  end
  
  # PATCH /admin/fluent-forms/settings
  def update_settings
    settings_params = params.require(:settings).permit!
    
    settings_params.each do |key, value|
      @plugin.set_setting(key, value)
    end
    
    redirect_to admin_fluent_forms_settings_path, notice: 'Settings updated successfully!'
  rescue => e
    Rails.logger.error "[Fluent Forms Admin] Settings update error: #{e.message}"
    redirect_to admin_fluent_forms_settings_path, alert: 'Failed to update settings'
  end
  
  private
  
  def set_form
    @form_data = fetch_form(params[:id])
    redirect_to admin_fluent_forms_path, alert: 'Form not found' unless @form_data
  end
  
  def set_plugin
    @plugin = FluentFormsPro.new
  end
  
  def fetch_all_forms
    results = ActiveRecord::Base.connection.execute("SELECT * FROM ff_forms ORDER BY created_at DESC")
    results.map do |row|
      {
        id: row[0],
        title: row[1],
        status: row[4],
        form_type: row[6],
        has_payment: row[7],
        created_at: row[10],
        updated_at: row[11],
        submission_count: count_submissions(row[0])
      }
    end
  rescue => e
    Rails.logger.error "[Fluent Forms Admin] Fetch forms error: #{e.message}"
    []
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
      form_fields: JSON.parse(result[2] || '{}'),
      settings: JSON.parse(result[3] || '{}'),
      status: result[4],
      appearance_settings: result[5] ? JSON.parse(result[5]) : {},
      form_type: result[6],
      has_payment: result[7],
      conditions: result[8] ? JSON.parse(result[8]) : {},
      created_at: result[10],
      updated_at: result[11]
    }
  rescue => e
    Rails.logger.error "[Fluent Forms Admin] Fetch form error: #{e.message}"
    nil
  end
  
  def fetch_entries(form_id, options = {})
    limit = options[:limit] || 50
    
    query = if form_id
      "SELECT * FROM ff_submissions WHERE form_id = ? ORDER BY created_at DESC"
    else
      "SELECT * FROM ff_submissions ORDER BY created_at DESC"
    end
    
    query += " LIMIT #{limit}" if limit
    
    results = if form_id
      ActiveRecord::Base.connection.execute(query, form_id)
    else
      ActiveRecord::Base.connection.execute(query)
    end
    
    results.map do |row|
      {
        id: row[0],
        form_id: row[1],
        serial_number: row[2],
        response_data: JSON.parse(row[3] || '{}'),
        source_url: row[4],
        user_id: row[5],
        status: row[12],
        is_favorite: row[13],
        created_at: row[14]
      }
    end
  rescue => e
    Rails.logger.error "[Fluent Forms Admin] Fetch entries error: #{e.message}"
    []
  end
  
  def fetch_entry_details(entry_id)
    result = ActiveRecord::Base.connection.execute(
      "SELECT * FROM ff_submissions WHERE id = ? LIMIT 1",
      entry_id
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
      city: result[9],
      country: result[10],
      payment_status: result[11],
      status: result[12],
      is_favorite: result[13],
      created_at: result[14],
      updated_at: result[15]
    }
  end
  
  def count_submissions(form_id)
    result = ActiveRecord::Base.connection.execute(
      "SELECT COUNT(*) FROM ff_submissions WHERE form_id = ?",
      form_id
    ).first
    
    result.first
  rescue
    0
  end
  
  def update_entry_status(entry_id, status)
    ActiveRecord::Base.connection.execute(
      "UPDATE ff_submissions SET status = ?, updated_at = ? WHERE id = ?",
      status,
      Time.current,
      entry_id
    )
  end
  
  def calculate_stats
    {
      total_forms: ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM ff_forms").first.first,
      total_submissions: ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM ff_submissions").first.first,
      unread_submissions: ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM ff_submissions WHERE status = 'unread'").first.first,
      forms_with_payments: ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM ff_forms WHERE has_payment = 1").first.first
    }
  rescue
    { total_forms: 0, total_submissions: 0, unread_submissions: 0, forms_with_payments: 0 }
  end
  
  def calculate_analytics(form_id, date_range)
    # Analytics calculation logic
    {
      views: rand(100..1000),
      submissions: count_submissions(form_id),
      conversion_rate: rand(10..50),
      average_completion_time: rand(30..180)
    }
  end
  
  def generate_csv(entries)
    require 'csv'
    
    CSV.generate do |csv|
      # Header row
      if entries.any?
        headers = ['ID', 'Serial Number', 'Status', 'Created At']
        headers += entries.first[:response_data].keys
        csv << headers
        
        # Data rows
        entries.each do |entry|
          row = [
            entry[:id],
            entry[:serial_number],
            entry[:status],
            entry[:created_at]
          ]
          row += entry[:response_data].values
          csv << row
        end
      end
    end
  end
  
  def form_templates
    [
      { id: 'blank', name: 'Blank Form', description: 'Start from scratch' },
      { id: 'contact', name: 'Contact Form', description: 'Simple contact form with name, email, and message' },
      { id: 'registration', name: 'Registration Form', description: 'User registration with multiple fields' },
      { id: 'survey', name: 'Survey Form', description: 'Survey with multiple choice questions' },
      { id: 'order', name: 'Order Form', description: 'Product order form with payment' },
      { id: 'booking', name: 'Booking Form', description: 'Appointment booking form' },
      { id: 'feedback', name: 'Feedback Form', description: 'Customer feedback form' },
      { id: 'application', name: 'Application Form', description: 'Job or program application' },
      { id: 'newsletter', name: 'Newsletter Signup', description: 'Simple email capture form' },
      { id: 'quiz', name: 'Quiz Form', description: 'Quiz with scoring' }
    ]
  end
  
  def get_template_fields(template_type)
    case template_type
    when 'contact'
      contact_form_template
    when 'registration'
      registration_form_template
    when 'survey'
      survey_form_template
    else
      blank_form_template
    end
  end
  
  def blank_form_template
    {
      fields: [],
      submitButton: default_submit_button
    }
  end
  
  def contact_form_template
    {
      fields: [
        text_field('name', 'Name', true),
        email_field('email', 'Email', true),
        textarea_field('message', 'Message', true)
      ],
      submitButton: default_submit_button
    }
  end
  
  def registration_form_template
    {
      fields: [
        text_field('first_name', 'First Name', true),
        text_field('last_name', 'Last Name', true),
        email_field('email', 'Email', true),
        text_field('phone', 'Phone Number', false),
        textarea_field('address', 'Address', false)
      ],
      submitButton: default_submit_button
    }
  end
  
  def survey_form_template
    {
      fields: [
        text_field('name', 'Your Name', true),
        radio_field('satisfaction', 'How satisfied are you?', ['Very Satisfied', 'Satisfied', 'Neutral', 'Dissatisfied'], true),
        textarea_field('comments', 'Additional Comments', false)
      ],
      submitButton: default_submit_button
    }
  end
  
  def text_field(name, label, required)
    {
      index: rand(1000),
      element: 'input_text',
      attributes: { name: name, 'data-required': required, 'data-type': 'text' },
      settings: {
        label: label,
        label_placement: 'top',
        admin_field_label: label,
        validation_rules: required ? { required: { value: true, message: "#{label} is required" } } : {}
      }
    }
  end
  
  def email_field(name, label, required)
    {
      index: rand(1000),
      element: 'input_email',
      attributes: { name: name, 'data-required': required, 'data-type': 'email' },
      settings: {
        label: label,
        label_placement: 'top',
        admin_field_label: label,
        validation_rules: {
          required: { value: true, message: "#{label} is required" },
          email: { value: true, message: 'Please enter a valid email' }
        }
      }
    }
  end
  
  def textarea_field(name, label, required)
    {
      index: rand(1000),
      element: 'textarea',
      attributes: { name: name, 'data-required': required, 'data-type': 'text', rows: 4 },
      settings: {
        label: label,
        label_placement: 'top',
        admin_field_label: label,
        validation_rules: required ? { required: { value: true, message: "#{label} is required" } } : {}
      }
    }
  end
  
  def radio_field(name, label, options, required)
    {
      index: rand(1000),
      element: 'input_radio',
      attributes: { name: name, 'data-required': required, 'data-type': 'radio' },
      settings: {
        label: label,
        label_placement: 'top',
        admin_field_label: label,
        options: options.map { |opt| { label: opt, value: opt.parameterize } },
        validation_rules: required ? { required: { value: true, message: "#{label} is required" } } : {}
      }
    }
  end
  
  def default_submit_button
    {
      uniqElKey: 'el_submit',
      element: 'button',
      attributes: { type: 'submit', class: 'ff-btn ff-btn-submit ff-btn-md' },
      settings: {
        align: 'left',
        button_style: 'default',
        button_size: 'md',
        background_color: '#409EFF',
        color: '#ffffff',
        button_ui: { type: 'default', text: 'Submit', img_url: '' }
      }
    }
  end
  
  def default_form_settings
    {
      confirmation: {
        redirectTo: 'samePage',
        messageToShow: 'Thank you for your submission!',
        samePageFormBehavior: 'hide_form'
      },
      restrictions: {},
      layout: {
        labelPlacement: 'top',
        helpMessagePlacement: 'with_label',
        errorMessagePlacement: 'inline'
      }
    }
  end
  
  def default_appearance_settings
    {
      theme: 'default',
      customCss: '',
      submitButtonPosition: 'left'
    }
  end
  
  def field_types
    [
      { type: 'input_text', label: 'Text Input', icon: 'text' },
      { type: 'input_email', label: 'Email', icon: 'envelope' },
      { type: 'input_number', label: 'Number', icon: 'hashtag' },
      { type: 'input_phone', label: 'Phone', icon: 'phone' },
      { type: 'textarea', label: 'Textarea', icon: 'align-left' },
      { type: 'select', label: 'Dropdown', icon: 'caret-down' },
      { type: 'input_radio', label: 'Radio Button', icon: 'dot-circle' },
      { type: 'input_checkbox', label: 'Checkbox', icon: 'check-square' },
      { type: 'input_date', label: 'Date', icon: 'calendar' },
      { type: 'input_file', label: 'File Upload', icon: 'upload' },
      { type: 'input_hidden', label: 'Hidden Field', icon: 'eye-slash' },
      { type: 'input_password', label: 'Password', icon: 'lock' },
      { type: 'input_url', label: 'Website URL', icon: 'link' },
      { type: 'rating', label: 'Rating', icon: 'star' },
      { type: 'slider', label: 'Slider', icon: 'sliders-h' },
      { type: 'repeater', label: 'Repeater', icon: 'redo' },
      { type: 'step', label: 'Step', icon: 'shoe-prints' },
      { type: 'html', label: 'HTML', icon: 'code' },
      { type: 'section_break', label: 'Section Break', icon: 'minus' },
      { type: 'payment', label: 'Payment', icon: 'credit-card' }
    ]
  end
  
  def available_integrations
    [
      { id: 'mailchimp', name: 'Mailchimp', description: 'Email marketing', icon: 'mailchimp' },
      { id: 'slack', name: 'Slack', description: 'Team messaging', icon: 'slack' },
      { id: 'zapier', name: 'Zapier', description: 'Connect to 3000+ apps', icon: 'zapier' },
      { id: 'webhook', name: 'Webhooks', description: 'Custom webhooks', icon: 'link' },
      { id: 'google_sheets', name: 'Google Sheets', description: 'Spreadsheet integration', icon: 'table' },
      { id: 'stripe', name: 'Stripe', description: 'Payment processing', icon: 'stripe' },
      { id: 'paypal', name: 'PayPal', description: 'Payment processing', icon: 'paypal' }
    ]
  end
  
  def get_active_integrations
    # Return list of active integrations
    []
  end
end


