class Admin::ContentTypesController < Admin::BaseController
  before_action :set_content_type, only: %i[ show edit update destroy ]
  before_action :ensure_admin

  # GET /admin/content_types or /admin/content_types.json
  def index
    @content_types = ContentType.all.ordered
    
    respond_to do |format|
      format.html
      format.json { render json: content_types_json }
    end
  end

  # GET /admin/content_types/1 or /admin/content_types/1.json
  def show
  end

  # GET /admin/content_types/new
  def new
    @content_type = ContentType.new
  end

  # GET /admin/content_types/1/edit
  def edit
  end

  # POST /admin/content_types or /admin/content_types.json
  def create
    @content_type = ContentType.new(content_type_params)

    respond_to do |format|
      if @content_type.save
        format.html { redirect_to admin_content_types_path, notice: "Content type was successfully created." }
        format.json { render :show, status: :created, location: [:admin, @content_type] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @content_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/content_types/1 or /admin/content_types/1.json
  def update
    respond_to do |format|
      if @content_type.update(content_type_params)
        format.html { redirect_to admin_content_types_path, notice: "Content type was successfully updated." }
        format.json { render :show, status: :ok, location: [:admin, @content_type] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @content_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/content_types/1 or /admin/content_types/1.json
  def destroy
    # Don't allow deletion of default 'post' type
    if @content_type.ident == 'post'
      respond_to do |format|
        format.html { redirect_to admin_content_types_path, alert: "Cannot delete the default 'post' content type." }
        format.json { render json: { error: "Cannot delete default content type" }, status: :unprocessable_entity }
      end
      return
    end
    
    @content_type.destroy!

    respond_to do |format|
      format.html { redirect_to admin_content_types_path, notice: "Content type was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_content_type
      @content_type = ContentType.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def content_type_params
      params.require(:content_type).permit(
        :ident, :label, :singular, :plural, :description, :icon,
        :public, :hierarchical, :has_archive, :menu_position,
        :rest_base, :active,
        supports: [], capabilities: {}
      )
    end
    
    def content_types_json
      @content_types.map do |ct|
        {
          id: ct.id,
          ident: ct.ident,
          label: ct.label,
          singular: ct.singular,
          plural: ct.plural,
          icon: ct.icon,
          public: ct.public,
          hierarchical: ct.hierarchical,
          has_archive: ct.has_archive,
          posts_count: ct.posts.count,
          active: ct.active,
          created_at: ct.created_at.strftime("%Y-%m-%d %H:%M")
        }
      end
    end
    
    def ensure_admin
      unless current_user&.administrator?
        redirect_to admin_root_path, alert: 'You do not have permission to manage content types.'
      end
    end
end

