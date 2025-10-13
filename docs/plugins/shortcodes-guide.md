# RailsPress Shortcodes Guide

## Overview

Shortcodes are simple codes that let you embed complex content and functionality into your posts and pages using a simple syntax. They work like macros that expand into full HTML when the content is displayed.

## Basic Syntax

### Self-Closing Shortcode
```
[shortcode_name attribute="value"]
```

### Enclosing Shortcode
```
[shortcode_name attribute="value"]Content here[/shortcode_name]
```

## Built-in Shortcodes

### 1. Gallery

Display a gallery of images from your media library.

**Syntax:**
```
[gallery ids="1,2,3" columns="3" size="medium"]
```

**Attributes:**
- `ids` (required) - Comma-separated media IDs
- `columns` - Number of columns (1-6, default: 3)
- `size` - Image size (thumbnail, medium, large, default: medium)

**Example:**
```
[gallery ids="10,11,12,13,14,15" columns="4"]
```

### 2. Button

Create styled call-to-action buttons.

**Syntax:**
```
[button url="/contact" style="primary" size="medium"]Click Here[/button]
```

**Attributes:**
- `url` (required) - Button destination URL
- `style` - Button color (primary, secondary, success, danger, default: primary)
- `size` - Button size (small, medium, large, default: medium)
- `target` - Link target (_self, _blank, default: _self)

**Examples:**
```
[button url="/signup" style="success" size="large"]Get Started[/button]
[button url="https://external.com" target="_blank"]Visit Site[/button]
```

### 3. YouTube

Embed YouTube videos responsively.

**Syntax:**
```
[youtube id="VIDEO_ID" width="560" height="315"]
```

**Attributes:**
- `id` (required) - YouTube video ID
- `width` - Video width (default: 560)
- `height` - Video height (default: 315)

**Example:**
```
[youtube id="dQw4w9WgXcQ"]
```

### 4. Recent Posts

Display a list of recent posts.

**Syntax:**
```
[recent_posts count="5" category="technology"]
```

**Attributes:**
- `count` - Number of posts (default: 5)
- `category` - Filter by category slug (optional)

**Examples:**
```
[recent_posts count="3"]
[recent_posts count="10" category="tutorials"]
```

### 5. Contact Form

Display a contact form.

**Syntax:**
```
[contact_form id="contact" email="admin@example.com"]
```

**Attributes:**
- `id` - Form identifier (default: contact)
- `email` - Recipient email (default: admin email from settings)

**Example:**
```
[contact_form email="support@mysite.com"]
```

### 6. Columns

Create multi-column layouts.

**Syntax:**
```
[columns count="2"]
Your content here will be split into columns
[/columns]
```

**Attributes:**
- `count` - Number of columns (2-4, default: 2)

**Example:**
```
[columns count="3"]
<div>Column 1 content</div>
<div>Column 2 content</div>
<div>Column 3 content</div>
[/columns]
```

### 7. Alert

Display alert/notice boxes.

**Syntax:**
```
[alert type="info"]Your message here[/alert]
```

**Attributes:**
- `type` - Alert style (info, success, warning, danger, default: info)

**Examples:**
```
[alert type="success"]Your changes have been saved![/alert]
[alert type="warning"]Please verify your email address.[/alert]
[alert type="danger"]This action cannot be undone.[/alert]
```

### 8. Code

Display code blocks with syntax highlighting.

**Syntax:**
```
[code lang="ruby"]
def hello
  puts "Hello World"
end
[/code]
```

**Attributes:**
- `lang` - Programming language (ruby, javascript, python, etc.)

**Example:**
```
[code lang="javascript"]
const greeting = "Hello World";
console.log(greeting);
[/code]
```

## Advanced Usage

### Nested Shortcodes

Some shortcodes can be nested:

```
[columns count="2"]
  [alert type="info"]Information in column 1[/alert]
  [alert type="success"]Success in column 2[/alert]
[/columns]
```

### Combining Shortcodes

```
[alert type="info"]
Check out our latest posts:
[recent_posts count="3"]
[/alert]
```

### Dynamic Attributes

Use shortcodes with dynamic data:

```
[button url="/posts/my-latest-post"]Read Latest Post[/button]
```

## Creating Custom Shortcodes

### Via Plugin

The recommended way is through a plugin:

```ruby
class MyPlugin < Railspress::PluginBase
  plugin_name 'My Custom Plugin'
  plugin_version '1.0.0'
  
  def activate
    super
    register_shortcodes
  end
  
  private
  
  def register_shortcodes
    # Simple shortcode
    Railspress::ShortcodeProcessor.register('hello') do |attrs|
      name = attrs[:name] || 'World'
      "<p>Hello, #{name}!</p>"
    end
    
    # Shortcode with content
    Railspress::ShortcodeProcessor.register('highlight') do |attrs, content|
      color = attrs[:color] || 'yellow'
      "<mark style='background-color: #{color}'>#{content}</mark>"
    end
    
    # Advanced shortcode with context
    Railspress::ShortcodeProcessor.register('user_info') do |attrs, content, context|
      if context[:current_user]
        "<p>Logged in as: #{context[:current_user].email}</p>"
      else
        "<p>Please log in</p>"
      end
    end
  end
end
```

### Via Initializer

For system-wide shortcodes, add to an initializer:

```ruby
# config/initializers/custom_shortcodes.rb

Rails.application.config.after_initialize do
  Railspress::ShortcodeProcessor.register('price') do |attrs|
    amount = attrs[:amount]
    currency = attrs[:currency] || 'USD'
    
    "<span class='price'>#{currency} #{amount}</span>"
  end
end
```

### Direct Registration

```ruby
# In a controller or model
Railspress::ShortcodeProcessor.register('download') do |attrs|
  file_id = attrs[:id]
  medium = Medium.find_by(id: file_id)
  
  if medium&.file&.attached?
    url = Rails.application.routes.url_helpers.rails_blob_path(medium.file)
    "<a href='#{url}' download class='download-button'>Download #{medium.title}</a>"
  else
    ''
  end
end
```

## Shortcode Best Practices

### 1. Use Descriptive Names
```
[download_button] ✓ Good
[db] ✗ Too cryptic
```

### 2. Provide Defaults
```ruby
register('my_shortcode') do |attrs|
  color = attrs[:color] || 'blue'  # Default value
  # ...
end
```

### 3. Validate Input
```ruby
register('gallery') do |attrs|
  ids = attrs[:ids]
  return '' if ids.blank?  # Handle missing required attrs
  
  # Process...
end
```

### 4. Sanitize Output
```ruby
register('user_content') do |attrs, content|
  sanitized = ActionView::Base.full_sanitizer.sanitize(content)
  "<div>#{sanitized}</div>"
end
```

### 5. Handle Errors Gracefully
```ruby
register('api_data') do |attrs|
  begin
    # Risky operation
  rescue => e
    Rails.logger.error "Shortcode error: #{e.message}"
    "[Error loading data]"
  end
end
```

## Advanced Shortcode Examples

### Pricing Table

```ruby
Railspress::ShortcodeProcessor.register('pricing_table') do |attrs, content|
  plans = attrs[:plans]&.split(',') || []
  
  html = '<div class="pricing-grid grid grid-cols-3 gap-6">'
  plans.each do |plan|
    html += render_pricing_plan(plan)
  end
  html += '</div>'
  html
end
```

Usage:
```
[pricing_table plans="basic,pro,enterprise"]
```

### Tabs

```ruby
Railspress::ShortcodeProcessor.register('tabs') do |attrs, content|
  tabs = content.scan(/\[tab title="([^"]+)"\](.*?)\[\/tab\]/m)
  
  html = '<div class="tabs">'
  html += '<div class="tab-buttons">'
  tabs.each_with_index do |(title, _), i|
    html += "<button class='tab-button #{i == 0 ? 'active' : ''}'>#{title}</button>"
  end
  html += '</div>'
  
  html += '<div class="tab-content">'
  tabs.each_with_index do |(_, content), i|
    html += "<div class='tab-pane #{i == 0 ? 'active' : ''}'>#{content}</div>"
  end
  html += '</div></div>'
  
  html
end

Railspress::ShortcodeProcessor.register('tab') do |attrs, content|
  # Processed by parent [tabs] shortcode
  content
end
```

Usage:
```
[tabs]
[tab title="Overview"]Overview content here[/tab]
[tab title="Features"]Features content here[/tab]
[tab title="Pricing"]Pricing content here[/tab]
[/tabs]
```

### Conditional Content

```ruby
Railspress::ShortcodeProcessor.register('if_logged_in') do |attrs, content, context|
  if context[:current_user]
    content
  else
    ''
  end
end

Railspress::ShortcodeProcessor.register('if_role') do |attrs, content, context|
  required_role = attrs[:role]
  
  if context[:current_user]&.role == required_role
    content
  else
    ''
  end
end
```

Usage:
```
[if_logged_in]
Welcome back! This content is only for logged-in users.
[/if_logged_in]

[if_role role="administrator"]
Admin-only content here
[/if_role]
```

## Shortcode Testing

### Admin Tester

Use the built-in tester at `/admin/shortcodes`:
1. Enter shortcode syntax
2. Click "Test Shortcode"
3. See the rendered output
4. Copy the code or output

### Console Testing

```ruby
# Test in Rails console
content = "[button url='/test']Click Me[/button]"
result = Railspress::ShortcodeProcessor.process(content)
puts result
```

### Unit Testing

```ruby
# In your tests
describe 'Shortcodes' do
  it 'processes button shortcode' do
    content = "[button url='/test']Click[/button]"
    result = Railspress::ShortcodeProcessor.process(content)
    
    expect(result).to include('href="/test"')
    expect(result).to include('Click')
  end
end
```

## Shortcode Security

### XSS Prevention

Always escape user input:

```ruby
register('user_content') do |attrs, content|
  safe_content = ERB::Util.html_escape(content)
  "<div>#{safe_content}</div>"
end
```

### Sanitization

Use Rails sanitizers:

```ruby
register('custom_html') do |attrs, content|
  # Allow only safe tags
  sanitized = ActionController::Base.helpers.sanitize(
    content,
    tags: %w(p strong em a),
    attributes: %w(href title)
  )
  "<div>#{sanitized}</div>"
end
```

### Attribute Validation

```ruby
register('link') do |attrs|
  url = attrs[:url]
  
  # Validate URL
  return '' unless url =~ URI::DEFAULT_PARSER.make_regexp
  
  "<a href='#{ERB::Util.html_escape(url)}'>Link</a>"
end
```

## Performance Tips

### 1. Cache Shortcode Output

```ruby
register('expensive_operation') do |attrs|
  cache_key = "shortcode:expensive:#{attrs[:id]}"
  
  Rails.cache.fetch(cache_key, expires_in: 1.hour) do
    # Expensive operation
    perform_calculation
  end
end
```

### 2. Lazy Loading

```ruby
register('lazy_gallery') do |attrs|
  # Add lazy loading attributes
  '<img src="..." loading="lazy" />'
end
```

### 3. Minimize DB Queries

```ruby
register('post_list') do |attrs|
  # Use includes to avoid N+1
  posts = Post.includes(:user, :categories).published.limit(5)
  render_posts(posts)
end
```

## Troubleshooting

### Shortcode Not Processing

1. **Check Registration**: Ensure shortcode is registered
2. **Check Syntax**: Verify brackets and quotes
3. **Check Logs**: Look for error messages
4. **Test in Tester**: Use `/admin/shortcodes` to test

### Output Not Rendering

1. **HTML Safety**: Use `.html_safe` if needed
2. **Check Context**: Ensure necessary data is available
3. **Validate Attributes**: Check required attributes are provided

### Conflicts

```ruby
# Avoid naming conflicts
Railspress::ShortcodeProcessor.exists?('button')  # Check before registering

# Override existing shortcode
Railspress::ShortcodeProcessor.unregister('button')
Railspress::ShortcodeProcessor.register('button') do |attrs, content|
  # New implementation
end
```

## Migration from WordPress

### Common WordPress Shortcodes

| WordPress | RailsPress Equivalent |
|-----------|----------------------|
| `[gallery]` | `[gallery ids="1,2,3"]` |
| `[caption]` | `[alert type="info"]` |
| `[embed]` | `[youtube id="..."]` |
| `[audio]` | Custom implementation needed |
| `[video]` | Custom implementation needed |

### Converting WordPress Shortcodes

WordPress:
```
[gallery ids="1,2,3" size="medium" columns="3"]
```

RailsPress:
```
[gallery ids="1,2,3" size="medium" columns="3"]
```

Most WordPress shortcodes work the same way!

## API Access

### List All Shortcodes

```ruby
# In console
Railspress::ShortcodeProcessor.all
# => ["gallery", "button", "youtube", ...]
```

### Check if Shortcode Exists

```ruby
Railspress::ShortcodeProcessor.exists?('button')
# => true
```

### Process Content

```ruby
content = "Check out this [button url='/demo']Demo[/button]"
result = Railspress::ShortcodeProcessor.process(content)
```

## Examples by Use Case

### Landing Page

```
[alert type="success"]
🎉 Limited Time Offer - 50% Off!
[/alert]

[columns count="3"]
<div class="feature">
  <h3>Fast</h3>
  <p>Lightning quick performance</p>
</div>
<div class="feature">
  <h3>Secure</h3>
  <p>Bank-level security</p>
</div>
<div class="feature">
  <h3>Scalable</h3>
  <p>Grows with your business</p>
</div>
[/columns]

[button url="/signup" style="success" size="large"]Start Free Trial[/button]
```

### Blog Post

```
[alert type="info"]
This post is part of our Rails Tutorial series.
[/alert]

Here's a quick demo:

[youtube id="dQw4w9WgXcQ"]

[code lang="ruby"]
def hello_world
  puts "Hello from RailsPress!"
end
[/code]

[button url="/next-tutorial"]Continue to Next Tutorial →[/button]
```

### Gallery Page

```
[gallery ids="1,2,3,4,5,6,7,8,9" columns="3" size="large"]

[columns count="2"]
[recent_posts count="5" category="photography"]
[contact_form email="gallery@example.com"]
[/columns]
```

## Plugin Integration

Plugins can register their own shortcodes:

```ruby
# lib/plugins/my_plugin/my_plugin.rb

class MyPlugin < Railspress::PluginBase
  def activate
    super
    register_my_shortcodes
  end
  
  def deactivate
    super
    unregister_my_shortcodes
  end
  
  private
  
  def register_my_shortcodes
    Railspress::ShortcodeProcessor.register('my_feature') do |attrs|
      # Plugin functionality
    end
  end
  
  def unregister_my_shortcodes
    Railspress::ShortcodeProcessor.unregister('my_feature')
  end
end
```

## Reference

### Available Shortcodes

View all available shortcodes at: `/admin/shortcodes`

### Test Shortcodes

Use the interactive tester at: `/admin/shortcodes`

### Documentation

- This guide: `SHORTCODES_GUIDE.md`
- Plugin system: `lib/railspress/plugin_base.rb`
- Processor: `lib/railspress/shortcode_processor.rb`

---

**Make your content dynamic with shortcodes!** 🚀

Embed galleries, buttons, forms, and custom functionality with simple bracket syntax.



