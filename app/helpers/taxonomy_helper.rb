module TaxonomyHelper
  # Get category taxonomy
  def category_taxonomy
    @category_taxonomy ||= Taxonomy.find_by(slug: 'category')
  end
  
  # Get tag taxonomy
  def tag_taxonomy
    @tag_taxonomy ||= Taxonomy.find_by(slug: 'tag')
  end
  
  # Get post format taxonomy
  def post_format_taxonomy
    @post_format_taxonomy ||= Taxonomy.find_by(slug: 'post_format')
  end
  
  # Get all categories
  def all_categories
    category_taxonomy&.terms&.order(:name) || Term.none
  end
  
  # Get all tags
  def all_tags
    tag_taxonomy&.terms&.order(:name) || Term.none
  end
  
  # Get categories for a post
  def post_categories(post)
    return [] unless category_taxonomy
    post.terms.where(taxonomy: category_taxonomy)
  end
  
  # Get tags for a post
  def post_tags(post)
    return [] unless tag_taxonomy
    post.terms.where(taxonomy: tag_taxonomy)
  end
  
  # Get category names for a post
  def post_category_names(post)
    post_categories(post).pluck(:name)
  end
  
  # Get tag names for a post
  def post_tag_names(post)
    post_tags(post).pluck(:name)
  end
  
  # Category link
  def category_link(term, options = {})
    return unless term
    
    css_class = options[:class] || 'category-link'
    link_to term.name, "/blog/category/#{term.slug}", class: css_class
  end
  
  # Tag link
  def tag_link(term, options = {})
    return unless term
    
    css_class = options[:class] || 'tag-link'
    link_to term.name, "/blog/tag/#{term.slug}", class: css_class
  end
  
  # Render category list for post
  def render_post_categories(post, options = {})
    categories = post_categories(post)
    return '' if categories.empty?
    
    separator = options[:separator] || ', '
    css_class = options[:class] || 'post-categories'
    
    content_tag(:div, class: css_class) do
      categories.map { |cat| category_link(cat, options) }.join(separator).html_safe
    end
  end
  
  # Render tag list for post
  def render_post_tags(post, options = {})
    tags = post_tags(post)
    return '' if tags.empty?
    
    separator = options[:separator] || ' '
    css_class = options[:class] || 'post-tags'
    
    content_tag(:div, class: css_class) do
      tags.map { |tag| tag_link(tag, class: 'tag-badge') }.join(separator).html_safe
    end
  end
  
  # Get term by slug and taxonomy
  def find_term(taxonomy_slug, term_slug)
    taxonomy = Taxonomy.find_by(slug: taxonomy_slug)
    return nil unless taxonomy
    
    taxonomy.terms.friendly.find(term_slug)
  rescue ActiveRecord::RecordNotFound
    nil
  end
  
  # Get posts by category
  def posts_in_category(category_slug, limit = nil)
    term = find_term('category', category_slug)
    return Post.none unless term
    
    posts = Post.published_status.visible_to_public
                .joins(:term_relationships)
                .where(term_relationships: { term_id: term.id })
                .order(published_at: :desc)
                .distinct
    
    limit ? posts.limit(limit) : posts
  end
  
  # Get posts by tag
  def posts_with_tag(tag_slug, limit = nil)
    term = find_term('tag', tag_slug)
    return Post.none unless term
    
    posts = Post.published_status.visible_to_public
                .joins(:term_relationships)
                .where(term_relationships: { term_id: term.id })
                .order(published_at: :desc)
                .distinct
    
    limit ? posts.limit(limit) : posts
  end
  
  # Get popular categories (most posts)
  def popular_categories(limit = 10)
    return [] unless category_taxonomy
    
    category_taxonomy.terms
      .joins(:term_relationships)
      .where(term_relationships: { object_type: 'Post' })
      .group('terms.id')
      .order('COUNT(term_relationships.id) DESC')
      .limit(limit)
  end
  
  # Get popular tags (most posts)
  def popular_tags(limit = 10)
    return [] unless tag_taxonomy
    
    tag_taxonomy.terms
      .joins(:term_relationships)
      .where(term_relationships: { object_type: 'Post' })
      .group('terms.id')
      .order('COUNT(term_relationships.id) DESC')
      .limit(limit)
  end
  
  # Render taxonomy cloud (tags or categories)
  def render_taxonomy_cloud(taxonomy_slug, options = {})
    taxonomy = Taxonomy.find_by(slug: taxonomy_slug)
    return '' unless taxonomy
    
    terms = taxonomy.terms
      .joins(:term_relationships)
      .where(term_relationships: { object_type: 'Post' })
      .group('terms.id')
      .select('terms.*, COUNT(term_relationships.id) as post_count')
      .order(:name)
    
    return '' if terms.empty?
    
    max_count = terms.maximum('post_count') || 1
    min_count = terms.minimum('post_count') || 1
    
    content_tag(:div, class: options[:class] || 'taxonomy-cloud') do
      terms.map do |term|
        size = calculate_cloud_size(term.post_count, min_count, max_count)
        link_to term.name, 
                taxonomy_slug == 'tag' ? "/blog/tag/#{term.slug}" : "/blog/category/#{term.slug}",
                class: "cloud-item cloud-size-#{size}",
                title: "#{term.post_count} posts"
      end.join(' ').html_safe
    end
  end
  
  private
  
  def calculate_cloud_size(count, min, max)
    return 3 if min == max
    
    # Scale from 1 to 5
    ((count - min).to_f / (max - min) * 4).round + 1
  end
end

