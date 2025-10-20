module Admin
  module System
    class ChannelsController < Admin::BaseController
      before_action :set_channel, only: [:show, :edit, :update, :destroy]

      def index
        @channels = Channel.all.order(:name)
        
        respond_to do |format|
          format.html do
            @channels_data = channels_json
            @stats = {
              total: Channel.count,
              active: Channel.active.count,
              overrides: ChannelOverride.count,
              content_items: Post.count + Page.count + Medium.count
            }
            @bulk_actions = [
              { value: 'enable', label: 'Enable Channels' },
              { value: 'disable', label: 'Disable Channels' },
              { value: 'delete', label: 'Delete Channels' }
            ]
            @status_options = [
              { value: 'enabled', label: 'Enabled' },
              { value: 'disabled', label: 'Disabled' }
            ]
            @columns = [
              {
                title: "",
                formatter: "rowSelection",
                titleFormatter: "rowSelection",
                width: 40,
                headerSort: false
              },
              {
                title: "Name",
                field: "name",
                width: 200,
                formatter: "html"
              },
              {
                title: "Slug",
                field: "slug",
                width: 120
              },
              {
                title: "Domain",
                field: "domain",
                width: 150
              },
              {
                title: "Locale",
                field: "locale",
                width: 80
              },
              {
                title: "Status",
                field: "status",
                width: 100,
                formatter: "html"
              },
              {
                title: "Content",
                field: "content_counts",
                width: 150,
                formatter: "html"
              },
              {
                title: "Overrides",
                field: "overrides_count",
                width: 100
              },
              {
                title: "Created",
                field: "created_at",
                width: 150,
                formatter: "datetime",
                formatterParams: {
                  inputFormat: "YYYY-MM-DDTHH:mm:ss.SSSZ",
                  outputFormat: "DD/MM/YYYY HH:mm"
                }
              },
              {
                title: "Actions",
                field: "actions",
                width: 120,
                headerSort: false,
                formatter: "html"
              }
            ]
          end
          format.json { render json: channels_json }
        end
      end

      def show
        @overrides = @channel.channel_overrides.includes(:resource).order(:resource_type, :path)
      end

      def new
        @channel = Channel.new
      end

      def create
        @channel = Channel.new(channel_params)

        if @channel.save
          redirect_to admin_system_channel_path(@channel), notice: 'Channel was successfully created.'
        else
          render :new
        end
      end

      def edit
      end

      def update
        if @channel.update(channel_params)
          redirect_to admin_system_channel_path(@channel), notice: 'Channel was successfully updated.'
        else
          render :edit
        end
      end

      def destroy
        @channel.destroy
        redirect_to admin_system_channels_path, notice: 'Channel was successfully deleted.'
      end

      private

      def set_channel
        @channel = Channel.find(params[:id])
      end

      def channel_params
        params.require(:channel).permit(:name, :slug, :domain, :locale, :enabled, metadata: {}, settings: {})
      end

      def channels_json
        @channels.map do |channel|
          {
            id: channel.id,
            name: "<a href='#{admin_system_channel_path(channel)}' class='text-indigo-400 hover:text-indigo-300 font-medium'>#{channel.name}</a>",
            slug: channel.slug,
            domain: channel.domain || '-',
            locale: channel.locale.upcase,
            status: channel.enabled? ? 
              "<span class='inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800'>Enabled</span>" :
              "<span class='inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800'>Disabled</span>",
            content_counts: "#{channel.posts.count} posts, #{channel.pages.count} pages, #{channel.media.count} media",
            overrides_count: channel.channel_overrides.count,
            created_at: channel.created_at.iso8601,
            actions: "<div class='flex items-center space-x-2'>
              <a href='#{admin_system_channel_path(channel)}' class='text-gray-400 hover:text-white' title='View'>
                <svg class='w-4 h-4' fill='none' stroke='currentColor' viewBox='0 0 24 24'>
                  <path stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M15 12a3 3 0 11-6 0 3 3 0 016 0z'/>
                  <path stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z'/>
                </svg>
              </a>
              <a href='#{edit_admin_system_channel_path(channel)}' class='text-gray-400 hover:text-white' title='Edit'>
                <svg class='w-4 h-4' fill='none' stroke='currentColor' viewBox='0 0 24 24'>
                  <path stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z'/>
                </svg>
              </a>
              <a href='#{admin_system_channel_channel_overrides_path(channel)}' class='text-gray-400 hover:text-white' title='Overrides'>
                <svg class='w-4 h-4' fill='none' stroke='currentColor' viewBox='0 0 24 24'>
                  <path stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z'/>
                  <path stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M15 12a3 3 0 11-6 0 3 3 0 016 0z'/>
                </svg>
              </a>
            </div>"
          }
        end
      end
    end
  end
end