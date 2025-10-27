class Admin::StockPhotosController < Admin::BaseController
  def search
    service = StockPhotoService.new
    
    result = service.search(
      params[:query] || '',
      provider: params[:provider] || 'all',
      page: params[:page] || 1,
      per_page: params[:per_page] || 30,
      orientation: params[:orientation],
      color: params[:color]
    )
    
    render json: { 
      photos: result[:photos], 
      errors: result[:errors],
      success: true 
    }
  end

  def import
    service = StockPhotoService.new
    photo_data = JSON.parse(params[:photo_data]).with_indifferent_access
    
    medium = service.import_as_external(photo_data, current_user)
    
    if medium
      # Auto-bookmark the imported photo
      bookmark = StockPhotoBookmark.find_or_create_by(
        user: current_user,
        provider_photo_id: photo_data[:id]
      ) do |b|
        b.provider = photo_data[:provider]
        b.thumbnail_url = photo_data[:thumbnail_url]
        b.preview_url = photo_data[:preview_url]
        b.download_url = photo_data[:download_url]
        b.width = photo_data[:width]
        b.height = photo_data[:height]
        b.photographer = photo_data[:photographer]
        b.photographer_url = photo_data[:photographer_url]
        b.source_url = photo_data[:source_url]
        b.alt_description = photo_data[:alt_description]
        b.title = photo_data[:title]
        b.photo_data = photo_data.to_json
      end
      
      render json: { 
        success: true, 
        medium: medium_json(medium),
        bookmarked: bookmark.persisted?,
        message: 'Photo imported successfully'
      }
    else
      render json: { success: false, message: 'Failed to import photo' }, status: :unprocessable_entity
    end
  end
  
  def bookmarks
    @bookmarks = StockPhotoBookmark.where(user: current_user).recent
    render json: { photos: @bookmarks.map { |b| bookmark_to_photo_json(b) }, success: true }
  end
  
  def bookmark
    photo_data = JSON.parse(params[:photo_data]).with_indifferent_access
    bookmark = StockPhotoBookmark.find_or_initialize_by(user: current_user, provider_photo_id: photo_data[:id])
    
    bookmark.assign_attributes(
      provider: photo_data[:provider],
      thumbnail_url: photo_data[:thumbnail_url],
      preview_url: photo_data[:preview_url],
      download_url: photo_data[:download_url],
      width: photo_data[:width],
      height: photo_data[:height],
      photographer: photo_data[:photographer],
      photographer_url: photo_data[:photographer_url],
      source_url: photo_data[:source_url],
      alt_description: photo_data[:alt_description],
      title: photo_data[:title],
      photo_data: photo_data.to_json
    )
    
    if bookmark.save
      render json: { success: true, bookmarked: true }
    else
      render json: { success: false, message: bookmark.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end
  
  def unbookmark
    bookmark = StockPhotoBookmark.find_by(user: current_user, provider_photo_id: params[:provider_photo_id])
    if bookmark&.destroy
      render json: { success: true, bookmarked: false }
    else
      render json: { success: false }, status: :not_found
    end
  end

  private

  def medium_json(medium)
    {
      id: medium.id,
      filename: medium.filename,
      title: medium.title,
      alt_text: medium.alt_text,
      description: medium.description,
      file_type: medium.content_type,
      file_size: medium.file_size,
      width: medium.width,
      height: medium.height,
      url: medium.url,
      thumbnail_url: medium.thumbnail_url || medium.url,
      created_at: medium.created_at.iso8601,
      is_external: medium.is_external?
    }
  end
  
  def bookmark_to_photo_json(bookmark)
    {
      id: bookmark.provider_photo_id,
      provider: bookmark.provider,
      thumbnail_url: bookmark.thumbnail_url,
      preview_url: bookmark.preview_url,
      download_url: bookmark.download_url,
      width: bookmark.width,
      height: bookmark.height,
      photographer: bookmark.photographer,
      photographer_url: bookmark.photographer_url,
      source: bookmark.provider.capitalize,
      source_url: bookmark.source_url,
      alt_description: bookmark.alt_description,
      title: bookmark.title,
      bookmarked: true
    }
  end
end

