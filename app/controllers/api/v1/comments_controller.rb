module Api
  module V1
    class CommentsController < BaseController
      # No authentication required for public comment creation
      before_action :set_comment, only: [:show, :update, :destroy, :approve, :spam]
      
      # GET /api/v1/comments
      def index
        comments = Comment.kept.includes(:user, :commentable)
        
        # Filter by status
        comments = comments.where(status: params[:status]) if params[:status].present?
        
        # Filter by commentable
        if params[:post_id].present?
          comments = comments.where(commentable_type: 'Post', commentable_id: params[:post_id])
        elsif params[:page_id].present?
          comments = comments.where(commentable_type: 'Page', commentable_id: params[:page_id])
        end
        
        # Only approved for non-authenticated users
        unless @api_user&.can_edit_others_posts?
          comments = comments.approved
        end
        
        # Root comments only or include replies
        comments = comments.root_comments if params[:root_only] == 'true'
        
        @comments = paginate(comments.recent)
        
        render_success(
          @comments.map { |comment| comment_serializer(comment) }
        )
      end
      
      # GET /api/v1/comments/:id
      def show
        render_success(comment_serializer(@comment, detailed: true))
      end
      
      # POST /api/v1/comments
      def create
        # Check if comments are enabled
        unless SiteSetting.get('comments_enabled', true)
          return render json: { error: 'Comments are disabled for this site' }, status: :forbidden
        end
        
        # Check if registration is required and user is not logged in
        if SiteSetting.get('comment_registration_required', false) && !@api_user
          return render json: { error: 'You must be logged in to post comments' }, status: :unauthorized
        end
        
        @comment = Comment.new(comment_params)
        @comment.user = @api_user if @api_user
        
        # Check Akismet if enabled
        if akismet_enabled?
          akismet_data = {
            user_ip: request.remote_ip,
            user_agent: request.user_agent,
            referrer: request.referer,
            permalink: commentable_url(@comment.commentable),
            comment_type: 'comment',
            comment_author: @comment.author_name || @comment.user&.email,
            comment_author_email: @comment.author_email || @comment.user&.email,
            comment_author_url: @comment.author_url,
            comment_content: @comment.content
          }
          
          akismet = AkismetService.new(akismet_api_key, site_url)
          if akismet.spam?(akismet_data)
            @comment.status = :spam
          else
            @comment.status = SiteSetting.get('comments_moderation', true) ? :pending : :approved
          end
        else
          @comment.status = SiteSetting.get('comments_moderation', true) ? :pending : :approved
        end
        
        if @comment.save
          render json: { success: true, comment: { id: @comment.id, status: @comment.status } }, status: :created
        else
          render json: { error: @comment.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end
      
      # PATCH/PUT /api/v1/comments/:id
      def update
        unless can_edit_comment?
          return render_error('You do not have permission to edit this comment', :forbidden)
        end
        
        if @comment.update(comment_update_params)
          render_success(comment_serializer(@comment))
        else
          render_error(@comment.errors.full_messages.join(', '))
        end
      end
      
      # DELETE /api/v1/comments/:id
      def destroy
        unless can_delete_comment?
          return render_error('You do not have permission to delete this comment', :forbidden)
        end
        
        @comment.destroy
        render_success({ message: 'Comment deleted successfully' })
      end
      
      # PATCH /api/v1/comments/:id/approve
      def approve
        unless current_api_user.can_edit_others_posts?
          return render_error('You do not have permission to approve comments', :forbidden)
        end
        
        @comment.update(status: :approved)
        render_success(comment_serializer(@comment))
      end
      
      # PATCH /api/v1/comments/:id/spam
      def spam
        unless current_api_user.can_edit_others_posts?
          return render_error('You do not have permission to mark comments as spam', :forbidden)
        end
        
        @comment.update(status: :spam)
        render_success(comment_serializer(@comment))
      end
      
      private
      
      def set_comment
        @comment = Comment.find(params[:id])
      end
      
      def can_edit_comment?
        return true if @api_user&.can_edit_others_posts?
        @comment.user_id == @api_user&.id
      end
      
      def can_delete_comment?
        return true if @api_user&.administrator?
        @comment.user_id == @api_user&.id
      end
      
      def comment_params
        params.require(:comment).permit(
          :content, :author_name, :author_email, :author_url, :author_ip, :author_agent,
          :comment_type, :comment_approved, :comment_parent_id,
          :commentable_type, :commentable_id, :parent_id
        )
      end
      
      def comment_update_params
        if current_api_user&.can_edit_others_posts?
          params.require(:comment).permit(:content, :status, :author_name, :author_email, :author_url)
        else
          params.require(:comment).permit(:content)
        end
      end
      
      def comment_serializer(comment, detailed: false)
        data = {
          id: comment.id,
          content: comment.content,
          author: comment.author,
          author_email: comment.author_email,
          author_url: comment.author_url,
          status: comment.status,
          created_at: comment.created_at,
          updated_at: comment.updated_at,
          commentable: {
            type: comment.commentable_type,
            id: comment.commentable_id,
            title: comment.commentable.try(:title)
          },
          parent_id: comment.parent_id,
          replies_count: comment.replies.count
        }
        
        if detailed
          data.merge!(
            replies: comment.replies.approved.map { |r| comment_serializer(r) },
            user: comment.user ? { id: comment.user.id, email: comment.user.email } : nil
          )
        end
        
        data
      end

      def akismet_enabled?
        SiteSetting.get('akismet_enabled', false) && SiteSetting.get('akismet_api_key', '').present?
      end

      def akismet_api_key
        SiteSetting.get('akismet_api_key', '')
      end

      def site_url
        SiteSetting.get('site_url', 'http://localhost:3000')
      end

      def commentable_url(commentable)
        case commentable
        when Post
          "#{site_url}/posts/#{commentable.slug}"
        when Page
          "#{site_url}/pages/#{commentable.slug}"
        else
          site_url
        end
      end
    end
  end
end








