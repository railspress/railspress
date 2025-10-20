module Api
  module V1
    class PagesController < BaseController
      before_action :set_page, only: [:show, :update, :destroy]
      
      # GET /api/v1/pages
      def index
        pages = Page.all
        
        # Filter by status
        pages = pages.where(status: params[:status]) if params[:status].present?
        
        # Filter by parent
        pages = pages.where(parent_id: params[:parent_id]) if params[:parent_id].present?
        
        # Root pages only
        pages = pages.root_pages if params[:root_only] == 'true'
        
        # Filter by channel
        if params[:channel].present?
          channel = Channel.find_by(slug: params[:channel])
          if channel
            # Get pages assigned to this channel or global pages (no channel assignment)
            pages = pages.left_joins(:channels)
                         .where('channels.id = ? OR channels.id IS NULL', channel.id)
            
            # Apply channel exclusions
            excluded_page_ids = channel.channel_overrides
                                       .exclusions
                                       .enabled
                                       .where(resource_type: 'Page')
                                       .pluck(:resource_id)
            pages = pages.where.not(id: excluded_page_ids) if excluded_page_ids.any?
            
            @current_channel = channel
          end
        end
        
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
        # Set current channel if channel parameter is provided
        if params[:channel].present?
          @current_channel = Channel.find_by(slug: params[:channel])
        end
        
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
        # Get channel slugs for this page
        channel_slugs = page.channels.pluck(:slug)
        
        # Start with basic page data
        page_data = {
          id: page.id,
          title: page.title,
          slug: page.slug,
          status: page.status,
          channels: channel_slugs,
          channel_context: @current_channel&.slug
        }
        
        # Add detailed fields if requested
        if detailed
          page_data.merge!({
            content: page.content,
            published_at: page.published_at,
            parent_id: page.parent_id,
            order: page.order,
            template: page.template,
            created_at: page.created_at,
            updated_at: page.updated_at,
            url: Rails.application.routes.url_helpers.page_url(page, host: request.host)
          })
        end
        
        # Apply channel overrides if current channel is set
        if @current_channel
          original_data = page_data.dup
          overridden_data, provenance = @current_channel.apply_overrides_to_data(
            original_data, 
            'Page', 
            page.id, 
            true
          )
          
          # Merge overridden data
          page_data.merge!(overridden_data)
          
          # Add provenance information
          page_data[:provenance] = provenance if provenance.present?
        end
        
        page_data
      end
      
      def filter_meta
        {
          status: params[:status],
          parent_id: params[:parent_id],
          root_only: params[:root_only],
          channel: params[:channel]
        }
      end
    end
  end
end





