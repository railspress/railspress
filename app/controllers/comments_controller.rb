class CommentsController < ApplicationController
  before_action :set_commentable

  def create
    @comment = @commentable.comments.build(comment_params)
    @comment.user = current_user if user_signed_in?
    @comment.status = :pending

    if @comment.save
      redirect_back fallback_location: root_path, notice: 'Your comment has been submitted and is awaiting moderation.'
    else
      redirect_back fallback_location: root_path, alert: 'There was an error submitting your comment.'
    end
  end

  private

  def set_commentable
    if params[:post_id]
      @commentable = Post.friendly.find(params[:post_id])
    elsif params[:page_id]
      @commentable = Page.friendly.find(params[:page_id])
    end
  end

  def comment_params
    params.require(:comment).permit(:content, :author_name, :author_email, :author_url, :parent_id)
  end
end





