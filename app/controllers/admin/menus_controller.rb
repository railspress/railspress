class Admin::MenusController < Admin::BaseController
  before_action :set_menu, only: %i[ show edit update destroy ]

  # GET /admin/menus or /admin/menus.json
  def index
    @menus = Menu.all
  end

  # GET /admin/menus/1 or /admin/menus/1.json
  def show
  end

  # GET /admin/menus/new
  def new
    @menu = Menu.new
  end

  # GET /admin/menus/1/edit
  def edit
  end

  # POST /admin/menus or /admin/menus.json
  def create
    @menu = Menu.new(menu_params)

    respond_to do |format|
      if @menu.save
        format.html { redirect_to [:admin, @menu], notice: "Menu was successfully created." }
        format.json { render :show, status: :created, location: @menu }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @menu.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/menus/1 or /admin/menus/1.json
  def update
    respond_to do |format|
      if @menu.update(menu_params)
        format.html { redirect_to [:admin, @menu], notice: "Menu was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @menu }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @menu.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/menus/1 or /admin/menus/1.json
  def destroy
    @menu.destroy!

    respond_to do |format|
      format.html { redirect_to admin_menus_path, notice: "Menu was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_menu
      @menu = Menu.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def menu_params
      params.fetch(:menu, {})
    end
end
