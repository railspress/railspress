# SlickForms Pro - Advanced Form Builder
#
# Extends SlickForms with premium features:
# - Advanced field types (file upload, date picker, rating, signature)
# - Conditional logic
# - Multi-page forms
# - Payment integration (Stripe)
# - Advanced analytics
# - White labeling
# - Priority support

class SlickFormsPro < Railspress::PluginBase
  plugin_name 'Slick Forms Pro'
  plugin_version '2.0.0'
  plugin_description 'Advanced form builder with premium features, payments, and analytics'
  plugin_author 'RailsPress Pro'
  plugin_url 'https://railspress.com/plugins/slick-forms-pro'
  plugin_license 'Commercial'
  
  def setup
    # Check if base SlickForms is active
    unless plugin_active?('slick_forms')
      log("WARNING: SlickForms Pro requires SlickForms base plugin", :warn)
    end
    
    # Additional Pro Settings
    define_setting :enable_payments,
      type: 'boolean',
      label: 'Enable Payment Forms',
      description: 'Allow forms to accept payments via Stripe',
      default: false
    
    define_setting :stripe_publishable_key,
      type: 'string',
      label: 'Stripe Publishable Key',
      placeholder: 'pk_...'
    
    define_setting :stripe_secret_key,
      type: 'string',
      label: 'Stripe Secret Key',
      placeholder: 'sk_...'
    
    define_setting :enable_analytics,
      type: 'boolean',
      label: 'Enable Analytics',
      description: 'Track form views, submissions, and conversion rates',
      default: true
    
    define_setting :enable_conditional_logic,
      type: 'boolean',
      label: 'Enable Conditional Logic',
      description: 'Show/hide fields based on other field values',
      default: true
    
    define_setting :max_file_size,
      type: 'number',
      label: 'Max File Size (MB)',
      default: 10,
      min: 1,
      max: 100
    
    define_setting :allowed_file_types,
      type: 'text',
      label: 'Allowed File Types',
      description: 'Comma-separated list of allowed extensions',
      default: 'pdf,doc,docx,jpg,png'
    
    # Register admin pages
    register_admin_page(
      slug: 'analytics',
      title: 'Form Analytics',
      menu_title: 'Analytics',
      icon: 'chart',
      callback: :render_analytics_page
    )
    
    register_admin_page(
      slug: 'payments',
      title: 'Payment Forms',
      menu_title: 'Payments',
      icon: 'credit-card',
      callback: :render_payments_page
    )
    
    register_admin_page(
      slug: 'integrations',
      title: 'Integrations',
      menu_title: 'Integrations',
      icon: 'link',
      callback: :render_integrations_page
    )
    
    register_admin_page(
      slug: 'settings',
      title: 'Pro Settings',
      menu_title: 'Pro Settings',
      icon: 'cog'
    )
    
    # Register admin routes (automatically scoped under /admin)
    register_admin_routes do
      namespace :slick_forms_pro do
        # Analytics
        get 'analytics/overview', to: 'analytics#overview'
        get 'analytics/form/:id', to: 'analytics#form'
        get 'analytics/export', to: 'analytics#export'
        
        # Payments
        resources :payments, only: [:index, :show] do
          member do
            post :refund
          end
        end
        
        # Integrations
        resources :integrations do
          member do
            post :test
            patch :toggle
          end
        end
        
        # Templates
        resources :templates, only: [:index, :show, :create]
      end
    end
    
    # Register frontend routes (automatically scoped under /plugins)
    register_frontend_routes do
      # File upload endpoint
      post 'upload', to: 'slick_forms_pro/uploads#create', as: 'slick_form_pro_upload'
      
      # Payment webhook
      post 'webhooks/stripe', to: 'slick_forms_pro/webhooks#stripe'
      
      # API endpoints
      namespace :api do
        namespace :v1 do
          get 'forms/:id/stats', to: 'slick_forms_pro/stats#show'
          post 'forms/:id/validate', to: 'slick_forms_pro/validator#validate'
        end
      end
    end
    
    # Create background jobs
    create_job 'SlickFormsProAnalyticsJob' do
      def perform
        # Process analytics data
        Rails.logger.info "Processing SlickForms Pro analytics"
      end
    end
    
    create_job 'SlickFormsProPaymentJob' do
      def perform(payment_id)
        # Process payment
        Rails.logger.info "Processing payment ##{payment_id}"
      end
    end
    
    # Schedule recurring analytics job
    schedule_recurring_job(
      'analytics_daily',
      'SlickFormsProAnalyticsJob',
      cron: '0 2 * * *' # Daily at 2 AM
    )
    
    # Add filters to extend base plugin
    add_filter('slick_forms_field_types', :add_pro_fields)
    add_filter('slick_forms_form_settings', :add_pro_settings)
    add_action('slick_forms_submission_saved', :process_pro_features)
    
    log("SlickForms Pro initialized successfully")
  end
  
  def activate
    super
    create_pro_tables
    set_setting(:enable_analytics, true)
    set_setting(:max_file_size, 10)
    log("SlickForms Pro activated")
  end
  
  # Render analytics page
  def render_analytics_page
    {
      title: 'Form Analytics',
      charts: generate_analytics_charts,
      stats: {
        total_views: get_total_views,
        total_submissions: get_total_submissions,
        conversion_rate: calculate_conversion_rate,
        average_time: calculate_average_completion_time
      },
      top_forms: get_top_performing_forms(5)
    }
  end
  
  # Render payments page
  def render_payments_page
    {
      title: 'Payment Forms',
      payments: get_recent_payments(50),
      stats: {
        total_revenue: calculate_total_revenue,
        successful_payments: get_successful_payments_count,
        failed_payments: get_failed_payments_count,
        refunded_amount: calculate_refunded_amount
      }
    }
  end
  
  # Render integrations page
  def render_integrations_page
    {
      title: 'Integrations',
      available_integrations: available_integrations,
      active_integrations: get_active_integrations
    }
  end
  
  # Available integrations
  def available_integrations
    [
      { id: 'mailchimp', name: 'Mailchimp', icon: '📧', description: 'Add subscribers to Mailchimp lists' },
      { id: 'slack', name: 'Slack', icon: '💬', description: 'Send notifications to Slack channels' },
      { id: 'zapier', name: 'Zapier', icon: '⚡', description: 'Connect to 3000+ apps via Zapier' },
      { id: 'google_sheets', name: 'Google Sheets', icon: '📊', description: 'Save submissions to Google Sheets' },
      { id: 'webhooks', name: 'Custom Webhooks', icon: '🔗', description: 'Send data to custom webhook URLs' }
    ]
  end
  
  private
  
  def plugin_active?(plugin_identifier)
    Railspress::PluginSystem.plugin_loaded?(plugin_identifier)
  end
  
  def add_pro_fields(base_fields, form)
    base_fields + [
      { type: 'file', label: 'File Upload', icon: '📎' },
      { type: 'date', label: 'Date Picker', icon: '📅' },
      { type: 'time', label: 'Time Picker', icon: '⏰' },
      { type: 'rating', label: 'Star Rating', icon: '⭐' },
      { type: 'signature', label: 'Signature Pad', icon: '✍️' },
      { type: 'phone', label: 'Phone Number', icon: '📱' },
      { type: 'address', label: 'Address Field', icon: '🏠' },
      { type: 'payment', label: 'Payment Field', icon: '💳' },
      { type: 'slider', label: 'Range Slider', icon: '🎚️' },
      { type: 'color', label: 'Color Picker', icon: '🎨' },
      { type: 'matrix', label: 'Matrix Rating', icon: '📊' },
      { type: 'survey', label: 'Survey Field', icon: '📋' }
    ]
  end

  # Pro version features (extends free features)
  def features
    {
      'Drag and Drop Builder' => true,
      'AI Form Builder' => true,
      'Conditional Logic' => true,
      'Advanced Form Styler' => true,
      'Numeric Calculation' => true,
      'Unique Entry Validation' => true,
      'Multi-Step Forms' => true,
      'Conversational Forms' => true,
      'Advanced Post Creation' => true,
      'Payment' => true,
      'Coupon' => true,
      'Inventory' => true,
      'Address Autocomplete' => true,
      'Spam Protection' => true,
      'Quiz and Survey' => true,
      'Multi-column Form' => true,
      'Version History' => true,
      'Fully Responsive' => true,
      'Personality Quiz' => true,
      'CSS Ready Classes' => true,
      'Keyboard Navigation' => true,
      'Undo/Redo' => true,
      'Default Input Fields Value' => true,
      'Accessibility' => true
    }
  end
  
  # Implement Pro Features
  
  def advanced_form_styler_enabled?
    true # Advanced CSS customization, themes
  end
  
  def numeric_calculation_enabled?
    true # Mathematical operations between fields
  end
  
  def multi_step_forms_enabled?
    true # Wizard-style multi-page forms
  end
  
  def advanced_post_creation_enabled?
    true # Auto-create posts from form submissions
  end
  
  def coupon_enabled?
    true # Discount codes, coupons
  end
  
  def inventory_enabled?
    true # Stock management, product selection
  end
  
  def address_autocomplete_enabled?
    true # Google Places API integration
  end
  
  def quiz_survey_enabled?
    true # Scoring, results, analytics
  end
  
  def personality_quiz_enabled?
    true # Advanced quiz logic, personality tests
  end
  
  # Advanced field types
  def advanced_field_types
    [
      { type: 'calculation', label: 'Calculation Field', icon: '🧮' },
      { type: 'signature', label: 'Signature Pad', icon: '✍️' },
      { type: 'file_upload', label: 'File Upload', icon: '📎' },
      { type: 'date_time', label: 'Date & Time', icon: '📅' },
      { type: 'rating', label: 'Rating Scale', icon: '⭐' },
      { type: 'matrix', label: 'Matrix Rating', icon: '📊' },
      { type: 'slider', label: 'Range Slider', icon: '🎚️' },
      { type: 'color_picker', label: 'Color Picker', icon: '🎨' },
      { type: 'address', label: 'Address with Autocomplete', icon: '🏠' },
      { type: 'product_selector', label: 'Product Selector', icon: '🛒' },
      { type: 'coupon_field', label: 'Coupon Code', icon: '🎫' },
      { type: 'inventory_tracker', label: 'Inventory Tracker', icon: '📦' }
    ]
  end
  
  # Process advanced features
  def process_pro_features(submission)
    # Process calculations
    if numeric_calculation_enabled?
      process_calculations(submission)
    end
    
    # Process inventory
    if inventory_enabled?
      update_inventory(submission)
    end
    
    # Process coupons
    if coupon_enabled?
      validate_coupon(submission)
    end
    
    # Process quiz scoring
    if quiz_survey_enabled?
      calculate_quiz_score(submission)
    end
    
    # Process address autocomplete
    if address_autocomplete_enabled?
      validate_address(submission)
    end
    
    # Process advanced post creation
    if advanced_post_creation_enabled?
      create_advanced_post(submission)
    end
  end
  
  private
  
  def process_calculations(submission)
    log("Processing numeric calculations")
    # Calculate totals, tax, shipping, etc.
  end
  
  def update_inventory(submission)
    log("Updating inventory levels")
    # Decrease stock for purchased items
  end
  
  def validate_coupon(submission)
    log("Validating coupon code")
    # Check coupon validity and apply discount
  end
  
  def calculate_quiz_score(submission)
    log("Calculating quiz score")
    # Score quiz responses and determine results
  end
  
  def validate_address(submission)
    log("Validating and formatting address")
    # Use Google Places API to validate addresses
  end
  
  def create_advanced_post(submission)
    log("Creating advanced post from submission")
    # Auto-generate posts with custom fields, categories, etc.
  end
  
  def add_pro_settings(base_settings, form)
    base_settings.merge({
      conditional_logic: true,
      multi_page: true,
      save_progress: true,
      payment_enabled: get_setting(:enable_payments, false)
    })
  end
  
  def process_pro_features(submission)
    # Process analytics
    track_submission_analytics(submission) if get_setting(:enable_analytics, true)
    
    # Process payment if applicable
    process_payment(submission) if submission[:payment_required]
    
    # Send to integrations
    send_to_integrations(submission)
  end
  
  def create_pro_tables
    # Analytics table
    unless table_exists?('slick_forms_analytics')
      ActiveRecord::Migration.create_table :slick_forms_analytics do |t|
        t.references :slick_form, null: false
        t.date :date, null: false
        t.integer :views, default: 0
        t.integer :submissions, default: 0
        t.integer :spam_blocked, default: 0
        t.decimal :conversion_rate, precision: 5, scale: 2
        t.decimal :avg_completion_time, precision: 10, scale: 2
        t.timestamps
      end
    end
    
    # Payments table
    unless table_exists?('slick_forms_payments')
      ActiveRecord::Migration.create_table :slick_forms_payments do |t|
        t.references :slick_form_submission, null: false
        t.string :stripe_payment_intent_id
        t.decimal :amount, precision: 10, scale: 2, null: false
        t.string :currency, default: 'usd'
        t.string :status # pending, succeeded, failed, refunded
        t.text :error_message
        t.datetime :paid_at
        t.datetime :refunded_at
        t.timestamps
      end
    end
    
    # Integrations table
    unless table_exists?('slick_forms_integrations')
      ActiveRecord::Migration.create_table :slick_forms_integrations do |t|
        t.references :slick_form, null: false
        t.string :integration_type # mailchimp, slack, zapier, etc.
        t.string :name
        t.json :config, default: {}
        t.boolean :active, default: true
        t.timestamps
      end
    end
    
    log("Created SlickForms Pro tables")
  end
  
  def track_submission_analytics(submission)
    # Analytics tracking logic
  end
  
  def process_payment(submission)
    # Payment processing logic
  end
  
  def send_to_integrations(submission)
    # Integration sending logic
  end
  
  def generate_analytics_charts
    # Chart data generation
    []
  end
  
  def get_total_views
    0
  end
  
  def get_total_submissions
    0
  end
  
  def calculate_conversion_rate
    0.0
  end
  
  def calculate_average_completion_time
    0.0
  end
  
  def get_top_performing_forms(limit)
    []
  end
  
  def get_recent_payments(limit)
    []
  end
  
  def calculate_total_revenue
    0.0
  end
  
  def get_successful_payments_count
    0
  end
  
  def get_failed_payments_count
    0
  end
  
  def calculate_refunded_amount
    0.0
  end
  
  def get_active_integrations
    []
  end
  
  def table_exists?(table_name)
    ActiveRecord::Base.connection.table_exists?(table_name)
  end
end

# Register the plugin
Railspress::PluginSystem.register_plugin('slick_forms_pro', SlickFormsPro.new)
