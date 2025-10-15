class FrontendThemeRenderer
  class << self
    def render_template(template_name, context = {})
      # Get the active theme
      active_theme = Theme.active.first
      return render_error('No active theme found') unless active_theme
      
      # Ensure PublishedThemeVersion exists
      published_version = ensure_published_version_exists(active_theme)
      return render_error('Failed to create published theme version') unless published_version
      
      # Use FrontendRendererService to render
      renderer = FrontendRendererService.new(published_version)
      
      begin
        renderer.render_template(template_name, context)
      rescue => e
        Rails.logger.error "Frontend rendering error: #{e.message}"
        render_error("Rendering error: #{e.message}")
      end
    end
    
    def load_assets
      # Get the active theme
      active_theme = Theme.active.first
      return { css: '', js: '' } unless active_theme
      
      # Ensure PublishedThemeVersion exists
      published_version = ensure_published_version_exists(active_theme)
      return { css: '', js: '' } unless published_version
      
      # Use FrontendRendererService to get assets
      renderer = FrontendRendererService.new(published_version)
      renderer.assets
    end
    
    def current_theme_name
      active_theme = Theme.active.first
      active_theme&.name&.underscore || 'default'
    end
    
    private
    
    def ensure_published_version_exists(theme)
      # Check if we already have a PublishedThemeVersion for this theme
      published_version = PublishedThemeVersion.where(theme: theme).latest.first
      
      if published_version
        Rails.logger.debug "Using existing PublishedThemeVersion #{published_version.id} for theme #{theme.name}"
        return published_version
      end
      
      Rails.logger.info "No PublishedThemeVersion found for #{theme.name}, creating initial version..."
      
      # Create initial PublishedThemeVersion
      published_version = PublishedThemeVersion.create!(
        theme: theme,
        version_number: 1,
        published_at: Time.current,
        published_by: User.first, # TODO: Use system user or current user if available
        tenant: theme.tenant
      )
      
      # Copy all files from ThemeVersion to PublishedThemeFile
      theme_version = ThemeVersion.for_theme(theme.name).live.first
      
      if theme_version && theme_version.theme_files.any?
        theme_version.theme_files.each do |theme_file|
          # Use the theme file's content directly
          content = theme_file.current_content
          next unless content
          
          # Use the file_path as is (it should already be relative)
          relative_path = theme_file.file_path
          
          PublishedThemeFile.create!(
            published_theme_version: published_version,
            file_path: relative_path,
            file_type: theme_file.file_type,
            content: content,
            checksum: Digest::MD5.hexdigest(content)
          )
        end
        
        Rails.logger.info "Created initial PublishedThemeVersion #{published_version.id} with #{published_version.published_theme_files.count} files"
      else
        Rails.logger.warn "No theme files found for #{theme.name}"
      end
      
      published_version
    rescue => e
      Rails.logger.error "Failed to create PublishedThemeVersion for #{theme.name}: #{e.message}"
      nil
    end
    
    def render_error(message)
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Error - RailsPress</title>
          <style>
            body { font-family: system-ui, sans-serif; margin: 0; padding: 2rem; background: #f5f5f5; }
            .error-container { max-width: 600px; margin: 0 auto; background: white; padding: 2rem; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .error-title { color: #dc2626; margin-bottom: 1rem; }
            .error-message { color: #374151; line-height: 1.6; }
          </style>
        </head>
        <body>
          <div class="error-container">
            <h1 class="error-title">Theme Error</h1>
            <p class="error-message">#{message}</p>
          </div>
        </body>
        </html>
      HTML
    end
  end
end
