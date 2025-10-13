module Api
  module V1
    class PagesController < BaseController
      before_action :set_page, only: [:show, :update, :destroy]
      
      # GET /api/v1/pages
      def index
        pages = Page.includes(:user, :children)
        
        # Filter by status
        pages = pages.where(status: params[:status]) if params[:status].present?
        
        # Filter by parent
        pages = pages.where(parent_id: params[:parent_id]) if params[:parent_id].present?
        
        # Root pages only
        pages = pages.root_pages if params[:root_only] == 'true'
        
        # Only published for non-authenticated or non-admin users
        unless current_api_user&.can_edit_others_posts?
          pages = pages.published
        end
        
        # Paginate
        @pages = paginate(pages.order(order: :asc, created_at: :desc))
        
        render_success(
          @pages.map { |page| page_serializer(page) },
          { filters: filter_meta }
        )
      end
      
      # GET /api/v1/pages/:id
      def show
        render_success(page_serializer(@page, detailed: true))
      end
      
      # POST /api/v1/pages
      def create
        unless current_api_user.can_publish?
          return render_error('You do not have permission to create pages', :forbidden)
        end
        
        @page = current_api_user.pages.build(page_params)
        
        if @page.save
          render_success(page_serializer(@page), {}, :created)
        else
          render_error(@page.errors.full_messages.join(', '))
        end
      end
      
      # PATCH/PUT /api/v1/pages/:id
      def update
        unless can_edit_page?
          return render_error('You do not have permission to edit this page', :forbidden)
        end
        
        if @page.update(page_params)
          render_success(page_serializer(@page))
        else
          render_error(@page.errors.full_messages.join(', '))
        end
      end
      
      # DELETE /api/v1/pages/:id
      def destroy
        unless current_api_user.can_delete_posts?
          return render_error('You do not have permission to delete pages', :forbidden)
        end
        
        @page.destroy
        render_success({ message: 'Page deleted successfully' })
      end
      
      private
      
      def set_page
        @page = Page.friendly.find(params[:id])
      end
      
      def can_edit_page?
        return true if current_api_user.can_edit_others_posts?
        @page.user_id == current_api_user.id
      end
      
      def page_params
        params.require(:page).permit(
          :title, :slug, :content, :status, :published_at,
          :parent_id, :order, :template, :meta_description, :meta_keywords
        )
      end
      
      def page_serializer(page, detailed: false)
        data = {
          id: page.id,
          title: page.title,
          slug: page.slug,
          status: page.status,
          order: page.order,
          template: page.template,
          published_at: page.published_at,
          created_at: page.created_at,
          updated_at: page.updated_at,
          author: {
            id: page.user.id,
            email: page.user.email
          },
          parent: page.parent ? { id: page.parent.id, title: page.parent.title, slug: page.parent.slug } : nil,
          children_count: page.children.count,
          breadcrumbs: page.breadcrumbs.map { |b| { title: b.title, slug: b.slug } },
          meta: {
            description: page.meta_description,
            keywords: page.meta_keywords
          },
          url: page_url(page.slug)
        }
        
        if detailed
          data.merge!(
            content: page.content.to_s,
            children: page.children.map { |c| { id: c.id, title: c.title, slug: c.slug } }
          )
        end
        
        data
      end
      
      def filter_meta
        {
          status: params[:status],
          parent_id: params[:parent_id],
          root_only: params[:root_only]
        }
      end
    end
  end
end





