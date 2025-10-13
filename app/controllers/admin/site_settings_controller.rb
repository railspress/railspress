class Admin::SiteSettingsController < Admin::BaseController
  before_action :set_site_setting, only: %i[ show edit update destroy ]

  # GET /admin/site_settings or /admin/site_settings.json
  def index
    @site_settings = SiteSetting.all
  end

  # GET /admin/site_settings/1 or /admin/site_settings/1.json
  def show
  end

  # GET /admin/site_settings/new
  def new
    @site_setting = SiteSetting.new
  end

  # GET /admin/site_settings/1/edit
  def edit
  end

  # POST /admin/site_settings or /admin/site_settings.json
  def create
    @site_setting = SiteSetting.new(site_setting_params)

    respond_to do |format|
      if @site_setting.save
        format.html { redirect_to [:admin, @site_setting], notice: "Site setting was successfully created." }
        format.json { render :show, status: :created, location: @site_setting }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @site_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/site_settings/1 or /admin/site_settings/1.json
  def update
    respond_to do |format|
      if @site_setting.update(site_setting_params)
        format.html { redirect_to [:admin, @site_setting], notice: "Site setting was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @site_setting }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @site_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/site_settings/1 or /admin/site_settings/1.json
  def destroy
    @site_setting.destroy!

    respond_to do |format|
      format.html { redirect_to admin_site_settings_path, notice: "Site setting was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_site_setting
      @site_setting = SiteSetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def site_setting_params
      params.fetch(:site_setting, {})
    end
end
