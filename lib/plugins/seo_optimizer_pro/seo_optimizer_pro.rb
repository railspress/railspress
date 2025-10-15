# SEO Optimizer Pro Plugin for RailsPress
# Enhances SEO capabilities with sitemaps, meta tags, and analytics

class SeoOptimizerPro < Railspress::PluginBase
  plugin_name 'SEO Optimizer Pro'
  plugin_version '2.5.0'
  plugin_description 'Complete SEO solution with XML sitemaps, meta tag management, and analytics'
  plugin_author 'RailsPress Team'

  def activate
    super
    Rails.logger.info "SEO Optimizer Pro activated"
    
    # Register hooks
    register_seo_hooks
    
    # Generate sitemap on activation
    GenerateSitemapJob.perform_later if defined?(GenerateSitemapJob)
  end

  def deactivate
    super
    Rails.logger.info "SEO Optimizer Pro deactivated"
  end

  private

  def register_seo_hooks
    # Add filter to modify page titles
    add_filter('page_title', :enhance_page_title)
    
    # Add action hook for tracking page views
    add_action('post_viewed', :track_page_view)
  end

  def enhance_page_title(title)
    site_name = SiteSetting.get('site_title', 'RailsPress')
    "#{title} | #{site_name}"
  end

  def track_page_view(post_id)
    # Track in analytics
    Rails.logger.info "Tracking view for post #{post_id}"
  end

  # Plugin-specific methods
  def generate_sitemap
    # Generate XML sitemap
    posts = Post.published
    pages = Page.published
    
    # Build sitemap XML
    # This would be implemented based on sitemap format
  end

  def get_google_analytics_id
    get_setting('google_analytics_id', '')
  end

  def sitemap_enabled?
    get_setting('sitemap_enabled', false)
  end
end

# Initialize the plugin
SeoOptimizerPro.new








