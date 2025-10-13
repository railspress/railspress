class Admin::PluginPagesController < Admin::BaseController
  before_action :set_plugin
  before_action :check_capability
  
  # Show plugin admin page
  def show
    @page_slug = params[:page_slug]
    @admin_page = @plugin.admin_pages.find { |p| p[:slug] == @page_slug }
    
    unless @admin_page
      redirect_to admin_plugins_path, alert: "Page not found"
      return
    end
    
    # If the plugin has a custom callback for this page
    if @admin_page[:callback]
      @page_data = @plugin.send(@admin_page[:callback])
    else
      # Default: render settings page
      @page_data = @plugin.render_settings_page
    end
  end
  
  # Update plugin settings
  def update
    @page_slug = params[:page_slug]
    
    # Update all submitted settings
    if params[:settings]
      params[:settings].each do |key, value|
        @plugin.set_setting(key.to_sym, value)
      end
      
      flash[:notice] = "Settings saved successfully"
    end
    
    redirect_to admin_plugin_page_path(plugin_identifier: params[:plugin_identifier], page_slug: @page_slug)
  end
  
  # Handle custom actions
  def action
    action_name = params[:action_name]
    
    if @plugin.respond_to?(action_name)
      result = @plugin.send(action_name, params)
      render json: { success: true, data: result }
    else
      render json: { success: false, error: "Action not found" }, status: 404
    end
  end
  
  private
  
  def set_plugin
    plugin_identifier = params[:plugin_identifier]
    @plugin = Railspress::PluginSystem.get_plugin(plugin_identifier)
    
    unless @plugin
      redirect_to admin_plugins_path, alert: "Plugin not found"
    end
  end
  
  def check_capability
    # Check if user has required capability for this page
    return if current_user.administrator?
    
    capability = @plugin.admin_pages.find { |p| p[:slug] == params[:page_slug] }&.dig(:capability)
    
    case capability
    when 'editor'
      ensure_editor_access
    when 'author'
      # Authors have basic access
    else
      ensure_admin
    end
  end
end
