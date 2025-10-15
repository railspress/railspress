class Admin::TrashController < Admin::BaseController
  before_action :ensure_admin
  
  def index
    @posts = Post.trashed.includes(:user, :content_type).order(deleted_at: :desc)
    @pages = Page.trashed.includes(:user).order(deleted_at: :desc)
    @media = Medium.trashed.includes(:user, :upload).order(deleted_at: :desc)
    @comments = Comment.trashed.includes(:user, :commentable).order(deleted_at: :desc)
    
    @stats = {
      posts: @posts.count,
      pages: @pages.count,
      media: @media.count,
      comments: @comments.count,
      total: @posts.count + @pages.count + @media.count + @comments.count
    }
  end
  
  def restore
    item = find_item
    item.untrash!
    
    flash[:notice] = "#{item.class.name} restored successfully"
    redirect_to admin_trash_index_path
  end
  
  def destroy_permanently
    item = find_item
    item.destroy_permanently!
    
    flash[:notice] = "#{item.class.name} permanently deleted"
    redirect_to admin_trash_index_path
  end
  
  def empty_trash
    Post.trashed.find_each(&:destroy_permanently!)
    Page.trashed.find_each(&:destroy_permanently!)
    Medium.trashed.find_each(&:destroy_permanently!)
    Comment.trashed.find_each(&:destroy_permanently!)
    
    flash[:notice] = "Trash emptied successfully"
    redirect_to admin_trash_index_path
  end
  
  private
  
  def find_item
    model_class = params[:type].constantize
    model_class.find(params[:id])
  end
end
