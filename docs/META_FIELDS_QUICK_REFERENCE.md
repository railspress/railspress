# Meta Fields Quick Reference

## Basic Operations

```ruby
# Set meta field
object.set_meta('key', 'value')
object.set_meta('key', 'value', immutable: true)

# Get meta field
value = object.get_meta('key')

# Delete meta field
object.delete_meta('key')

# Check if exists
object.has_meta?('key')
```

## Type Conversion

```ruby
# Get as specific type with default
string_val = object.get_meta_as_string('key', 'default')
int_val = object.get_meta_as_integer('key', 0)
float_val = object.get_meta_as_float('key', 0.0)
bool_val = object.get_meta_as_boolean('key', false)
json_val = object.get_meta_as_json('key', {})

# Set JSON
object.set_meta_json('key', { data: 'value' })
```

## Bulk Operations

```ruby
# Bulk set
object.bulk_set_meta({
  'key1' => 'value1',
  'key2' => 'value2'
})

# Bulk get
values = object.bulk_get_meta(['key1', 'key2'])

# Get all meta fields
all_meta = object.all_meta
```

## Plugin Namespacing

```ruby
# Plugin-specific methods
object.set_plugin_meta('plugin_name', 'key', 'value')
value = object.get_plugin_meta('plugin_name', 'key')
object.delete_plugin_meta('plugin_name', 'key')

# Bulk plugin operations
object.bulk_set_plugin_meta('plugin_name', { 'key1' => 'value1' })
plugin_data = object.get_all_plugin_meta('plugin_name')
object.delete_all_plugin_meta('plugin_name')
```

## API Endpoints

```http
# List meta fields
GET /api/v1/posts/123/meta_fields
GET /api/v1/posts/123/meta_fields?key=featured

# Get specific field
GET /api/v1/posts/123/meta_fields/featured

# Create field
POST /api/v1/posts/123/meta_fields
{
  "meta_field": {
    "key": "featured",
    "value": "true",
    "immutable": false
  }
}

# Update field
PATCH /api/v1/posts/123/meta_fields/featured
{
  "meta_field": {
    "value": "false"
  }
}

# Delete field
DELETE /api/v1/posts/123/meta_fields/featured

# Bulk create
POST /api/v1/posts/123/meta_fields/bulk
{
  "meta_fields": [
    { "key": "featured", "value": "true" },
    { "key": "views", "value": "150" }
  ]
}

# Bulk update
PATCH /api/v1/posts/123/meta_fields/bulk
{
  "meta_fields": {
    "featured": { "value": "false" },
    "views": { "value": "200" }
  }
}
```

## Supported Models

- `Post` - Post-specific plugin data
- `Page` - Page-specific plugin data
- `User` - User-specific plugin data
- `AiAgent` - AI agent configuration

## Cache Keys

- Individual: `meta_field:ModelName:ID:key`
- All fields: `meta_fields:ModelName:ID`
- Cache duration: 1 hour
- Auto-invalidated on updates

## Best Practices

1. Use plugin namespacing: `object.set_plugin_meta('plugin', 'key', 'value')`
2. Use type conversion methods: `object.get_meta_as_integer('views', 0)`
3. Use immutable for configuration: `object.set_meta('version', '1.0', immutable: true)`
4. Use bulk operations for multiple fields
5. Clean up on plugin uninstall

