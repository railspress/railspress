class Admin::SearchesController < Admin::BaseController
  # GET /admin/search/autocomplete?q=query&types=posts,pages
  def autocomplete
    query = params[:q]
    types = params[:types]&.split(',') || %w[posts pages taxonomies users]
    
    results = {
      posts: [],
      pages: [],
      taxonomies: [],
      users: []
    }
    
    if query.present?
      results[:posts] = search_posts(query) if types.include?('posts')
      results[:pages] = search_pages(query) if types.include?('pages')
      results[:taxonomies] = search_taxonomies(query) if types.include?('taxonomies')
      results[:users] = search_users(query) if types.include?('users')
    end
    
    render json: results
  end
  
  private
  
  def search_posts(query)
    Post.where("title LIKE ? OR content LIKE ?", "%#{query}%", "%#{query}%")
        .limit(5)
        .order(updated_at: :desc)
        .map { |p| post_json(p) }
  end
  
  def search_pages(query)
    Page.where("title LIKE ?", "%#{query}%")
        .limit(5)
        .order(updated_at: :desc)
        .map { |p| page_json(p) }
  end
  
  def search_taxonomies(query)
    Term.where("name LIKE ?", "%#{query}%")
        .limit(5)
        .order(name: :asc)
        .map { |t| taxonomy_json(t) }
  end
  
  def search_users(query)
    User.where("name LIKE ?", "%#{query}%")
        .limit(5)
        .order(name: :asc)
        .map { |u| user_json(u) }
  end
  
  def post_json(post)
    {
      id: post.id,
      title: post.title || 'Untitled',
      type: 'post',
      url: "/admin/posts/#{post.uuid}/edit",
      status: post.status,
      updated_at: post.updated_at
    }
  end
  
  def page_json(page)
    {
      id: page.id,
      title: page.title || 'Untitled',
      type: 'page',
      url: "/admin/pages/#{page.uuid}/edit",
      status: page.status,
      updated_at: page.updated_at
    }
  end
  
  def taxonomy_json(term)
    {
      id: term.id,
      name: term.name,
      type: 'taxonomy',
      taxonomy: term.taxonomy,
      url: "/admin/taxonomies/#{term.taxonomy}/terms/#{term.id}",
      count: 0
    }
  end
  
  def user_json(user)
    {
      id: user.id,
      name: user.name || 'Unknown',
      email: user.email || '',
      type: 'user',
      url: "/admin/users/#{user.id}",
      role: 'user'
    }
  end
end
