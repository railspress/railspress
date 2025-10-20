module Api
  module V1
    class ChannelsController < BaseController
      before_action :set_channel, only: [:show, :update, :destroy]
      
      # GET /api/v1/channels
      def index
        channels = Channel.all.order(:name)
        
        render_success(
          channels.map { |channel| channel_serializer(channel) },
          { total: channels.count }
        )
      end
      
      # GET /api/v1/channels/:id
      def show
        render_success(channel_serializer(@channel, detailed: true))
      end
      
      # POST /api/v1/channels
      def create
        unless current_api_user&.can_manage_channels?
          return render_error('You do not have permission to create channels', :forbidden)
        end
        
        @channel = Channel.new(channel_params)
        
        if @channel.save
          render_success(channel_serializer(@channel), {}, :created)
        else
          render_error(@channel.errors.full_messages.join(', '))
        end
      end
      
      # PATCH/PUT /api/v1/channels/:id
      def update
        unless current_api_user&.can_manage_channels?
          return render_error('You do not have permission to update channels', :forbidden)
        end
        
        if @channel.update(channel_params)
          render_success(channel_serializer(@channel))
        else
          render_error(@channel.errors.full_messages.join(', '))
        end
      end
      
      # DELETE /api/v1/channels/:id
      def destroy
        unless current_api_user&.can_manage_channels?
          return render_error('You do not have permission to delete channels', :forbidden)
        end
        
        @channel.destroy
        render_success({ message: 'Channel deleted successfully' })
      end
      
      private
      
      def set_channel
        @channel = Channel.find(params[:id])
      end
      
      def channel_params
        params.require(:channel).permit(:name, :slug, :domain, :locale, :enabled, metadata: {}, settings: {})
      end
      
      def channel_serializer(channel, detailed: false)
        data = {
          id: channel.id,
          name: channel.name,
          slug: channel.slug,
          domain: channel.domain,
          locale: channel.locale,
          enabled: channel.enabled,
          metadata: channel.metadata,
          settings: channel.settings,
          created_at: channel.created_at,
          updated_at: channel.updated_at,
          content_stats: {
            posts_count: channel.posts.count,
            pages_count: channel.pages.count,
            media_count: channel.media.count
          },
          override_stats: {
            total_overrides: channel.channel_overrides.count,
            active_overrides: channel.channel_overrides.enabled.count,
            exclusions: channel.channel_overrides.exclusions.count,
            data_overrides: channel.channel_overrides.overrides.count
          }
        }
        
        if detailed
          data.merge!(
            overrides: channel.channel_overrides.includes(:resource).map do |override|
              {
                id: override.id,
                resource_type: override.resource_type,
                resource_id: override.resource_id,
                resource_name: override.resource_name,
                kind: override.kind,
                path: override.path,
                data: override.data,
                enabled: override.enabled,
                created_at: override.created_at,
                updated_at: override.updated_at
              }
            end
          )
        end
        
        data
      end
    end
  end
end
