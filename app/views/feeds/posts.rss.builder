xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do
  xml.channel do
    xml.title @title_suffix.present? ? "#{SiteSetting.get('site_title', 'RailsPress')} - #{@title_suffix}" : SiteSetting.get('site_title', 'RailsPress')
    xml.description SiteSetting.get('site_description', "Latest posts from #{SiteSetting.get('site_title', 'RailsPress')}")
    xml.link root_url
    xml.language "en-us"
    xml.pubDate @posts.first&.published_at&.rfc822 || Time.current.rfc822
    xml.lastBuildDate Time.current.rfc822
    xml.ttl "60"
    
    # Self-referencing link (RSS best practice)
    xml.atom :link, href: request.original_url, rel: "self", type: "application/rss+xml"
    
    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.description strip_tags(post.excerpt.presence || post.content.to_s.truncate(300))
        xml.link blog_post_url(post)
        xml.guid blog_post_url(post), isPermaLink: "true"
        xml.pubDate post.published_at&.rfc822 || post.created_at.rfc822
        
        # Author
        if post.user
          xml.dc :creator, post.user.name || post.user.email
          xml.author "#{post.user.email} (#{post.user.name || post.user.email})"
        end
        
        # Categories
        post.categories.each do |category|
          xml.category category.name, domain: category_url(category.slug)
        end
        
        # Tags
        post.tags.each do |tag|
          xml.category tag.name, domain: tag_url(tag.slug)
        end
        
        # Full content (WordPress-style content:encoded)
        xml.content :encoded do
          xml.cdata! post.content.to_s
        end
      end
    end
  end
end

