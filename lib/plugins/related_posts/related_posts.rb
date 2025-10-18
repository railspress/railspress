# Related Posts Plugin
# Adds related posts functionality based on categories and tags

class RelatedPosts < Railspress::PluginBase
  plugin_name 'Related Posts'
  plugin_version '1.0.0'
  plugin_description 'Displays related posts based on categories and tags'
  plugin_author 'RailsPress'

  # Define settings schema
  settings_schema do
    section 'General Settings' do
      number 'count', 'Number of related posts to show', default: 5, min: 1, max: 20
      checkbox 'show_excerpt', 'Show post excerpt', default: true
      checkbox 'show_thumbnail', 'Show post thumbnail', default: true
      select 'sort_by', 'Sort related posts by', 
             options: [
               ['Relevance (default)', 'relevance'],
               ['Date (newest first)', 'date_desc'],
               ['Date (oldest first)', 'date_asc'],
               ['Title (A-Z)', 'title_asc'],
               ['Title (Z-A)', 'title_desc']
             ], 
             default: 'relevance'
    end
    
    section 'Display Options' do
      text 'title', 'Section title', default: 'Related Posts', placeholder: 'e.g., You might also like...'
      checkbox 'show_in_single_post', 'Show in single post pages', default: true
      checkbox 'show_in_archive', 'Show in archive pages', default: false
      select 'layout', 'Display layout',
             options: [
               ['List (default)', 'list'],
               ['Grid (2 columns)', 'grid_2'],
               ['Grid (3 columns)', 'grid_3'],
               ['Grid (4 columns)', 'grid_4']
             ],
             default: 'list'
    end
    
    section 'Advanced' do
      checkbox 'include_same_author', 'Include posts by same author', default: false
      checkbox 'exclude_sticky', 'Exclude sticky posts', default: true
      number 'cache_duration', 'Cache duration (minutes)', default: 60, min: 0, max: 1440
    end
  end

  def activate
    super
    register_hooks
    inject_helper_methods
  end

  private

  def register_hooks
    # Add filter to modify related posts logic
    add_filter('related_posts_count', :get_related_posts_count)
    add_filter('related_posts_query', :enhance_related_posts_query)
  end

  def inject_helper_methods
    # Add helper method to ApplicationController
    ApplicationController.helper_method :get_related_posts if defined?(ApplicationController)
  end

  def get_related_posts_count(default_count)
    get_setting('count', default_count)
  end

  def enhance_related_posts_query(posts)
    # Can add additional filtering or sorting logic
    posts
  end

  # Public method that can be called from views
  def self.find_related(post, limit = 5)
    return Post.none unless post

    # Find posts with matching categories or tags
    related_by_category = Post.published
      .joins(:categories)
      .where(categories: { id: post.category_ids })
      .where.not(id: post.id)
      .distinct

    related_by_tag = Post.published
      .joins(:tags)
      .where(tags: { id: post.tag_ids })
      .where.not(id: post.id)
      .distinct

    # Combine and prioritize by category match
    (related_by_category.to_a + related_by_tag.to_a)
      .uniq
      .sort_by { |p| -matching_score(post, p) }
      .first(limit)
  end

  def self.matching_score(post1, post2)
    category_matches = (post1.category_ids & post2.category_ids).count * 2
    tag_matches = (post1.tag_ids & post2.tag_ids).count
    category_matches + tag_matches
  end
end

# Helper method for views
module RelatedPostsHelper
  def get_related_posts(post, limit = 5)
    RelatedPosts.find_related(post, limit)
  end
end

# Include helper in ApplicationController
if defined?(ApplicationController)
  ApplicationController.helper(RelatedPostsHelper)
end

RelatedPosts.new








