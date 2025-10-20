module Api
  module V1
    class MediaController < BaseController
      before_action :set_medium, only: [:show, :update, :destroy]
      
      # GET /api/v1/media
      def index
        media = Medium.all
        
        # Filter by type
        # media = media.by_type(params[:type]) if params[:type].present? # Temporarily disabled
        
        # Filter by channel
        if params[:channel].present?
          channel = Channel.find_by(slug: params[:channel])
          if channel
            # Get media assigned to this channel or global media (no channel assignment)
            media = media.left_joins(:channels)
                         .where('channels.id = ? OR channels.id IS NULL', channel.id)
            
            # Apply channel exclusions
            excluded_media_ids = channel.channel_overrides
                                       .exclusions
                                       .enabled
                                       .where(resource_type: 'Medium')
                                       .pluck(:resource_id)
            media = media.where.not(id: excluded_media_ids) if excluded_media_ids.any?
            
            @current_channel = channel
          end
        end
        
        # Only published for non-authenticated or non-admin users
        # unless current_api_user&.can_edit_others_posts?
        #   media = media.where(status: 'approved')
        # end
        
        # Paginate
        @media = paginate(media.order(created_at: :desc))
        
        render_success(
          @media.map { |medium| medium_serializer(medium) },
          { filters: filter_meta }
        )
      end
      
      # GET /api/v1/media/:id
      def show
        # Set current channel if channel parameter is provided
        if params[:channel].present?
          @current_channel = Channel.find_by(slug: params[:channel])
        end
        
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
        # Get channel slugs for this medium
        channel_slugs = medium.channels.pluck(:slug)
        
        # Start with basic medium data
        medium_data = {
          id: medium.id,
          title: medium.title,
          file_name: medium.file_name,
          file_type: medium.file_type,
          channels: channel_slugs,
          channel_context: @current_channel&.slug
        }
        
        # Add detailed fields if requested
        if detailed
          medium_data.merge!({
            description: medium.description,
            alt_text: medium.alt_text,
            file_size: medium.file_size,
            created_at: medium.created_at,
            updated_at: medium.updated_at,
            url: medium.file_url if medium.respond_to?(:file_url)
          })
        end
        
        # Apply channel overrides if current channel is set
        if @current_channel
          original_data = medium_data.dup
          overridden_data, provenance = @current_channel.apply_overrides_to_data(
            original_data, 
            'Medium', 
            medium.id, 
            true
          )
          
          # Merge overridden data
          medium_data.merge!(overridden_data)
          
          # Add provenance information
          medium_data[:provenance] = provenance if provenance.present?
        end
        
        medium_data
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
