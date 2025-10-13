module SeoHelper
  # Render complete SEO meta tags for a post or page
  def render_seo_tags(resource)
    return '' unless resource.respond_to?(:seo_title)
    
    tags = []
    
    # Basic meta tags
    tags << tag.meta(name: 'description', content: resource.seo_description) if resource.seo_description
    tags << tag.meta(name: 'keywords', content: resource.meta_keywords) if resource.meta_keywords
    tags << tag.meta(name: 'robots', content: resource.seo_robots)
    tags << tag.link(rel: 'canonical', href: resource.seo_canonical_url)
    
    # Open Graph tags
    tags << tag.meta(property: 'og:title', content: resource.seo_og_title)
    tags << tag.meta(property: 'og:description', content: resource.seo_og_description)
    tags << tag.meta(property: 'og:type', content: 'article')
    tags << tag.meta(property: 'og:url', content: resource.seo_canonical_url)
    
    if resource.seo_og_image.present?
      tags << tag.meta(property: 'og:image', content: resource.seo_og_image)
      tags << tag.meta(property: 'og:image:alt', content: resource.title)
    end
    
    if resource.respond_to?(:published_at) && resource.published_at
      tags << tag.meta(property: 'article:published_time', content: resource.published_at.iso8601)
      tags << tag.meta(property: 'article:modified_time', content: resource.updated_at.iso8601)
    end
    
    if resource.respond_to?(:user) && resource.user
      tags << tag.meta(property: 'article:author', content: resource.user.email)
    end
    
    # Twitter Card tags
    tags << tag.meta(name: 'twitter:card', content: resource.twitter_card)
    tags << tag.meta(name: 'twitter:title', content: resource.seo_twitter_title)
    tags << tag.meta(name: 'twitter:description', content: resource.seo_twitter_description)
    
    if resource.seo_twitter_image.present?
      tags << tag.meta(name: 'twitter:image', content: resource.seo_twitter_image)
    end
    
    safe_join(tags, "\n")
  end
  
  # Render structured data (Schema.org JSON-LD)
  def render_structured_data(resource)
    return '' unless resource.respond_to?(:structured_data)
    
    content_tag(:script, type: 'application/ld+json') do
      resource.structured_data.to_json.html_safe
    end
  end
  
  # Generate meta title with site name
  def seo_page_title(resource_title = nil, options = {})
    site_name = SiteSetting.get('site_title', 'RailsPress')
    separator = options[:separator] || '|'
    
    if resource_title
      "#{resource_title} #{separator} #{site_name}"
    else
      site_name
    end
  end
end




