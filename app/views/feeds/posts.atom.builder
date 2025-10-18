xml.instruct! :xml, version: "1.0"
xml.feed xmlns: "http://www.w3.org/2005/Atom" do
  xml.title @title_suffix.present? ? "#{SiteSetting.get('site_title', 'RailsPress')} - #{@title_suffix}" : SiteSetting.get('site_title', 'RailsPress')
  xml.subtitle SiteSetting.get('site_description', "Latest posts from #{SiteSetting.get('site_title', 'RailsPress')}")
  xml.link href: root_url
  xml.link href: request.original_url, rel: "self"
  xml.updated @posts.first&.updated_at&.iso8601 || Time.current.iso8601
  xml.id root_url
  
  @posts.each do |post|
    xml.entry do
      xml.title post.title
      xml.link href: blog_post_url(post), rel: "alternate"
      xml.id blog_post_url(post)
      xml.published post.published_at&.iso8601 || post.created_at.iso8601
      xml.updated post.updated_at.iso8601
      
      if post.user
        xml.author do
          xml.name post.user.name || post.user.email
          xml.email post.user.email
        end
      end
      
      xml.summary post.excerpt.presence || strip_tags(post.content.to_s.truncate(300)), type: "text"
      xml.content post.content.to_s, type: "html"
      
      # Categories as Atom categories
      post.category.each do |category|
        xml.category term: category.slug, label: category.name
      end
      
      post.post_tag.each do |tag|
        xml.category term: tag.slug, label: tag.name
      end
    end
  end
end

