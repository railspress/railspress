class Admin::Tools::ExportPersonalDataController < Admin::BaseController
  # GET /admin/tools/export_personal_data
  def index
    @export_requests = PersonalDataExportRequest.order(created_at: :desc).limit(50) rescue []
  end
  
  # POST /admin/tools/export_personal_data/request
  def request
    email = params[:email]
    
    unless email.present?
      redirect_to admin_export_personal_data_path, alert: 'Please provide an email address'
      return
    end
    
    user = User.find_by(email: email)
    
    unless user
      redirect_to admin_export_personal_data_path, alert: 'No user found with that email address'
      return
    end
    
    # Create export request
    export_request = PersonalDataExportRequest.create!(
      user_id: user.id,
      email: email,
      requested_by: current_user.id,
      status: 'pending',
      token: SecureRandom.hex(32)
    )
    
    # Queue the export job
    PersonalDataExportWorker.perform_async(export_request.id)
    
    redirect_to admin_export_personal_data_path, 
                notice: "Personal data export request created for #{email}. Processing..."
  rescue => e
    Rails.logger.error("Personal data export error: #{e.message}")
    redirect_to admin_export_personal_data_path, alert: "Request failed: #{e.message}"
  end
  
  # GET /admin/tools/export_personal_data/download/:token
  def download
    export_request = PersonalDataExportRequest.find_by(token: params[:token])
    
    unless export_request
      redirect_to admin_export_personal_data_path, alert: 'Export request not found'
      return
    end
    
    unless export_request.status == 'completed'
      redirect_to admin_export_personal_data_path, alert: 'Export is not ready yet'
      return
    end
    
    unless File.exist?(export_request.file_path)
      redirect_to admin_export_personal_data_path, alert: 'Export file not found'
      return
    end
    
    send_file export_request.file_path,
              filename: "personal_data_#{export_request.email.gsub('@', '_at_')}_#{Date.today}.json",
              type: 'application/json',
              disposition: 'attachment'
  rescue => e
    Rails.logger.error("Personal data download error: #{e.message}")
    redirect_to admin_export_personal_data_path, alert: "Download failed: #{e.message}"
  end
end




