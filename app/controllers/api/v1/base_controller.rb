class Api::V1::BaseController < ActionController::API
  # Skip Devise authentication
  skip_before_action :authenticate_user! if respond_to?(:authenticate_user!)
  
  # Set content type to JSON
  before_action :set_content_type
  
  # This will be overridden by child controllers that need authentication
  def authenticate_api_key
    # Default implementation - do nothing
  end
  
  private
  
  def set_content_type
    response.headers['Content-Type'] = 'application/json'
  end
  
  def render_success(data, meta = {}, status = :ok)
    response_data = {
      success: true,
      data: data
    }
    response_data[:meta] = meta if meta.present?
    
    render json: response_data, status: status
  end
  
  def current_api_user
    @api_user
  end
  
  def paginate(collection, per_page = 20)
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || per_page
    per_page = [per_page, 100].min # Cap at 100 items per page
    
    collection.page(page).per(per_page)
  end
end