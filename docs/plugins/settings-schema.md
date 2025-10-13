# Plugin Settings Schema API Guide

**Automatically generate admin settings pages for your plugins!**

---

## 📚 Table of Contents

- [Introduction](#introduction)
- [Quick Start](#quick-start)
- [Schema Definition](#schema-definition)
- [Field Types](#field-types)
- [Validation](#validation)
- [Examples](#examples)
- [Best Practices](#best-practices)

---

## Introduction

The **Plugin Settings Schema API** allows plugin developers to declaratively define their settings using a simple DSL. RailsPress automatically:

✅ **Generates admin UI** - Beautiful forms rendered automatically  
✅ **Handles validation** - Built-in validation rules  
✅ **Manages storage** - Settings saved to database  
✅ **Provides helpers** - Easy access to settings values  
✅ **Supports all field types** - Text, select, checkbox, color, and more  

**No more manual form creation!** Just define your schema and get a full admin interface.

---

## Quick Start

### Define Settings Schema

```ruby
class MyPlugin < Railspress::PluginBase
  plugin_name 'My Plugin'
  plugin_version '1.0.0'
  
  # Define settings schema
  settings_schema do
    section 'General Settings' do
      text 'api_key', 'API Key',
        description: 'Your API key from the service',
        required: true,
        placeholder: 'sk_live_...'
      
      checkbox 'enabled', 'Enable Integration',
        description: 'Turn integration on/off',
        default: true
      
      number 'max_items', 'Maximum Items',
        description: 'Maximum items to fetch',
        default: 10,
        min: 1,
        max: 100
    end
  end
end
```

### Access Settings

```ruby
# In your plugin
api_key = get_setting('api_key')
enabled = get_setting('enabled', false)  # with default
max_items = get_setting('max_items', 10)
```

### Admin Interface

The admin settings page is automatically available at:
```
/admin/plugins/:id/settings
```

**That's it!** RailsPress handles everything else.

---

## Schema Definition

### Basic Structure

```ruby
settings_schema do
  section 'Section Name', description: 'Optional description' do
    # Add fields here
  end
  
  section 'Another Section' do
    # More fields
  end
end
```

### Multiple Sections

Organize settings into logical groups:

```ruby
settings_schema do
  section 'API Configuration', description: 'External API settings' do
    text 'api_url', 'API URL'
    text 'api_key', 'API Key', required: true
  end
  
  section 'Display Options', description: 'Control how content is displayed' do
    select 'layout', 'Layout Type', [['Grid', 'grid'], ['List', 'list']]
    number 'items_per_page', 'Items Per Page', default: 10
  end
  
  section 'Advanced', description: 'Advanced settings for power users' do
    code 'custom_css', 'Custom CSS'
    checkbox 'debug_mode', 'Debug Mode', default: false
  end
end
```

---

## Field Types

### Text Field

Simple text input.

```ruby
text 'field_key', 'Field Label',
  description: 'Help text shown below field',
  required: true,
  placeholder: 'Enter text...',
  default: 'default value'
```

**Options:**
- `required` - Mark as required
- `placeholder` - Placeholder text
- `default` - Default value
- `description` - Help text
- `pattern` - Regex validation pattern

### Textarea Field

Multi-line text input.

```ruby
textarea 'long_text', 'Description',
  description: 'Enter a long description',
  rows: 6,
  placeholder: 'Type here...',
  default: ''
```

**Options:**
- `rows` - Number of rows (default: 4)
- Plus all text field options

### Number Field

Numeric input with validation.

```ruby
number 'count', 'Item Count',
  description: 'How many items to show',
  default: 10,
  min: 1,
  max: 100,
  step: 1
```

**Options:**
- `min` - Minimum value
- `max` - Maximum value
- `step` - Increment step
- `default` - Default value

### Checkbox Field

Boolean on/off toggle.

```ruby
checkbox 'enabled', 'Enable Feature',
  description: 'Turn this feature on or off',
  default: true
```

**Value**: `true` or `false`

### Select Field

Dropdown selection.

```ruby
select 'theme', 'Theme',
  [
    ['Light', 'light'],
    ['Dark', 'dark'],
    ['Auto', 'auto']
  ],
  description: 'Choose a theme',
  default: 'light'
```

**Choices format**: `[[Label, Value], ...]`

### Radio Field

Radio button group.

```ruby
radio 'size', 'Size',
  [
    ['Small', 'sm'],
    ['Medium', 'md'],
    ['Large', 'lg']
  ],
  description: 'Select a size',
  default: 'md'
```

**Choices format**: Same as select

### Email Field

Email input with validation.

```ruby
email 'contact_email', 'Contact Email',
  description: 'Email address for notifications',
  required: true,
  placeholder: 'user@example.com'
```

**Validation**: Automatically validates email format

### URL Field

URL input with validation.

```ruby
url 'webhook_url', 'Webhook URL',
  description: 'URL to send webhooks',
  required: true,
  placeholder: 'https://example.com/webhook'
```

**Validation**: Automatically validates URL format

### Color Field

Color picker.

```ruby
color 'primary_color', 'Primary Color',
  description: 'Main theme color',
  default: '#3B82F6'
```

**Value**: Hex color code (e.g., `#3B82F6`)

### WYSIWYG Field

Rich text editor.

```ruby
wysiwyg 'welcome_message', 'Welcome Message',
  description: 'Message shown to users',
  editor: 'trix'  # or 'tinymce'
```

**Value**: HTML string

### Code Field

Code editor for custom code.

```ruby
code 'custom_css', 'Custom CSS',
  description: 'Add custom CSS styles',
  language: 'css',
  placeholder: '.my-class { color: red; }'
```

**Languages**: `css`, `javascript`, `html`, `json`, `yaml`

### Custom Field

Render your own field HTML.

```ruby
custom 'advanced_option', 'Advanced Option' do |form, value|
  # Return custom HTML
  content_tag(:div, class: 'custom-field') do
    # Your custom field rendering
  end
end
```

---

## Validation

### Built-in Validation

Fields are automatically validated based on type and options:

```ruby
# Required validation
text 'api_key', 'API Key', required: true

# Min/Max validation
number 'count', 'Count', min: 1, max: 100

# Pattern validation (regex)
text 'slug', 'Slug', pattern: /\A[a-z0-9-]+\z/

# Email format validation
email 'contact', 'Email'  # Auto-validates email format

# URL format validation
url 'webhook', 'Webhook URL'  # Auto-validates URL format
```

### Validation Errors

Validation errors are automatically displayed:

```ruby
# Invalid setting
{ 'count' => 150 }  # Fails: max is 100

# Error shown to user:
# "Count must be at most 100"
```

---

## Complete Example

### Full Plugin with Schema

```ruby
class SocialSharing < Railspress::PluginBase
  plugin_name 'Social Sharing'
  plugin_version '2.0.0'
  plugin_description 'Add social sharing buttons with customizable settings'
  
  settings_schema do
    section 'Button Configuration' do
      checkbox 'show_facebook', 'Facebook',
        description: 'Show Facebook share button',
        default: true
      
      checkbox 'show_twitter', 'Twitter/X',
        description: 'Show Twitter/X share button',
        default: true
      
      checkbox 'show_linkedin', 'LinkedIn',
        description: 'Show LinkedIn share button',
        default: false
      
      select 'button_position', 'Button Position',
        [
          ['Above Content', 'above'],
          ['Below Content', 'below'],
          ['Both', 'both']
        ],
        default: 'below'
    end
    
    section 'Appearance' do
      select 'button_style', 'Button Style',
        [
          ['Icon Only', 'icon'],
          ['Icon + Text', 'icon_text'],
          ['Text Only', 'text']
        ],
        default: 'icon'
      
      color 'button_color', 'Button Color',
        default: '#3B82F6'
      
      number 'button_size', 'Button Size (px)',
        default: 40,
        min: 24,
        max: 64
    end
    
    section 'Advanced' do
      textarea 'custom_message', 'Share Message Template',
        description: 'Use {{title}} and {{url}} as placeholders',
        rows: 3,
        default: 'Check out this post: {{title}}'
      
      checkbox 'count_shares', 'Show Share Count',
        description: 'Display number of shares (requires API)',
        default: false
    end
  end
  
  def initialize
    super
    register_filters if get_setting('show_facebook', true) || get_setting('show_twitter', true)
  end
  
  private
  
  def register_filters
    add_filter('post_content', 20) do |content, post|
      position = get_setting('button_position', 'below')
      buttons = render_share_buttons(post)
      
      case position
      when 'above'
        buttons + content
      when 'below'
        content + buttons
      when 'both'
        buttons + content + buttons
      else
        content
      end
    end
  end
  
  def render_share_buttons(post)
    buttons_html = []
    
    if get_setting('show_facebook', true)
      buttons_html << facebook_button(post)
    end
    
    if get_setting('show_twitter', true)
      buttons_html << twitter_button(post)
    end
    
    <<~HTML
      <div class="social-share-buttons" style="margin: 2rem 0; display: flex; gap: 0.5rem;">
        #{buttons_html.join("\n")}
      </div>
    HTML
  end
  
  def facebook_button(post)
    color = get_setting('button_color', '#3B82F6')
    size = get_setting('button_size', 40)
    
    <<~HTML
      <a href="https://facebook.com/sharer/sharer.php?u=#{post.url}" 
         target="_blank"
         style="display: inline-flex; align-items: center; justify-content: center; width: #{size}px; height: #{size}px; background: #{color}; color: white; border-radius: 50%; text-decoration: none;">
        f
      </a>
    HTML
  end
  
  def twitter_button(post)
    message = get_setting('custom_message', 'Check out this post: {{title}}')
    message = message.gsub('{{title}}', post.title).gsub('{{url}}', post.url)
    
    color = get_setting('button_color', '#3B82F6')
    size = get_setting('button_size', 40)
    
    <<~HTML
      <a href="https://twitter.com/intent/tweet?text=#{CGI.escape(message)}" 
         target="_blank"
         style="display: inline-flex; align-items: center; justify-content: center; width: #{size}px; height: #{size}px; background: #{color}; color: white; border-radius: 50%; text-decoration: none;">
        𝕏
      </a>
    HTML
  end
end
```

---

## Accessing Settings

### In Your Plugin

```ruby
# Get setting with default
value = get_setting('key', 'default_value')

# Get setting (returns nil if not set)
value = get_setting('key')

# Check if setting exists
if has_setting?('key')
  # Do something
end

# Get all settings
all_settings = settings
```

### In Views/Controllers

```ruby
# Get plugin instance
plugin = Railspress::PluginSystem.get_plugin('my_plugin')

# Access settings
if plugin
  api_key = plugin.get_setting('api_key')
end
```

---

## Best Practices

### 1. Organize Settings Logically

✅ **Good:**
```ruby
section 'API Configuration' do
  # API-related settings
end

section 'Display Options' do
  # UI-related settings
end
```

❌ **Bad:**
```ruby
section 'Settings' do
  # Everything mixed together
end
```

### 2. Provide Good Descriptions

✅ **Good:**
```ruby
text 'api_key', 'API Key',
  description: 'Find this in your account dashboard under Settings → API Keys',
  placeholder: 'sk_live_...'
```

❌ **Bad:**
```ruby
text 'api_key', 'API Key'
# No description or placeholder
```

### 3. Use Sensible Defaults

✅ **Good:**
```ruby
checkbox 'enabled', 'Enable Feature', default: true
number 'timeout', 'Timeout (seconds)', default: 30, min: 1, max: 300
```

✅ Settings work out of the box without configuration

### 4. Validate Input

```ruby
# Use built-in validation
text 'email', 'Email', required: true
number 'age', 'Age', min: 18, max: 120

# Or custom validation in update_settings method
def update_settings(new_settings)
  if new_settings['api_key'].present? && !valid_api_key?(new_settings['api_key'])
    return { error: 'Invalid API key format' }
  end
  
  super
end
```

### 5. Group Related Settings

```ruby
section 'Social Media' do
  checkbox 'enable_twitter', 'Twitter'
  checkbox 'enable_facebook', 'Facebook'
  checkbox 'enable_linkedin', 'LinkedIn'
end
```

---

## Field Reference

### All Available Field Types

| Field Type | Input | Best For |
|------------|-------|----------|
| `text` | Single-line text | Short text, IDs, names |
| `textarea` | Multi-line text | Long text, descriptions |
| `number` | Numeric | Counts, limits, timeouts |
| `checkbox` | Toggle | Boolean on/off |
| `select` | Dropdown | Multiple options |
| `radio` | Radio buttons | Exclusive choices |
| `email` | Email input | Email addresses |
| `url` | URL input | Web addresses |
| `color` | Color picker | Colors |
| `wysiwyg` | Rich text | Formatted content |
| `code` | Code editor | CSS, JS, JSON |
| `custom` | Custom HTML | Special cases |

### Field Options Reference

```ruby
# All field types support:
required: true/false          # Mark as required
description: 'Help text'      # Show below field
default: 'value'              # Default value
placeholder: 'Hint...'        # Placeholder text

# Number-specific:
min: 0                        # Minimum value
max: 100                      # Maximum value
step: 1                       # Increment step

# Textarea-specific:
rows: 6                       # Number of rows

# Code-specific:
language: 'css'               # Syntax highlighting

# Select/Radio-specific:
choices: [['Label', 'value']] # Options array
```

---

## Advanced Examples

### Example 1: SEO Plugin

```ruby
class SeoOptimizer < Railspress::PluginBase
  plugin_name 'SEO Optimizer'
  
  settings_schema do
    section 'Meta Tags' do
      text 'default_title_suffix', 'Default Title Suffix',
        description: 'Appended to all page titles',
        default: '| My Site',
        placeholder: '| My Site Name'
      
      textarea 'default_description', 'Default Meta Description',
        description: 'Used when page has no description',
        rows: 3,
        placeholder: 'Your site description...'
      
      url 'default_og_image', 'Default OG Image',
        description: 'Default Open Graph image URL',
        placeholder: 'https://example.com/og-image.jpg'
    end
    
    section 'Indexing' do
      checkbox 'noindex_categories', 'No-Index Category Pages',
        description: 'Prevent search engines from indexing category pages',
        default: false
      
      checkbox 'noindex_tags', 'No-Index Tag Pages',
        default: false
      
      select 'robots_default', 'Default Robots Meta',
        [
          ['Index, Follow', 'index, follow'],
          ['Index, No-Follow', 'index, nofollow'],
          ['No-Index, Follow', 'noindex, follow'],
          ['No-Index, No-Follow', 'noindex, nofollow']
        ],
        default: 'index, follow'
    end
    
    section 'Schema.org' do
      select 'organization_type', 'Organization Type',
        [
          ['Organization', 'Organization'],
          ['Corporation', 'Corporation'],
          ['Local Business', 'LocalBusiness'],
          ['Person', 'Person']
        ],
        default: 'Organization'
      
      text 'organization_name', 'Organization Name',
        placeholder: 'Your Company Name'
      
      url 'organization_logo', 'Organization Logo URL',
        placeholder: 'https://example.com/logo.png'
    end
  end
end
```

### Example 2: Analytics Plugin

```ruby
class AnalyticsTracker < Railspress::PluginBase
  plugin_name 'Analytics Tracker'
  
  settings_schema do
    section 'Google Analytics' do
      checkbox 'enable_ga4', 'Enable Google Analytics 4',
        default: false
      
      text 'ga4_measurement_id', 'GA4 Measurement ID',
        description: 'Your GA4 Measurement ID (starts with G-)',
        placeholder: 'G-XXXXXXXXXX',
        required: false
    end
    
    section 'Custom Events' do
      checkbox 'track_downloads', 'Track Downloads',
        description: 'Track file download clicks',
        default: true
      
      checkbox 'track_outbound_links', 'Track Outbound Links',
        description: 'Track clicks on external links',
        default: true
      
      checkbox 'track_scroll_depth', 'Track Scroll Depth',
        description: 'Track how far users scroll',
        default: false
    end
    
    section 'Privacy' do
      checkbox 'anonymize_ip', 'Anonymize IP Addresses',
        description: 'Comply with GDPR by anonymizing IPs',
        default: true
      
      checkbox 'respect_dnt', 'Respect Do Not Track',
        description: 'Honor user Do Not Track browser setting',
        default: true
      
      text 'cookie_domain', 'Cookie Domain',
        description: 'Domain for analytics cookies (leave blank for auto)',
        placeholder: '.example.com'
    end
  end
end
```

### Example 3: Content Import Plugin

```ruby
class ContentImporter < Railspress::PluginBase
  plugin_name 'Content Importer'
  
  settings_schema do
    section 'Import Source' do
      select 'source_type', 'Import From',
        [
          ['WordPress XML', 'wordpress'],
          ['Medium RSS', 'medium'],
          ['Ghost JSON', 'ghost'],
          ['Custom API', 'api']
        ],
        required: true
      
      url 'source_url', 'Source URL',
        description: 'URL to import from',
        placeholder: 'https://example.com/feed.xml'
    end
    
    section 'Import Options' do
      checkbox 'import_images', 'Import Images',
        description: 'Download and import images',
        default: true
      
      checkbox 'import_comments', 'Import Comments',
        default: false
      
      select 'post_status', 'Imported Post Status',
        [
          ['Draft', 'draft'],
          ['Published', 'published']
        ],
        default: 'draft'
      
      select 'author', 'Assign to Author',
        User.author.pluck(:email, :id),
        description: 'User to assign imported posts to'
    end
    
    section 'Mapping' do
      code 'category_mapping', 'Category Mapping (JSON)',
        description: 'Map source categories to your categories',
        language: 'json',
        placeholder: '{"Tech": "technology", "News": "updates"}'
      
      checkbox 'create_missing_categories', 'Create Missing Categories',
        description: 'Auto-create categories that don\'t exist',
        default: true
    end
  end
end
```

---

## Tips & Tricks

### 1. Conditional Fields (Future)

Show/hide fields based on other values:

```ruby
# Coming soon
section 'API Settings' do
  select 'api_type', 'API Type', [['REST', 'rest'], ['GraphQL', 'graphql']]
  
  # Show only if api_type == 'rest'
  text 'rest_endpoint', 'REST Endpoint',
    show_if: { api_type: 'rest' }
  
  # Show only if api_type == 'graphql'
  text 'graphql_endpoint', 'GraphQL Endpoint',
    show_if: { api_type: 'graphql' }
end
```

### 2. Field Groups (Future)

Group related fields visually:

```ruby
# Coming soon
section 'Credentials' do
  group 'API Authentication' do
    text 'api_username', 'Username'
    text 'api_password', 'Password', type: 'password'
  end
end
```

### 3. Dynamic Choices

Load choices dynamically:

```ruby
select 'user_id', 'Select User',
  User.all.pluck(:email, :id),  # Dynamic from database
  description: 'Choose a user'
```

---

## Migration Guide

### Old Way (Manual Forms)

```ruby
# Old: Manual form in settings.html.erb
<%= form_with ... do |f| %>
  <%= f.text_field :api_key %>
  <%= f.checkbox :enabled %>
  # Lots of manual HTML...
<% end %>
```

### New Way (Schema)

```ruby
# New: Just define schema
settings_schema do
  section 'Settings' do
    text 'api_key', 'API Key'
    checkbox 'enabled', 'Enable'
  end
end

# Form auto-generated!
```

**Benefits:**
- ✅ Less code
- ✅ Automatic validation
- ✅ Consistent UI
- ✅ Easy to maintain

---

## Troubleshooting

### Schema Not Showing

**Issue**: Settings page shows JSON editor instead of form

**Solution**: Ensure your plugin:
1. Inherits from `Railspress::PluginBase`
2. Defines `settings_schema` block
3. Is properly loaded

### Settings Not Saving

**Issue**: Settings don't persist

**Solution**:
1. Check validation errors
2. Ensure plugin record exists in database
3. Check browser console for JS errors

### Field Not Rendering

**Issue**: Custom field doesn't appear

**Solution**:
1. Check field type is valid
2. Ensure helper is included
3. Check for typos in schema

---

## API Reference

### SettingsSchema Methods

```ruby
schema = plugin.settings_schema

# Get all sections
schema.sections  # => Array of Section objects

# Get all fields
schema.all_fields  # => Array of Field objects

# Find specific field
field = schema.find_field('api_key')  # => Field object

# Validate settings
errors = schema.validate(settings_hash)  # => Hash of errors
```

### Field Methods

```ruby
field.key          # => 'api_key'
field.label        # => 'API Key'
field.required?    # => true/false
field.default      # => Default value
field.description  # => Help text
field.validate(value)  # => Array of errors
```

---

## Resources

- **Plugin Base**: `lib/railspress/plugin_base.rb`
- **Settings Schema**: `lib/railspress/settings_schema.rb`
- **Helper**: `app/helpers/plugin_settings_helper.rb`
- **Example Plugin**: `lib/plugins/email_notifications/`

---

**Version**: 1.0.0  
**Last Updated**: October 2025  
**Status**: Production Ready

---

*Simplify plugin development with declarative settings!* 🚀



