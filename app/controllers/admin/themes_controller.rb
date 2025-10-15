class Admin::ThemesController < Admin::BaseController
  before_action :ensure_admin, only: [:activate, :destroy, :sync]
  before_action :set_themes_manager

  # GET /admin/themes
  def index
    # Sync themes from filesystem to database
    @themes_manager.sync_themes
    
    @active_theme = Theme.active.first
    @installed_themes = Theme.all.order(:name)
    @available_themes = @installed_themes
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
    # Handle both ID and theme name/slug
    if params[:id].match?(/\A\d+\z/)
      @theme = Theme.find(params[:id])
    else
      # Try to find by slug first, then by name
      @theme = Theme.find_by(slug: params[:id]) || Theme.find_by(name: params[:id])
    end
    
    unless @theme
      flash[:alert] = "✗ Theme not found."
      redirect_to admin_themes_path
      return
    end
    
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

  # GET /admin/themes/preview?theme=theme_name
  def preview
    @theme_name = params[:theme]
    @theme_config = load_theme_config(@theme_name)
    
    render layout: false
  end

  private

  def set_themes_manager
    @themes_manager = ThemesManager.new
  end

  def theme_params
    params.require(:theme).permit(:name, :description, :version, :active, :config)
  end

  def load_theme_config(theme_name)
    config_path = Rails.root.join('app', 'themes', theme_name, 'config.yml')
    File.exist?(config_path) ? YAML.load_file(config_path) : {}
  end
end
