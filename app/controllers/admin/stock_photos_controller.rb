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
      render json: { 
        success: true, 
        medium: medium_json(medium),
        message: 'Photo imported successfully'
      }
    else
      render json: { success: false, message: 'Failed to import photo' }, status: :unprocessable_entity
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
end

