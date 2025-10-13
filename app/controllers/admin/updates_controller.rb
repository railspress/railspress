class Admin::UpdatesController < Admin::BaseController
  def index
    @update_info = Railspress::UpdateChecker.check_for_updates
    @release_notes = Railspress::UpdateChecker.fetch_release_notes if @update_info[:update_available]
  end
  
  def check
    # Force a fresh check (bypass cache)
    Rails.cache.delete('railspress:update_check')
    @update_info = Railspress::UpdateChecker.check_for_updates
    
    if @update_info[:update_available]
      flash[:success] = "New version available: #{@update_info[:latest_version]}"
    else
      flash[:info] = "You're running the latest version (#{@update_info[:current_version]})"
    end
    
    redirect_to admin_updates_path
  end
  
  def release_notes
    @release_info = Railspress::UpdateChecker.fetch_release_notes
    
    if @release_info
      render json: @release_info
    else
      render json: { error: 'Could not fetch release notes' }, status: :unprocessable_entity
    end
  end
end




