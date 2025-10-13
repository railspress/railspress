module Api
  module V1
    class CategoriesController < BaseController
      skip_before_action :authenticate_api_user!, only: [:index, :show]
      before_action :set_category, only: [:show, :update, :destroy]
      
      # GET /api/v1/categories
      def index
        categories = Term.for_taxonomy('category').includes(:term_relationships, :children)
        
        # Filter by parent
        categories = categories.where(parent_id: params[:parent_id]) if params[:parent_id].present?
        categories = categories.root_terms if params[:root_only] == 'true'
        
        # Search
        categories = categories.where('name LIKE ?', "%#{params[:q]}%") if params[:q].present?
        
        @categories = paginate(categories.ordered)
        
        render_success(
          @categories.map { |cat| category_serializer(cat) }
        )
      end
      
      # GET /api/v1/categories/:id
      def show
        render_success(category_serializer(@category, detailed: true))
      end
      
      # POST /api/v1/categories
      def create
        unless current_api_user.can_edit_others_posts?
          return render_error('You do not have permission to create categories', :forbidden)
        end
        
        @category = Term.new(category_params.merge(taxonomy: Taxonomy.categories))
        
        if @category.save
          render_success(category_serializer(@category), {}, :created)
        else
          render_error(@category.errors.full_messages.join(', '))
        end
      end
      
      # PATCH/PUT /api/v1/categories/:id
      def update
        unless current_api_user.can_edit_others_posts?
          return render_error('You do not have permission to edit categories', :forbidden)
        end
        
        if @category.update(category_params)
          render_success(category_serializer(@category))
        else
          render_error(@category.errors.full_messages.join(', '))
        end
      end
      
      # DELETE /api/v1/categories/:id
      def destroy
        unless current_api_user.administrator?
          return render_error('Only administrators can delete categories', :forbidden)
        end
        
        @category.destroy
        render_success({ message: 'Category deleted successfully' })
      end
      
      private
      
      def set_category
        @category = Term.for_taxonomy('category').friendly.find(params[:id])
      end
      
      def category_params
        params.require(:category).permit(:name, :slug, :description, :parent_id)
      end
      
      def category_serializer(category, detailed: false)
        data = {
          id: category.id,
          name: category.name,
          slug: category.slug,
          description: category.description,
          post_count: category.post_count,
          parent: category.parent ? { id: category.parent.id, name: category.parent.name, slug: category.parent.slug } : nil,
          children_count: category.children.count,
          url: category_url(category.slug)
        }
        
        if detailed
          data.merge!(
            children: category.children.map { |c| { id: c.id, name: c.name, slug: c.slug } },
            recent_posts: category.posts.published.recent.limit(5).map { |p| 
              { id: p.id, title: p.title, slug: p.slug, published_at: p.published_at }
            }
          )
        end
        
        data
      end
    end
  end
end



