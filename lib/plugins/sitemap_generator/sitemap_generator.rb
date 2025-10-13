# Sitemap Generator Plugin
# Automatically generates XML sitemaps for SEO

class SitemapGenerator < Railspress::PluginBase
  plugin_name 'Sitemap Generator'
  plugin_version '1.0.0'
  plugin_description 'Automatically generates XML sitemaps for better SEO'
  plugin_author 'RailsPress'

  def activate
    super
    register_hooks
    generate_sitemap
  end

  private

  def register_hooks
    # Generate sitemap when posts/pages are published
    add_action('post_published', :generate_sitemap)
    add_action('page_published', :generate_sitemap)
  end

  def generate_sitemap
    sitemap_content = build_sitemap_xml
    sitemap_path = Rails.public_path.join('sitemap.xml')
    
    File.write(sitemap_path, sitemap_content)
    Rails.logger.info "Sitemap generated at #{sitemap_path}"
  rescue => e
    Rails.logger.error "Failed to generate sitemap: #{e.message}"
  end

  def build_sitemap_xml
    xml = []
    xml << '<?xml version="1.0" encoding="UTF-8"?>'
    xml << '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    
    # Add homepage
    xml << build_url_entry('/', priority: '1.0', changefreq: 'daily')
    
    # Add posts
    Post.published.find_each do |post|
      xml << build_url_entry(
        "/blog/#{post.slug}",
        lastmod: post.updated_at,
        priority: '0.8',
        changefreq: 'weekly'
      )
    end
    
    # Add pages
    Page.published.find_each do |page|
      xml << build_url_entry(
        "/#{page.slug}",
        lastmod: page.updated_at,
        priority: '0.6',
        changefreq: 'monthly'
      )
    end
    
    # Add category archives
    Term.for_taxonomy('category').find_each do |category|
      xml << build_url_entry(
        "/category/#{category.slug}",
        priority: '0.5',
        changefreq: 'weekly'
      )
    end
    
    xml << '</urlset>'
    xml.join("\n")
  end

  def build_url_entry(path, lastmod: nil, priority: '0.5', changefreq: 'monthly')
    base_url = get_setting('base_url', 'http://localhost:3000')
    
    entry = ["  <url>"]
    entry << "    <loc>#{base_url}#{path}</loc>"
    entry << "    <lastmod>#{lastmod.strftime('%Y-%m-%d')}</lastmod>" if lastmod
    entry << "    <changefreq>#{changefreq}</changefreq>"
    entry << "    <priority>#{priority}</priority>"
    entry << "  </url>"
    
    entry.join("\n")
  end
end

SitemapGenerator.new




