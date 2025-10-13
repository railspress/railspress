module SeoOptimizable
  extend ActiveSupport::Concern

  included do
    # Callbacks
    before_validation :set_default_seo_fields
    
    # Validations
    validates :meta_description, length: { maximum: 160 }, allow_blank: true
    validates :og_description, length: { maximum: 200 }, allow_blank: true
    validates :twitter_description, length: { maximum: 200 }, allow_blank: true
  end

  # SEO meta title (falls back to title)
  def seo_title
    meta_title.presence || title
  end

  # SEO meta description (falls back to excerpt)
  def seo_description
    meta_description.presence || excerpt.presence || title
  end

  # Open Graph title (falls back to meta_title or title)
  def seo_og_title
    og_title.presence || meta_title.presence || title
  end

  # Open Graph description (falls back to meta_description or excerpt)
  def seo_og_description
    og_description.presence || meta_description.presence || excerpt.presence || title
  end

  # Open Graph image URL
  def seo_og_image
    og_image_url.presence || (featured_image_url if respond_to?(:featured_image_url))
  end

  # Twitter card title
  def seo_twitter_title
    twitter_title.presence || seo_og_title
  end

  # Twitter card description
  def seo_twitter_description
    twitter_description.presence || seo_og_description
  end

  # Twitter card image
  def seo_twitter_image
    twitter_image_url.presence || seo_og_image
  end

  # Canonical URL (falls back to generated URL)
  def seo_canonical_url
    canonical_url.presence || seo_default_url
  end

  # Robots meta tag
  def seo_robots
    robots_meta.presence || 'index, follow'
  end

  # Generate structured data (Schema.org)
  def structured_data
    {
      "@context": "https://schema.org",
      "@type": schema_type.presence || default_schema_type,
      "headline": seo_title,
      "description": seo_description,
      "image": seo_og_image,
      "datePublished": published_at&.iso8601,
      "dateModified": updated_at&.iso8601,
      "author": author_structured_data,
      "publisher": publisher_structured_data,
      "url": seo_canonical_url,
      "keywords": meta_keywords
    }.compact
  end

  private

  def set_default_seo_fields
    # Auto-generate meta fields if not set
    self.meta_title ||= title if title.present?
    self.meta_description ||= generate_meta_description if respond_to?(:content)
    self.canonical_url ||= seo_default_url
  end

  def generate_meta_description
    return excerpt if respond_to?(:excerpt) && excerpt.present?
    return nil unless respond_to?(:content) && content.present?
    
    # Extract plain text and truncate
    plain_text = content.to_plain_text
    plain_text.truncate(160, separator: ' ', omission: '...')
  end

  def seo_default_url
    # Override in model if needed
    "#"
  end

  def default_schema_type
    self.class.name  # 'Post' or 'Page'
  end

  def author_structured_data
    return nil unless respond_to?(:user) && user.present?
    
    {
      "@type": "Person",
      "name": user.email,
      "url": "#"
    }
  end

  def publisher_structured_data
    {
      "@type": "Organization",
      "name": SiteSetting.get('site_title', 'RailsPress'),
      "url": Rails.application.routes.url_helpers.root_url
    }
  rescue
    nil
  end
end






