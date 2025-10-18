class Admin::SettingsController < Admin::BaseController
  before_action :ensure_admin

  # GET /admin/settings
  def index
    redirect_to admin_general_settings_path
  end

  # GET /admin/settings/general
  def general
    load_general_settings
  end

  # GET /admin/settings/writing
  def writing
    load_writing_settings
  end

  # GET /admin/settings/reading
  def reading
    load_reading_settings
  end

  # GET /admin/settings/discussion
  def discussion
    load_discussion_settings
  end

  # GET /admin/settings/media
  def media
    load_media_settings
  end

  # GET /admin/settings/permalinks
  def permalinks
    load_permalink_settings
  end

  # GET /admin/settings/privacy
  def privacy
    load_privacy_settings
  end

  # GET /admin/settings/email
  def email
    load_email_settings
  end
  
  # GET /admin/settings/post_by_email
  def post_by_email
    # Settings are loaded dynamically in the view
  end
  
  # GET /admin/settings/white_label
  def white_label
    load_white_label_settings
  end
  
  # GET /admin/settings/appearance
  def appearance
    load_appearance_settings
  end

  # GET /admin/settings/storage
  def storage
    load_storage_settings
  end

  # PATCH /admin/settings/update_general
  def update_general
    params[:settings].each do |key, value|
      SiteSetting.set(key, value, setting_type_for(key))
    end
    redirect_to admin_general_settings_path, notice: 'General settings updated successfully.'
  end

  # PATCH /admin/settings/update_writing
  def update_writing
    # Update site settings
    if params[:settings]
      params[:settings].each do |key, value|
        SiteSetting.set(key, value, setting_type_for(key))
      end
    end
    
    # Update user's editor preference
    if params[:user] && params[:user][:editor_preference]
      current_user.update(editor_preference: params[:user][:editor_preference])
    end
    
    redirect_to admin_writing_settings_path, notice: 'Writing settings updated successfully.'
  end

  # PATCH /admin/settings/update_reading
  def update_reading
    params[:settings].each do |key, value|
      SiteSetting.set(key, value, setting_type_for(key))
    end
    redirect_to admin_reading_settings_path, notice: 'Reading settings updated successfully.'
  end

  # PATCH /admin/settings/update_discussion
  def update_discussion
    params[:settings].each do |key, value|
      SiteSetting.set(key, value, setting_type_for(key))
    end
    redirect_to admin_discussion_settings_path, notice: 'Discussion settings updated successfully.'
  end

  # PATCH /admin/settings/update_media
  def update_media
    params[:settings].each do |key, value|
      SiteSetting.set(key, value, setting_type_for(key))
    end
    redirect_to admin_media_settings_path, notice: 'Media settings updated successfully.'
  end

  # PATCH /admin/settings/update_permalinks
  def update_permalinks
    params[:settings].each do |key, value|
      SiteSetting.set(key, value, setting_type_for(key))
    end
    redirect_to admin_permalinks_settings_path, notice: 'Permalink settings updated successfully.'
  end

  # PATCH /admin/settings/update_privacy
  def update_privacy
    params[:settings].each do |key, value|
      SiteSetting.set(key, value, setting_type_for(key))
    end
    redirect_to admin_privacy_settings_path, notice: 'Privacy settings updated successfully.'
  end

  # PATCH /admin/settings/update_email
  def update_email
    params[:settings].each do |key, value|
      SiteSetting.set(key, value, setting_type_for(key))
    end
    
    # Apply email configuration
    configure_action_mailer
    
    redirect_to admin_email_settings_path, notice: 'Email settings updated successfully.'
  end

  # POST /admin/settings/test_email
  def test_email
    provider = SiteSetting.get('email_provider', 'smtp')
    
    begin
      TestMailer.test_email(params[:test_email_address]).deliver_now
      
      render json: { 
        success: true, 
        message: "Test email sent successfully via #{provider.upcase}!" 
      }
    rescue => e
      render json: { 
        success: false, 
        message: "Failed to send test email: #{e.message}"
      }, status: :unprocessable_entity
    end
  end
  
  # PATCH /admin/settings/update_post_by_email
  def update_post_by_email
    # Save all post by email settings
    [
      'post_by_email_enabled',
      'imap_server',
      'imap_port',
      'imap_email',
      'imap_password',
      'imap_ssl',
      'imap_folder',
      'post_by_email_default_category',
      'post_by_email_default_author',
      'post_by_email_mark_as_read',
      'post_by_email_delete_after_import'
    ].each do |key|
      value = params[key]
      if value.present?
        SiteSetting.set(key, value, setting_type_for(key))
      elsif key == 'post_by_email_enabled' || key == 'post_by_email_mark_as_read' || key == 'post_by_email_delete_after_import'
        # Handle unchecked checkboxes
        SiteSetting.set(key, false, 'boolean')
      end
    end
    
    render json: { success: true, message: 'Post by Email settings saved successfully!' }
  rescue => e
    Rails.logger.error "Error saving post by email settings: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end
  
  # POST /admin/settings/test_post_by_email
  def test_post_by_email
    begin
      result = PostByEmailService.check_mail
      
      render json: { 
        success: true, 
        message: "#{result[:new_posts]} new post(s) created, #{result[:checked]} email(s) checked" 
      }
    rescue => e
      Rails.logger.error "Error testing post by email: #{e.message}"
      render json: { 
        success: false, 
        error: "Connection failed: #{e.message}"
      }, status: :unprocessable_entity
    end
  end
  
  # PATCH /admin/settings/update_white_label
  def update_white_label
    # Handle logo upload if present
    if params[:settings] && params[:settings][:admin_logo].present?
      # Store logo using ActiveStorage or similar
      logo_file = params[:settings][:admin_logo]
      SiteSetting.set('admin_logo_url', store_logo(logo_file), :string)
      params[:settings].delete(:admin_logo)
    end
    
    params[:settings].each do |key, value|
      SiteSetting.set(key, value, setting_type_for(key))
    end
    
    redirect_to admin_settings_white_label_path, notice: 'White label settings updated successfully.'
  end
  
  # PATCH /admin/settings/update_appearance
  def update_appearance
    params[:settings].each do |key, value|
      SiteSetting.set(key, value, setting_type_for(key))
    end
    
    redirect_to admin_settings_appearance_path, notice: 'Appearance settings updated successfully.'
  end

  # PATCH /admin/settings/update_storage
  def update_storage
    # Update storage settings
    if params[:settings]
      params[:settings].each do |key, value|
        SiteSetting.set(key, value, setting_type_for(key))
      end
    end
    
    # Update tenant storage configuration if we have a current tenant
    if defined?(ActsAsTenant) && ActsAsTenant.current_tenant
      tenant = ActsAsTenant.current_tenant
      tenant.update!(
        storage_type: params[:storage_type] || 'local',
        storage_bucket: params[:storage_bucket],
        storage_region: params[:storage_region],
        storage_access_key: params[:storage_access_key],
        storage_secret_key: params[:storage_secret_key],
        storage_endpoint: params[:storage_endpoint],
        storage_path: params[:storage_path]
      )
    end
    
    # Apply storage configuration
    begin
      storage_config = StorageConfigurationService.new
      storage_config.configure_active_storage
      storage_config.update_storage_config
    rescue => e
      Rails.logger.error "Failed to apply storage configuration: #{e.message}"
      redirect_to admin_storage_settings_path, alert: 'Storage settings updated but configuration failed to apply. Please check the logs.'
      return
    end
    
    redirect_to admin_storage_settings_path, notice: 'Storage settings updated successfully.'
  end

  private

  def load_general_settings
    @settings = {
      site_title: SiteSetting.get('site_title', 'RailsPress'),
      site_tagline: SiteSetting.get('site_tagline', 'A Ruby on Rails CMS'),
      site_url: SiteSetting.get('site_url', 'http://localhost:3000'),
      admin_email: SiteSetting.get('admin_email', 'admin@railspress.com'),
      timezone: SiteSetting.get('timezone', 'UTC'),
      date_format: SiteSetting.get('date_format', '%B %d, %Y'),
      time_format: SiteSetting.get('time_format', '%H:%M'),
      language: SiteSetting.get('language', 'en')
    }
  end

  def load_writing_settings
    @settings = {
      default_post_status: SiteSetting.get('default_post_status', 'draft'),
      default_post_category: SiteSetting.get('default_post_category', ''),
      default_post_format: SiteSetting.get('default_post_format', 'standard'),
      enable_auto_save: SiteSetting.get('enable_auto_save', true),
      auto_save_interval: SiteSetting.get('auto_save_interval', 60),
      enable_revisions: SiteSetting.get('enable_revisions', true),
      max_revisions: SiteSetting.get('max_revisions', 10),
      rich_editor_type: SiteSetting.get('rich_editor_type', 'trix')
    }
  end

  def load_reading_settings
    @settings = {
      posts_per_page: SiteSetting.get('posts_per_page', 10),
      posts_per_rss: SiteSetting.get('posts_per_rss', 10),
      homepage_display: SiteSetting.get('homepage_display', 'posts'),
      homepage_page_id: SiteSetting.get('homepage_page_id', ''),
      blog_page_id: SiteSetting.get('blog_page_id', ''),
      show_on_front: SiteSetting.get('show_on_front', 'posts'),
      excerpt_length: SiteSetting.get('excerpt_length', 200)
    }
  end

  def load_media_settings
    @settings = {
      image_max_width: SiteSetting.get('image_max_width', 2048),
      image_max_height: SiteSetting.get('image_max_height', 2048),
      thumbnail_width: SiteSetting.get('thumbnail_width', 150),
      thumbnail_height: SiteSetting.get('thumbnail_height', 150),
      medium_width: SiteSetting.get('medium_width', 300),
      medium_height: SiteSetting.get('medium_height', 300),
      large_width: SiteSetting.get('large_width', 1024),
      large_height: SiteSetting.get('large_height', 1024),
      auto_optimize_images: SiteSetting.get('auto_optimize_images', false),
      allowed_file_types: SiteSetting.get('allowed_file_types', 'jpg,jpeg,png,gif,pdf,doc,docx'),
      max_upload_size: SiteSetting.get('max_upload_size', 10)
    }
  end

  def load_permalink_settings
    @settings = {
      permalink_structure: SiteSetting.get('permalink_structure', '/blog/:slug'),
      category_base: SiteSetting.get('category_base', 'category'),
      tag_base: SiteSetting.get('tag_base', 'tag'),
      use_trailing_slash: SiteSetting.get('use_trailing_slash', false),
      auto_redirect_old_urls: SiteSetting.get('auto_redirect_old_urls', true)
    }
  end

  def load_discussion_settings
    @settings = {
      comments_enabled: SiteSetting.get('comments_enabled', true),
      comments_moderation: SiteSetting.get('comments_moderation', true),
      comment_registration_required: SiteSetting.get('comment_registration_required', false),
      close_comments_after_days: SiteSetting.get('close_comments_after_days', 0),
      show_avatars: SiteSetting.get('show_avatars', true),
      akismet_api_key: SiteSetting.get('akismet_api_key', ''),
      akismet_enabled: SiteSetting.get('akismet_enabled', false)
    }
  end

  def load_privacy_settings
    @settings = {
      gdpr_compliance_enabled: SiteSetting.get('gdpr_compliance_enabled', false),
      cookie_consent_required: SiteSetting.get('cookie_consent_required', false),
      privacy_policy_page_id: SiteSetting.get('privacy_policy_page_id', ''),
      allow_user_registration: SiteSetting.get('allow_user_registration', true),
      default_user_role: SiteSetting.get('default_user_role', 'subscriber')
    }
  end

  def load_email_settings
    @settings = {
      email_provider: SiteSetting.get('email_provider', 'smtp'),
      email_logging_enabled: SiteSetting.get('email_logging_enabled', true),
      
      # SMTP
      smtp_host: SiteSetting.get('smtp_host', 'smtp.gmail.com'),
      smtp_port: SiteSetting.get('smtp_port', 587),
      smtp_encryption: SiteSetting.get('smtp_encryption', 'tls'),
      smtp_username: SiteSetting.get('smtp_username', ''),
      smtp_password: SiteSetting.get('smtp_password', ''),
      smtp_timeout: SiteSetting.get('smtp_timeout', 10),
      
      # Resend
      resend_api_key: SiteSetting.get('resend_api_key', ''),
      
      # Default sender
      default_from_email: SiteSetting.get('default_from_email', 'noreply@railspress.com'),
      default_from_name: SiteSetting.get('default_from_name', 'RailsPress')
    }
  end
  
  def load_white_label_settings
    @settings = {
      admin_app_name: SiteSetting.get('admin_app_name', 'RailsPress'),
      admin_app_url: SiteSetting.get('admin_app_url', 'http://localhost:3000'),
      admin_logo_url: SiteSetting.get('admin_logo_url', ''),
      admin_favicon_url: SiteSetting.get('admin_favicon_url', ''),
      admin_footer_text: SiteSetting.get('admin_footer_text', 'Powered by RailsPress'),
      admin_support_email: SiteSetting.get('admin_support_email', 'support@railspress.com'),
      admin_support_url: SiteSetting.get('admin_support_url', 'https://railspress.com/support'),
      hide_branding: SiteSetting.get('hide_branding', false)
    }
  end
  
  def load_appearance_settings
    @settings = {
      # Color Scheme
      color_scheme: SiteSetting.get('color_scheme', 'onyx'),
      
      # Color Accents
      primary_color: SiteSetting.get('primary_color', '#6366F1'),
      secondary_color: SiteSetting.get('secondary_color', '#8B5CF6'),
      
      # Typography
      heading_font: SiteSetting.get('heading_font', 'Inter'),
      body_font: SiteSetting.get('body_font', 'Inter'),
      paragraph_font: SiteSetting.get('paragraph_font', 'Inter'),
      
      # Font Sizes
      heading_size: SiteSetting.get('heading_size', '1.875rem'),
      body_size: SiteSetting.get('body_size', '0.875rem'),
      paragraph_size: SiteSetting.get('paragraph_size', '1rem')
    }
  end

  def load_storage_settings
    # Get current tenant storage settings if available
    current_tenant = defined?(ActsAsTenant) ? ActsAsTenant.current_tenant : nil
    
    @settings = {
      # Storage Type
      storage_type: current_tenant&.storage_type || SiteSetting.get('storage_type', 'local'),
      
      # Local Storage Configuration
      local_storage_path: SiteSetting.get('local_storage_path', Rails.root.join('storage').to_s),
      
      # S3 Configuration
      storage_bucket: current_tenant&.storage_bucket || SiteSetting.get('storage_bucket', ''),
      storage_region: current_tenant&.storage_region || SiteSetting.get('storage_region', 'us-east-1'),
      storage_access_key: current_tenant&.storage_access_key || SiteSetting.get('storage_access_key', ''),
      storage_secret_key: current_tenant&.storage_secret_key || SiteSetting.get('storage_secret_key', ''),
      storage_endpoint: current_tenant&.storage_endpoint || SiteSetting.get('storage_endpoint', ''),
      storage_path: current_tenant&.storage_path || SiteSetting.get('storage_path', ''),
      
      # General Storage Settings
      enable_cdn: SiteSetting.get('enable_cdn', false),
      cdn_url: SiteSetting.get('cdn_url', ''),
      auto_optimize_uploads: SiteSetting.get('auto_optimize_uploads', true),
      max_file_size: SiteSetting.get('max_file_size', 10), # MB
      allowed_file_types: SiteSetting.get('allowed_file_types', 'jpg,jpeg,png,gif,pdf,doc,docx,mp4,mp3')
    }
  end

  def configure_action_mailer
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
      # Resend uses its own delivery method
      ActionMailer::Base.delivery_method = :resend
    end
  end

  def setting_type_for(key)
    boolean_settings = %w[
      enable_auto_save enable_revisions auto_optimize_images use_trailing_slash
      auto_redirect_old_urls comments_enabled comments_moderation 
      comment_registration_required show_avatars gdpr_compliance_enabled
      cookie_consent_required allow_user_registration email_logging_enabled
      hide_branding enable_cdn auto_optimize_uploads
    ]
    
    integer_settings = %w[
      auto_save_interval max_revisions posts_per_page posts_per_rss
      image_max_width image_max_height thumbnail_width thumbnail_height
      medium_width medium_height large_width large_height max_upload_size
      close_comments_after_days excerpt_length smtp_port smtp_timeout
      max_file_size
    ]
    
    if boolean_settings.include?(key)
      'boolean'
    elsif integer_settings.include?(key)
      'integer'
    else
      'string'
    end
  end
  
  def store_logo(file)
    # For now, just return a placeholder
    # In production, you'd upload to ActiveStorage or external service
    return '/uploads/logo.png'
  end

  def shortcuts
    # Load command palette shortcut settings
    @command_palette_shortcut = SiteSetting.get('command_palette_shortcut', 'cmd+k')
  end
  
  def update_shortcuts
    shortcut = params[:command_palette_shortcut]
    
    # Validate shortcut format
    valid_shortcuts = ['cmd+k', 'ctrl+k', 'cmd+shift+p', 'ctrl+shift+p', 'cmd+i', 'ctrl+i']
    unless valid_shortcuts.include?(shortcut)
      redirect_to admin_shortcuts_settings_path, alert: 'Invalid shortcut format'
      return
    end
    
    SiteSetting.set('command_palette_shortcut', shortcut)
    redirect_to admin_shortcuts_settings_path, notice: 'Shortcuts updated successfully!'
  end
  
  # JSON endpoint for JavaScript to get shortcut settings
  def shortcuts_json
    render json: {
      command_palette_shortcut: SiteSetting.get('command_palette_shortcut', 'cmd+k')
    }
  end

  def ensure_admin
    redirect_to admin_root_path, alert: 'Access denied.' unless current_user&.administrator?
  end
end

