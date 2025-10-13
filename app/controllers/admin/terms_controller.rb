class Admin::TermsController < Admin::BaseController
  before_action :set_taxonomy
  before_action :set_term, only: [:edit, :update, :destroy]

  # GET /admin/taxonomies/:taxonomy_id/terms
  def index
    @terms = @taxonomy.terms.includes(:parent, :children).order(name: :asc)
    @term = Term.new(taxonomy: @taxonomy)
  end

  # POST /admin/taxonomies/:taxonomy_id/terms
  def create
    @term = @taxonomy.terms.build(term_params)

    if @term.save
      redirect_to admin_taxonomy_terms_path(@taxonomy), notice: 'Term was successfully created.'
    else
      @terms = @taxonomy.terms.includes(:parent, :children).order(name: :asc)
      render :index, status: :unprocessable_entity
    end
  end

  # GET /admin/taxonomies/:taxonomy_id/terms/:id/edit
  def edit
  end

  # PATCH/PUT /admin/taxonomies/:taxonomy_id/terms/:id
  def update
    if @term.update(term_params)
      redirect_to admin_taxonomy_terms_path(@taxonomy), notice: 'Term was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/taxonomies/:taxonomy_id/terms/:id
  def destroy
    @term.destroy
    redirect_to admin_taxonomy_terms_path(@taxonomy), notice: 'Term was successfully deleted.'
  end

  private

  def set_taxonomy
    @taxonomy = Taxonomy.friendly.find(params[:taxonomy_id])
  end

  def set_term
    @term = @taxonomy.terms.friendly.find(params[:id])
  end

  def term_params
    params.require(:term).permit(:name, :slug, :description, :parent_id, metadata: {})
  end
end
