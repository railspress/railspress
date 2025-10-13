# Sitemap Generator Plugin

Automatically generates XML sitemaps for better SEO and search engine discoverability.

## Features

- 🗺️ Automatic XML sitemap generation
- 📄 Includes all published posts and pages
- 🏷️ Category archives support
- ⚡ Auto-regenerates on content publish
- 🔧 Configurable base URL
- ✅ Google/Bing compatible format

## Installation

Built-in plugin. Activate from:
**Admin → Plugins → Sitemap Generator → Activate**

## Configuration

### Settings

- **Base URL**: Your site's base URL (default: http://localhost:3000)
- **Sitemap Enabled**: Toggle sitemap generation

Access in: **Admin → Plugins → Sitemap Generator → Settings**

## Usage

### Automatic Generation

Sitemap is automatically generated when:
- Plugin is activated
- A post is published
- A page is published

### Manual Generation

```ruby
SitemapGenerator.new.generate_sitemap
```

### Access Sitemap

```
https://yoursite.com/sitemap.xml
```

## Sitemap Structure

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://yoursite.com/</loc>
    <priority>1.0</priority>
    <changefreq>daily</changefreq>
  </url>
  <url>
    <loc>https://yoursite.com/blog/post-slug</loc>
    <lastmod>2025-10-12</lastmod>
    <priority>0.8</priority>
    <changefreq>weekly</changefreq>
  </url>
  <!-- more URLs -->
</urlset>
```

## Priority Levels

- Homepage: 1.0 (highest)
- Blog posts: 0.8
- Pages: 0.6
- Category archives: 0.5

## Submit to Search Engines

### Google Search Console

1. Go to https://search.google.com/search-console
2. Add your sitemap: `https://yoursite.com/sitemap.xml`

### Bing Webmaster Tools

1. Go to https://www.bing.com/webmasters
2. Submit sitemap URL

## Hooks Registered

- `post_published` → Regenerates sitemap
- `page_published` → Regenerates sitemap

## Technical Details

- **File**: `/public/sitemap.xml`
- **Format**: XML (Sitemap Protocol 0.9)
- **Encoding**: UTF-8
- **Max URLs**: Unlimited (splits into multiple files if >50,000)

## Version

1.0.0

## License

MIT




