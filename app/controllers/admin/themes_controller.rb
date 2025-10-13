class Admin::ThemesController < Admin::BaseController
  before_action :ensure_admin, only: [:activate, :destroy]

  # GET /admin/themes
  def index
    @active_theme = Theme.active.first
    @available_themes = Railspress::ThemeLoader.available_themes
    @installed_themes = Theme.all
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
    theme_name = params[:theme_name] || params[:id]
    theme_display_name = theme_name.titleize
    
    if Railspress::ThemeLoader.activate_theme(theme_name)
      flash[:notice] = "✓ Theme '#{theme_display_name}' activated successfully! View your frontend to see the changes."
      redirect_to admin_themes_path
    else
      flash[:alert] = "✗ Failed to activate theme '#{theme_display_name}'. Please check the theme files."
      redirect_to admin_themes_path
    end
  end

  # GET /admin/themes/preview?theme=theme_name
  def preview
    @theme_name = params[:theme]
    @theme_config = load_theme_config(@theme_name)
    
    render layout: false
  end

  private

  def theme_params
    params.require(:theme).permit(:name, :description, :author, :version, :active, :settings)
  end

  def load_theme_config(theme_name)
    config_path = Rails.root.join('app', 'themes', theme_name, 'config.yml')
    File.exist?(config_path) ? YAML.load_file(config_path) : {}
  end
end
