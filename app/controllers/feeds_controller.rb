class FeedsController < ApplicationController
  before_action :set_cache_headers
  
  # GET /feed or /feed.rss
  def posts
    @posts = Post.published_status.visible_to_public
                 .order(published_at: :desc)
                 .limit(50)
                 .includes(:user, :terms)
    
    respond_to do |format|
      format.rss { render layout: false }
      format.atom { render layout: false }
    end
  end
  
  # GET /feed/posts.rss
  def posts_rss
    posts
  end
  
  # GET /feed/comments.rss
  def comments
    @comments = Comment.where(status: 'approved')
                      .order(created_at: :desc)
                      .limit(50)
                      .includes(:commentable)
    
    respond_to do |format|
      format.rss { render layout: false }
    end
  end
  
  # GET /feed/category/:slug.rss
  def category
    @category = Term.for_taxonomy('category').friendly.find(params[:slug])
    @posts = @category.posts.published_status.visible_to_public
                     .order(published_at: :desc)
                     .limit(50)
                     .includes(:user, :taxonomies)
    @title_suffix = "Category: #{@category.name}"
    
    respond_to do |format|
      format.rss { render :posts, layout: false }
    end
  end
  
  # GET /feed/tag/:slug.rss
  def tag
    tag_taxonomy = Taxonomy.find_by!(slug: 'tag')
    @tag = tag_taxonomy.terms.friendly.find(params[:slug])
    @posts = Post.published_status.visible_to_public
                 .joins(:term_relationships)
                 .where(term_relationships: { term_id: @tag.id })
                 .order(published_at: :desc)
                 .distinct
                 .limit(50)
                 .includes(:user, :terms)
    @title_suffix = "Tag: #{@tag.name}"
    
    respond_to do |format|
      format.rss { render :posts, layout: false }
    end
  end
  
  # GET /feed/author/:id.rss
  def author
    @user = User.find(params[:id])
    @posts = @user.posts.published_status.visible_to_public
                  .order(published_at: :desc)
                  .limit(50)
                  .includes(:user, :terms)
    @title_suffix = "Author: #{@user.name || @user.email}"
    
    respond_to do |format|
      format.rss { render :posts, layout: false }
    end
  end
  
  # GET /feed/pages.rss
  def pages
    @pages = Page.published_status.visible_to_public
                 .order(published_at: :desc)
                 .limit(50)
    
    respond_to do |format|
      format.rss { render layout: false }
    end
  end
  
  private
  
  def set_cache_headers
    # Cache RSS feeds for 1 hour
    expires_in 1.hour, public: true
  end
end



