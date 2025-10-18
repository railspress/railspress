class Admin::ProfileController < Admin::BaseController
  before_action :set_user

  # GET /admin/profile
  def show
    redirect_to edit_admin_profile_path
  end

  # GET /admin/profile/edit
  def edit
    @available_editors = available_editors
  end

  # PATCH /admin/profile
  def update
    user_params_filtered = user_params
    
    # Remove password params if not provided
    if params[:user][:password].blank?
      user_params_filtered = user_params_filtered.except(:password, :password_confirmation)
    end
    
    # Handle avatar upload
    if params[:user][:avatar].present?
      @user.avatar.attach(params[:user][:avatar])
    end

    if @user.update(user_params_filtered)
      redirect_to edit_admin_profile_path, notice: 'Profile updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/profile/avatar
  def remove_avatar
    @user.avatar.purge if @user.avatar.attached?
    redirect_to edit_admin_profile_path, notice: 'Avatar removed successfully.'
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:email, :name, :password, :password_confirmation, :avatar, :bio, :website, :twitter, :github, :linkedin, :phone, :location, :avatar_url, :editor_preference)
  end

  def available_editors
    [
      ['BlockNote (Modern Block Editor)', 'blocknote'],
      ['Editor.js (Rich Block Editor)', 'editorjs'],
      ['Trix (Rich Text Editor)', 'trix'],
      ['Simple Textarea', 'simple']
    ]
  end
end
