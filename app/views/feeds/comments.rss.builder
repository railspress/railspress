xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do
  xml.channel do
    xml.title "#{SiteSetting.get('site_title', 'RailsPress')} - Comments"
    xml.description "Latest comments on #{SiteSetting.get('site_title', 'RailsPress')}"
    xml.link root_url
    xml.language "en-us"
    xml.pubDate @comments.first&.created_at&.rfc822 || Time.current.rfc822
    xml.lastBuildDate Time.current.rfc822
    xml.ttl "60"
    
    xml.atom :link, href: request.original_url, rel: "self", type: "application/rss+xml"
    
    @comments.each do |comment|
      xml.item do
        xml.title "Comment on #{comment.commentable&.title || 'Post'} by #{comment.author_name}"
        xml.description strip_tags(comment.content)
        
        # Link to the comment on the post/page
        if comment.commentable_type == 'Post'
          xml.link blog_post_url(comment.commentable) + "#comment-#{comment.id}"
          xml.guid blog_post_url(comment.commentable) + "#comment-#{comment.id}", isPermaLink: "true"
        else
          xml.link page_url(comment.commentable.slug) + "#comment-#{comment.id}"
          xml.guid page_url(comment.commentable.slug) + "#comment-#{comment.id}", isPermaLink: "true"
        end
        
        xml.pubDate comment.created_at.rfc822
        xml.dc :creator, comment.author_name
        
        # Include the full comment
        xml.content :encoded do
          xml.cdata! simple_format(comment.content)
        end
      end
    end
  end
end

