module Api
  module V1
    class BaseController < ApplicationController
      # Skip CSRF for API requests
      skip_before_action :verify_authenticity_token
      
      # Include pagination
      include Pagy::Backend
      
      before_action :set_default_format
      before_action :authenticate_api_user!
      
      # Rescue from common errors
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request
      
      private
      
      def set_default_format
        request.format = :json unless params[:format]
      end
      
      # API Authentication using Bearer token
      def authenticate_api_user!
        token = request.headers['Authorization']&.split(' ')&.last
        
        unless token
          render json: { error: 'Missing authorization token' }, status: :unauthorized
          return
        end
        
        @current_api_user = User.find_by(api_token: token)
        
        unless @current_api_user
          render json: { error: 'Invalid authorization token' }, status: :unauthorized
        end
      end
      
      def current_api_user
        @current_api_user
      end
      
      # Error handlers
      def not_found(exception)
        render json: {
          error: 'Resource not found',
          message: exception.message
        }, status: :not_found
      end
      
      def unprocessable_entity(exception)
        render json: {
          error: 'Validation failed',
          messages: exception.record.errors.full_messages
        }, status: :unprocessable_entity
      end
      
      def bad_request(exception)
        render json: {
          error: 'Bad request',
          message: exception.message
        }, status: :bad_request
      end
      
      def forbidden
        render json: {
          error: 'Forbidden',
          message: 'You do not have permission to perform this action'
        }, status: :forbidden
      end
      
      # Pagination helpers
      def paginate(collection)
        @pagy, records = pagy(collection, items: params[:per_page] || 25)
        records
      end
      
      def pagination_meta
        return {} unless @pagy
        
        {
          current_page: @pagy.page,
          per_page: @pagy.items,
          total_pages: @pagy.pages,
          total_count: @pagy.count,
          next_page: @pagy.next,
          prev_page: @pagy.prev
        }
      end
      
      # Standard response format
      def render_success(data, meta = {}, status = :ok)
        render json: {
          success: true,
          data: data,
          meta: meta.merge(pagination_meta)
        }, status: status
      end
      
      def render_error(message, status = :unprocessable_entity)
        render json: {
          success: false,
          error: message
        }, status: status
      end
    end
  end
end





