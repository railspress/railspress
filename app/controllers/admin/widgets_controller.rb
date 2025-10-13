class Admin::WidgetsController < Admin::BaseController
  before_action :set_widget, only: %i[ show edit update destroy ]

  # GET /admin/widgets or /admin/widgets.json
  def index
    @widgets = Widget.all
  end

  # GET /admin/widgets/1 or /admin/widgets/1.json
  def show
  end

  # GET /admin/widgets/new
  def new
    @widget = Widget.new
  end

  # GET /admin/widgets/1/edit
  def edit
  end

  # POST /admin/widgets or /admin/widgets.json
  def create
    @widget = Widget.new(widget_params)

    respond_to do |format|
      if @widget.save
        format.html { redirect_to [:admin, @widget], notice: "Widget was successfully created." }
        format.json { render :show, status: :created, location: @widget }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @widget.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/widgets/1 or /admin/widgets/1.json
  def update
    respond_to do |format|
      if @widget.update(widget_params)
        format.html { redirect_to [:admin, @widget], notice: "Widget was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @widget }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @widget.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/widgets/1 or /admin/widgets/1.json
  def destroy
    @widget.destroy!

    respond_to do |format|
      format.html { redirect_to admin_widgets_path, notice: "Widget was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_widget
      @widget = Widget.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def widget_params
      params.fetch(:widget, {})
    end
end
