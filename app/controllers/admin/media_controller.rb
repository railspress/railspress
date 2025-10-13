class Admin::MediaController < Admin::BaseController
  before_action :set_medium, only: %i[ show edit update destroy ]

  # GET /admin/media or /admin/media.json
  def index
    @media = Medium.all
  end

  # GET /admin/media/1 or /admin/media/1.json
  def show
  end

  # GET /admin/media/new
  def new
    @medium = Medium.new
  end

  # GET /admin/media/1/edit
  def edit
  end

  # POST /admin/media or /admin/media.json
  def create
    @medium = Medium.new(medium_params)

    respond_to do |format|
      if @medium.save
        format.html { redirect_to [:admin, @medium], notice: "Medium was successfully created." }
        format.json { render :show, status: :created, location: @medium }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @medium.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/media/1 or /admin/media/1.json
  def update
    respond_to do |format|
      if @medium.update(medium_params)
        format.html { redirect_to [:admin, @medium], notice: "Medium was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @medium }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @medium.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/media/1 or /admin/media/1.json
  def destroy
    @medium.destroy!

    respond_to do |format|
      format.html { redirect_to admin_media_path, notice: "Medium was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_medium
      @medium = Medium.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def medium_params
      params.fetch(:medium, {})
    end
end
