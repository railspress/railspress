class StockPhotoService
  def initialize
    @unsplash_key = SiteSetting.get('unsplash_access_key', '')
    @pexels_key = SiteSetting.get('pexels_api_key', '')
    @pixabay_key = SiteSetting.get('pixabay_api_key', '')
  end

  def search(query, provider: 'all', page: 1, per_page: 30, orientation: nil, color: nil)
    results = []
    errors = []
    
    if provider == 'all' || provider == 'unsplash'
      if @unsplash_key.present?
        unsplash_results = search_unsplash(query, page, per_page, orientation, color)
        if unsplash_results.is_a?(Hash) && unsplash_results[:error]
          errors << "Unsplash: #{unsplash_results[:error]}"
        else
          results += unsplash_results
        end
      else
        errors << "Unsplash: API key not configured"
      end
    end
    
    if provider == 'all' || provider == 'pexels'
      if @pexels_key.present?
        pexels_results = search_pexels(query, page, per_page, orientation, color)
        if pexels_results.is_a?(Hash) && pexels_results[:error]
          errors << "Pexels: #{pexels_results[:error]}"
        else
          results += pexels_results
        end
      else
        errors << "Pexels: API key not configured"
      end
    end
    
    if provider == 'all' || provider == 'pixabay'
      if @pixabay_key.present?
        pixabay_results = search_pixabay(query, page, per_page, orientation, color)
        if pixabay_results.is_a?(Hash) && pixabay_results[:error]
          errors << "Pixabay: #{pixabay_results[:error]}"
        else
          results += pixabay_results
        end
      else
        errors << "Pixabay: API key not configured"
      end
    end
    
    { photos: results, errors: errors }
  end

  def import_as_external(photo_data, user)
    # Create Upload with external URL (hotlinked, per TOS requirements)
    upload = Upload.new(
      title: photo_data[:title] || photo_data[:alt_description] || 'Stock Photo',
      description: "Photo by #{photo_data[:photographer]} on #{photo_data[:source]}",
      user: user,
      storage_provider: StorageProvider.active.first,
      is_external: true,
      external_url: photo_data[:download_url],
      external_thumbnail_url: photo_data[:thumbnail_url],
      external_preview_url: photo_data[:preview_url],
      external_width: photo_data[:width],
      external_height: photo_data[:height],
      external_content_type: 'image/jpeg' # All stock photos are images
    )
    
    return nil unless upload.save
    
    # Create Medium record
    medium = Medium.new(
      title: photo_data[:title] || photo_data[:alt_description] || 'Stock Photo',
      alt_text: photo_data[:alt_description],
      description: "Photo by #{photo_data[:photographer]} on #{photo_data[:source]}. Source: #{photo_data[:source_url]}",
      user: user,
      upload: upload
    )
    
    medium.save ? medium : nil
  end

  private

  def search_unsplash(query, page, per_page, orientation, color)
    url = "https://api.unsplash.com/search/photos"
    
    # Valid orientations for Unsplash: landscape, portrait, squarish
    valid_orientations = ['landscape', 'portrait', 'squarish']
    params = {
      query: query,
      page: page,
      per_page: per_page
    }
    
    # Only add orientation if it's valid
    if orientation.present? && valid_orientations.include?(orientation)
      params[:orientation] = orientation
    end
    
    # Only add color if present (Unsplash accepts hex colors)
    if color.present?
      params[:color] = color
    end
    
    response = HTTParty.get(url, {
      query: params,
      headers: { 'Authorization' => "Client-ID #{@unsplash_key}" }
    })
    
    unless response.success?
      error_msg = response['errors']&.join(', ') || "HTTP #{response.code}"
      Rails.logger.error "Unsplash API error: #{error_msg}"
      return { error: error_msg }
    end
    
    response['results'].map do |photo|
      {
        id: "unsplash_#{photo['id']}",
        provider: 'unsplash',
        thumbnail_url: photo['urls']['small'],
        preview_url: photo['urls']['regular'],
        download_url: photo['urls']['full'],
        width: photo['width'],
        height: photo['height'],
        photographer: photo['user']['name'],
        photographer_url: photo['user']['links']['html'],
        source: 'Unsplash',
        source_url: photo['links']['html'],
        alt_description: photo['alt_description'] || photo['description'],
        title: photo['description'] || photo['alt_description'] || "Photo by #{photo['user']['name']}"
      }
    end
  rescue => e
    Rails.logger.error "Unsplash API error: #{e.message}"
    { error: e.message }
  end

  def search_pexels(query, page, per_page, orientation, color)
    url = "https://api.pexels.com/v1/search"
    params = {
      query: query,
      page: page,
      per_page: per_page,
      orientation: orientation,
      color: color
    }.compact
    
    response = HTTParty.get(url, {
      query: params,
      headers: { 'Authorization' => @pexels_key }
    })
    
    unless response.success?
      error_msg = response['error'] || "HTTP #{response.code}"
      Rails.logger.error "Pexels API error: #{error_msg}"
      return { error: error_msg }
    end
    
    response['photos'].map do |photo|
      {
        id: "pexels_#{photo['id']}",
        provider: 'pexels',
        thumbnail_url: photo['src']['medium'], # Changed from 'small' to 'medium' for higher resolution
        preview_url: photo['src']['large'], # Changed from 'medium' to 'large' for better preview
        download_url: photo['src']['original'],
        width: photo['width'],
        height: photo['height'],
        photographer: photo['photographer'],
        photographer_url: photo['photographer_url'],
        source: 'Pexels',
        source_url: photo['url'],
        alt_description: photo['alt'],
        title: photo['alt'] || "Photo by #{photo['photographer']}"
      }
    end
  rescue => e
    Rails.logger.error "Pexels API error: #{e.message}"
    { error: e.message }
  end

  def search_pixabay(query, page, per_page, orientation, color)
    url = "https://pixabay.com/api/"
    params = {
      key: @pixabay_key,
      q: query,
      page: page,
      per_page: per_page,
      orientation: orientation,
      colors: color,
      image_type: 'photo'
    }.compact
    
    response = HTTParty.get(url, query: params)
    
    unless response.success?
      error_msg = response['error'] || "HTTP #{response.code}"
      Rails.logger.error "Pixabay API error: #{error_msg}"
      return { error: error_msg }
    end
    
    response['hits'].map do |photo|
      {
        id: "pixabay_#{photo['id']}",
        provider: 'pixabay',
        thumbnail_url: photo['webformatURL'], # Changed from 'previewURL' to 'webformatURL' for higher resolution
        preview_url: photo['largeImageURL'], # Changed from 'webformatURL' to 'largeImageURL' for better preview
        download_url: photo['largeImageURL'],
        width: photo['imageWidth'],
        height: photo['imageHeight'],
        photographer: photo['user'],
        photographer_url: "https://pixabay.com/users/#{photo['user']}-#{photo['user_id']}/",
        source: 'Pixabay',
        source_url: photo['pageURL'],
        alt_description: photo['tags'],
        title: photo['tags'] || "Photo by #{photo['user']}"
      }
    end
  rescue => e
    Rails.logger.error "Pixabay API error: #{e.message}"
    { error: e.message }
  end
end

