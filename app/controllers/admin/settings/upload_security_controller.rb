class Admin::Settings::UploadSecurityController < Admin::BaseController
  before_action :set_upload_security
  
  # GET /admin/settings/upload_security
  def show
  end
  
  # PATCH /admin/settings/upload_security
  def update
    if @upload_security.update(upload_security_params)
      redirect_to admin_settings_upload_security_path, notice: "Upload security settings updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_upload_security
    @upload_security = UploadSecurity.current
  end
  
  def upload_security_params
    params.require(:upload_security).permit(
      :max_file_size_human,
      :allowed_extensions_list,
      :blocked_extensions_list,
      :allowed_mime_types_list,
      :blocked_mime_types_list,
      :scan_for_viruses,
      :quarantine_suspicious,
      :auto_approve_trusted
    )
  end
end

