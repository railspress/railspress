class Api::V1::UploadsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_upload_security
  before_action :validate_upload_permissions
  
  # POST /api/v1/uploads
  def create
    @upload = Upload.new(upload_params)
    @upload.user = current_user
    @upload.storage_provider = StorageProvider.active.first
    
    # Security validation
    unless @upload_security.file_allowed?(@upload.file)
      render json: { 
        error: 'File not allowed', 
        details: 'File type, size, or extension is not permitted' 
      }, status: :forbidden
      return
    end
    
    # Check for suspicious files
    if @upload_security.file_suspicious?(@upload.file)
      if @upload_security.quarantine_suspicious?
        @upload.quarantined = true
        @upload.quarantine_reason = 'Suspicious file pattern detected'
      else
        render json: { 
          error: 'File rejected', 
          details: 'File appears to be suspicious and has been blocked' 
        }, status: :forbidden
        return
      end
    end
    
    if @upload.save
      # Trigger plugin hooks
      Railspress::PluginSystem.do_action('upload_created', @upload)
      
      render json: {
        id: @upload.id,
        title: @upload.title,
        filename: @upload.filename,
        content_type: @upload.content_type,
        file_size: @upload.file_size,
        url: @upload.url,
        quarantined: @upload.quarantined?,
        created_at: @upload.created_at
      }, status: :created
    else
      render json: { 
        error: 'Upload failed', 
        details: @upload.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  # GET /api/v1/uploads
  def index
    @uploads = current_user.uploads.includes(:storage_provider)
    
    # Filter by plugin if specified
    if params[:plugin].present?
      @uploads = @uploads.where("title LIKE ? OR description LIKE ?", 
                               "%#{params[:plugin]}%", "%#{params[:plugin]}%")
    end
    
    # Filter by file type
    if params[:file_type].present?
      case params[:file_type]
      when 'image'
        @uploads = @uploads.joins(:file_attachment)
                          .where(active_storage_blobs: { content_type: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'] })
      when 'document'
        @uploads = @uploads.joins(:file_attachment)
                          .where(active_storage_blobs: { content_type: ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'] })
      when 'archive'
        @uploads = @uploads.joins(:file_attachment)
                          .where(active_storage_blobs: { content_type: ['application/zip', 'application/x-rar-compressed'] })
      end
    end
    
    # Filter by quarantine status
    if params[:quarantined].present?
      @uploads = @uploads.where(quarantined: params[:quarantined] == 'true')
    end
    
    # Pagination
    @uploads = @uploads.page(params[:page]).per(params[:per_page] || 20)
    
    render json: {
      uploads: @uploads.map do |upload|
        {
          id: upload.id,
          title: upload.title,
          description: upload.description,
          filename: upload.filename,
          content_type: upload.content_type,
          file_size: upload.file_size,
          url: upload.url,
          quarantined: upload.quarantined?,
          quarantine_reason: upload.quarantine_reason,
          created_at: upload.created_at,
          updated_at: upload.updated_at
        }
      end,
      pagination: {
        current_page: @uploads.current_page,
        total_pages: @uploads.total_pages,
        total_count: @uploads.total_count,
        per_page: @uploads.limit_value
      }
    }
  end
  
  # GET /api/v1/uploads/:id
  def show
    @upload = current_user.uploads.find(params[:id])
    
    render json: {
      id: @upload.id,
      title: @upload.title,
      description: @upload.description,
      filename: @upload.filename,
      content_type: @upload.content_type,
      file_size: @upload.file_size,
      url: @upload.url,
      quarantined: @upload.quarantined?,
      quarantine_reason: @upload.quarantine_reason,
      created_at: @upload.created_at,
      updated_at: @upload.updated_at,
      storage_provider: {
        id: @upload.storage_provider.id,
        name: @upload.storage_provider.name,
        type: @upload.storage_provider.provider_type
      }
    }
  end
  
  # PATCH/PUT /api/v1/uploads/:id
  def update
    @upload = current_user.uploads.find(params[:id])
    
    if @upload.update(upload_params.except(:file))
      render json: {
        id: @upload.id,
        title: @upload.title,
        description: @upload.description,
        filename: @upload.filename,
        content_type: @upload.content_type,
        file_size: @upload.file_size,
        url: @upload.url,
        quarantined: @upload.quarantined?,
        quarantine_reason: @upload.quarantine_reason,
        updated_at: @upload.updated_at
      }
    else
      render json: { 
        error: 'Update failed', 
        details: @upload.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/uploads/:id
  def destroy
    @upload = current_user.uploads.find(params[:id])
    @upload.destroy!
    
    head :no_content
  end
  
  # POST /api/v1/uploads/:id/approve
  def approve
    @upload = current_user.uploads.find(params[:id])
    
    if @upload.quarantined?
      @upload.update!(quarantined: false, quarantine_reason: nil)
      render json: { message: 'Upload approved and released from quarantine' }
    else
      render json: { error: 'Upload is not quarantined' }, status: :bad_request
    end
  end
  
  # POST /api/v1/uploads/:id/reject
  def reject
    @upload = current_user.uploads.find(params[:id])
    
    if @upload.quarantined?
      @upload.destroy!
      render json: { message: 'Upload rejected and deleted' }
    else
      render json: { error: 'Upload is not quarantined' }, status: :bad_request
    end
  end
  
  private
  
  def set_upload_security
    @upload_security = UploadSecurity.current
  end
  
  def validate_upload_permissions
    unless current_user.can_upload_files?
      render json: { error: 'Insufficient permissions' }, status: :forbidden
    end
  end
  
  def upload_params
    params.require(:upload).permit(:title, :description, :alt_text, :file)
  end
end

