class Admin::PluginsController < Admin::BaseController
  before_action :ensure_admin
  before_action :set_plugin, only: [:show, :edit, :update, :destroy, :activate, :deactivate, :settings]

  # GET /admin/plugins
  def index
    @installed_plugins = Plugin.all.order(active: :desc, name: :asc)
  end

  # GET /admin/plugins/browse
  def browse
    @available_plugins = fetch_available_plugins
    @categories = plugin_categories
    @featured_plugins = @available_plugins.select { |p| p[:featured] }
    
    # Filter by category
    if params[:category].present?
      @available_plugins = @available_plugins.select { |p| p[:category] == params[:category] }
    end
    
    # Search
    if params[:q].present?
      query = params[:q].downcase
      @available_plugins = @available_plugins.select do |p|
        p[:name].downcase.include?(query) || 
        p[:description].downcase.include?(query) ||
        p[:tags].any? { |t| t.downcase.include?(query) }
      end
    end
  end

  # GET /admin/plugins/marketplace
  def marketplace
    @available_plugins = fetch_available_plugins
    @categories = plugin_categories
    @featured_plugins = @available_plugins.select { |p| p[:featured] }
    @popular_plugins = @available_plugins.sort_by { |p| -p[:downloads] }.first(10)
    @new_plugins = @available_plugins.select { |p| p[:new] }.first(10)
    
    # Filter by category
    if params[:category].present?
      @available_plugins = @available_plugins.select { |p| p[:category] == params[:category] }
    end
    
    # Search
    if params[:q].present?
      query = params[:q].downcase
      @available_plugins = @available_plugins.select do |p|
        p[:name].downcase.include?(query) || 
        p[:description].downcase.include?(query) ||
        p[:tags].any? { |t| t.downcase.include?(query) }
      end
    end
  end

  # GET /admin/plugins/1
  def show
  end

  # GET /admin/plugins/new
  def new
    @plugin = Plugin.new
  end

  # GET /admin/plugins/1/edit
  def edit
  end

  # POST /admin/plugins
  def create
    @plugin = Plugin.new(plugin_params)

    if @plugin.save
      redirect_to admin_plugins_path, notice: "Plugin was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/plugins/1
  def update
    if @plugin.update(plugin_params)
      redirect_to admin_plugins_path, notice: "Plugin was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/plugins/1
  def destroy
    @plugin.destroy
    redirect_to admin_plugins_path, notice: "Plugin was successfully deleted."
  end

  # PATCH /admin/plugins/1/activate
  def activate
    if @plugin.activate!
      # Load the plugin
      load_plugin(@plugin)
      redirect_to admin_plugins_path, notice: "Plugin '#{@plugin.name}' activated successfully."
    else
      redirect_to admin_plugins_path, alert: "Failed to activate plugin."
    end
  end

  # PATCH /admin/plugins/1/deactivate
  def deactivate
    if @plugin.deactivate!
      redirect_to admin_plugins_path, notice: "Plugin '#{@plugin.name}' deactivated."
    else
      redirect_to admin_plugins_path, alert: "Failed to deactivate plugin."
    end
  end

  # POST /admin/plugins/install
  def install
    plugin_slug = params[:plugin_slug]
    plugin_data = fetch_available_plugins.find { |p| p[:slug] == plugin_slug }
    
    unless plugin_data
      return redirect_to browse_admin_plugins_path, alert: "Plugin not found."
    end

    # Check if already installed
    if Plugin.exists?(name: plugin_data[:name])
      return redirect_to browse_admin_plugins_path, alert: "Plugin already installed."
    end

    # Create plugin record
    plugin = Plugin.create!(
      name: plugin_data[:name],
      description: plugin_data[:description],
      author: plugin_data[:author],
      version: plugin_data[:version],
      active: false
    )

    # In a real implementation, this would download and install the plugin files
    # For now, we just create the database record
    
    redirect_to admin_plugins_path, notice: "Plugin '#{plugin.name}' installed successfully. You can now activate it."
  end

  # GET /admin/plugins/1/settings
  def settings
    @plugin_settings = @plugin.settings || {}
  end

  # PATCH /admin/plugins/1/update_settings
  def update_settings
    @plugin = Plugin.find(params[:id])
    
    if @plugin.update(settings: params[:plugin][:settings])
      redirect_to admin_plugins_path, notice: "Plugin settings updated."
    else
      redirect_to settings_admin_plugin_path(@plugin), alert: "Failed to update settings."
    end
  end

  private

  def set_plugin
    @plugin = Plugin.find(params[:id])
  end

  def plugin_params
    params.require(:plugin).permit(:name, :description, :author, :version, :active, :settings)
  end

  def load_plugin(plugin)
    plugin_path = Rails.root.join('lib', 'plugins', plugin.name.underscore, "#{plugin.name.underscore}.rb")
    
    if File.exist?(plugin_path)
      require plugin_path
      Rails.logger.info "Loaded plugin: #{plugin.name}"
    end
  end

  def plugin_categories
    [
      'SEO & Marketing',
      'Security',
      'Performance',
      'Social Media',
      'Analytics',
      'Content Enhancement',
      'E-commerce',
      'Forms & Contact',
      'Media & Gallery',
      'Development Tools'
    ]
  end

  # Mock plugin marketplace - In production, this would fetch from a real API
  def fetch_available_plugins
    [
      {
        slug: 'seo-optimizer',
        name: 'SEO Optimizer Pro',
        author: 'RailsPress Team',
        version: '2.5.0',
        description: 'Complete SEO solution with XML sitemaps, meta tag management, social media integration, and Google Analytics.',
        long_description: 'SEO Optimizer Pro is the most comprehensive SEO plugin for RailsPress. It includes automatic XML sitemaps, advanced meta tag management, Open Graph and Twitter Card support, breadcrumbs, canonical URLs, and Google Analytics integration. Perfect for improving your search engine rankings.',
        rating: 4.8,
        downloads: 125000,
        category: 'SEO & Marketing',
        tags: ['seo', 'google', 'analytics', 'sitemap', 'meta tags'],
        featured: true,
        screenshots: ['screenshot1.png', 'screenshot2.png'],
        requires: '1.0.0',
        tested_up_to: '1.5.0',
        last_updated: '2025-09-15'
      },
      {
        slug: 'contact-form-builder',
        name: 'Contact Form Builder',
        author: 'FormCraft',
        version: '1.8.2',
        description: 'Drag-and-drop form builder with email notifications, spam protection, and integrations.',
        long_description: 'Build beautiful contact forms with our intuitive drag-and-drop interface. Includes reCAPTCHA integration, email notifications, file uploads, conditional logic, multi-page forms, and integrations with popular email marketing services.',
        rating: 4.9,
        downloads: 89000,
        category: 'Forms & Contact',
        tags: ['forms', 'contact', 'email', 'captcha'],
        featured: true,
        screenshots: [],
        requires: '1.0.0',
        tested_up_to: '1.5.0',
        last_updated: '2025-10-01'
      },
      {
        slug: 'security-guardian',
        name: 'Security Guardian',
        author: 'SecureRails',
        version: '3.1.0',
        description: 'Advanced security features including firewall, malware scanning, and two-factor authentication.',
        long_description: 'Protect your site with enterprise-grade security. Features include web application firewall, malware scanning, brute force protection, two-factor authentication, security headers, file integrity monitoring, and detailed security reports.',
        rating: 4.7,
        downloads: 67000,
        category: 'Security',
        tags: ['security', '2fa', 'firewall', 'malware'],
        featured: false,
        screenshots: [],
        requires: '1.0.0',
        tested_up_to: '1.5.0',
        last_updated: '2025-09-28'
      },
      {
        slug: 'performance-booster',
        name: 'Performance Booster',
        author: 'SpeedUp Labs',
        version: '2.0.3',
        description: 'Comprehensive caching, minification, lazy loading, and CDN integration for maximum performance.',
        long_description: 'Supercharge your site speed with advanced caching strategies, asset minification, image optimization, lazy loading, database query optimization, and CDN integration. Includes performance monitoring and detailed reports.',
        rating: 4.6,
        downloads: 54000,
        category: 'Performance',
        tags: ['cache', 'speed', 'optimization', 'cdn'],
        featured: true,
        screenshots: [],
        requires: '1.0.0',
        tested_up_to: '1.5.0',
        last_updated: '2025-10-05'
      },
      {
        slug: 'social-share-buttons',
        name: 'Social Share Buttons',
        author: 'ShareKit',
        version: '1.5.1',
        description: 'Beautiful, customizable social media sharing buttons for all major platforms.',
        long_description: 'Add stunning social sharing buttons to your posts and pages. Supports Facebook, Twitter, LinkedIn, Pinterest, Reddit, WhatsApp, and more. Fully customizable with multiple styles, floating sidebar option, and share count display.',
        rating: 4.5,
        downloads: 98000,
        category: 'Social Media',
        tags: ['social', 'sharing', 'facebook', 'twitter'],
        featured: false,
        screenshots: [],
        requires: '1.0.0',
        tested_up_to: '1.5.0',
        last_updated: '2025-08-20'
      },
      {
        slug: 'analytics-dashboard',
        name: 'Analytics Dashboard Pro',
        author: 'DataViz Inc',
        version: '4.2.0',
        description: 'Real-time analytics dashboard with visitor tracking, heatmaps, and detailed reports.',
        long_description: 'Get deep insights into your site traffic with real-time analytics. Track visitors, page views, bounce rates, conversion goals, heatmaps, user flow, geographic data, and more. Beautiful charts and exportable reports included.',
        rating: 4.9,
        downloads: 43000,
        category: 'Analytics',
        tags: ['analytics', 'tracking', 'reports', 'stats'],
        featured: false,
        screenshots: [],
        requires: '1.2.0',
        tested_up_to: '1.5.0',
        last_updated: '2025-10-10'
      },
      {
        slug: 'markdown-editor',
        name: 'Markdown Editor Plus',
        author: 'EditorTech',
        version: '1.3.0',
        description: 'Enhanced markdown editor with live preview, syntax highlighting, and export options.',
        long_description: 'Write content in markdown with our enhanced editor. Features include live preview, syntax highlighting, table support, footnotes, emoji picker, export to multiple formats, and seamless integration with the existing rich text editor.',
        rating: 4.4,
        downloads: 31000,
        category: 'Content Enhancement',
        tags: ['markdown', 'editor', 'writing'],
        featured: false,
        screenshots: [],
        requires: '1.0.0',
        tested_up_to: '1.5.0',
        last_updated: '2025-09-12'
      },
      {
        slug: 'image-gallery',
        name: 'Advanced Image Gallery',
        author: 'GalleryPro',
        version: '2.1.5',
        description: 'Create stunning image galleries with lightbox, masonry layouts, and slideshow features.',
        long_description: 'Build beautiful image galleries with multiple layout options including masonry, grid, carousel, and justified layouts. Features lightbox viewer, slideshow mode, lazy loading, touch gestures, captions, and social sharing.',
        rating: 4.7,
        downloads: 72000,
        category: 'Media & Gallery',
        tags: ['gallery', 'images', 'lightbox', 'slideshow'],
        featured: false,
        screenshots: [],
        requires: '1.0.0',
        tested_up_to: '1.5.0',
        last_updated: '2025-09-30'
      },
      {
        slug: 'ecommerce-lite',
        name: 'E-Commerce Lite',
        author: 'ShopRails',
        version: '3.0.0',
        description: 'Lightweight e-commerce solution with product management, cart, and payment integration.',
        long_description: 'Transform your site into an online store with our lightweight e-commerce plugin. Features include product catalog, shopping cart, checkout process, Stripe integration, inventory management, order tracking, and customer accounts.',
        rating: 4.6,
        downloads: 38000,
        category: 'E-commerce',
        tags: ['shop', 'ecommerce', 'products', 'payments'],
        featured: true,
        screenshots: [],
        requires: '1.2.0',
        tested_up_to: '1.5.0',
        last_updated: '2025-10-08'
      },
      {
        slug: 'backup-manager',
        name: 'Backup Manager',
        author: 'BackupSafe',
        version: '1.6.0',
        description: 'Automated backups with cloud storage support and one-click restore functionality.',
        long_description: 'Never lose your data with automated backups to cloud storage. Supports AWS S3, Google Cloud Storage, Dropbox, and more. Schedule automatic backups, one-click restore, incremental backups, and email notifications.',
        rating: 4.8,
        downloads: 56000,
        category: 'Development Tools',
        tags: ['backup', 'restore', 'cloud', 's3'],
        featured: false,
        screenshots: [],
        requires: '1.0.0',
        tested_up_to: '1.5.0',
        last_updated: '2025-09-25'
      },
      {
        slug: 'multilingual',
        name: 'Multilingual Content Manager',
        author: 'TranslateCMS',
        version: '2.3.1',
        description: 'Complete multilingual solution with automatic translation and language switcher.',
        long_description: 'Make your site multilingual with ease. Features include manual and automatic translation, language switcher widget, SEO for multiple languages, RTL support, translation management interface, and integration with Google Translate API.',
        rating: 4.5,
        downloads: 29000,
        category: 'Content Enhancement',
        tags: ['translation', 'multilingual', 'i18n', 'languages'],
        featured: false,
        screenshots: [],
        requires: '1.3.0',
        tested_up_to: '1.5.0',
        last_updated: '2025-10-02'
      },
      {
        slug: 'email-marketing',
        name: 'Email Marketing Suite',
        author: 'MailRails',
        version: '1.9.0',
        description: 'Newsletter management, email campaigns, subscriber management, and analytics.',
        long_description: 'Build your email list and send beautiful newsletters. Features include subscriber management, email campaign builder, drag-and-drop email designer, automation, segmentation, A/B testing, and detailed analytics.',
        rating: 4.7,
        downloads: 41000,
        category: 'SEO & Marketing',
        tags: ['email', 'newsletter', 'marketing', 'campaigns'],
        featured: false,
        screenshots: [],
        requires: '1.1.0',
        tested_up_to: '1.5.0',
        last_updated: '2025-09-18'
      }
    ]
  end

  # GET /admin/plugins/1/settings
  def settings
    @plugin_settings = @plugin.settings || {}
    
    # Try to load plugin instance to get schema
    @plugin_instance = Railspress::PluginSystem.get_plugin(@plugin.name.underscore) rescue nil
    
    # If no plugin instance, try to load the plugin class
    if @plugin_instance.nil?
      plugin_path = Rails.root.join('lib', 'plugins', @plugin.name.underscore, "#{@plugin.name.underscore}.rb")
      if File.exist?(plugin_path)
        begin
          load plugin_path
          plugin_class_name = @plugin.name.classify
          plugin_class = plugin_class_name.constantize rescue nil
          @plugin_instance = plugin_class.new if plugin_class && plugin_class.ancestors.include?(Railspress::PluginBase)
        rescue => e
          Rails.logger.error "Failed to load plugin for settings: #{e.message}"
        end
      end
    end
    
    @schema = @plugin_instance&.settings_schema
  end

  # PATCH /admin/plugins/1/update_settings
  def update_settings
    new_settings = settings_params
    
    # Try to get schema for validation
    @plugin_instance = Railspress::PluginSystem.get_plugin(@plugin.name.underscore) rescue nil
    if @plugin_instance && @plugin_instance.settings_schema
      # Validate against schema
      errors = @plugin_instance.settings_schema.validate(new_settings)
      
      if errors.any?
        flash[:alert] = "Validation errors: #{errors.values.flatten.join(', ')}"
        redirect_to settings_admin_plugin_path(@plugin)
        return
      end
    end
    
    if @plugin.update(settings: new_settings)
      redirect_to admin_plugins_path, notice: "Plugin settings updated successfully."
    else
      redirect_to settings_admin_plugin_path(@plugin), alert: "Failed to update plugin settings."
    end
  end

  private

  def set_plugin
    @plugin = Plugin.find(params[:id])
  end

  def plugin_params
    params.require(:plugin).permit(:name, :description, :author, :version, :active)
  end

  def settings_params
    params.require(:plugin).permit(:settings).to_h.dig(:settings) || {}
  end

  def load_plugin(plugin)
    plugin_path = Rails.root.join('lib', 'plugins', plugin.name.underscore, "#{plugin.name.underscore}.rb")
    
    if File.exist?(plugin_path)
      begin
        load plugin_path
        Rails.logger.info "Successfully loaded plugin: #{plugin.name}"
        true
      rescue => e
        Rails.logger.error "Failed to load plugin #{plugin.name}: #{e.message}"
        false
      end
    else
      Rails.logger.warn "Plugin file not found: #{plugin_path}"
      true # Don't fail if file doesn't exist yet
    end
  end
end
