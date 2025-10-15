module Api
  module V1
    class TaxonomiesController < BaseController
      skip_before_action :authenticate_api_user!, only: [:index, :show, :terms]
      before_action :set_taxonomy, only: [:show, :update, :destroy, :terms]
      
      # GET /api/v1/taxonomies
      def index
        taxonomies = Taxonomy.all
        
        # Filter by object type
        taxonomies = taxonomies.where("object_types LIKE ?", "%#{params[:object_type]}%") if params[:object_type].present?
        
        # Filter by type
        case params[:type]
        when 'hierarchical'
          taxonomies = taxonomies.hierarchical
        when 'flat'
          taxonomies = taxonomies.flat
        end
        
        @taxonomies = paginate(taxonomies.order(:name))
        
        render_success(
          @taxonomies.map { |taxonomy| taxonomy_serializer(taxonomy) }
        )
      end
      
      # GET /api/v1/taxonomies/:id
      def show
        render_success(taxonomy_serializer(@taxonomy, detailed: true))
      end
      
      # GET /api/v1/taxonomies/:id/terms
      def terms
        terms = @taxonomy.terms.includes(:parent, :children)
        
        # Root terms only
        terms = terms.root_terms if params[:root_only] == 'true'
        
        @terms = paginate(terms.ordered)
        
        render_success(
          @terms.map { |term| term_serializer(term) }
        )
      end
      
      # POST /api/v1/taxonomies
      def create
        unless current_api_user.administrator?
          return render_error('Only administrators can create taxonomies', :forbidden)
        end
        
        @taxonomy = Taxonomy.new(taxonomy_params)
        
        if @taxonomy.save
          render_success(taxonomy_serializer(@taxonomy), {}, :created)
        else
          render_error(@taxonomy.errors.full_messages.join(', '))
        end
      end
      
      # PATCH/PUT /api/v1/taxonomies/:id
      def update
        unless current_api_user.administrator?
          return render_error('Only administrators can update taxonomies', :forbidden)
        end
        
        if @taxonomy.update(taxonomy_params)
          render_success(taxonomy_serializer(@taxonomy))
        else
          render_error(@taxonomy.errors.full_messages.join(', '))
        end
      end
      
      # DELETE /api/v1/taxonomies/:id
      def destroy
        unless current_api_user.administrator?
          return render_error('Only administrators can delete taxonomies', :forbidden)
        end
        
        @taxonomy.destroy
        render_success({ message: 'Taxonomy deleted successfully' })
      end
      
      private
      
      def set_taxonomy
        @taxonomy = Taxonomy.friendly.find(params[:id])
      end
      
      def taxonomy_params
        params.require(:taxonomy).permit(:name, :slug, :description, :hierarchical, object_types: [], settings: {})
      end
      
      def taxonomy_serializer(taxonomy, detailed: false)
        data = {
          id: taxonomy.id,
          name: taxonomy.name,
          slug: taxonomy.slug,
          description: taxonomy.description,
          hierarchical: taxonomy.hierarchical?,
          object_types: taxonomy.object_types,
          term_count: taxonomy.term_count
        }
        
        if detailed
          data.merge!(
            terms: taxonomy.root_terms.map { |term| term_serializer(term) },
            settings: taxonomy.settings
          )
        end
        
        data
      end
      
      def term_serializer(term)
        {
          id: term.id,
          name: term.name,
          slug: term.slug,
          description: term.description,
          count: term.count,
          parent_id: term.parent_id,
          parent: term.parent ? { id: term.parent.id, name: term.parent.name } : nil,
          children_count: term.children.count
        }
      end
    end
  end
end








