xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title "#{SiteSetting.get('site_title', 'RailsPress')} - Pages"
    xml.description "Latest pages from #{SiteSetting.get('site_title', 'RailsPress')}"
    xml.link root_url
    xml.language "en-us"
    xml.pubDate @pages.first&.published_at&.rfc822 || Time.current.rfc822
    xml.lastBuildDate Time.current.rfc822
    xml.ttl "60"
    
    xml.atom :link, href: request.original_url, rel: "self", type: "application/rss+xml"
    
    @pages.each do |page|
      xml.item do
        xml.title page.title
        xml.description strip_tags(page.content.to_s.truncate(300))
        xml.link page_url(page.slug)
        xml.guid page_url(page.slug), isPermaLink: "true"
        xml.pubDate page.published_at&.rfc822 || page.created_at.rfc822
        
        xml.content :encoded do
          xml.cdata! page.content.to_s
        end
      end
    end
  end
end

