module Api
  module V1
    class UsersController < BaseController
      before_action :ensure_admin, except: [:me, :update_profile]
      before_action :set_user, only: [:show, :update, :destroy]
      
      # GET /api/v1/users
      def index
        users = User.all
        
        # Filter by role
        users = users.where(role: params[:role]) if params[:role].present?
        
        # Search
        users = users.where('email LIKE ?', "%#{params[:q]}%") if params[:q].present?
        
        # Paginate
        @users = paginate(users.order(created_at: :desc))
        
        render_success(
          @users.map { |user| user_serializer(user) }
        )
      end
      
      # GET /api/v1/users/me
      def me
        render_success(user_serializer(current_api_user, detailed: true))
      end
      
      # GET /api/v1/users/:id
      def show
        render_success(user_serializer(@user, detailed: true))
      end
      
      # POST /api/v1/users
      def create
        @user = User.new(user_params)
        
        if @user.save
          render_success(user_serializer(@user), {}, :created)
        else
          render_error(@user.errors.full_messages.join(', '))
        end
      end
      
      # PATCH/PUT /api/v1/users/:id
      def update
        if @user.update(user_params)
          render_success(user_serializer(@user))
        else
          render_error(@user.errors.full_messages.join(', '))
        end
      end
      
      # PATCH /api/v1/users/profile
      def update_profile
        if current_api_user.update(profile_params)
          render_success(user_serializer(current_api_user))
        else
          render_error(current_api_user.errors.full_messages.join(', '))
        end
      end
      
      # DELETE /api/v1/users/:id
      def destroy
        if @user.id == current_api_user.id
          return render_error('You cannot delete yourself', :forbidden)
        end
        
        @user.destroy
        render_success({ message: 'User deleted successfully' })
      end
      
      # POST /api/v1/users/regenerate_token
      def regenerate_token
        current_api_user.regenerate_api_token!
        render_success({
          api_token: current_api_user.api_token,
          message: 'API token regenerated successfully'
        })
      end
      
      private
      
      def ensure_admin
        unless current_api_user.administrator?
          render_error('Only administrators can manage users', :forbidden)
        end
      end
      
      def set_user
        @user = User.find(params[:id])
      end
      
      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation, :role)
      end
      
      def profile_params
        params.require(:user).permit(:email, :password, :password_confirmation)
      end
      
      def user_serializer(user, detailed: false)
        data = {
          id: user.id,
          email: user.email,
          role: user.role,
          created_at: user.created_at,
          posts_count: user.posts.count,
          pages_count: user.pages.count,
          comments_count: user.comments.count
        }
        
        if detailed
          data.merge!(
            api_token: user.id == current_api_user.id ? user.api_token : '[HIDDEN]',
            api_requests_count: user.api_requests_count,
            api_requests_reset_at: user.api_requests_reset_at
          )
        end
        
        data
      end
    end
  end
end




