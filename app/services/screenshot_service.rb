require 'ferrum'

class ScreenshotService
  attr_reader :url, :width, :height, :format

  def initialize(url, options = {})
    @url = url
    @width = options[:width] || 1200
    @height = options[:height] || 800
    @format = options[:format] || :png
  end

  def capture
    Rails.logger.info "ScreenshotService: Capturing screenshot of #{@url}"
    
    browser = Ferrum::Browser.new(
      headless: true,
      window_size: [@width, @height],
      timeout: 15,  # Reduced timeout
      process_timeout: 10,  # Add process timeout
      slow_mo: 0,  # No slow motion
      browser_options: {
        'no-sandbox' => nil,
        'disable-dev-shm-usage' => nil,
        'disable-gpu' => nil,
        'disable-extensions' => nil,
        'disable-plugins' => nil,
        'disable-web-security' => nil,
        'disable-features' => 'VizDisplayCompositor'
      }
    )

    begin
      Rails.logger.info "ScreenshotService: Browser created, navigating to #{@url}"
      
      # Navigate with reduced timeout
      browser.go_to(@url)
      
      # Check if we got redirected to login page
      current_url = browser.current_url
      Rails.logger.info "ScreenshotService: Current URL after navigation: #{current_url}"
      
      if current_url.include?('/auth/sign_in')
        Rails.logger.info "ScreenshotService: Redirected to login, this is expected for admin routes"
        raise "Cannot capture screenshot of admin route - authentication required"
      end
      
      # Wait for page to fully load
      Rails.logger.info "ScreenshotService: Waiting for page to load completely"
      sleep(2)  # Give the page time to render
      
      # Take screenshot
      Rails.logger.info "ScreenshotService: Taking screenshot with format #{@format}"
      screenshot_data = browser.screenshot(
        format: @format,
        full: false
      )
      
      Rails.logger.info "ScreenshotService: Screenshot captured successfully"
      screenshot_data
    rescue => e
      Rails.logger.error "ScreenshotService: Error during capture - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    ensure
      browser.quit
    end
  end

  def capture_and_save(file_path)
    screenshot_data = capture
    
    # Ensure directory exists
    FileUtils.mkdir_p(File.dirname(file_path))
    
    # Save screenshot
    File.write(file_path, screenshot_data)
    
    file_path
  end

  # Capture theme preview screenshot
  def self.capture_theme_preview(theme_name, options = {})
    url = Rails.application.routes.url_helpers.preview_admin_themes_url(theme: theme_name, host: 'localhost:3000')
    
    screenshot_service = new(url, options)
    
    # Generate filename
    filename = "screenshot_#{theme_name.downcase}_#{Time.current.strftime('%Y%m%d_%H%M%S')}.#{options[:format] || 'png'}"
    file_path = Rails.root.join('tmp', 'screenshots', filename)
    
    screenshot_service.capture_and_save(file_path)
  end

  # Capture theme screenshot and return data directly (no filesystem storage)
  def self.capture_theme_screenshot_data(theme, options = {})
    Rails.logger.info "ScreenshotService: capture_theme_screenshot_data called with theme: #{theme.inspect}"
    return nil unless theme
    
    # Handle both Theme model objects and hash objects
    theme_id = theme.respond_to?(:id) ? theme.id : theme[:id]
    theme_name = theme.respond_to?(:name) ? theme.name : theme[:name]
    Rails.logger.info "ScreenshotService: Theme ID: #{theme_id}, Name: #{theme_name}"
    
    # Use optimized options for faster screenshots
    optimized_options = {
      width: 800,  # Smaller width for faster processing
      height: 600, # Smaller height for faster processing
      format: :png
    }.merge(options)
    
    # Use the working public preview route with theme ID
    public_preview_url = Rails.application.routes.url_helpers.theme_preview_url(host: 'localhost:3000', id: theme_id)
    Rails.logger.info "ScreenshotService: Using public preview URL: #{public_preview_url}"
    
    screenshot_service = new(public_preview_url, optimized_options)
    screenshot_service.capture
  end

  
end
