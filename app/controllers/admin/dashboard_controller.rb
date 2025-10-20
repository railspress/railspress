class Admin::DashboardController < Admin::BaseController
  def index
    # Content metrics only
    @posts_count = Post.count
    @published_posts_count = Post.published.count
    @pages_count = Page.count
    @comments_count = Comment.count
    @pending_comments_count = Comment.pending.count
    @recent_posts = Post.order(created_at: :desc).limit(5)
    @recent_comments = Comment.order(created_at: :desc).limit(5)
  end
end