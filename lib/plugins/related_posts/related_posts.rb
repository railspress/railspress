# Related Posts Plugin
# Adds related posts functionality based on categories and tags

class RelatedPosts < Railspress::PluginBase
  plugin_name 'Related Posts'
  plugin_version '1.0.0'
  plugin_description 'Displays related posts based on categories and tags'
  plugin_author 'RailsPress'

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





