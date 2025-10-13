class Admin::TagsController < Admin::BaseController
  before_action :set_taxonomy
  before_action :set_term, only: %i[ show edit update destroy ]

  # GET /admin/tags or /admin/tags.json
  def index
    @terms = @taxonomy.terms.includes(:term_relationships).order(:name)
    
    respond_to do |format|
      format.html
      format.json {
        render json: @terms.map { |term|
          {
            id: term.id,
            name: term.name,
            slug: term.slug,
            description: term.description,
            posts_count: term.term_relationships.where(object_type: 'Post').count,
            created_at: term.created_at.strftime('%B %d, %Y')
          }
        }
      }
    end
  end

  # GET /admin/tags/1 or /admin/tags/1.json
  def show
    @posts = Post.joins(:term_relationships)
                 .where(term_relationships: { term_id: @term.id })
                 .order(created_at: :desc)
                 .page(params[:page])
  end

  # GET /admin/tags/new
  def new
    @term = @taxonomy.terms.new
  end

  # GET /admin/tags/1/edit
  def edit
  end

  # POST /admin/tags or /admin/tags.json
  def create
    @term = @taxonomy.terms.new(term_params)

    respond_to do |format|
      if @term.save
        format.html { redirect_to admin_tag_path(@term), notice: "Tag was successfully created." }
        format.json { render :show, status: :created, location: admin_tag_path(@term) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @term.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/tags/1 or /admin/tags/1.json
  def update
    respond_to do |format|
      if @term.update(term_params)
        format.html { redirect_to admin_tag_path(@term), notice: "Tag was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: admin_tag_path(@term) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @term.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/tags/1 or /admin/tags/1.json
  def destroy
    @term.destroy!

    respond_to do |format|
      format.html { redirect_to admin_tags_path, notice: "Tag was successfully deleted.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Set the tag taxonomy
    def set_taxonomy
      @taxonomy = Taxonomy.find_by!(slug: 'tag')
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_taxonomies_path, alert: "Tag taxonomy not found. Please run seeds."
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_term
      @term = @taxonomy.terms.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_tags_path, alert: "Tag not found."
    end

    # Only allow a list of trusted parameters through.
    def term_params
      params.require(:term).permit(:name, :slug, :description, :meta)
    end
end
