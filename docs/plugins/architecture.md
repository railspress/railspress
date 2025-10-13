# RailsPress Plugin Architecture

## Overview

RailsPress uses a WordPress-inspired but Rails-native plugin system that allows developers to extend functionality without modifying core code.

## Architecture Principles

### 1. **Inheritance-Based**
All plugins inherit from `Railspress::PluginBase` which provides:
- Lifecycle management (activate/deactivate)
- Settings storage and retrieval
- Hook and filter registration
- Shortcode registration
- Helper injection
- Logging and error handling

### 2. **Hook-Driven**
Plugins use hooks and filters to interact with the core system:
- **Actions**: Execute code at specific points (events)
- **Filters**: Modify data before it's used
- **Shortcodes**: Add custom content tags

### 3. **Self-Contained**
Each plugin is a self-contained directory with:
- Main plugin file
- Optional assets, views, helpers
- Documentation
- Tests
- Configuration

### 4. **Database-Managed**
Plugins are stored in the `plugins` table with:
- Name, description, version
- Active/inactive status
- Settings (JSON)
- Activation metadata

## Core Components

### PluginBase Class

Located: `lib/railspress/plugin_base.rb`

**Responsibilities:**
- Provides plugin DSL (plugin_name, plugin_version, etc.)
- Manages activation/deactivation lifecycle
- Stores and retrieves settings
- Registers hooks, filters, and shortcodes
- Injects helpers into controllers
- Handles errors gracefully

**Key Methods:**
```ruby
# Metadata
plugin_name 'Name'
plugin_version '1.0.0'
plugin_description 'Description'
plugin_author 'Author'

# Lifecycle
activate()
deactivate()

# Settings
get_setting(key, default)
set_setting(key, value)
setting_enabled?(key)

# Hooks & Filters
add_action(hook_name, method_name)
add_filter(filter_name, method_name)

# Shortcodes
register_shortcode(name, &block)
unregister_shortcode(name)
```

### PluginSystem Class

Located: `lib/railspress/plugin_system.rb`

**Responsibilities:**
- Global hook and filter registry
- Execute hooks across all plugins
- Apply filters in sequence
- Manage plugin loading order
- Track registered actions/filters

**Key Methods:**
```ruby
# Actions
do_action(hook_name, *args)
add_action(hook_name, callback)

# Filters
apply_filters(filter_name, value, *args)
add_filter(filter_name, callback)

# Management
plugin_loaded?(name)
active_plugins()
```

## Standard Plugin Structure

### Minimal Plugin

```ruby
class MinimalPlugin < Railspress::PluginBase
  plugin_name 'Minimal Plugin'
  plugin_version '1.0.0'
  plugin_description 'Does one thing well'
  plugin_author 'Your Name'
  
  def activate
    super
    Rails.logger.info "#{plugin_name} activated"
  end
  
  def deactivate
    super
    Rails.logger.info "#{plugin_name} deactivated"
  end
end

MinimalPlugin.new
```

### Full-Featured Plugin

```ruby
class FullPlugin < Railspress::PluginBase
  # Metadata
  plugin_name 'Full-Featured Plugin'
  plugin_version '2.0.0'
  plugin_description 'Complete example'
  plugin_author 'RailsPress Team'
  plugin_url 'https://github.com/railspress/full-plugin'
  plugin_license 'MIT'
  
  # Default settings
  def self.default_settings
    {
      'feature_enabled' => true,
      'api_key' => '',
      'max_items' => 10
    }
  end
  
  # Activation
  def activate
    super
    
    Rails.logger.info "Activating #{plugin_name}..."
    
    register_hooks
    register_filters
    register_shortcodes
    inject_helpers
    schedule_background_jobs
    
    create_default_settings
    run_migrations if needs_migration?
    
    Rails.logger.info "#{plugin_name} activated successfully"
  end
  
  # Deactivation
  def deactivate
    super
    
    Rails.logger.info "Deactivating #{plugin_name}..."
    
    cancel_background_jobs
    cleanup_temporary_data
    
    Rails.logger.info "#{plugin_name} deactivated"
  end
  
  private
  
  def register_hooks
    add_action('post_published', :on_post_published)
    add_action('comment_created', :on_comment_created)
  end
  
  def register_filters
    add_filter('post_content', :enhance_content)
    add_filter('meta_description', :optimize_meta)
  end
  
  def register_shortcodes
    register_shortcode('my_feature') do |attrs, content|
      process_shortcode(attrs, content)
    end
  end
  
  def inject_helpers
    ApplicationController.helper(FullPluginHelper) if defined?(ApplicationController)
  end
  
  def schedule_background_jobs
    if defined?(Sidekiq::Cron)
      Sidekiq::Cron::Job.create(
        name: "#{plugin_name} - Sync",
        cron: '0 */6 * * *',
        class: 'FullPluginSyncJob'
      )
    end
  end
  
  def cancel_background_jobs
    Sidekiq::Cron::Job.destroy("#{plugin_name} - Sync") if defined?(Sidekiq::Cron)
  end
  
  # Hook callbacks
  def on_post_published(post_id)
    # Handle post publication
  end
  
  # Filter callbacks
  def enhance_content(content)
    return content unless setting_enabled?('feature_enabled')
    # Enhance and return content
    content
  end
  
  # Public API
  def self.process_data(data)
    # Public method callable from anywhere
  end
end

# Helper module
module FullPluginHelper
  def full_plugin_method
    # Helper method
  end
end

# Initialize
FullPlugin.new
```

## Plugin Categories

### 1. Content Enhancement
**Examples**: Related Posts, Reading Time, Table of Contents
**Pattern**: Filters on content, add metadata

### 2. SEO & Marketing
**Examples**: Sitemap Generator, SEO Optimizer, Social Sharing
**Pattern**: Generate files, modify meta tags

### 3. Security & Spam
**Examples**: Spam Protection, CAPTCHA, Rate Limiting
**Pattern**: Validate input, block malicious content

### 4. Media & Assets
**Examples**: Image Optimizer, CDN Integration, Lazy Loading
**Pattern**: Process files, modify URLs

### 5. Notifications & Alerts
**Examples**: Email Notifications, Webhooks, Push Notifications
**Pattern**: Listen to events, send notifications

### 6. Analytics & Tracking
**Examples**: Page Views, Event Tracking, Heatmaps
**Pattern**: Track events, store analytics

### 7. Admin Enhancements
**Examples**: Bulk Actions, Quick Edit, Dashboard Widgets
**Pattern**: Extend admin UI, add features

### 8. API & Integrations
**Examples**: Third-party syncs, External APIs
**Pattern**: Background jobs, API calls

## Plugin Hooks Reference

### Content Lifecycle

```ruby
# Posts
'post_created'        # (post_id)
'post_updated'        # (post_id)
'post_published'      # (post_id)
'post_deleted'        # (post_id)
'post_viewed'         # (post_id)

# Pages
'page_created'        # (page_id)
'page_updated'        # (page_id)
'page_published'      # (page_id)
'page_deleted'        # (page_id)

# Comments
'comment_created'     # (comment_id)
'comment_approved'    # (comment_id)
'comment_marked_spam' # (comment)

# Media
'media_uploaded'      # (medium_id)
'media_deleted'       # (medium_id)
```

### System Hooks

```ruby
'application_boot'    # ()
'cache_cleared'       # ()
'theme_activated'     # (theme_id)
'plugin_activated'    # (plugin_name)
```

## Filter Reference

### Content Filters

```ruby
'post_content'        # (content, post) → modified content
'post_title'          # (title, post) → modified title
'post_excerpt'        # (excerpt, post) → modified excerpt
'page_content'        # (content, page) → modified content
'comment_content'     # (content, comment) → modified content
```

### Meta Filters

```ruby
'meta_description'    # (description, object) → modified meta
'meta_keywords'       # (keywords, object) → modified keywords
'canonical_url'       # (url, object) → modified URL
'og_image'            # (image_url, object) → modified image
```

### Query Filters

```ruby
'posts_query'         # (relation) → modified ActiveRecord relation
'search_results'      # (results, query) → modified results
'related_posts'       # (posts, current_post) → modified posts
```

## Best Practices

### 1. Always Call Super

```ruby
def activate
  super # REQUIRED - initializes parent class
  # Your code here
end

def deactivate
  super # REQUIRED - cleans up parent class
  # Your code here
end
```

### 2. Handle Errors Gracefully

```ruby
def process_data(data)
  # Your logic
rescue => e
  Rails.logger.error "#{plugin_name} error: #{e.message}"
  nil # Return safe default
end
```

### 3. Use Settings for Configuration

```ruby
# DON'T hard-code
API_KEY = 'hardcoded123'

# DO use settings
api_key = get_setting('api_key', '')
```

### 4. Validate Inputs

```ruby
def on_comment_created(comment_id)
  comment = Comment.find_by(id: comment_id)
  return unless comment # Validate exists
  
  # Process comment
end
```

### 5. Use Background Jobs for Heavy Work

```ruby
def on_post_published(post_id)
  # DON'T block the request
  # process_heavy_task(post_id)
  
  # DO use background job
  HeavyTaskJob.perform_later(post_id)
end
```

## Testing Plugins

### RSpec Example

```ruby
# spec/plugins/your_plugin_spec.rb
require 'rails_helper'

RSpec.describe YourPlugin do
  subject(:plugin) { described_class.new }
  
  describe 'metadata' do
    it { expect(plugin.plugin_name).to eq('Your Plugin') }
    it { expect(plugin.plugin_version).to match(/\d+\.\d+\.\d+/) }
  end
  
  describe '#activate' do
    it 'registers hooks' do
      expect { plugin.activate }.not_to raise_error
    end
    
    it 'sets up correctly' do
      plugin.activate
      expect(plugin.active?).to be true
    end
  end
  
  describe 'functionality' do
    before { plugin.activate }
    after { plugin.deactivate }
    
    it 'processes data correctly' do
      result = plugin.process_something('input')
      expect(result).to eq('expected_output')
    end
  end
end
```

## Plugin Loader

Located: `config/initializers/plugin_system.rb`

**Loading Process:**
1. Initialize PluginSystem
2. Find active plugins in database
3. Load plugin files from `lib/plugins/*/`
4. Execute plugin initialization
5. Call `activate` on active plugins

**Load Order:**
Plugins load in alphabetical order by directory name.

## Security Considerations

### 1. Input Sanitization

```ruby
def process_user_input(input)
  sanitized = ActionController::Base.helpers.sanitize(input)
  # Process sanitized input
end
```

### 2. XSS Prevention

```ruby
def generate_html(content)
  ERB::Util.html_escape(content)
end
```

### 3. SQL Injection Prevention

```ruby
# DON'T
Post.where("title = '#{user_input}'")

# DO
Post.where(title: user_input)
```

### 4. Rate Limiting

```ruby
def api_call
  return if rate_limited?
  # Make API call
end

def rate_limited?
  # Check rate limit
end
```

## Performance Tips

### 1. Cache Expensive Operations

```ruby
def expensive_calculation(id)
  Rails.cache.fetch("plugin:calc:#{id}", expires_in: 1.hour) do
    # Expensive operation
  end
end
```

### 2. Eager Load Associations

```ruby
# DON'T (N+1 query)
posts.each { |post| post.user.name }

# DO
posts.includes(:user).each { |post| post.user.name }
```

### 3. Batch Process

```ruby
Post.find_in_batches(batch_size: 100) do |batch|
  batch.each { |post| process(post) }
end
```

## Installed Plugins

### Current Plugin Inventory

1. **SEO Optimizer Pro** - Complete SEO solution
2. **Sitemap Generator** - XML sitemap generation
3. **Related Posts** - Find related content
4. **Reading Time** - Calculate reading duration
5. **Spam Protection** - Comment spam prevention
6. **Email Notifications** - Email alerts
7. **Social Sharing** - Social media integration
8. **Image Optimizer** - Image compression
9. **Advanced Shortcodes** - Extended shortcode library

All plugins follow the standardized architecture defined in this document.

## Creating a New Plugin

### Quick Start

```bash
# 1. Create plugin directory
mkdir -p lib/plugins/my_plugin

# 2. Copy template
cp lib/plugins/PLUGIN_TEMPLATE.rb lib/plugins/my_plugin/my_plugin.rb

# 3. Edit plugin file
# Update class name, metadata, and logic

# 4. Create database entry
rails runner "
Plugin.create!(
  name: 'My Plugin',
  description: 'Does something cool',
  version: '1.0.0',
  active: false
)
"

# 5. Activate via admin or console
rails runner "
plugin = Plugin.find_by(name: 'My Plugin')
plugin.update!(active: true)
"
```

### Testing Your Plugin

```bash
# Run plugin specs
bundle exec rspec lib/plugins/my_plugin/spec/

# Test in console
rails console
> plugin = MyPlugin.new
> plugin.activate
> # Test functionality
> plugin.deactivate
```

## Plugin Distribution

### Packaging for Release

1. Create README.md with usage instructions
2. Add LICENSE file
3. Include CHANGELOG.md
4. Write comprehensive tests
5. Add example configuration
6. Create screenshots/demos

### Submission Checklist

- [ ] Follows PluginBase architecture
- [ ] Calls `super` in lifecycle methods
- [ ] Has tests (>80% coverage)
- [ ] Documented with README
- [ ] No security vulnerabilities
- [ ] No performance issues
- [ ] Compatible with multi-tenancy
- [ ] Works with theme system
- [ ] Handles errors gracefully
- [ ] Logs important events

## Plugin Registry (Future)

Coming soon: Central registry for community plugins
- Browse and install plugins
- Automatic updates
- Rating and reviews
- Security audits
- Compatibility tracking

## Migration Guide

### From WordPress Plugins

WordPress plugins can be adapted to RailsPress:

| WordPress | RailsPress |
|-----------|------------|
| `add_action()` | `add_action()` ✅ Same API |
| `add_filter()` | `add_filter()` ✅ Same API |
| `add_shortcode()` | `register_shortcode()` |
| `register_activation_hook()` | `activate()` method |
| `get_option()` | `get_setting()` |
| `update_option()` | `set_setting()` |

### Key Differences

1. **Class-based** instead of procedural
2. **Inherits from PluginBase** for common functionality  
3. **Active** Record for database
4. **Background jobs** with Sidekiq instead of WP-Cron
5. **Assets** in plugin directory, served by Rails

## Dynamic Plugin Routes

**NEW**: Plugins can now register their own routes without modifying `config/routes.rb`!

### How It Works

```ruby
class MyPlugin < Railspress::PluginBase
  def activate
    super
    register_plugin_routes
  end
  
  private
  
  def register_plugin_routes
    register_routes do
      # Public routes
      get '/my-plugin', to: 'my_plugin#index'
      
      # Admin routes
      namespace :admin do
        resources :my_plugin
      end
    end
  end
end
```

### Benefits

- ✅ **No route conflicts** - Your routes.rb stays untouched
- ✅ **Self-contained** - Routes defined in plugin
- ✅ **Auto-cleanup** - Routes removed when plugin deactivated
- ✅ **Version control friendly** - No core file modifications

### Best Practices

1. **Namespace your routes** - Use `/my-plugin/*` pattern
2. **Use admin namespace** - Keep admin routes organized
3. **Document routes** - List all routes in plugin README
4. **Test routes** - Write route specs

See `docs/plugins/DYNAMIC_ROUTES.md` for complete documentation.

## Troubleshooting

### Plugin Not Loading

1. Check plugin file name matches directory
2. Verify plugin is in database (`Plugin.find_by(name: '...')`)
3. Check `active` is true
4. Look for errors in logs
5. Verify class inherits from `Railspress::PluginBase`

### Hooks Not Firing

1. Check hook name spelling
2. Verify plugin is activated
3. Confirm hook is being triggered (add logging)
4. Check method visibility (should be private or public)

### Settings Not Saving

1. Check plugin is in database
2. Verify settings column exists
3. Check JSON serialization
4. Look for validation errors

## Support & Resources

- **Template**: `lib/plugins/PLUGIN_TEMPLATE.rb`
- **Examples**: `lib/plugins/*/`
- **Base Class**: `lib/railspress/plugin_base.rb`
- **System**: `lib/railspress/plugin_system.rb`
- **Guide**: `lib/plugins/README.md`

---

**Build powerful plugins for RailsPress!** 🔌

Extend your CMS with custom functionality while maintaining consistency and quality.



