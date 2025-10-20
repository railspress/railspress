module Admin
  module System
    class ChannelOverridesController < Admin::BaseController
      before_action :set_channel
      before_action :set_channel_override, only: [:show, :edit, :update, :destroy]
      
      def index
        @overrides = @channel.channel_overrides.includes(:resource).order(:resource_type, :path)
        @overrides_by_type = @overrides.group_by(&:resource_type)
      end
      
      def show
      end
      
      def new
        @channel_override = @channel.channel_overrides.build
        @resource_types = %w[Post Page Medium Setting]
      end
      
      def create
        @channel_override = @channel.channel_overrides.build(channel_override_params)
        
        if @channel_override.save
          redirect_to admin_system_channel_channel_overrides_path(@channel), notice: 'Override was successfully created.'
        else
          @resource_types = %w[Post Page Medium Setting]
          render :new
        end
      end
      
      def edit
        @resource_types = %w[Post Page Medium Setting]
      end
      
      def update
        if @channel_override.update(channel_override_params)
          redirect_to admin_system_channel_channel_overrides_path(@channel), notice: 'Override was successfully updated.'
        else
          @resource_types = %w[Post Page Medium Setting]
          render :edit
        end
      end
      
      def destroy
        @channel_override.destroy
        redirect_to admin_system_channel_channel_overrides_path(@channel), notice: 'Override was successfully deleted.'
      end
      
      def copy_from_channel
        source_channel = Channel.find(params[:source_channel_id])
        
        source_channel.channel_overrides.each do |override|
          new_override = override.dup
          new_override.channel = @channel
          new_override.save
        end
        
        redirect_to admin_system_channel_channel_overrides_path(@channel), notice: "Overrides copied from #{source_channel.name}."
      end
      
      def export
        overrides_data = @channel.channel_overrides.map do |override|
          {
            resource_type: override.resource_type,
            resource_id: override.resource_id,
            kind: override.kind,
            path: override.path,
            data: override.data,
            enabled: override.enabled
          }
        end
        
        respond_to do |format|
          format.json { render json: { channel: @channel.name, overrides: overrides_data } }
          format.yaml { render plain: overrides_data.to_yaml }
        end
      end
      
      def import
        if params[:file].present?
          begin
            data = case File.extname(params[:file].original_filename)
            when '.json'
              JSON.parse(params[:file].read)
            when '.yml', '.yaml'
              YAML.load(params[:file].read)
            else
              raise "Unsupported file format"
            end
            
            overrides_data = data.is_a?(Hash) && data['overrides'] ? data['overrides'] : data
            
            overrides_data.each do |override_data|
              @channel.channel_overrides.create!(
                resource_type: override_data['resource_type'],
                resource_id: override_data['resource_id'],
                kind: override_data['kind'],
                path: override_data['path'],
                data: override_data['data'],
                enabled: override_data['enabled']
              )
            end
            
            redirect_to admin_system_channel_channel_overrides_path(@channel), notice: 'Overrides imported successfully.'
          rescue => e
            redirect_to admin_system_channel_channel_overrides_path(@channel), alert: "Import failed: #{e.message}"
          end
        else
          redirect_to admin_system_channel_channel_overrides_path(@channel), alert: 'No file provided.'
        end
      end
      
      private
      
      def set_channel
        @channel = Channel.find(params[:channel_id])
      end
      
      def set_channel_override
        @channel_override = @channel.channel_overrides.find(params[:id])
      end
      
      def channel_override_params
        params.require(:channel_override).permit(:resource_type, :resource_id, :kind, :path, :enabled, data: {})
      end
    end
  end
end

