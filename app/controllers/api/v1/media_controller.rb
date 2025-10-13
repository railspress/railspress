module Api
  module V1
    class MediaController < BaseController
      before_action :set_medium, only: [:show, :update, :destroy]
      
      # GET /api/v1/media
      def index
        media = Medium.includes(:user)
        
        # Filter by file type
        case params[:type]
        when 'images'
          media = media.images
        when 'videos'
          media = media.videos
        when 'documents'
          media = media.documents
        end
        
        # Search
        media = media.where('title LIKE ?', "%#{params[:q]}%") if params[:q].present?
        
        # Paginate
        @media = paginate(media.recent)
        
        render_success(
          @media.map { |m| medium_serializer(m) }
        )
      end
      
      # GET /api/v1/media/:id
      def show
        render_success(medium_serializer(@medium, detailed: true))
      end
      
      # POST /api/v1/media
      def create
        @medium = current_api_user.media.build(medium_params)
        
        if @medium.save
          render_success(medium_serializer(@medium), {}, :created)
        else
          render_error(@medium.errors.full_messages.join(', '))
        end
      end
      
      # PATCH/PUT /api/v1/media/:id
      def update
        unless can_edit_medium?
          return render_error('You do not have permission to edit this media', :forbidden)
        end
        
        if @medium.update(medium_params)
          render_success(medium_serializer(@medium))
        else
          render_error(@medium.errors.full_messages.join(', '))
        end
      end
      
      # DELETE /api/v1/media/:id
      def destroy
        unless can_delete_medium?
          return render_error('You do not have permission to delete this media', :forbidden)
        end
        
        @medium.destroy
        render_success({ message: 'Media deleted successfully' })
      end
      
      private
      
      def set_medium
        @medium = Medium.find(params[:id])
      end
      
      def can_edit_medium?
        return true if current_api_user.can_edit_others_posts?
        @medium.user_id == current_api_user.id
      end
      
      def can_delete_medium?
        return true if current_api_user.can_delete_posts?
        @medium.user_id == current_api_user.id
      end
      
      def medium_params
        params.require(:medium).permit(:title, :description, :alt_text, :file)
      end
      
      def medium_serializer(medium, detailed: false)
        data = {
          id: medium.id,
          title: medium.title,
          description: medium.description,
          alt_text: medium.alt_text,
          file_type: medium.file_type,
          file_size: medium.file_size,
          created_at: medium.created_at,
          updated_at: medium.updated_at,
          author: {
            id: medium.user.id,
            email: medium.user.email
          },
          url: medium.file.attached? ? url_for(medium.file) : nil,
          thumbnail_url: medium.image? && medium.file.attached? ? url_for(medium.file.variant(resize_to_limit: [300, 300])) : nil
        }
        
        data
      end
    end
  end
end




