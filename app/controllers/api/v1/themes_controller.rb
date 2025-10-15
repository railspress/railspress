class Api::V1::ThemesController < Api::V1::BaseController
  before_action :authenticate_api_key
  before_action :set_theme, only: [:show, :screenshot]
  skip_before_action :set_content_type, only: [:screenshot]
  
  # GET /api/v1/themes
  def index
    @themes = Theme.includes(:published_version)
    
    render json: {
      themes: @themes.map do |theme|
        {
          id: theme.id,
          name: theme.name,
          slug: theme.slug,
          description: theme.description,
          version: theme.version,
          active: theme.active?,
          screenshot_url: api_v1_theme_screenshot_url(theme.id),
          created_at: theme.created_at,
          updated_at: theme.updated_at
        }
      end
    }
  end
  
  # GET /api/v1/themes/:id
  def show
    render json: {
      theme: {
        id: @theme.id,
        name: @theme.name,
        slug: @theme.slug,
        description: @theme.description,
        version: @theme.version,
        active: @theme.active?,
        screenshot_url: api_v1_theme_screenshot_url(@theme.id),
        created_at: @theme.created_at,
        updated_at: @theme.updated_at
      }
    }
  end
  
  # GET /api/v1/themes/:id/screenshot
  def screenshot
    cache_key = "theme_screenshot_#{@theme.id}"
    Rails.logger.info "API: Cache key: #{cache_key}"
    
    # Try to get from cache first
    cached_screenshot = Rails.cache.read(cache_key)
    Rails.logger.info "API: Cache read result: #{cached_screenshot ? 'HIT' : 'MISS'}"
    
    if cached_screenshot
      Rails.logger.info "API: Serving cached screenshot for theme #{@theme.id} (size: #{cached_screenshot.bytesize} bytes)"
      send_data cached_screenshot, 
                type: 'image/png', 
                disposition: 'inline',
                filename: "theme_#{@theme.id}_screenshot.png"
      return
    end
    
    begin
      # Generate new screenshot
      Rails.logger.info "API: Generating new screenshot for theme #{@theme.id}"
      screenshot_data = ScreenshotService.capture_theme_screenshot_data(@theme, {
        width: 1200,
        height: 800,
        format: :png
      })
      
      # Ferrum returns base64-encoded PNG data, decode it to binary
      if screenshot_data.match?(/^[A-Za-z0-9+\/]*={0,2}$/)
        screenshot_data = Base64.decode64(screenshot_data)
      end
      
      # Cache the screenshot for 1 hour
      Rails.logger.info "API: Caching screenshot for theme #{@theme.id} (size: #{screenshot_data.bytesize} bytes)"
      Rails.cache.write(cache_key, screenshot_data, expires_in: 1.hour)
      
      send_data screenshot_data, 
                type: 'image/png', 
                disposition: 'inline',
                filename: "theme_#{@theme.id}_screenshot.png"
    rescue => e
      Rails.logger.error "API: Screenshot capture failed for theme #{@theme.id}: #{e.message}"
      render json: { 
        error: { 
          message: "Failed to capture screenshot", 
          type: "screenshot_error",
          code: "screenshot_failed",
          details: e.message
        } 
      }, status: :internal_server_error
    end
  end
  
  private
  
  def set_theme
    @theme = Theme.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { 
      error: { 
        message: "Theme not found", 
        type: "not_found_error",
        code: "theme_not_found"
      } 
    }, status: :not_found
  end
end
