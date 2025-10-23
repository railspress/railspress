class Admin::MediaController < Admin::BaseController
  before_action :set_medium, only: %i[ show edit update destroy ]
  skip_before_action :verify_authenticity_token, only: [:upload]

  # GET /admin/media or /admin/media.json
  def index
    @media = Medium.kept.includes(:user, :upload).order(created_at: :desc)
    
    # Show trashed if explicitly requested
    if params[:show_trash] == 'true'
      @media = Medium.trashed.includes(:user, :upload).order(deleted_at: :desc)
    end
    
    respond_to do |format|
      format.html do
        # For the new grid view, we just need the media objects
        # No need for complex JSON data structure
      end
      format.json { render json: media_json }
    end
  end

  # POST /admin/media/bulk_upload
  def bulk_upload
    uploaded_files = []
    errors = []

    if params[:media].present?
      params[:media].each do |index, media_params|
        medium = Medium.new(
          title: media_params[:title],
          user: current_user
        )
        
        if media_params[:file].present?
          medium.file.attach(media_params[:file])
          
          if medium.save
            uploaded_files << medium
          else
            errors << "#{media_params[:file].original_filename}: #{medium.errors.full_messages.join(', ')}"
          end
        end
      end
    end

    respond_to do |format|
      if errors.empty?
        format.json { render json: { success: true, message: "Successfully uploaded #{uploaded_files.count} file(s)" } }
      else
        format.json { render json: { success: false, message: errors.join('; ') }, status: :unprocessable_entity }
      end
    end
  end

  # POST /admin/media/upload (for EditorJS and general file uploads)
  def upload
    # Accept both :image (EditorJS) and :file (generic) parameters
    file = params[:image] || params[:file]
    
    unless file.present?
      return render json: {
        success: 0,
        message: 'No file provided'
      }, status: :bad_request
    end
    
    # Security validation
    upload_security = UploadSecurity.current
    unless upload_security.file_allowed?(file)
      return render json: {
        success: 0,
        message: 'File type, size, or extension is not permitted'
      }, status: :forbidden
    end
    
    # Check for suspicious files
    quarantine_file = false
    quarantine_reason = nil
    
    if upload_security.file_suspicious?(file)
      if upload_security.quarantine_suspicious?
        quarantine_file = true
        quarantine_reason = 'Suspicious file pattern detected'
      else
        return render json: {
          success: 0,
          message: 'File appears to be suspicious and has been blocked'
        }, status: :forbidden
      end
    end
    
    # Create Upload record with file attachment
    upload = Upload.new(
      title: file.original_filename,
      user: current_user,
      quarantined: quarantine_file,
      quarantine_reason: quarantine_reason
    )
    upload.file.attach(file)
    upload.storage_provider = StorageProvider.active.first
    
    # Create Medium record linked to upload
    medium = Medium.new(
      title: file.original_filename,
      user: current_user,
      upload: upload
    )
    
    if upload.save && medium.save
      # Medium after_create callback will trigger:
      # - media_uploaded plugin hooks
      # - optimize_image_if_needed (for images only)
      
      render json: {
        success: 1,
        file: {
          url: upload.url,
          size: upload.file_size,
          type: upload.content_type
        },
        medium_id: medium.id
      }
    else
      render json: {
        success: 0,
        message: (upload.errors.full_messages + medium.errors.full_messages).join(', ')
      }, status: :unprocessable_entity
    end
  end

  # GET /admin/media/1 or /admin/media/1.json
  def show
  end

  # GET /admin/media/new
  def new
    @medium = Medium.new
  end

  # GET /admin/media/1/edit
  def edit
  end

  # POST /admin/media or /admin/media.json
  def create
    @medium = Medium.new(medium_params)

    respond_to do |format|
      if @medium.save
        format.html { redirect_to [:admin, @medium], notice: "Medium was successfully created." }
        format.json { render :show, status: :created, location: @medium }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @medium.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/media/1 or /admin/media/1.json
  def update
    respond_to do |format|
      if @medium.update(medium_params)
        format.html { redirect_to [:admin, @medium], notice: "Medium was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @medium }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @medium.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/media/1 or /admin/media/1.json
  def destroy
    if @medium.trashed?
      @medium.destroy_permanently! # Permanent delete
      notice = "Media was permanently deleted."
    else
      @medium.trash!(current_user) # Soft delete
      notice = "Media was moved to trash."
    end

    respond_to do |format|
      format.html { redirect_to admin_media_path, notice: notice, status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_medium
      @medium = Medium.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def medium_params
      params.fetch(:medium, {})
    end

    def media_json
      @media.includes(:upload).map do |medium|
        {
          id: medium.id,
          filename: medium.filename,
          title: medium.title,
          file_type: medium.content_type,
          file_size: medium.file_size,
          thumbnail_url: medium.image? ? medium.url : nil,
          quarantined: medium.quarantined?,
          quarantine_reason: medium.quarantine_reason,
          created_at: medium.created_at.iso8601,
          edit_url: edit_admin_medium_path(medium),
          show_url: admin_medium_path(medium),
          delete_url: admin_medium_path(medium)
        }
      end
    end
end
