class Admin::TaxonomiesController < Admin::BaseController
  before_action :set_taxonomy, only: [:show, :edit, :update, :destroy]

  # GET /admin/taxonomies
  def index
    @taxonomies = Taxonomy.all.order(created_at: :desc)
  end

  # GET /admin/taxonomies/:id
  def show
    @terms = @taxonomy.terms.includes(:parent, :children).order(name: :asc)
  end

  # GET /admin/taxonomies/new
  def new
    @taxonomy = Taxonomy.new
  end

  # GET /admin/taxonomies/:id/edit
  def edit
  end

  # POST /admin/taxonomies
  def create
    @taxonomy = Taxonomy.new(taxonomy_params)

    if @taxonomy.save
      redirect_to admin_taxonomies_path, notice: 'Taxonomy was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/taxonomies/:id
  def update
    if @taxonomy.update(taxonomy_params)
      redirect_to admin_taxonomy_path(@taxonomy), notice: 'Taxonomy was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/taxonomies/:id
  def destroy
    @taxonomy.destroy
    redirect_to admin_taxonomies_path, notice: 'Taxonomy was successfully deleted.'
  end

  private

  def set_taxonomy
    @taxonomy = Taxonomy.friendly.find(params[:id])
  end

  def taxonomy_params
    params.require(:taxonomy).permit(:name, :slug, :description, :hierarchical, object_types: [], settings: {})
  end
end
