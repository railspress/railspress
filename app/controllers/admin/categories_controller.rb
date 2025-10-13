class Admin::CategoriesController < Admin::BaseController
  before_action :set_taxonomy
  before_action :set_term, only: %i[ show edit update destroy ]

  # GET /admin/categories or /admin/categories.json
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
            parent_id: term.parent_id,
            parent_name: term.parent&.name,
            created_at: term.created_at.strftime('%B %d, %Y')
          }
        }
      }
    end
  end

  # GET /admin/categories/1 or /admin/categories/1.json
  def show
    @posts = Post.joins(:term_relationships)
                 .where(term_relationships: { term_id: @term.id })
                 .order(created_at: :desc)
                 .page(params[:page])
  end

  # GET /admin/categories/new
  def new
    @term = @taxonomy.terms.new
    @parent_categories = @taxonomy.terms.where(parent_id: nil).order(:name)
  end

  # GET /admin/categories/1/edit
  def edit
    @parent_categories = @taxonomy.terms.where(parent_id: nil).where.not(id: @term.id).order(:name)
  end

  # POST /admin/categories or /admin/categories.json
  def create
    @term = @taxonomy.terms.new(term_params)

    respond_to do |format|
      if @term.save
        format.html { redirect_to admin_category_path(@term), notice: "Category was successfully created." }
        format.json { render :show, status: :created, location: admin_category_path(@term) }
      else
        @parent_categories = @taxonomy.terms.where(parent_id: nil).order(:name)
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @term.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/categories/1 or /admin/categories/1.json
  def update
    respond_to do |format|
      if @term.update(term_params)
        format.html { redirect_to admin_category_path(@term), notice: "Category was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: admin_category_path(@term) }
      else
        @parent_categories = @taxonomy.terms.where(parent_id: nil).where.not(id: @term.id).order(:name)
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @term.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/categories/1 or /admin/categories/1.json
  def destroy
    # Check if category has posts
    posts_count = @term.term_relationships.where(object_type: 'Post').count
    
    if posts_count > 0 && @term.slug == 'uncategorized'
      respond_to do |format|
        format.html { redirect_to admin_categories_path, alert: "Cannot delete the Uncategorized category.", status: :see_other }
        format.json { render json: { error: "Cannot delete default category" }, status: :unprocessable_entity }
      end
      return
    end

    # Move posts to Uncategorized if deleting non-default category
    if posts_count > 0
      uncategorized = @taxonomy.terms.find_by(slug: 'uncategorized')
      @term.term_relationships.where(object_type: 'Post').each do |rel|
        rel.update(term_id: uncategorized.id) if uncategorized
      end
    end

    @term.destroy!

    respond_to do |format|
      format.html { redirect_to admin_categories_path, notice: "Category was successfully deleted.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Set the category taxonomy
    def set_taxonomy
      @taxonomy = Taxonomy.find_by!(slug: 'category')
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_taxonomies_path, alert: "Category taxonomy not found. Please run seeds."
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_term
      @term = @taxonomy.terms.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_categories_path, alert: "Category not found."
    end

    # Only allow a list of trusted parameters through.
    def term_params
      params.require(:term).permit(:name, :slug, :description, :parent_id, :meta)
    end
end
