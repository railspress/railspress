class Admin::PluginProxyController < Admin::BaseController
  skip_before_action :verify_authenticity_token, only: [:proxy]
  skip_before_action :authenticate_user!, only: [:proxy], if: -> { params[:action_name] == 'assets' }
  skip_before_action :ensure_admin_access, only: [:proxy], if: -> { params[:action_name] == 'assets' }
  
  def proxy
    plugin_slug = params[:plugin_id]
    action = params[:action_name]
    
    Rails.logger.info "PluginProxy: #{plugin_slug}.#{action} - params: #{params.except(:file).inspect}"
    
    # Map plural actions to singular handlers
    action = action.singularize if action == 'assets'
    
    # Get plugin instance by slug
    plugin_record = Plugin.find_by(slug: plugin_slug)
    unless plugin_record
      return render json: { error: 'Plugin not found' }, status: 404
    end
    
    # Get plugin instance from PluginSystem
    plugin = Railspress::PluginSystem.get_plugin(plugin_record.name)
    
    unless plugin
      return render json: { error: 'Plugin not found' }, status: 404
    end
    
    # Check if handler exists
    handler_method = "handle_#{action}"
    unless plugin.respond_to?(handler_method)
      return render json: { error: 'Handler not found' }, status: 404
    end
    
    # Call handler with request context
    begin
      result = plugin.send(handler_method, request, params, current_user)
      
      # Handler returns [status, headers, body] or just body
      if result.is_a?(Array) && result.length == 3
        render_proxy_result(*result)
      else
        render json: result
      end
    rescue => e
      Rails.logger.error "Plugin handler error (#{plugin_id}.#{handler_method}): #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      render json: { error: 'Handler failed', message: e.message }, status: 500
    end
  end
  
  private
  
  def render_proxy_result(status, headers, body)
    headers.each { |k, v| response.headers[k] = v }
    render body: body.is_a?(Array) ? body.join : body, status: status
  end
end

