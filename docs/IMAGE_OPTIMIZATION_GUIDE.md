# RailsPress Image Optimization System

## Overview

The RailsPress Image Optimization System provides comprehensive image optimization capabilities that automatically process uploaded images to improve performance and reduce bandwidth usage. The system respects all storage settings including S3, CDN, and optimization preferences.

## Features

- **Automatic Optimization**: Images are automatically optimized on upload when enabled
- **Multiple Formats**: Generates WebP and AVIF variants for modern browsers
- **Lossless Compression**: Uses image_optim for additional compression
- **Metadata Stripping**: Removes EXIF data to reduce file size
- **Responsive Images**: Supports multiple sizes and formats
- **CDN Integration**: Works seamlessly with CDN settings
- **S3 Support**: Fully compatible with S3 storage
- **Background Processing**: Uses Sidekiq for non-blocking optimization

## Configuration

### Media Settings (`/admin/settings/media`)

- **Auto-optimize images**: Enable/disable automatic optimization
- **Image Quality**: Quality level for optimized images (1-100)
- **Strip Metadata**: Remove EXIF data from images
- **Enable WebP Variants**: Generate WebP format variants
- **Enable AVIF Variants**: Generate AVIF format variants
- **Compression Level**: Lossless compression level (1-9)

### Storage Settings (`/admin/settings/storage`)

- **Auto-optimize uploads**: Global optimization setting
- **Enable CDN**: Use CDN for serving optimized images
- **CDN URL**: CDN endpoint for media files
- **S3 Configuration**: Full S3 support with credentials

## Architecture

### Components

1. **ImageOptimizationService**: Core optimization logic
2. **OptimizeImageJob**: Background job for processing
3. **ImageOptimizer Plugin**: Hooks into upload process
4. **ImageOptimizationHelper**: View helpers for optimized images
5. **Upload Model**: Extended with variant support

### Flow

1. User uploads image via Medium creation
2. Medium triggers `media_uploaded` hook
3. ImageOptimizer plugin checks optimization settings
4. OptimizeImageJob is queued for background processing
5. ImageOptimizationService processes the image:
   - Resizes if too large
   - Compresses with image_optim
   - Strips metadata if enabled
   - Generates WebP/AVIF variants
6. Variants are stored as separate ActiveStorage blobs
7. URLs are generated respecting CDN settings

## Usage

### In Views

```erb
<!-- Basic optimized image -->
<%= optimized_image_tag(upload) %>

<!-- Responsive image with multiple sizes -->
<%= responsive_image_tag(upload, sizes: "(max-width: 768px) 100vw, 50vw") %>

<!-- Background image with format fallbacks -->
<div style="<%= optimized_background_image_css(upload) %>">
  Content
</div>
```

### In Models

```ruby
# Check if variants exist
upload.has_variant?('webp')
upload.has_variant?('avif')

# Get variant URLs
upload.webp_url
upload.avif_url
upload.optimized_url  # Best available format
```

### Manual Optimization

```ruby
# Optimize a specific medium
service = ImageOptimizationService.new(medium)
service.optimize!
service.generate_variants!
```

## Settings Reference

### Media Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `auto_optimize_images` | boolean | false | Enable automatic optimization |
| `image_quality` | integer | 85 | JPEG quality (1-100) |
| `strip_image_metadata` | boolean | true | Remove EXIF data |
| `enable_webp_variants` | boolean | true | Generate WebP variants |
| `enable_avif_variants` | boolean | true | Generate AVIF variants |
| `image_compression_level` | integer | 6 | Lossless compression level |

### Storage Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `auto_optimize_uploads` | boolean | true | Global optimization toggle |
| `enable_cdn` | boolean | false | Use CDN for serving |
| `cdn_url` | string | '' | CDN endpoint URL |

## Performance Benefits

- **File Size Reduction**: Typically 20-80% smaller files
- **Modern Formats**: WebP/AVIF provide better compression
- **Metadata Removal**: Reduces file size and privacy concerns
- **Background Processing**: Non-blocking uploads
- **CDN Integration**: Faster global delivery

## Browser Support

- **AVIF**: Modern browsers (Chrome 85+, Firefox 93+)
- **WebP**: Wide support (Chrome, Firefox, Safari 14+)
- **Fallback**: Original format for older browsers

## Dependencies

- `image_processing` (~> 1.2): Core image processing
- `image_optim` (~> 0.31): Lossless compression
- `mini_magick` (~> 4.12): Alternative processor
- `sidekiq`: Background job processing

## Troubleshooting

### Common Issues

1. **Optimization not running**: Check `auto_optimize_images` and `auto_optimize_uploads` settings
2. **Variants not generated**: Verify WebP/AVIF settings are enabled
3. **CDN not working**: Check CDN URL configuration
4. **S3 issues**: Verify S3 credentials and permissions

### Logs

Check Rails logs for optimization status:
```bash
tail -f log/development.log | grep "image optimization"
```

### Manual Testing

```ruby
# Test optimization service
medium = Medium.find(123)
service = ImageOptimizationService.new(medium)
service.optimize!
service.generate_variants!
```

## Future Enhancements

- **Progressive JPEG**: Support for progressive loading
- **Lazy Loading**: Automatic lazy loading implementation
- **Smart Cropping**: AI-powered image cropping
- **Format Detection**: Automatic format selection based on content
- **Batch Processing**: Bulk optimization of existing images
