class Admin::IntegrationsController < Admin::BaseController
  before_action :ensure_admin
  
  # GET /admin/integrations
  def index
    @integration_plugins = Plugin.where(name: integration_plugin_names).order(:name)
    @available_integrations = available_integrations_list
  end
  
  # GET /admin/integrations/uploadcare
  def uploadcare
    @plugin = Plugin.find_by(name: 'Uploadcare')
    
    unless @plugin
      redirect_to admin_integrations_path, alert: 'Uploadcare plugin not found. Please install it first.'
      return
    end
    
    # Load plugin instance
    @plugin_instance = load_plugin_instance(@plugin)
    @dashboard_url = @plugin_instance&.dashboard_url
    @widget_config = @plugin_instance&.widget_config || {}
    @enabled = @plugin_instance&.enabled? || false
  end
  
  # GET /admin/integrations/:name
  def show
    integration_name = params[:name]&.titleize
    @plugin = Plugin.find_by(name: integration_name)
    
    unless @plugin
      redirect_to admin_integrations_path, alert: "#{integration_name} integration not found."
      return
    end
    
    @plugin_instance = load_plugin_instance(@plugin)
    
    # Redirect to specific integration view if available
    if respond_to?("#{params[:name]}_integration", true)
      send("#{params[:name]}_integration")
    else
      render :show
    end
  end
  
  private
  
  def ensure_admin
    unless current_user&.administrator?
      redirect_to root_path, alert: 'Access denied. Administrator privileges required.'
    end
  end
  
  def integration_plugin_names
    [
      'Uploadcare',
      'Cloudinary',
      'AWS S3',
      'Google Analytics',
      'Mailchimp',
      'Stripe',
      'SendGrid',
      'Twilio',
      'Slack'
    ]
  end
  
  def available_integrations_list
    [
      {
        name: 'Uploadcare',
        description: 'Professional media management and CDN',
        icon: '📸',
        category: 'Media',
        status: plugin_status('Uploadcare'),
        url: uploadcare_admin_integrations_path,
        features: ['File Upload Widget', 'CDN Delivery', 'Image Transformations', 'Dashboard Integration']
      },
      {
        name: 'Cloudinary',
        description: 'Cloud-based image and video management',
        icon: '☁️',
        category: 'Media',
        status: 'available',
        url: '#',
        features: ['Image/Video Upload', 'AI-powered Transformations', 'DAM', 'CDN']
      },
      {
        name: 'AWS S3',
        description: 'Amazon S3 storage integration',
        icon: '🪣',
        category: 'Storage',
        status: 'available',
        url: '#',
        features: ['Object Storage', 'Versioning', 'Backup', 'CloudFront CDN']
      },
      {
        name: 'Google Analytics',
        description: 'Web analytics and reporting',
        icon: '📊',
        category: 'Analytics',
        status: 'available',
        url: '#',
        features: ['GA4 Tracking', 'Custom Events', 'Reports', 'User Behavior']
      },
      {
        name: 'Mailchimp',
        description: 'Email marketing and automation',
        icon: '📧',
        category: 'Marketing',
        status: 'available',
        url: '#',
        features: ['Email Campaigns', 'Lists', 'Automation', 'Reports']
      },
      {
        name: 'Stripe',
        description: 'Payment processing',
        icon: '💳',
        category: 'Payments',
        status: 'available',
        url: '#',
        features: ['Online Payments', 'Subscriptions', 'Invoicing', 'Webhooks']
      }
    ]
  end
  
  def plugin_status(plugin_name)
    plugin = Plugin.find_by(name: plugin_name)
    return 'not_installed' unless plugin
    return 'active' if plugin.active?
    'installed'
  end
  
  def load_plugin_instance(plugin)
    # Try to get from plugin system
    instance = Railspress::PluginSystem.get_plugin(plugin.name.underscore) rescue nil
    return instance if instance
    
    # Try to load manually
    plugin_path = Rails.root.join('lib', 'plugins', plugin.name.underscore, "#{plugin.name.underscore}.rb")
    if File.exist?(plugin_path)
      begin
        load plugin_path
        plugin_class_name = plugin.name.classify
        plugin_class = plugin_class_name.constantize rescue nil
        instance = plugin_class.new if plugin_class && plugin_class.ancestors.include?(Railspress::PluginBase)
      rescue => e
        Rails.logger.error "Failed to load plugin: #{e.message}"
      end
    end
    
    instance
  end
end








