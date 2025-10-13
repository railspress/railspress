class ThemeAssetsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def show
    theme_name = params[:theme]
    asset_path_array = params[:path]
    
    # Security: only allow alphanumeric, hyphens, underscores, and dots in theme name
    unless theme_name.match?(/\A[a-z0-9_-]+\z/)
      return head :not_found
    end
    
    # Construct the full path to the asset
    full_path = Rails.root.join('app', 'themes', theme_name, 'assets', *asset_path_array)
    
    # Security: ensure the path is within the theme directory
    assets_dir = Rails.root.join('app', 'themes', theme_name, 'assets')
    unless full_path.to_s.start_with?(assets_dir.to_s)
      return head :forbidden
    end
    
    # Check if file exists
    unless File.exist?(full_path) && File.file?(full_path)
      Rails.logger.warn "Theme asset not found: #{full_path}"
      return head :not_found
    end
    
    # Determine content type
    extension = File.extname(full_path)[1..-1]
    content_type = Mime::Type.lookup_by_extension(extension)
    content_type ||= 'application/octet-stream'
    
    # Send file with caching headers
    expires_in 1.year, public: true
    send_file full_path, type: content_type.to_s, disposition: 'inline'
  end
end
