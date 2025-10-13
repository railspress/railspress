class Admin::Tools::ImportController < Admin::BaseController
  # GET /admin/tools/import
  def index
    @import_jobs = ImportJob.order(created_at: :desc).limit(20) rescue []
  end
  
  # POST /admin/tools/import/upload
  def upload
    unless params[:file].present?
      redirect_to admin_import_path, alert: 'Please select a file to import'
      return
    end
    
    file = params[:file]
    import_type = params[:import_type] || 'wordpress'
    
    # Validate file type
    allowed_extensions = case import_type
    when 'wordpress' then ['.xml']
    when 'json' then ['.json']
    when 'csv' then ['.csv']
    else ['.xml', '.json', '.csv']
    end
    
    file_ext = File.extname(file.original_filename).downcase
    unless allowed_extensions.include?(file_ext)
      redirect_to admin_import_path, alert: "Invalid file type. Allowed: #{allowed_extensions.join(', ')}"
      return
    end
    
    # Store file temporarily
    temp_file = Tempfile.new(['import', file_ext])
    temp_file.binmode
    temp_file.write(file.read)
    temp_file.rewind
    
    # Create import job
    import_job = ImportJob.create!(
      import_type: import_type,
      file_path: temp_file.path,
      file_name: file.original_filename,
      user_id: current_user.id,
      status: 'pending',
      metadata: {
        file_size: file.size,
        content_type: file.content_type
      }
    )
    
    # Queue the import job
    ImportWorker.perform_async(import_job.id)
    
    redirect_to admin_import_path, notice: 'Import started. This may take a few minutes...'
  rescue => e
    Rails.logger.error("Import upload error: #{e.message}")
    redirect_to admin_import_path, alert: "Import failed: #{e.message}"
  end
  
  # POST /admin/tools/import/process
  def process
    import_job = ImportJob.find(params[:id])
    
    if import_job.status == 'completed'
      redirect_to admin_import_path, alert: 'This import has already been processed'
      return
    end
    
    ImportWorker.perform_async(import_job.id)
    
    redirect_to admin_import_path, notice: 'Import restarted'
  end
end






