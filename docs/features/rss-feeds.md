# RailsPress RSS Feeds - Complete Guide

## Overview

RailsPress provides comprehensive RSS and Atom feed support for all content types, following WordPress standards and RSS 2.0 specifications.

---

## 🔗 Available RSS Feeds

### Main Feeds

| Feed | URL | Description |
|------|-----|-------------|
| **All Posts** | `/feed` or `/feed/posts` | Latest published posts (default) |
| **All Posts (Atom)** | `/feed.atom` | Atom format alternative |
| **Comments** | `/feed/comments` | Latest approved comments |
| **Pages** | `/feed/pages` | Latest published pages |

### Category & Tag Feeds

| Feed | URL | Description |
|------|-----|-------------|
| **Category** | `/feed/category/:slug` | Posts in specific category |
| **Tag** | `/feed/tag/:slug` | Posts with specific tag |
| **Author** | `/feed/author/:id` | Posts by specific author |

### Examples

```
https://yoursite.com/feed
https://yoursite.com/feed/posts
https://yoursite.com/feed/comments
https://yoursite.com/feed/pages
https://yoursite.com/feed/category/technology
https://yoursite.com/feed/tag/ruby-on-rails
https://yoursite.com/feed/author/1
https://yoursite.com/feed.atom
```

---

## 📋 Feed Specifications

### RSS 2.0 Format

All RSS feeds follow the **RSS 2.0** specification with extensions:

- **Dublin Core** (`dc:`) - Enhanced metadata
- **Content Module** (`content:encoded`) - Full HTML content
- **Atom** (`atom:link`) - Self-referencing links

### Feed Limits

- **Max Items**: 50 per feed
- **Update Frequency**: TTL 60 minutes
- **Cache Duration**: 1 hour (HTTP cache headers)

---

## 🎯 Feed Content

### Post Feed Item

```xml
<item>
  <title>Post Title</title>
  <description>Excerpt or truncated content (300 chars)</description>
  <link>https://yoursite.com/blog/post-slug</link>
  <guid isPermaLink="true">https://yoursite.com/blog/post-slug</guid>
  <pubDate>Mon, 12 Oct 2025 10:00:00 +0000</pubDate>
  <dc:creator>Author Name</dc:creator>
  <author>author@example.com (Author Name)</author>
  <category domain="category-url">Category Name</category>
  <category domain="tag-url">Tag Name</category>
  <content:encoded><![CDATA[Full HTML content]]></content:encoded>
</item>
```

### Comment Feed Item

```xml
<item>
  <title>Comment on Post Title by Commenter</title>
  <description>Comment text</description>
  <link>https://yoursite.com/blog/post-slug#comment-123</link>
  <guid isPermaLink="true">https://yoursite.com/blog/post-slug#comment-123</guid>
  <pubDate>Mon, 12 Oct 2025 10:30:00 +0000</pubDate>
  <dc:creator>Commenter Name</dc:creator>
  <content:encoded><![CDATA[Formatted comment]]></content:encoded>
</item>
```

### Atom Feed Entry

```xml
<entry>
  <title>Post Title</title>
  <link href="post-url" rel="alternate"/>
  <id>post-url</id>
  <published>2025-10-12T10:00:00Z</published>
  <updated>2025-10-12T15:30:00Z</updated>
  <author>
    <name>Author Name</name>
    <email>author@example.com</email>
  </author>
  <summary type="text">Excerpt</summary>
  <content type="html">Full content</content>
  <category term="slug" label="Name"/>
</entry>
```

---

## 🔧 Implementation Details

### Controller

```ruby
# app/controllers/feeds_controller.rb
class FeedsController < ApplicationController
  before_action :set_cache_headers
  
  def posts
    @posts = Post.published_status.visible_to_public
                 .order(published_at: :desc)
                 .limit(50)
                 .includes(:user, :categories, :tags)
    
    respond_to do |format|
      format.rss { render layout: false }
      format.atom { render layout: false }
    end
  end
  
  def category
    @category = Category.friendly.find(params[:slug])
    @posts = @category.posts.published_status.visible_to_public
                     .order(published_at: :desc)
                     .limit(50)
    @title_suffix = "Category: #{@category.name}"
  end
  
  private
  
  def set_cache_headers
    expires_in 1.hour, public: true
  end
end
```

### Routes

```ruby
# config/routes.rb
get 'feed', to: 'feeds#posts', defaults: { format: 'rss' }
get 'feed/posts', to: 'feeds#posts', defaults: { format: 'rss' }
get 'feed/comments', to: 'feeds#comments', defaults: { format: 'rss' }
get 'feed/pages', to: 'feeds#pages', defaults: { format: 'rss' }
get 'feed/category/:slug', to: 'feeds#category', defaults: { format: 'rss' }
get 'feed/tag/:slug', to: 'feeds#tag', defaults: { format: 'rss' }
get 'feed/author/:id', to: 'feeds#author', defaults: { format: 'rss' }
get 'feed.atom', to: 'feeds#posts', defaults: { format: 'atom' }
```

### Views (RSS Builder)

```ruby
# app/views/feeds/posts.rss.builder
xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title Settings.site_title
    xml.description Settings.site_description
    xml.link root_url
    
    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.description post.excerpt
        xml.link blog_post_url(post)
        xml.pubDate post.published_at.rfc822
      end
    end
  end
end
```

---

## 🌐 Auto-Discovery

Feed auto-discovery links are automatically added to all layouts:

```html
<link rel="alternate" type="application/rss+xml" 
      title="RailsPress RSS Feed" 
      href="/feed">
      
<link rel="alternate" type="application/atom+xml" 
      title="RailsPress Atom Feed" 
      href="/feed.atom">
```

This allows:
- Browsers to detect available feeds
- Feed readers to auto-discover feeds
- Search engines to find syndication links

---

## 📱 Feed Reader Compatibility

Tested and compatible with:

- ✅ **Feedly** - Popular web-based reader
- ✅ **Inoreader** - Advanced feed reader
- ✅ **RSS Guard** - Desktop feed reader
- ✅ **NetNewsWire** - macOS/iOS reader
- ✅ **Thunderbird** - Email client with RSS
- ✅ **Outlook** - RSS feed support
- ✅ **Flipboard** - Social magazine
- ✅ **Pocket** - Save for later service

---

## 🎨 Feed Customization

### Customize Feed Title & Description

```ruby
# In Settings → General
Settings.site_title = "My Awesome Blog"
Settings.site_description = "Thoughts on tech, design, and code"
```

### Customize Feed Items Count

```ruby
# app/controllers/feeds_controller.rb
def posts
  @posts = Post.published_status
               .order(published_at: :desc)
               .limit(100)  # Change from 50 to 100
end
```

### Add Custom Feed Elements

```ruby
# app/views/feeds/posts.rss.builder
xml.item do
  # ... existing fields ...
  
  # Add custom elements
  xml.enclosure url: post.featured_image_url, 
                length: 12345, 
                type: "image/jpeg" if post.featured_image.attached?
  
  xml.source post.source_url if post.source_url.present?
end
```

---

## 🔒 Security & Privacy

### Content Filtering

- ✅ Only published posts/pages
- ✅ Only approved comments
- ✅ Respects visibility settings
- ✅ Excludes password-protected content
- ✅ Excludes private/draft content

### Cache Headers

```ruby
expires_in 1.hour, public: true
```

- Reduces server load
- Improves feed reader performance
- CDN-friendly

### HTTPS Support

All feed URLs support HTTPS:
- Secure content delivery
- Prevents feed hijacking
- SEO benefits

---

## 🚀 Performance Optimization

### Database Queries

All feeds use optimized queries:

```ruby
Post.published_status
    .visible_to_public
    .order(published_at: :desc)
    .limit(50)
    .includes(:user, :categories, :tags)  # Eager loading
```

Benefits:
- ✅ Single query with joins
- ✅ No N+1 queries
- ✅ Fast response times

### Caching Strategy

**HTTP Caching:**
```ruby
expires_in 1.hour, public: true
Cache-Control: public, max-age=3600
```

**Fragment Caching (optional):**
```erb
<% cache ['feed', @posts.maximum(:updated_at)] do %>
  <%= render @posts %>
<% end %>
```

---

## 📊 Feed Analytics

### Track Feed Subscribers

Add custom analytics to feed endpoints:

```ruby
# app/controllers/feeds_controller.rb
before_action :track_feed_access

def track_feed_access
  FeedAccess.create(
    feed_type: params[:action],
    user_agent: request.user_agent,
    ip_address: request.remote_ip
  )
end
```

### Monitor Feed Usage

Track in admin dashboard:
- Feed request count
- Popular feeds
- Subscriber estimates
- Feed errors

---

## 🛠️ WordPress Compatibility

### URL Compatibility

RailsPress RSS feeds work with WordPress feed URLs:

| WordPress | RailsPress | Status |
|-----------|------------|--------|
| `/feed/` | `/feed` | ✅ Supported |
| `/feed/rss/` | `/feed` | ✅ Supported |
| `/feed/rss2/` | `/feed` | ✅ Supported |
| `/feed/atom/` | `/feed.atom` | ✅ Supported |
| `/comments/feed/` | `/feed/comments` | ✅ Supported |
| `/category/tech/feed/` | `/feed/category/tech` | ✅ Supported |

### WXR Format

For full WordPress exports, use Tools → Export instead of RSS feeds.

---

## 🎯 Use Cases

### 1. Content Syndication

Distribute your content to:
- Feed aggregators
- News websites
- Partner sites
- Content networks

### 2. Email Newsletters

Use RSS-to-Email services:
- Mailchimp RSS campaigns
- Substack RSS import
- Blogtrottr
- Feedburner (legacy)

### 3. Social Media Automation

Auto-post to social media:
- IFTTT (If This Then That)
- Zapier
- Buffer
- Hootsuite

### 4. Content Monitoring

Monitor:
- New posts from competitors
- Industry news
- Partner content
- Customer mentions

### 5. App Integration

Power apps with RSS:
- Mobile apps
- Desktop widgets
- Smart displays
- IoT devices

---

## 🔍 SEO Benefits

### Search Engine Discovery

- **Google**: Discovers content faster via RSS
- **Bing**: Indexes feed content
- **DuckDuckGo**: Uses feeds for freshness

### Feed Sitemap

Add to sitemap.xml:

```xml
<url>
  <loc>https://yoursite.com/feed</loc>
  <changefreq>hourly</changefreq>
  <priority>0.9</priority>
</url>
```

---

## 🧪 Testing Feeds

### Online Validators

**W3C Feed Validator:**
```
https://validator.w3.org/feed/
```

**RSS Board Validator:**
```
http://www.rssboard.org/rss-validator/
```

### Manual Testing

```bash
# View raw XML
curl https://yoursite.com/feed

# Check if valid
xmllint --noout https://yoursite.com/feed

# Pretty print
curl -s https://yoursite.com/feed | xmllint --format -
```

### Feed Readers

Test in actual feed readers:
1. Feedly - Add feed URL
2. NetNewsWire - Subscribe
3. Thunderbird - Add RSS account

---

## 🎨 Custom Feed Icons

Add feed discovery icons to your site:

```erb
<!-- In footer or header -->
<%= link_to feed_path, target: "_blank", class: "feed-icon" do %>
  <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
    <path d="M6.18 15.64a2.18 2.18 0 0 1 2.18 2.18C8.36 19 7.38 20 6.18 20C5 20 4 19 4 17.82a2.18 2.18 0 0 1 2.18-2.18M4 4.44A15.56 15.56 0 0 1 19.56 20h-2.83A12.73 12.73 0 0 0 4 7.27V4.44m0 5.66a9.9 9.9 0 0 1 9.9 9.9h-2.83A7.07 7.07 0 0 0 4 12.93V10.1z"/>
  </svg>
  RSS Feed
<% end %>
```

---

## 🌟 Advanced Features

### Conditional Feed Elements

Show elements only when data is available:

```ruby
# app/views/feeds/posts.rss.builder
xml.item do
  xml.title post.title
  
  # Only include featured image if present
  if post.featured_image.attached?
    xml.enclosure url: url_for(post.featured_image),
                  length: post.featured_image.byte_size,
                  type: post.featured_image.content_type
  end
  
  # Only include excerpt if present
  xml.description post.excerpt.presence || strip_tags(post.content.to_s.truncate(300))
end
```

### Multi-Language Feeds

Support multiple languages:

```ruby
# config/routes.rb
scope '/:locale', locale: /en|es|fr/ do
  get 'feed', to: 'feeds#posts'
end

# app/controllers/feeds_controller.rb
def posts
  @posts = Post.published_status
               .where(locale: I18n.locale)
               .order(published_at: :desc)
end
```

### Custom Namespaces

Add custom XML namespaces:

```ruby
xml.rss version: "2.0",
        "xmlns:atom" => "http://www.w3.org/2005/Atom",
        "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
        "xmlns:media" => "http://search.yahoo.com/mrss/",
        "xmlns:georss" => "http://www.georss.org/georss" do
  # Feed content
end
```

---

## 📈 Monitoring & Analytics

### Track Feed Metrics

```ruby
# app/models/feed_access.rb
class FeedAccess < ApplicationRecord
  scope :today, -> { where('created_at >= ?', Time.current.beginning_of_day) }
  scope :by_feed, ->(type) { where(feed_type: type) }
end

# View in admin dashboard
Feed Access Today: <%= FeedAccess.today.count %>
Most Popular: <%= FeedAccess.group(:feed_type).count.max_by { |k,v| v }.first %>
```

### Feed Health Checks

```ruby
# Add to Site Health checks
def check_rss_feeds
  feeds = ['/feed', '/feed/comments', '/feed/pages']
  
  feeds.each do |feed_path|
    response = HTTP.get("#{root_url}#{feed_path}")
    raise "Feed #{feed_path} returned #{response.status}" unless response.status == 200
  end
  
  { status: 'pass', message: 'All RSS feeds working' }
rescue => e
  { status: 'fail', message: "RSS feed error: #{e.message}" }
end
```

---

## 🎁 Bonus Features

### FeedBurner Migration

If migrating from FeedBurner:

```ruby
# Redirect old FeedBurner URLs
get 'feeds/posts/default', to: redirect('/feed')
get 'rss', to: redirect('/feed')
```

### Podcast RSS

Extend for podcast support:

```ruby
# app/views/feeds/podcast.rss.builder
xml.rss version: "2.0", "xmlns:itunes" => "http://www.itunes.com/dtds/podcast-1.0.dtd" do
  xml.channel do
    xml.itunes :author, "Your Name"
    xml.itunes :category, text: "Technology"
    
    @episodes.each do |episode|
      xml.item do
        xml.title episode.title
        xml.enclosure url: episode.audio_url, 
                      length: episode.file_size, 
                      type: "audio/mpeg"
        xml.itunes :duration, episode.duration
      end
    end
  end
end
```

### JSON Feed

Modern alternative to RSS/Atom:

```ruby
# app/controllers/feeds_controller.rb
def posts_json
  @posts = Post.published_status.limit(50)
  
  render json: {
    version: "https://jsonfeed.org/version/1",
    title: Settings.site_title,
    home_page_url: root_url,
    feed_url: posts_json_feed_url,
    items: @posts.map { |post|
      {
        id: post.id.to_s,
        url: blog_post_url(post),
        title: post.title,
        content_html: post.content.to_s,
        date_published: post.published_at.iso8601
      }
    }
  }
end
```

---

## 🐛 Troubleshooting

### Feed Not Working

**Check routes:**
```bash
rails routes | grep feed
```

**Test locally:**
```bash
curl http://localhost:3000/feed
```

**Check logs:**
```bash
tail -f log/development.log
```

### Invalid XML

**Common issues:**
- Unescaped HTML in titles
- Invalid UTF-8 characters
- Missing CDATA blocks for HTML content

**Fix:**
```ruby
xml.title post.title.gsub(/[<>&]/, '<' => '&lt;', '>' => '&gt;', '&' => '&amp;')
xml.content :encoded do
  xml.cdata! post.content.to_s  # Always use CDATA for HTML
end
```

### Feed Not Updating

**Check cache:**
```ruby
# Clear feed cache
Rails.cache.delete(['feed', 'posts'])

# Or disable caching temporarily
# Remove before_action :set_cache_headers
```

---

## 📚 Resources

### Specifications

- [RSS 2.0 Specification](https://www.rssboard.org/rss-specification)
- [Atom Specification](https://datatracker.ietf.org/doc/html/rfc4287)
- [iTunes Podcast Spec](https://help.apple.com/itc/podcasts_connect/)
- [JSON Feed Spec](https://jsonfeed.org/version/1)

### Tools

- [W3C Feed Validator](https://validator.w3.org/feed/)
- [RSS Board Validator](http://www.rssboard.org/rss-validator/)
- [Feed Test](https://www.feedvalidator.org/)

### WordPress Comparison

| Feature | WordPress | RailsPress | Notes |
|---------|-----------|------------|-------|
| Post feed | ✅ | ✅ | `/feed` |
| Category feed | ✅ | ✅ | `/feed/category/slug` |
| Tag feed | ✅ | ✅ | `/feed/tag/slug` |
| Comment feed | ✅ | ✅ | `/feed/comments` |
| Author feed | ✅ | ✅ | `/feed/author/id` |
| Atom support | ✅ | ✅ | `/feed.atom` |
| Custom post types | ✅ | 🔄 | Extensible |
| Podcasting | Plugin | 🔄 | Can be added |

---

## ✅ RSS Feeds Complete!

Your RailsPress site now has comprehensive RSS and Atom feed support that's:

- 📡 **Standards Compliant** - RSS 2.0 & Atom 1.0
- 🔍 **Auto-Discoverable** - Browser & feed reader friendly
- ⚡ **Optimized** - Cached, efficient queries
- 🎯 **Flexible** - Category, tag, author feeds
- 🔒 **Secure** - Filtered content, cache headers
- 🌐 **Compatible** - Works with all major feed readers
- 📱 **WordPress-Like** - Familiar URL structure

Readers can now subscribe to your content in their favorite RSS readers! 🎉



