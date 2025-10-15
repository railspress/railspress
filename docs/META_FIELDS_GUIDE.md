# Meta Fields System Guide

The Meta Fields system provides a flexible way for plugins to extend Posts, Pages, Users, and AI Agents with custom key-value data without requiring database migrations. This system is fully cached with Redis for optimal performance.

## Overview

Meta Fields allow you to:
- Store custom data on any metable object (Post, Page, User, AiAgent)
- Use namespaced keys to avoid conflicts between plugins
- Set immutable fields that cannot be modified after creation
- Benefit from automatic Redis caching
- Access data through convenient helper methods

## Models with Meta Fields

The following models support meta fields:
- `Post` - For post-specific plugin data
- `Page` - For page-specific plugin data  
- `User` - For user-specific plugin data
- `AiAgent` - For AI agent configuration and state

## Basic Usage

### Setting Meta Fields

```ruby
# Basic usage
post.set_meta('featured', 'true')
post.set_meta('views', '150')
post.set_meta('rating', '4.5')

# With immutable flag (cannot be changed after creation)
post.set_meta('plugin_version', '1.2.3', immutable: true)

# Bulk operations
post.bulk_set_meta({
  'featured' => 'true',
  'views' => '150',
  'rating' => '4.5'
})
```

### Getting Meta Fields

```ruby
# Basic retrieval
featured = post.get_meta('featured')
views = post.get_meta('views')

# With type conversion
views_count = post.get_meta_as_integer('views', 0)
rating = post.get_meta_as_float('rating', 0.0)
is_featured = post.get_meta_as_boolean('featured', false)

# Bulk retrieval
values = post.bulk_get_meta(['featured', 'views', 'rating'])

# Check if field exists
if post.has_meta?('featured')
  # Handle featured post
end
```

### Deleting Meta Fields

```ruby
# Delete single field
post.delete_meta('featured')

# Clear all mutable fields
post.clear_all_meta!
```

## Plugin Namespacing

To avoid conflicts between plugins, use namespaced keys:

```ruby
# Plugin-specific methods
post.set_plugin_meta('my_plugin', 'custom_field', 'value')
value = post.get_plugin_meta('my_plugin', 'custom_field')

# Bulk plugin operations
post.bulk_set_plugin_meta('my_plugin', {
  'setting1' => 'value1',
  'setting2' => 'value2'
})

# Get all plugin meta fields
all_plugin_data = post.get_all_plugin_meta('my_plugin')
# Returns: { 'setting1' => 'value1', 'setting2' => 'value2' }

# Delete all plugin meta fields
post.delete_all_plugin_meta('my_plugin')
```

## Type Conversion Methods

The system provides convenient type conversion methods:

```ruby
# String (default)
title = post.get_meta_as_string('custom_title', 'Default Title')

# Integer
count = post.get_meta_as_integer('view_count', 0)

# Float
rating = post.get_meta_as_float('rating', 0.0)

# Boolean
enabled = post.get_meta_as_boolean('featured', false)

# JSON
config = post.get_meta_as_json('plugin_config', {})
post.set_meta_json('plugin_config', { key: 'value' })
```

## Caching

Meta fields are automatically cached in Redis for 1 hour:

```ruby
# First call hits database
post.get_meta('views')  # Database query + cache write

# Subsequent calls use cache
post.get_meta('views')  # Cache hit

# Cache is automatically invalidated on updates
post.set_meta('views', '200')  # Cache invalidated
```

### Cache Keys

The system uses these cache key patterns:
- Individual field: `meta_field:ModelName:ID:key`
- All fields: `meta_fields:ModelName:ID`

## API Endpoints

### List Meta Fields

```http
GET /api/v1/posts/123/meta_fields
GET /api/v1/posts/123/meta_fields?key=featured
GET /api/v1/posts/123/meta_fields?immutable=true
```

### Get Specific Meta Field

```http
GET /api/v1/posts/123/meta_fields/featured
```

### Create Meta Field

```http
POST /api/v1/posts/123/meta_fields
Content-Type: application/json
Authorization: Bearer YOUR_API_KEY

{
  "meta_field": {
    "key": "featured",
    "value": "true",
    "immutable": false
  }
}
```

### Update Meta Field

```http
PATCH /api/v1/posts/123/meta_fields/featured
Content-Type: application/json
Authorization: Bearer YOUR_API_KEY

{
  "meta_field": {
    "value": "false"
  }
}
```

### Delete Meta Field

```http
DELETE /api/v1/posts/123/meta_fields/featured
Authorization: Bearer YOUR_API_KEY
```

### Bulk Operations

```http
POST /api/v1/posts/123/meta_fields/bulk
Content-Type: application/json
Authorization: Bearer YOUR_API_KEY

{
  "meta_fields": [
    { "key": "featured", "value": "true" },
    { "key": "views", "value": "150" }
  ]
}
```

```http
PATCH /api/v1/posts/123/meta_fields/bulk
Content-Type: application/json
Authorization: Bearer YOUR_API_KEY

{
  "meta_fields": {
    "featured": { "value": "false" },
    "views": { "value": "200" }
  }
}
```

## Plugin Integration

### Plugin Base Integration

```ruby
class MyPlugin < Railspress::PluginBase
  def initialize
    super('my_plugin')
  end
  
  def on_post_save(post)
    # Set plugin-specific meta fields
    post.set_plugin_meta('my_plugin', 'last_processed', Time.current.iso8601)
    post.set_plugin_meta('my_plugin', 'version', '1.0.0', immutable: true)
  end
  
  def get_post_data(post)
    # Retrieve plugin data
    {
      last_processed: post.get_plugin_meta('my_plugin', 'last_processed'),
      version: post.get_plugin_meta('my_plugin', 'version')
    }
  end
end
```

### Hook Integration

```ruby
# In your plugin
Railspress::PluginSystem.add_action('post_save') do |post|
  # Set meta fields when post is saved
  post.set_plugin_meta('my_plugin', 'processed_at', Time.current.iso8601)
end

Railspress::PluginSystem.add_filter('post_content') do |content, post|
  # Modify content based on meta fields
  if post.get_plugin_meta('my_plugin', 'featured') == 'true'
    content = "<div class='featured'>#{content}</div>"
  end
  content
end
```

## Best Practices

### 1. Use Namespaced Keys

Always use plugin namespacing to avoid conflicts:

```ruby
# Good
post.set_plugin_meta('my_plugin', 'setting', 'value')

# Avoid
post.set_meta('setting', 'value')  # Could conflict with other plugins
```

### 2. Use Appropriate Types

```ruby
# Use type conversion methods
count = post.get_meta_as_integer('views', 0)
enabled = post.get_meta_as_boolean('featured', false)

# Avoid manual conversion
count = post.get_meta('views').to_i  # Less efficient
```

### 3. Use Immutable Fields for Configuration

```ruby
# Set plugin version as immutable
post.set_meta('plugin_version', '1.2.3', immutable: true)

# This will raise an error
post.set_meta('plugin_version', '1.2.4')  # ArgumentError
```

### 4. Clean Up on Plugin Uninstall

```ruby
# In plugin uninstall hook
Railspress::PluginSystem.add_action('plugin_uninstall') do |plugin_name|
  if plugin_name == 'my_plugin'
    # Clean up all plugin meta fields
    Post.find_each { |post| post.delete_all_plugin_meta('my_plugin') }
    Page.find_each { |page| page.delete_all_plugin_meta('my_plugin') }
    User.find_each { |user| user.delete_all_plugin_meta('my_plugin') }
    AiAgent.find_each { |agent| agent.delete_all_plugin_meta('my_plugin') }
  end
end
```

### 5. Use Bulk Operations

```ruby
# Efficient for multiple fields
post.bulk_set_plugin_meta('my_plugin', {
  'setting1' => 'value1',
  'setting2' => 'value2',
  'setting3' => 'value3'
})

# More efficient than multiple individual calls
```

## Performance Considerations

1. **Caching**: Meta fields are cached for 1 hour. Updates automatically invalidate cache.

2. **Bulk Operations**: Use bulk methods when setting/getting multiple fields.

3. **Indexes**: The system includes database indexes for optimal query performance.

4. **Memory Usage**: Large JSON values in meta fields consume more memory. Consider size limits.

## Error Handling

```ruby
begin
  post.set_meta('featured', 'true')
rescue ArgumentError => e
  # Handle immutable field modification
  Rails.logger.error "Cannot modify immutable field: #{e.message}"
end
```

## Migration from Custom Fields

If you're migrating from a custom fields system:

```ruby
# Old system
post.custom_field_value('featured')

# New system
post.get_meta('featured')
# or with plugin namespace
post.get_plugin_meta('my_plugin', 'featured')
```

## Troubleshooting

### Cache Issues

If you experience cache inconsistencies:

```ruby
# Clear all meta field cache for a specific object
Rails.cache.delete_matched("meta_field:#{post.class.name}:#{post.id}:*")
Rails.cache.delete("meta_fields:#{post.class.name}:#{post.id}")
```

### Performance Issues

Monitor meta field usage:

```ruby
# Count meta fields per object type
MetaField.group(:metable_type).count

# Find objects with many meta fields
Post.joins(:meta_fields).group(:id).having('COUNT(meta_fields.id) > ?', 10)
```

## Examples

### SEO Plugin

```ruby
class SeoPlugin < Railspress::PluginBase
  def enhance_post(post)
    post.set_plugin_meta('seo', 'focus_keyword', params[:focus_keyword])
    post.set_plugin_meta('seo', 'meta_title', params[:meta_title])
    post.set_plugin_meta('seo', 'meta_description', params[:meta_description])
    post.set_plugin_meta('seo', 'schema_type', 'Article', immutable: true)
  end
  
  def get_seo_data(post)
    {
      focus_keyword: post.get_plugin_meta('seo', 'focus_keyword'),
      meta_title: post.get_plugin_meta('seo', 'meta_title'),
      meta_description: post.get_plugin_meta('seo', 'meta_description'),
      schema_type: post.get_plugin_meta('seo', 'schema_type')
    }
  end
end
```

### Analytics Plugin

```ruby
class AnalyticsPlugin < Railspress::PluginBase
  def track_view(post)
    current_views = post.get_meta_as_integer('views', 0)
    post.set_meta('views', (current_views + 1).to_s)
    
    # Track view history
    history = post.get_meta_as_json('view_history', [])
    history << { timestamp: Time.current.iso8601, ip: request.ip }
    post.set_meta_json('view_history', history)
  end
end
```

This meta fields system provides a robust, cached, and plugin-friendly way to extend your RailsPress application with custom data.

