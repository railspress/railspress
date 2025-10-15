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
  
  def authenticate_api_key
    # Try Authorization header first, then query parameter
    api_key = request.headers['Authorization']&.split(' ')&.last || params[:api_key]
    @api_user = User.find_by(api_key: api_key)

    unless @api_user
      render json: { 
        error: { 
          message: "Invalid API key", 
          type: "authentication_error", 
          code: "invalid_api_key" 
        } 
      }, status: :unauthorized
      return false
    end
  end
end