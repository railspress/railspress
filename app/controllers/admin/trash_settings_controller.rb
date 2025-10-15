class Admin::TrashSettingsController < Admin::BaseController
  before_action :ensure_admin
  before_action :set_trash_setting
  
  def show
  end
  
  def update
    if @trash_setting.update(trash_setting_params)
      flash[:notice] = "Trash settings updated successfully"
      redirect_to admin_trash_settings_path
    else
      flash[:alert] = "Failed to update trash settings"
      render :show
    end
  end
  
  def test_cleanup
    # Test the cleanup process without actually deleting anything
    threshold = @trash_setting.cleanup_threshold
    
    @test_results = {
      posts: Post.trashed.where('deleted_at < ?', threshold).count,
      pages: Page.trashed.where('deleted_at < ?', threshold).count,
      media: Medium.trashed.where('deleted_at < ?', threshold).count,
      comments: Comment.trashed.where('deleted_at < ?', threshold).count
    }
    
    @test_results[:total] = @test_results.values.sum
    
    render :show
  end
  
  def run_cleanup
    if @trash_setting.auto_cleanup_enabled?
      Post.cleanup_trash!
      Page.cleanup_trash!
      Medium.cleanup_trash!
      Comment.cleanup_trash!
      
      flash[:notice] = "Trash cleanup completed successfully"
    else
      flash[:alert] = "Automatic cleanup is disabled"
    end
    
    redirect_to admin_trash_settings_path
  end
  
  private
  
  def set_trash_setting
    @trash_setting = TrashSetting.current
  end
  
  def trash_setting_params
    params.require(:trash_setting).permit(:auto_cleanup_enabled, :cleanup_after_days)
  end
end
