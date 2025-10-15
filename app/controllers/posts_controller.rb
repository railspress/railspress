class PostsController < ApplicationController
  include LiquidRenderable
  
  def index
    posts = Post.visible_to_public.recent.includes(:user, :categories, :tags).page(params[:page])
    title = "Blog"
    
    render_liquid('blog', {
      'posts' => posts,
      'title' => title,
      'template' => 'blog',
      'paginate' => {
        'current_page' => posts.current_page,
        'total_pages' => posts.total_pages,
        'per_page' => posts.limit_value
      }
    })
  end

  def show
    post = Post.friendly.find(params[:id])
    
    # Check if visible (handles all statuses)
    unless post.visible_to_public? || can_view_post?(post)
      raise ActiveRecord::RecordNotFound
    end
    
    # Auto-publish scheduled posts
    post.check_scheduled_publish
    
    # Check password protection
    if post.password_protected? && !password_verified?(post)
      return render_liquid('password_protected', { 'post' => post })
    end
    
    # Use Related Posts plugin if available, otherwise fallback to basic logic
    category_taxonomy = Taxonomy.find_by(slug: 'category')
    post_categories = category_taxonomy ? post.terms.where(taxonomy: category_taxonomy) : []
    
    related_posts = if defined?(RelatedPosts)
      RelatedPosts.find_related(post, 3)
    elsif post_categories.any?
      term_ids = post_categories.pluck(:id)
      Post.visible_to_public
          .joins(:term_relationships)
          .where(term_relationships: { term_id: term_ids })
          .where.not(id: post.id)
          .distinct
          .limit(3)
    else
      []
    end
    
    comments = post.comments.approved.root_comments.order(created_at: :desc)
    
    # Trigger post viewed hook for analytics plugins
    Railspress::PluginSystem.do_action('post_viewed', post.id) if defined?(Railspress::PluginSystem)
    
    render_liquid('post', {
      'post' => post,
      'page' => {
        'title' => post.title,
        'description' => post.respond_to?(:excerpt) ? post.excerpt : post.content.to_s.truncate(200),
        'featured_image' => post.respond_to?(:featured_image_url) ? post.featured_image_url : nil,
        'type' => 'article',
        'schema_type' => 'Article',
        'author' => post.user,
        'published_at' => post.published_at,
        'updated_at' => post.updated_at,
        'categories' => post.terms.joins(:taxonomy).where(taxonomies: { slug: 'category' }).to_a,
        'tags' => post.terms.joins(:taxonomy).where(taxonomies: { slug: 'tag' }).to_a
      },
      'site' => {
        'title' => SiteSetting.get('site_title', 'RailsPress'),
        'description' => SiteSetting.get('site_description', 'Built with RailsPress'),
        'settings' => {
          'comments_enabled' => SiteSetting.get('comments_enabled', true),
          'comments_moderation' => SiteSetting.get('comments_moderation', true),
          'comment_registration_required' => SiteSetting.get('comment_registration_required', false),
          'close_comments_after_days' => SiteSetting.get('close_comments_after_days', 0),
          'show_avatars' => SiteSetting.get('show_avatars', true),
          'akismet_enabled' => SiteSetting.get('akismet_enabled', false),
          'akismet_api_key' => SiteSetting.get('akismet_api_key', '')
        }
      },
      'related_posts' => related_posts.to_a,
      'comments' => comments.to_a,
      'current_user' => user_signed_in? ? current_user : nil,
      'template' => 'post'
    })
  end
  
  # POST /blog/:id/verify_password
  def verify_password
    @post = Post.friendly.find(params[:id])
    
    if @post.password_matches?(params[:password])
      # Store verified post ID in session
      session[:verified_posts] ||= []
      session[:verified_posts] << @post.id unless session[:verified_posts].include?(@post.id)
      
      redirect_to blog_post_path(@post), notice: 'Password verified successfully.'
    else
      redirect_to blog_post_path(@post), alert: 'Incorrect password. Please try again.'
    end
  end
  
  def category
    category = Term.for_taxonomy('category').friendly.find(params[:slug])
    posts = category.posts.visible_to_public.recent.page(params[:page])
    
    render_liquid('category', {
      'category' => category,
      'posts' => posts,
      'title' => "Category: #{category.name}",
      'page' => {
        'title' => "Category: #{category.name}",
        'description' => category.description
      },
      'template' => 'category',
      'paginate' => {
        'current_page' => posts.current_page,
        'total_pages' => posts.total_pages,
        'per_page' => posts.limit_value
      }
    })
  end
  
  def tag
    tag = Term.for_taxonomy('post_tag').friendly.find(params[:slug])
    posts = tag.posts.visible_to_public.recent.page(params[:page])
    
    render_liquid('tag', {
      'tag' => tag,
      'posts' => posts,
      'title' => "Tag: #{tag.name}",
      'page' => {
        'title' => "Tag: #{tag.name}",
        'description' => tag.description
      },
      'template' => 'tag',
      'paginate' => {
        'current_page' => posts.current_page,
        'total_pages' => posts.total_pages,
        'per_page' => posts.limit_value
      }
    })
  end
  
  def archive
    year = params[:year].to_i
    month = params[:month]&.to_i
    
    posts = Post.visible_to_public
    
    # SQLite-compatible date filtering
    if month
      start_date = Date.new(year, month, 1)
      end_date = start_date.end_of_month
    else
      start_date = Date.new(year, 1, 1)
      end_date = Date.new(year, 12, 31)
    end
    
    posts = posts.where(published_at: start_date.beginning_of_day..end_date.end_of_day)
    posts = posts.recent.page(params[:page])
    
    title = month ? "Archive: #{Date::MONTHNAMES[month]} #{year}" : "Archive: #{year}"
    
    render_liquid('archive', {
      'posts' => posts,
      'title' => title,
      'year' => year,
      'month' => month,
      'page' => {
        'title' => title
      },
      'template' => 'archive',
      'paginate' => {
        'current_page' => posts.current_page,
        'total_pages' => posts.total_pages,
        'per_page' => posts.limit_value
      }
    })
  end
  
  def search
    query = params[:q]
    posts = query.present? ? Post.visible_to_public.search(query).recent.page(params[:page]) : Post.none
    
    render_liquid('search', {
      'posts' => posts,
      'query' => query,
      'title' => "Search results for: #{query}",
      'page' => {
        'title' => "Search results for: #{query}"
      },
      'template' => 'search',
      'paginate' => posts.any? ? {
        'current_page' => posts.current_page,
        'total_pages' => posts.total_pages,
        'per_page' => posts.limit_value
      } : {}
    })
  end
  
  private
  
  def can_view_post?(post)
    return false unless user_signed_in?
    
    # Admins and editors can view everything
    return true if current_user.administrator? || current_user.editor?
    
    # Authors can view their own posts
    return true if post.user_id == current_user.id
    
    # Private posts visible to any logged-in user
    return true if post.private_post_status?
    
    false
  end
  
  def password_verified?(post)
    return true unless post.password_protected?
    return true if can_view_post?(post)  # Admins/editors/authors bypass password
    
    session[:verified_posts]&.include?(post.id)
  end
end
