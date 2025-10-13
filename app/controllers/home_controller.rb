class HomeController < ApplicationController
  include LiquidRenderable
  
  def index
    featured_posts = Post.published.recent.limit(3)
    recent_posts = Post.published.recent.limit(6)
    categories = Term.for_taxonomy('category').limit(10)
    
    render_liquid('index', {
      'featured_posts' => featured_posts,
      'recent_posts' => recent_posts,
      'categories' => categories,
      'template' => 'index'
    })
  end
end
