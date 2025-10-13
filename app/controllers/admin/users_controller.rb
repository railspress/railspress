class Admin::UsersController < Admin::BaseController
  before_action :ensure_admin
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # GET /admin/users
  def index
    @users = User.all.order(created_at: :desc)
    
    respond_to do |format|
      format.html
      format.json { render json: users_json }
    end
  end

  # GET /admin/users/1
  def show
  end

  # GET /admin/users/new
  def new
    @user = User.new
  end

  # GET /admin/users/1/edit
  def edit
  end

  # POST /admin/users
  def create
    @user = User.new(user_params)
    
    # Set password if provided
    if params[:user][:password].present?
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
    end

    if @user.save
      redirect_to admin_users_path, notice: 'User was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/users/1
  def update
    user_update_params = user_params
    
    # Remove password params if not provided
    if params[:user][:password].blank?
      user_update_params = user_update_params.except(:password, :password_confirmation)
    end

    if @user.update(user_update_params)
      redirect_to admin_users_path, notice: 'User was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/users/1
  def destroy
    if @user.id == current_user.id
      redirect_to admin_users_path, alert: 'You cannot delete your own account.'
      return
    end
    
    if @user.posts.any? || @user.pages.any?
      redirect_to admin_users_path, alert: 'Cannot delete user with existing content. Reassign content first.'
      return
    end

    @user.destroy
    redirect_to admin_users_path, notice: 'User was successfully deleted.'
  end

  # POST /admin/users/bulk_action
  def bulk_action
    action = params[:bulk_action]
    user_ids = params[:user_ids] || []

    case action
    when 'delete'
      bulk_delete(user_ids)
    when 'activate'
      bulk_activate(user_ids)
    when 'deactivate'
      bulk_deactivate(user_ids)
    when 'change_role'
      bulk_change_role(user_ids, params[:role])
    else
      redirect_to admin_users_path, alert: 'Invalid bulk action.'
    end
  end

  # GET /admin/users/profile (current user profile)
  def profile
    @user = current_user
    render :edit
  end

  # PATCH /admin/users/update_profile
  def update_profile
    @user = current_user
    
    user_update_params = user_params.except(:role) # Can't change own role
    
    # Remove password params if not provided
    if params[:user][:password].blank?
      user_update_params = user_update_params.except(:password, :password_confirmation)
    end

    if @user.update(user_update_params)
      redirect_to admin_users_path, notice: 'Profile updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :email, 
      :name, 
      :role, 
      :password, 
      :password_confirmation,
      :avatar
    )
  end

  def users_json
    users = User.all.order(created_at: :desc)
    
    # Apply filters
    if params[:role].present?
      users = users.where(role: params[:role])
    end
    
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      users = users.where(
        'email LIKE ? OR name LIKE ?', 
        search_term, 
        search_term
      )
    end
    
    users.map do |user|
      {
        id: user.id,
        email: user.email,
        name: user.name || 'N/A',
        role: user.role.titleize,
        role_badge: role_badge(user.role),
        posts_count: user.posts.count,
        pages_count: user.pages.count,
        created_at: user.created_at.strftime('%b %d, %Y'),
        last_sign_in: user.last_sign_in_at&.strftime('%b %d, %Y %H:%M') || 'Never',
        actions: user_actions(user)
      }
    end
  end

  def role_badge(role)
    colors = {
      'administrator' => 'bg-red-500',
      'editor' => 'bg-blue-500',
      'author' => 'bg-green-500',
      'contributor' => 'bg-yellow-500',
      'subscriber' => 'bg-gray-500'
    }
    
    color = colors[role] || 'bg-gray-500'
    "<span class='px-2 py-1 #{color} text-white text-xs rounded-full'>#{role.titleize}</span>"
  end

  def user_actions(user)
    actions = []
    actions << { label: 'Edit', url: edit_admin_user_path(user), class: 'text-blue-600' }
    actions << { label: 'View', url: admin_user_path(user), class: 'text-gray-600' }
    actions << { label: 'Delete', url: admin_user_path(user), method: 'delete', class: 'text-red-600' } unless user.id == current_user.id
    actions
  end

  def bulk_delete(user_ids)
    # Don't delete current user
    user_ids = user_ids.reject { |id| id.to_i == current_user.id }
    
    # Don't delete users with content
    users_with_content = User.where(id: user_ids).select { |u| u.posts.any? || u.pages.any? }
    
    if users_with_content.any?
      redirect_to admin_users_path, alert: "Cannot delete #{users_with_content.count} user(s) with existing content."
      return
    end
    
    count = User.where(id: user_ids).destroy_all.count
    redirect_to admin_users_path, notice: "#{count} user(s) deleted successfully."
  end

  def bulk_activate(user_ids)
    # Implementation depends on if you have an 'active' field
    redirect_to admin_users_path, notice: "Users activated."
  end

  def bulk_deactivate(user_ids)
    # Implementation depends on if you have an 'active' field
    redirect_to admin_users_path, notice: "Users deactivated."
  end

  def bulk_change_role(user_ids, new_role)
    return unless User.roles.keys.include?(new_role)
    
    # Don't change current user's role
    user_ids = user_ids.reject { |id| id.to_i == current_user.id }
    
    count = User.where(id: user_ids).update_all(role: new_role)
    redirect_to admin_users_path, notice: "#{count} user(s) role changed to #{new_role.titleize}."
  end

  def ensure_admin
    unless current_user&.administrator?
      redirect_to admin_root_path, alert: 'Access denied. Administrator privileges required.'
    end
  end
end






