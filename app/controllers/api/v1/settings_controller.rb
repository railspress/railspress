module Api
  module V1
    class SettingsController < BaseController
      before_action :ensure_admin, except: [:index, :show]
      
      # GET /api/v1/settings
      def index
        settings = SiteSetting.all
        
        render_success(
          settings.map { |s| setting_serializer(s) }
        )
      end
      
      # GET /api/v1/settings/:key
      def show
        setting = SiteSetting.find_by!(key: params[:id])
        render_success(setting_serializer(setting))
      end
      
      # POST /api/v1/settings
      def create
        key = params[:setting][:key]
        value = params[:setting][:value]
        setting_type = params[:setting][:setting_type] || 'string'
        
        if SiteSetting.set(key, value, setting_type)
          setting = SiteSetting.find_by(key: key)
          render_success(setting_serializer(setting), {}, :created)
        else
          render_error('Failed to create setting')
        end
      end
      
      # PATCH/PUT /api/v1/settings/:key
      def update
        setting = SiteSetting.find_by!(key: params[:id])
        
        if setting.update(setting_params)
          render_success(setting_serializer(setting))
        else
          render_error(setting.errors.full_messages.join(', '))
        end
      end
      
      # DELETE /api/v1/settings/:key
      def destroy
        setting = SiteSetting.find_by!(key: params[:id])
        setting.destroy
        render_success({ message: 'Setting deleted successfully' })
      end
      
      # GET /api/v1/settings/get/:key
      def get_value
        value = SiteSetting.get(params[:key], params[:default])
        render_success({ key: params[:key], value: value })
      end
      
      private
      
      def ensure_admin
        unless current_api_user.administrator?
          render_error('Only administrators can manage settings', :forbidden)
        end
      end
      
      def setting_params
        params.require(:setting).permit(:key, :value, :setting_type)
      end
      
      def setting_serializer(setting)
        {
          key: setting.key,
          value: setting.typed_value,
          raw_value: setting.value,
          setting_type: setting.setting_type
        }
      end
    end
  end
end





