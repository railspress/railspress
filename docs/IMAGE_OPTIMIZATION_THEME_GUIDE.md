# Image Optimization for Theme Developers

RailsPress provides powerful image optimization features that theme developers can leverage to create fast, modern websites with optimal image delivery.

## 🚀 Quick Start

### Basic Optimized Image

```liquid
{% image_optimized upload=post.featured_image alt="Featured Image" class="w-full h-auto" %}
```

### Responsive Images with Modern Formats

```liquid
{% image_optimized upload=post.featured_image alt="Responsive Image" class="hero-image" sizes="(max-width: 768px) 100vw, 50vw" %}
```

## 📋 Available Liquid Tags

### `image_optimized`

The main tag for displaying optimized images with automatic format selection and responsive variants.

**Parameters:**
- `upload` (required): Upload object or ID
- `alt`: Alt text for accessibility
- `class`: CSS classes
- `sizes`: Responsive sizes attribute
- `lazy`: Enable lazy loading (default: true)
- `quality`: Override quality setting
- `format`: Force specific format (webp, avif, original)

**Examples:**

```liquid
<!-- Basic usage -->
{% image_optimized upload=123 alt="My Image" %}

<!-- With responsive sizes -->
{% image_optimized upload=post.image alt="Post Image" sizes="(max-width: 768px) 100vw, 50vw" %}

<!-- Force WebP format -->
{% image_optimized upload=post.image alt="WebP Image" format="webp" %}

<!-- Custom quality -->
{% image_optimized upload=post.image alt="High Quality" quality="95" %}
```

### `background_image_optimized`

For CSS background images with optimization.

```liquid
{% background_image_optimized upload=hero.image class="hero-section" %}
```

### `optimization_stats`

Display optimization statistics widget.

```liquid
{% optimization_stats %}
```

## 🎨 Modern Image Formats

RailsPress automatically generates and serves the best format for each browser:

### Supported Formats

| Format | Browser Support | Compression | Use Case |
|--------|----------------|-------------|----------|
| **AVIF** | Chrome 85+, Firefox 93+ | Excellent | Modern browsers |
| **WebP** | Chrome 23+, Firefox 65+ | Excellent | Wide support |
| **HEIC** | Safari 11+ | Excellent | Apple devices |
| **JXL** | Chrome 91+ | Excellent | Future-proof |
| **JPEG** | All browsers | Good | Fallback |
| **PNG** | All browsers | Good | Transparency |

### Automatic Format Selection

The system automatically serves:
1. **AVIF** to supported browsers (best compression)
2. **WebP** to browsers that don't support AVIF
3. **Original format** as fallback

## 📱 Responsive Images

### Breakpoints

Default breakpoints: `320, 640, 768, 1024, 1200, 1920`

Custom breakpoints can be set in admin settings.

### Sizes Attribute

```liquid
<!-- Mobile-first approach -->
{% image_optimized upload=post.image sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw" %}

<!-- Art direction -->
{% image_optimized upload=post.image sizes="(max-width: 768px) 100vw, 50vw" %}
```

## ⚡ Performance Features

### Lazy Loading

All optimized images include automatic lazy loading:

```liquid
<!-- Lazy loading enabled (default) -->
{% image_optimized upload=post.image alt="Lazy loaded" %}

<!-- Disable lazy loading -->
{% image_optimized upload=post.image alt="Eager loaded" lazy=false %}
```

### Compression Levels

The system supports multiple compression levels:

- **Lossless**: Maximum quality, minimal compression (5-15% savings)
- **Lossy**: Balanced quality and compression (25-40% savings)  
- **Ultra**: Maximum compression, slight quality loss (40-60% savings)
- **Custom**: User-defined settings

### CDN Integration

Images are automatically served through CDN when enabled:

```liquid
<!-- CDN URLs are automatically generated -->
{% image_optimized upload=post.image alt="CDN Optimized" %}
```

## 🛠️ Advanced Usage

### Custom Image Processing

```liquid
<!-- High quality for hero images -->
{% image_optimized upload=hero.image alt="Hero" quality="95" class="hero-image" %}

<!-- Ultra compression for thumbnails -->
{% image_optimized upload=post.thumbnail alt="Thumbnail" quality="75" class="thumbnail" %}
```

### Multiple Image Formats

```liquid
<!-- Force specific formats -->
{% image_optimized upload=post.image alt="WebP" format="webp" %}
{% image_optimized upload=post.image alt="AVIF" format="avif" %}
{% image_optimized upload=post.image alt="Original" format="original" %}
```

### Background Images

```liquid
{% background_image_optimized upload=section.background class="hero-section" %}
```

This generates CSS:
```css
.hero-section {
  background-image: url('optimized-image.webp');
  background-size: cover;
  background-position: center;
}

@supports (background-image: url('optimized-image.avif')) {
  .hero-section {
    background-image: url('optimized-image.avif');
  }
}
```

## 📊 Analytics Integration

### Display Optimization Stats

```liquid
<!-- Show optimization statistics -->
{% optimization_stats %}
```

### Bulk Optimization Interface

```liquid
<!-- Admin bulk optimization tool -->
{% bulk_optimize %}
```

## 🎯 Best Practices

### 1. Use Appropriate Sizes

```liquid
<!-- Good: Specific sizes for different contexts -->
{% image_optimized upload=post.image sizes="(max-width: 768px) 100vw, 50vw" %}

<!-- Avoid: Generic sizes -->
{% image_optimized upload=post.image sizes="100vw" %}
```

### 2. Optimize Alt Text

```liquid
<!-- Good: Descriptive alt text -->
{% image_optimized upload=post.image alt="Sunset over mountains in Colorado" %}

<!-- Avoid: Generic alt text -->
{% image_optimized upload=post.image alt="Image" %}
```

### 3. Choose Right Compression

```liquid
<!-- Hero images: High quality -->
{% image_optimized upload=hero.image quality="95" %}

<!-- Thumbnails: Balanced -->
{% image_optimized upload=thumbnail.image quality="85" %}

<!-- Backgrounds: Compressed -->
{% image_optimized upload=bg.image quality="75" %}
```

### 4. Leverage Modern Formats

```liquid
<!-- Let the system choose the best format -->
{% image_optimized upload=post.image alt="Auto format" %}

<!-- Or force modern formats for specific use cases -->
{% image_optimized upload=post.image alt="WebP" format="webp" %}
```

## 🔧 Configuration

### Admin Settings

Theme developers can configure:

- **Compression Level**: System-wide compression setting
- **Quality Settings**: Custom quality values
- **Format Support**: Enable/disable specific formats
- **Responsive Breakpoints**: Custom breakpoint values
- **CDN Settings**: CDN integration

### Site Settings

```ruby
# In your theme or plugin
SiteSetting.set('image_compression_level', 'lossy')
SiteSetting.set('enable_webp_variants', true)
SiteSetting.set('enable_avif_variants', true)
SiteSetting.set('responsive_breakpoints', '320,640,768,1024,1200,1920')
```

## 🚨 Troubleshooting

### Common Issues

1. **Images not optimizing**
   - Check if auto-optimization is enabled
   - Verify image format is supported
   - Check file permissions

2. **Modern formats not serving**
   - Ensure WebP/AVIF variants are enabled
   - Check browser support
   - Verify CDN configuration

3. **Responsive images not working**
   - Check breakpoint configuration
   - Verify sizes attribute
   - Ensure variants are generated

### Debug Mode

Enable debug logging:

```ruby
# In development
Rails.logger.level = :debug
```

## 📈 Performance Benefits

### Typical Results

- **File Size Reduction**: 25-60% smaller files
- **Loading Speed**: 2-3x faster image loading
- **Bandwidth Savings**: Significant reduction in data usage
- **SEO Benefits**: Improved Core Web Vitals scores

### Browser Support

- **AVIF**: 85%+ of modern browsers
- **WebP**: 95%+ of browsers
- **Fallbacks**: 100% compatibility

## 🔮 Future Features

- **AI-powered optimization**: Automatic quality adjustment
- **Advanced analytics**: Detailed performance metrics
- **Custom formats**: Support for emerging formats
- **Batch processing**: Bulk optimization tools

---

## 📚 Additional Resources

- [Image Optimization Service API](api/image-optimization.md)
- [Performance Best Practices](performance.md)
- [CDN Integration Guide](cdn-integration.md)
- [Analytics Dashboard](analytics.md)

For more information, visit the [RailsPress Documentation](https://docs.railspress.com/image-optimization).
