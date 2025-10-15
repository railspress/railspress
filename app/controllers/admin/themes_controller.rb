class Admin::ThemesController < Admin::BaseController
  before_action :ensure_admin, only: [:activate, :destroy, :sync]
  before_action :set_themes_manager

  # GET /admin/themes
  def index
    # Auto-sync themes from filesystem if none exist or if filesystem has themes not in database
    filesystem_themes = Dir.glob(File.join(Rails.root, 'app', 'themes', '*')).map { |dir| File.basename(dir) }
    database_themes = Theme.pluck(:slug)
    
    if Theme.count == 0 || filesystem_themes.any? { |theme| !database_themes.include?(theme) }
      Rails.logger.info "Auto-syncing themes from filesystem..."
      @themes_manager.sync_themes
    end
    
    @active_theme = Theme.active.first
    @installed_themes = Theme.all.order(:name)
    
    # Convert Theme objects to hash structure expected by the view
    @available_themes = @installed_themes.map do |theme|
      {
        id: theme.id,
        name: theme.name,
        display_name: theme.name,
        description: theme.description || "No description available",
        author: theme.author || "Unknown",
        version: theme.version || "1.0.0",
        active: theme.active
      }
    end
  end

  # GET /admin/themes/1
  def show
    @theme = Theme.find(params[:id])
  end

  # GET /admin/themes/new
  def new
    @theme = Theme.new
  end

  # GET /admin/themes/1/edit
  def edit
    @theme = Theme.find(params[:id])
  end

  # POST /admin/themes
  def create
    @theme = Theme.new(theme_params)

    respond_to do |format|
      if @theme.save
        format.html { redirect_to admin_themes_path, notice: "Theme was successfully created." }
        format.json { render :show, status: :created, location: @theme }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @theme.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/themes/1
  def update
    @theme = Theme.find(params[:id])

    respond_to do |format|
      if @theme.update(theme_params)
        format.html { redirect_to admin_themes_path, notice: "Theme was successfully updated." }
        format.json { render :show, status: :ok, location: @theme }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @theme.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/themes/1
  def destroy
    @theme = Theme.find(params[:id])
    
    if @theme.active?
      redirect_to admin_themes_path, alert: "Cannot delete active theme."
    else
      @theme.destroy
      redirect_to admin_themes_path, notice: "Theme was successfully deleted."
    end
  end

  # PATCH /admin/themes/1/activate
  def activate
    @theme = Theme.find(params[:id])
    
    if @theme.activate!
      flash[:notice] = "✓ Theme '#{@theme.name}' activated successfully! View your frontend to see the changes."
    else
      flash[:alert] = "✗ Failed to activate theme '#{@theme.name}'. Please check the theme files."
    end
    
    redirect_to admin_themes_path
  end
  
  # POST /admin/themes/sync
  def sync
    synced_count = @themes_manager.sync_themes
    
    if synced_count > 0
      flash[:notice] = "✓ Synced #{synced_count} themes from filesystem to database."
    else
      flash[:info] = "All themes are already up to date."
    end
    
    redirect_to admin_themes_path
  end


  # GET /admin/themes/:id/load_customizer
  def load_customizer
    theme = Theme.find(params[:id])
    
    # Only sync if no published version exists
    unless theme.published_version
      @themes_manager.sync_theme(theme.slug)
      theme.reload
    end
    
    # Ensure published version exists
    theme.ensure_published_version_exists!
    
    # Find or create BuilderTheme
    builder_theme = BuilderTheme.current_for_theme(theme.name.underscore)
    
    if builder_theme
      redirect_to admin_builder_path(builder_theme)
    else
      redirect_to admin_builder_index_path(theme_name: theme.name)
    end
  end

  # GET /admin/themes/:id/load_preview
  def load_preview
    theme = Theme.find(params[:id])
    
    # Only sync if no published version exists
    unless theme.published_version
      @themes_manager.sync_theme(theme.slug)
      theme.reload
    end
    
    # Ensure published version exists
    theme.ensure_published_version_exists!
    
    # Redirect to preview
    redirect_to preview_admin_themes_path(id: theme.id)
  end

  # GET /admin/themes/preview?id=theme_id
  def preview
    @theme_id = params[:id]
    @theme = Theme.find(@theme_id)
    @theme_name = @theme.name
    @theme_config = load_theme_config(@theme_name)
    
    # Ensure theme has a published version
    @theme.ensure_published_version_exists!
    published_version = @theme.published_version
    
    # If still no published version, create one
    unless published_version
      @theme.ensure_published_version_exists!
      published_version = @theme.published_version
    end
    
    if published_version
      # Use FrontendRendererService for proper rendering
      renderer = FrontendRendererService.new(published_version)
      template_type = params[:template] || 'index'
      
      begin
        @preview_html = renderer.render_template(template_type, preview_context)
        @assets = renderer.assets
      rescue => e
        Rails.logger.error "Theme preview rendering failed: #{e.message}"
        @preview_html = "<div style='padding: 20px; color: red;'>Preview Error: #{e.message}</div>"
        @assets = { css: '', js: '' }
      end
    else
      @preview_html = "<div style='padding: 20px; color: red;'>No published version found for #{@theme_name}</div>"
      @assets = { css: '', js: '' }
    end
    
    render 'preview', layout: false
  end

  private

  def set_themes_manager
    @themes_manager = ThemesManager.new
  end

  def theme_params
    params.require(:theme).permit(:name, :description, :version, :active, :config)
  end

  def load_theme_config(theme_name)
    theme = Theme.find_by(name: theme_name)
    return {} unless theme
    
    config_path = Rails.root.join('app', 'themes', theme.slug, 'config', 'theme.json')
    if File.exist?(config_path)
      JSON.parse(File.read(config_path))
    else
      {}
    end
  rescue JSON::ParserError
    {}
  end
  
  def preview_context
    {
      # Page context
      'page' => {
        'title' => 'Theme Preview',
        'description' => 'Preview of the theme',
        'url' => '/preview',
        'seo_title' => 'Theme Preview - RailsPress',
        'meta_description' => 'Preview of the selected theme',
        'template' => 'index'
      },
      
      # Site context
      'site' => {
        'title' => 'RailsPress Site',
        'description' => 'A sample RailsPress site',
        'url' => 'https://example.com',
        'name' => 'RailsPress Site',
        'tagline' => 'Built with Rails'
      },
      
      # Sample content
      'posts' => [],
      'pages' => [],
      'current_user' => nil,
      'settings' => {},
      'theme_settings' => {}
    }
  end
end
