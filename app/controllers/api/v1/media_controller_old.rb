class Api::V1::MediaController < ApplicationController
  before_action :authenticate_user!
  before_action :set_medium, only: %i[show update destroy approve reject]
  before_action :validate_media_permissions
  
  # GET /api/v1/media
  def index
    @media = Medium.all
    
    # Filter by type
    if params[:type].present?
      @media = @media.by_type(params[:type])
    end
    
    # Filter by user
    if params[:user_id].present?
      @media = @media.where(user_id: params[:user_id])
    end
    
    # Filter by quarantine status
    if params[:quarantined].present?
      @media = params[:quarantined] == 'true' ? @media.quarantined : @media.approved
    end
    
    # Filter by channel
    if params[:channel].present?
      channel = Channel.find_by(slug: params[:channel])
      if channel
        # Get media assigned to this channel or global media (no channel assignment)
        @media = @media.left_joins(:channels)
                       .where('channels.id = ? OR channels.id IS NULL', channel.id)
        
        # Apply channel exclusions
        excluded_media_ids = channel.channel_overrides
                                    .exclusions
                                    .enabled
                                    .where(resource_type: 'Medium')
                                    .pluck(:resource_id)
        @media = @media.where.not(id: excluded_media_ids) if excluded_media_ids.any?
        
        @current_channel = channel
      end
    end
    
    # Search
    if params[:search].present?
      @media = @media.where("media.title ILIKE ? OR media.description ILIKE ?", 
                           "%#{params[:search]}%", "%#{params[:search]}%")
    end
    
    # Pagination
    @media = @media.page(params[:page]).per(params[:per_page] || 20)
    
    render json: {
      media: @media.map { |medium| medium_serializer(medium) },
      pagination: {
        current_page: @media.current_page,
        total_pages: @media.total_pages,
        total_count: @media.total_count,
        per_page: @media.limit_value
      },
      stats: {
        total: Medium.count,
        images: Medium.images.count,
        videos: Medium.videos.count,
        documents: Medium.documents.count,
        quarantined: Medium.quarantined.count
      },
      filters: {
        type: params[:type],
        user_id: params[:user_id],
        quarantined: params[:quarantined],
        search: params[:search],
        channel: params[:channel]
      }
    }
  end
  
  # GET /api/v1/media/:id
  def show
    render json: @medium.api_attributes
  end
  
  # POST /api/v1/media
  def create
    # Check if we're creating from an existing upload
    if params[:upload_id].present?
      upload = current_user.uploads.find(params[:upload_id])
      
      @medium = Medium.new(medium_params.except(:file))
      @medium.user = current_user
      @medium.upload = upload
      
      if @medium.save
        render json: @medium.api_attributes, status: :created
      else
        render json: { 
          error: 'Media creation failed', 
          details: @medium.errors.full_messages 
        }, status: :unprocessable_entity
      end
    else
      # Create new upload and media together
      if params[:medium][:file].present?
        # Create upload first
        upload = current_user.uploads.build(
          title: params[:medium][:title] || params[:medium][:file].original_filename,
          description: params[:medium][:description],
          alt_text: params[:medium][:alt_text]
        )
        upload.file.attach(params[:medium][:file])
        upload.storage_provider = StorageProvider.active.first
        
        # Security validation
        security = UploadSecurity.current
        unless security.file_allowed?(params[:medium][:file])
          render json: { 
            error: 'File not allowed', 
            details: 'File type, size, or extension is not permitted' 
          }, status: :forbidden
          return
        end
        
        # Check for suspicious files
        if security.file_suspicious?(params[:medium][:file])
          if security.quarantine_suspicious?
            upload.quarantined = true
            upload.quarantine_reason = 'Suspicious file pattern detected'
          else
            render json: { 
              error: 'File rejected', 
              details: 'File appears to be suspicious and has been blocked' 
            }, status: :forbidden
            return
          end
        end
        
        if upload.save
          # Create media record
          @medium = Medium.new(medium_params.except(:file))
          @medium.user = current_user
          @medium.upload = upload
          
          if @medium.save
            render json: @medium.api_attributes, status: :created
          else
            upload.destroy # Clean up upload if media creation fails
            render json: { 
              error: 'Media creation failed', 
              details: @medium.errors.full_messages 
            }, status: :unprocessable_entity
          end
        else
          render json: { 
            error: 'Upload failed', 
            details: upload.errors.full_messages 
          }, status: :unprocessable_entity
        end
      else
        render json: { 
          error: 'No file provided', 
          details: 'Either file or upload_id must be provided' 
        }, status: :bad_request
      end
    end
  end
  
  # PATCH/PUT /api/v1/media/:id
  def update
    if @medium.update(medium_params.except(:file))
      render json: @medium.api_attributes
    else
      render json: { 
        error: 'Update failed', 
        details: @medium.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/media/:id
  def destroy
    @medium.destroy!
    head :no_content
  end
  
  # POST /api/v1/media/:id/approve
  def approve
    if @medium.quarantined?
      @medium.upload.approve!
      render json: { message: 'Media approved and released from quarantine' }
    else
      render json: { error: 'Media is not quarantined' }, status: :bad_request
    end
  end
  
  # POST /api/v1/media/:id/reject
  def reject
    if @medium.quarantined?
      @medium.destroy!
      render json: { message: 'Media rejected and deleted' }
    else
      render json: { error: 'Media is not quarantined' }, status: :bad_request
    end
  end
  
  private
  
  def medium_serializer(medium)
    data = medium.api_attributes.merge({
      channels: medium.channels.map { |c| c.slug },
      channel_context: @current_channel&.slug
    })
    
    # Apply channel overrides if current channel is set
    if @current_channel
      data = @current_channel.apply_overrides_to_data(data, 'Medium', medium.id)
      
      # Add provenance information
      data[:provenance] = {
        title: data[:title] != medium.title ? 'channel_override' : 'resource',
        description: data[:description] != medium.description ? 'channel_override' : 'resource'
      }
    end
    
    data
  end
  
  def set_medium
    @medium = current_user.media.find(params[:id])
  end
  
  def validate_media_permissions
    unless current_user.can_upload_media?
      render json: { error: 'Insufficient permissions' }, status: :forbidden
    end
  end
  
  def medium_params
    params.require(:medium).permit(:title, :description, :alt_text, :file, :upload_id)
  end
end