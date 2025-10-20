module Api
  module V1
    class MediaController < BaseController
      before_action :set_medium, only: [:show, :update, :destroy]
      
      # GET /api/v1/media
      def index
        media = Medium.all
        
        # Filter by type
        media = media.by_type(params[:type]) if params[:type].present?
        
        # Filter by channel
        if params[:channel].present?
          channel = Channel.find_by(slug: params[:channel])
          if channel
            # Get media assigned to this channel or global media (no channel assignment)
            # media = media.left_joins(:channels)
            #              .where('channels.id = ? OR channels.id IS NULL', channel.id)
            
            # Apply channel exclusions
            # excluded_media_ids = channel.channel_overrides
            #                            .exclusions
            #                            .enabled
            #                            .where(resource_type: 'Medium')
            #                            .pluck(:resource_id)
            # media = media.where.not(id: excluded_media_ids) if excluded_media_ids.any?
            
            @current_channel = channel
          end
        end
        
        # Only published for non-authenticated or non-admin users
        unless current_api_user&.can_edit_others_posts?
          media = media.where(status: 'approved')
        end
        
        # Paginate
        @media = paginate(media.order(created_at: :desc))
        
        render_success(
          @media.map { |medium| medium_serializer(medium) },
          { filters: filter_meta }
        )
      end
      
      # GET /api/v1/media/:id
      def show
        render_success(medium_serializer(@medium, detailed: true))
      end
      
      # POST /api/v1/media
      def create
        unless current_api_user&.can_edit_others_posts?
          return render_error('You do not have permission to create media', :forbidden)
        end
        
        @medium = current_api_user.media.build(medium_params)
        
        if @medium.save
          render_success(medium_serializer(@medium), {}, :created)
        else
          render_error(@medium.errors.full_messages.join(', '))
        end
      end
      
      # PATCH/PUT /api/v1/media/:id
      def update
        unless current_api_user&.can_edit_others_posts?
          return render_error('You do not have permission to edit media', :forbidden)
        end
        
        if @medium.update(medium_params)
          render_success(medium_serializer(@medium))
        else
          render_error(@medium.errors.full_messages.join(', '))
        end
      end
      
      # DELETE /api/v1/media/:id
      def destroy
        unless current_api_user&.can_edit_others_posts?
          return render_error('You do not have permission to delete media', :forbidden)
        end
        
        @medium.destroy
        render_success({ message: 'Media deleted successfully' })
      end
      
      private
      
      def set_medium
        @medium = Medium.find(params[:id])
      end
      
      def medium_params
        params.require(:medium).permit(
          :title, :description, :file, :alt_text, :status
        )
      end
      
      def medium_serializer(medium, detailed: false)
        {
          id: medium.id,
          title: medium.title,
          description: medium.description,
          status: medium.status,
          created_at: medium.created_at,
          updated_at: medium.updated_at
        }
      end
      
      def filter_meta
        {
          type: params[:type],
          channel: params[:channel]
        }
      end
    end
  end
end

