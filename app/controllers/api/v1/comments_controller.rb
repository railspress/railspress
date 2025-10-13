module Api
  module V1
    class CommentsController < BaseController
      skip_before_action :authenticate_api_user!, only: [:index, :show, :create]
      before_action :set_comment, only: [:show, :update, :destroy, :approve, :spam]
      
      # GET /api/v1/comments
      def index
        comments = Comment.includes(:user, :commentable)
        
        # Filter by status
        comments = comments.where(status: params[:status]) if params[:status].present?
        
        # Filter by commentable
        if params[:post_id].present?
          comments = comments.where(commentable_type: 'Post', commentable_id: params[:post_id])
        elsif params[:page_id].present?
          comments = comments.where(commentable_type: 'Page', commentable_id: params[:page_id])
        end
        
        # Only approved for non-authenticated users
        unless current_api_user&.can_edit_others_posts?
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
        @comment = Comment.new(comment_params)
        @comment.user = current_api_user if current_api_user
        @comment.status = :pending
        
        if @comment.save
          render_success(comment_serializer(@comment), {}, :created)
        else
          render_error(@comment.errors.full_messages.join(', '))
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
        return true if current_api_user&.can_edit_others_posts?
        @comment.user_id == current_api_user&.id
      end
      
      def can_delete_comment?
        return true if current_api_user&.administrator?
        @comment.user_id == current_api_user&.id
      end
      
      def comment_params
        params.require(:comment).permit(
          :content, :author_name, :author_email, :author_url,
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
    end
  end
end






