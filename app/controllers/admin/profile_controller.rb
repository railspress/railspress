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

  # PATCH /admin/profile/editor_preference
  def editor_preference
    editor_value = params[:editor_preference]
    
    if editor_value.blank?
      render json: { error: 'Editor preference is required' }, status: :unprocessable_entity
      return
    end

    valid_editors = ['editorjs', 'trix', 'ckeditor5']
    unless valid_editors.include?(editor_value)
      render json: { error: 'Invalid editor preference' }, status: :unprocessable_entity
      return
    end

    if @user.update(editor_preference: editor_value)
      render json: { status: 'success', editor_preference: editor_value }
    else
      render json: { error: 'Failed to update editor preference' }, status: :unprocessable_entity
    end
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
      ['EditorJS (Rich Block Editor)', 'editorjs'],
      ['Trix (Rich Text Editor)', 'trix'],
      ['CKEditor 5 (Classic Editor)', 'ckeditor5']
    ]
  end
end
