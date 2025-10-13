# Social Sharing Plugin
# Adds social media sharing buttons to posts and pages

class SocialSharing < Railspress::PluginBase
  plugin_name 'Social Sharing'
  plugin_version '1.0.0'
  plugin_description 'Add beautiful social sharing buttons to your content'
  plugin_author 'RailsPress'

  def activate
    super
    inject_helper_methods
  end

  private

  def inject_helper_methods
    ApplicationController.helper_method :social_share_buttons if defined?(ApplicationController)
  end

  # Generate Open Graph meta tags
  def self.open_graph_tags(post)
    return '' unless post

    tags = []
    tags << tag(:meta, property: 'og:title', content: post.title)
    tags << tag(:meta, property: 'og:type', content: 'article')
    tags << tag(:meta, property: 'og:url', content: post_url(post))
    tags << tag(:meta, property: 'og:description', content: post.excerpt || post.title)
    
    if post.featured_image_file.attached?
      tags << tag(:meta, property: 'og:image', content: url_for(post.featured_image_file))
    end
    
    tags << tag(:meta, property: 'article:published_time', content: post.published_at.iso8601)
    tags << tag(:meta, property: 'article:author', content: post.author_name)
    
    tags.join("\n").html_safe
  end

  # Generate Twitter Card meta tags
  def self.twitter_card_tags(post)
    return '' unless post

    tags = []
    tags << tag(:meta, name: 'twitter:card', content: 'summary_large_image')
    tags << tag(:meta, name: 'twitter:title', content: post.title)
    tags << tag(:meta, name: 'twitter:description', content: post.excerpt || post.title)
    
    if post.featured_image_file.attached?
      tags << tag(:meta, name: 'twitter:image', content: url_for(post.featured_image_file))
    end
    
    tags.join("\n").html_safe
  end

  def self.tag(name, attributes = {})
    attrs = attributes.map { |k, v| "#{k}=\"#{ERB::Util.html_escape(v)}\"" }.join(' ')
    "<#{name} #{attrs}>"
  end

  def self.post_url(post)
    # This would use the actual URL helper
    "http://localhost:3000/blog/#{post.slug}"
  end

  def self.url_for(attachment)
    Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: false)
  rescue
    ''
  end
end

# Helper module
module SocialSharingHelper
  def social_share_buttons(post, options = {})
    platforms = options[:platforms] || [:facebook, :twitter, :linkedin, :pinterest, :email]
    size = options[:size] || 'medium'
    
    url = blog_post_url(post.slug)
    title = post.title
    
    buttons = platforms.map do |platform|
      case platform
      when :facebook
        link_to "https://www.facebook.com/sharer/sharer.php?u=#{CGI.escape(url)}", 
                target: '_blank', 
                class: "share-button share-facebook #{size}",
                title: "Share on Facebook" do
          '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>'.html_safe
        end
      when :twitter
        link_to "https://twitter.com/intent/tweet?url=#{CGI.escape(url)}&text=#{CGI.escape(title)}", 
                target: '_blank',
                class: "share-button share-twitter #{size}",
                title: "Share on Twitter" do
          '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z"/></svg>'.html_safe
        end
      when :linkedin
        link_to "https://www.linkedin.com/shareArticle?mini=true&url=#{CGI.escape(url)}&title=#{CGI.escape(title)}", 
                target: '_blank',
                class: "share-button share-linkedin #{size}",
                title: "Share on LinkedIn" do
          '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/></svg>'.html_safe
        end
      when :email
        link_to "mailto:?subject=#{CGI.escape(title)}&body=#{CGI.escape(url)}", 
                class: "share-button share-email #{size}",
                title: "Share via Email" do
          '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>'.html_safe
        end
      end
    end
    
    content_tag :div, class: 'social-share-buttons flex items-center space-x-2' do
      buttons.join.html_safe
    end
  end

  def social_meta_tags(post)
    return '' unless post
    (SocialSharing.open_graph_tags(post) + "\n" + SocialSharing.twitter_card_tags(post)).html_safe
  end
end

# Include helper
if defined?(ApplicationController)
  ApplicationController.helper(SocialSharingHelper)
end

module SocialSharingHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  
  def social_share_buttons(post, options = {})
    return '' unless post
    
    platforms = options[:platforms] || [:facebook, :twitter, :linkedin, :email]
    
    url = blog_post_url(post.slug) rescue "#"
    title = post.title
    
    buttons_html = platforms.map do |platform|
      share_button_for(platform, url, title)
    end.join
    
    content_tag :div, buttons_html.html_safe, class: 'flex items-center space-x-2'
  end
  
  def social_meta_tags(post)
    SocialSharing.open_graph_tags(post) + SocialSharing.twitter_card_tags(post)
  end
  
  private
  
  def share_button_for(platform, url, title)
    case platform
    when :facebook
      share_url = "https://www.facebook.com/sharer/sharer.php?u=#{CGI.escape(url)}"
      icon_svg = '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>'
      bg_class = 'bg-blue-600 hover:bg-blue-700'
    when :twitter  
      share_url = "https://twitter.com/intent/tweet?url=#{CGI.escape(url)}&text=#{CGI.escape(title)}"
      icon_svg = '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z"/></svg>'
      bg_class = 'bg-sky-500 hover:bg-sky-600'
    when :linkedin
      share_url = "https://www.linkedin.com/shareArticle?mini=true&url=#{CGI.escape(url)}&title=#{CGI.escape(title)}"
      icon_svg = '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/></svg>'
      bg_class = 'bg-blue-700 hover:bg-blue-800'
    when :email
      share_url = "mailto:?subject=#{CGI.escape(title)}&body=#{CGI.escape(url)}"
      icon_svg = '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>'
      bg_class = 'bg-gray-600 hover:bg-gray-700'
    else
      return ''
    end
    
    link_to share_url, 
            target: '_blank',
            rel: 'noopener noreferrer',
            class: "p-2 #{bg_class} text-white rounded-lg transition",
            title: "Share on #{platform.to_s.titleize}" do
      icon_svg.html_safe
    end
  end
end

SocialSharing.new






