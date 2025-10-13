class Admin::Tools::ExportController < Admin::BaseController
  # GET /admin/tools/export
  def index
    @export_jobs = ExportJob.order(created_at: :desc).limit(20) rescue []
  end
  
  # POST /admin/tools/export/generate
  def generate
    export_type = params[:export_type] || 'json'
    export_options = params[:options] || {}
    
    # Create export job
    export_job = ExportJob.create!(
      export_type: export_type,
      user_id: current_user.id,
      status: 'pending',
      options: export_options,
      metadata: {
        include_posts: export_options[:include_posts] == '1',
        include_pages: export_options[:include_pages] == '1',
        include_media: export_options[:include_media] == '1',
        include_users: export_options[:include_users] == '1',
        include_settings: export_options[:include_settings] == '1',
        include_comments: export_options[:include_comments] == '1'
      }
    )
    
    # Queue the export job
    ExportWorker.perform_async(export_job.id)
    
    redirect_to admin_export_path, notice: 'Export started. You will be able to download it shortly...'
  rescue => e
    Rails.logger.error("Export generation error: #{e.message}")
    redirect_to admin_export_path, alert: "Export failed: #{e.message}"
  end
  
  # GET /admin/tools/export/download/:id
  def download
    export_job = ExportJob.find(params[:id])
    
    unless export_job.status == 'completed'
      redirect_to admin_export_path, alert: 'Export is not ready yet'
      return
    end
    
    unless File.exist?(export_job.file_path)
      redirect_to admin_export_path, alert: 'Export file not found'
      return
    end
    
    send_file export_job.file_path,
              filename: export_job.file_name,
              type: export_job.content_type || 'application/octet-stream',
              disposition: 'attachment'
  rescue => e
    Rails.logger.error("Export download error: #{e.message}")
    redirect_to admin_export_path, alert: "Download failed: #{e.message}"
  end
end





