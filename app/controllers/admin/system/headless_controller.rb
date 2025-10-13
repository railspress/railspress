class Admin::System::HeadlessController < Admin::BaseController
  def index
    @headless_enabled = SiteSetting.get('headless_mode', false)
    @cors_enabled = SiteSetting.get('cors_enabled', false)
    @cors_origins = SiteSetting.get('cors_origins', '*')
    @cors_methods = SiteSetting.get('cors_methods', 'GET, POST, PATCH, PUT, DELETE, OPTIONS')
    @cors_headers = SiteSetting.get('cors_headers', '*')
  end
  
  def update
    headless_enabled = params[:headless_mode] == '1'
    cors_enabled = params[:cors_enabled] == '1'
    
    SiteSetting.set('headless_mode', headless_enabled)
    SiteSetting.set('cors_enabled', cors_enabled)
    SiteSetting.set('cors_origins', params[:cors_origins]) if params[:cors_origins].present?
    SiteSetting.set('cors_methods', params[:cors_methods]) if params[:cors_methods].present?
    SiteSetting.set('cors_headers', params[:cors_headers]) if params[:cors_headers].present?
    
    if headless_enabled
      flash[:notice] = "Headless mode enabled. Frontend routes are now disabled. Access your content via GraphQL and REST APIs."
    else
      flash[:notice] = "Headless mode disabled. Frontend routes are now enabled."
    end
    
    redirect_to admin_system_headless_path
  end
  
  def test_cors
    render json: {
      success: true,
      message: "CORS is configured correctly",
      cors_origins: SiteSetting.get('cors_origins', '*'),
      timestamp: Time.current
    }
  end
end



