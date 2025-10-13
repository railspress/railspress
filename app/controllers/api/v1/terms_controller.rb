module Api
  module V1
    class TermsController < BaseController
      skip_before_action :authenticate_api_user!, only: [:index, :show]
      before_action :set_taxonomy, except: [:index, :show]
      before_action :set_term, only: [:show, :update, :destroy]
      
      # GET /api/v1/terms
      def index
        terms = Term.includes(:taxonomy, :parent)
        
        # Filter by taxonomy
        terms = terms.for_taxonomy(params[:taxonomy]) if params[:taxonomy].present?
        
        # Search
        terms = terms.where('name LIKE ?', "%#{params[:q]}%") if params[:q].present?
        
        @terms = paginate(terms.ordered)
        
        render_success(
          @terms.map { |term| term_serializer(term) }
        )
      end
      
      # GET /api/v1/terms/:id
      def show
        render_success(term_serializer(@term, detailed: true))
      end
      
      # POST /api/v1/taxonomies/:taxonomy_id/terms
      def create
        unless current_api_user.can_edit_others_posts?
          return render_error('You do not have permission to create terms', :forbidden)
        end
        
        @term = @taxonomy.terms.build(term_params)
        
        if @term.save
          render_success(term_serializer(@term), {}, :created)
        else
          render_error(@term.errors.full_messages.join(', '))
        end
      end
      
      # PATCH/PUT /api/v1/taxonomies/:taxonomy_id/terms/:id
      def update
        unless current_api_user.can_edit_others_posts?
          return render_error('You do not have permission to update terms', :forbidden)
        end
        
        if @term.update(term_params)
          render_success(term_serializer(@term))
        else
          render_error(@term.errors.full_messages.join(', '))
        end
      end
      
      # DELETE /api/v1/taxonomies/:taxonomy_id/terms/:id
      def destroy
        unless current_api_user.administrator?
          return render_error('Only administrators can delete terms', :forbidden)
        end
        
        @term.destroy
        render_success({ message: 'Term deleted successfully' })
      end
      
      private
      
      def set_taxonomy
        @taxonomy = Taxonomy.friendly.find(params[:taxonomy_id])
      end
      
      def set_term
        if params[:taxonomy_id]
          @term = @taxonomy.terms.friendly.find(params[:id])
        else
          @term = Term.friendly.find(params[:id])
        end
      end
      
      def term_params
        params.require(:term).permit(:name, :slug, :description, :parent_id, metadata: {})
      end
      
      def term_serializer(term, detailed: false)
        data = {
          id: term.id,
          name: term.name,
          slug: term.slug,
          description: term.description,
          count: term.count,
          taxonomy: {
            id: term.taxonomy.id,
            name: term.taxonomy.name,
            slug: term.taxonomy.slug
          },
          parent: term.parent ? { id: term.parent.id, name: term.parent.name, slug: term.parent.slug } : nil,
          children_count: term.children.count
        }
        
        if detailed
          data.merge!(
            children: term.children.map { |c| { id: c.id, name: c.name, slug: c.slug } },
            breadcrumbs: term.breadcrumbs.map { |b| { id: b.id, name: b.name, slug: b.slug } },
            metadata: term.metadata
          )
        end
        
        data
      end
    end
  end
end






