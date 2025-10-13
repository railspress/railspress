module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :verify_authenticity_token
      
      # POST /api/v1/auth/login
      def login
        user = User.find_by(email: params[:email])
        
        if user&.valid_password?(params[:password])
          render json: {
            success: true,
            data: {
              user: {
                id: user.id,
                email: user.email,
                role: user.role
              },
              api_token: user.api_token,
              message: 'Login successful'
            }
          }, status: :ok
        else
          render json: {
            success: false,
            error: 'Invalid email or password'
          }, status: :unauthorized
        end
      end
      
      # POST /api/v1/auth/register
      def register
        user = User.new(registration_params)
        user.role = :subscriber # New users are subscribers by default
        
        if user.save
          render json: {
            success: true,
            data: {
              user: {
                id: user.id,
                email: user.email,
                role: user.role
              },
              api_token: user.api_token,
              message: 'Registration successful'
            }
          }, status: :created
        else
          render json: {
            success: false,
            error: user.errors.full_messages.join(', ')
          }, status: :unprocessable_entity
        end
      end
      
      # POST /api/v1/auth/validate
      def validate_token
        token = request.headers['Authorization']&.split(' ')&.last
        user = User.find_by(api_token: token)
        
        if user
          render json: {
            success: true,
            data: {
              valid: true,
              user: {
                id: user.id,
                email: user.email,
                role: user.role
              }
            }
          }
        else
          render json: {
            success: false,
            data: { valid: false },
            error: 'Invalid token'
          }, status: :unauthorized
        end
      end
      
      private
      
      def registration_params
        params.permit(:email, :password, :password_confirmation)
      end
    end
  end
end




