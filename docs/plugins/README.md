# RailsPress Plugin Development Guide

## Plugin Architecture Standard

All RailsPress plugins must follow this standardized architecture for consistency, maintainability, and discoverability.

## Directory Structure

```
lib/plugins/
└── your_plugin/
    ├── your_plugin.rb          # Main plugin file (required)
    ├── README.md               # Plugin documentation (recommended)
    ├── config.yml              # Plugin configuration (optional)
    ├── assets/                 # Plugin assets (optional)
    │   ├── javascripts/
    │   ├── stylesheets/
    │   └── images/
    ├── views/                  # Plugin views (optional)
    │   └── partials/
    ├── helpers/                # Plugin helpers (optional)
    │   └── your_plugin_helper.rb
    └── spec/                   # Plugin tests (recommended)
        └── your_plugin_spec.rb
```

## Plugin Class Structure

### Required Components

```ruby
class YourPlugin < Railspress::PluginBase
  # 1. Metadata (REQUIRED)
  plugin_name 'Your Plugin Name'
  plugin_version '1.0.0'
  plugin_description 'Brief description'
  plugin_author 'Your Name'
  
  # 2. Activation (REQUIRED)
  def activate
    super # Always call super first!
    # Your activation logic
  end
  
  # 3. Deactivation (REQUIRED)
  def deactivate
    super # Always call super first!
    # Your cleanup logic
  end
end

# 4. Initialize (REQUIRED)
YourPlugin.new
```

### Optional Components

```ruby
  # Optional metadata
  plugin_url 'https://github.com/user/plugin'
  plugin_license 'MIT'
  plugin_requires '7.1.0' # Minimum Rails version
  
  # Default settings
  def self.default_settings
    {
      'enabled' => true,
      'option_1' => 'value'
    }
  end
  
  # Settings page (if plugin has settings)
  def settings_form_fields
    [
      { name: 'option_1', type: 'text', label: 'Option 1', default: 'value' },
      { name: 'option_2', type: 'boolean', label: 'Enable Feature', default: true }
    ]
  end
```

## Plugin Lifecycle

### 1. Activation

```ruby
def activate
  super # ALWAYS call super first
  
  Rails.logger.info "#{plugin_name} v#{plugin_version} activated"
  
  # Register hooks and filters
  register_hooks
  register_filters
  register_shortcodes
  
  # Inject helpers
  inject_helpers
  
  # One-time setup
  create_default_settings
  run_migrations if respond_to?(:run_migrations)
  
  # Background jobs
  schedule_jobs if respond_to?(:schedule_jobs)
end
```

### 2. Deactivation

```ruby
def deactivate
  super # ALWAYS call super first
  
  Rails.logger.info "#{plugin_name} deactivated"
  
  # Cleanup (usually handled by parent)
  unregister_all_hooks
  unregister_all_shortcodes
  cancel_scheduled_jobs if respond_to?(:cancel_scheduled_jobs)
end
```

## Hooks & Filters

### Available Action Hooks

```ruby
# Content hooks
add_action('post_created', :on_post_created)
add_action('post_updated', :on_post_updated)
add_action('post_published', :on_post_published)
add_action('post_deleted', :on_post_deleted)

add_action('page_created', :on_page_created)
add_action('page_updated', :on_page_updated)
add_action('page_published', :on_page_published)

add_action('comment_created', :on_comment_created)
add_action('comment_approved', :on_comment_approved)

add_action('media_uploaded', :on_media_uploaded)

# User hooks
add_action('user_created', :on_user_created)
add_action('user_login', :on_user_login)

# System hooks
add_action('application_boot', :on_boot)
add_action('cache_cleared', :on_cache_cleared)
```

### Available Filters

```ruby
# Content filters
add_filter('post_content', :modify_content)
add_filter('post_title', :modify_title)
add_filter('post_excerpt', :modify_excerpt)

add_filter('page_content', :modify_page_content)
add_filter('page_title', :modify_page_title)

# Meta filters
add_filter('meta_description', :modify_meta)
add_filter('meta_keywords', :modify_keywords)

# SEO filters
add_filter('canonical_url', :modify_canonical)
add_filter('robots_meta', :modify_robots)
```

## Shortcode Registration

```ruby
def register_shortcodes
  # Simple shortcode
  register_shortcode('my_shortcode') do |attrs|
    value = attrs[:value] || 'default'
    "<div class='my-shortcode'>#{value}</div>"
  end
  
  # Shortcode with content
  register_shortcode('wrapper') do |attrs, content|
    style = attrs[:style] || 'default'
    "<div class='wrapper-#{style}'>#{content}</div>"
  end
  
  # Shortcode with context
  register_shortcode('user_info') do |attrs, content, context|
    user = context[:current_user]
    user ? "<p>Hello, #{user.email}</p>" : "<p>Guest</p>"
  end
end

def cleanup_shortcodes
  unregister_shortcode('my_shortcode')
  unregister_shortcode('wrapper')
  unregister_shortcode('user_info')
end
```

## Helper Injection

```ruby
# Define helper module
module YourPluginHelper
  def your_helper_method(arg)
    # Your helper logic
  end
  
  def another_helper
    # Another helper
  end
end

# Inject into ApplicationController
def inject_helpers
  if defined?(ApplicationController)
    ApplicationController.helper(YourPluginHelper)
    ApplicationController.helper_method :your_helper_method
  end
end
```

## Settings Management

```ruby
# Get setting
value = get_setting('option_name', 'default_value')

# Set setting
set_setting('option_name', 'new_value')

# Check if enabled
if setting_enabled?('feature_name')
  # Feature is enabled
end

# Get all settings
all_settings = settings
```

## Background Jobs

```ruby
# Schedule recurring job
def schedule_jobs
  if defined?(Sidekiq)
    Sidekiq::Cron::Job.create(
      name: "#{plugin_name} - Daily Task",
      cron: '0 0 * * *', # Daily at midnight
      class: 'YourPluginJob'
    )
  end
end

# Cancel on deactivation
def cancel_scheduled_jobs
  if defined?(Sidekiq)
    Sidekiq::Cron::Job.destroy("#{plugin_name} - Daily Task")
  end
end
```

## Database Migrations

```ruby
# If your plugin needs database tables
def run_migrations
  migration_path = File.join(File.dirname(__FILE__), 'db/migrate')
  ActiveRecord::MigrationContext.new(migration_path).migrate
end
```

## Testing

### Plugin Spec Structure

```ruby
# spec/plugins/your_plugin_spec.rb
require 'rails_helper'

RSpec.describe YourPlugin, type: :plugin do
  let(:plugin) { YourPlugin.new }
  
  describe 'metadata' do
    it 'has correct name' do
      expect(plugin.plugin_name).to eq('Your Plugin')
    end
    
    it 'has version' do
      expect(plugin.plugin_version).to be_present
    end
  end
  
  describe '#activate' do
    it 'registers hooks' do
      plugin.activate
      expect(Railspress::PluginSystem.has_action?('post_created')).to be true
    end
  end
  
  describe '#deactivate' do
    it 'unregisters hooks' do
      plugin.activate
      plugin.deactivate
      expect(Railspress::PluginSystem.has_action?('post_created')).to be false
    end
  end
  
  describe 'functionality' do
    before { plugin.activate }
    after { plugin.deactivate }
    
    it 'does what it should' do
      # Test plugin functionality
    end
  end
end
```

## Plugin Standards Checklist

### Code Quality
- [ ] Follows PluginBase architecture
- [ ] Calls `super` in activate/deactivate
- [ ] Properly namespaced
- [ ] No global state pollution
- [ ] Error handling with fallbacks
- [ ] Logging for important events

### Documentation
- [ ] README.md with usage examples
- [ ] Inline comments for complex logic
- [ ] Settings documented
- [ ] Hooks/filters documented
- [ ] Public API documented

### Testing
- [ ] RSpec tests for core functionality
- [ ] Tests for hooks/filters
- [ ] Tests for settings
- [ ] Integration tests if applicable

### Security
- [ ] Input sanitization
- [ ] XSS prevention in output
- [ ] SQL injection prevention
- [ ] Rate limiting for API calls
- [ ] Permission checks

### Performance
- [ ] Database queries optimized
- [ ] Caching where appropriate
- [ ] Lazy loading
- [ ] Background jobs for heavy tasks
- [ ] No N+1 queries

### Compatibility
- [ ] Works with multi-tenancy
- [ ] Compatible with theme system
- [ ] Doesn't conflict with core
- [ ] Graceful degradation

## Common Patterns

### Pattern 1: Content Enhancement

```ruby
def activate
  super
  add_filter('post_content', :enhance_content)
end

private

def enhance_content(content)
  # Add reading time, TOC, etc.
  enhanced = content
  enhanced = add_reading_time(enhanced)
  enhanced = add_table_of_contents(enhanced)
  enhanced
end
```

### Pattern 2: Event Tracking

```ruby
def activate
  super
  add_action('post_viewed', :track_view)
  add_action('post_shared', :track_share)
end

private

def track_view(post_id)
  increment_stat(post_id, 'views')
end

def track_share(post_id, platform)
  increment_stat(post_id, "shares_#{platform}")
end
```

### Pattern 3: Email Notifications

```ruby
def activate
  super
  add_action('comment_created', :notify_author)
end

private

def notify_author(comment_id)
  comment = Comment.find_by(id: comment_id)
  return unless comment && setting_enabled?('email_notifications')
  
  NotificationMailer.new_comment(comment).deliver_later
end
```

### Pattern 4: API Integration

```ruby
def activate
  super
  add_action('post_published', :sync_to_service)
end

private

def sync_to_service(post_id)
  return unless setting_enabled?('sync_enabled')
  
  post = Post.find_by(id: post_id)
  api_key = get_setting('api_key')
  
  SyncJob.perform_later(post.id, api_key)
rescue => e
  Rails.logger.error "Sync failed: #{e.message}"
end
```

## Publishing Your Plugin

### 1. Create README.md

```markdown
# Your Plugin Name

Brief description.

## Features

- Feature 1
- Feature 2

## Installation

Add to your RailsPress installation:
\`\`\`bash
# Copy plugin to lib/plugins/
cp -r your_plugin lib/plugins/
\`\`\`

## Usage

Activate in Admin → Plugins

## Configuration

Settings available in Admin → Plugins → Your Plugin → Settings

## License

MIT
```

### 2. Add Tests

```bash
# Run plugin tests
bundle exec rspec lib/plugins/your_plugin/spec/
```

### 3. Version Your Plugin

Follow [Semantic Versioning](https://semver.org/):
- MAJOR.MINOR.PATCH
- 1.0.0 → 1.0.1 (patch)
- 1.0.1 → 1.1.0 (minor)
- 1.1.0 → 2.0.0 (major)

### 4. Changelog

Keep a CHANGELOG.md:

```markdown
# Changelog

## [1.0.0] - 2025-01-15

### Added
- Initial release
- Feature X
- Feature Y
```

## Plugin Best Practices

### DO ✅

- Call `super` in activate/deactivate
- Validate inputs and sanitize outputs
- Use settings for configuration
- Log important events
- Handle errors gracefully
- Write tests
- Document your code
- Use semantic versioning
- Follow naming conventions

### DON'T ❌

- Modify core models directly
- Use global variables
- Hard-code values (use settings)
- Ignore errors silently
- Skip calling `super`
- Pollute global namespace
- Include untested code
- Break SemVer

## Plugin Registry (Coming Soon)

Share your plugins with the community:
- Submit to RailsPress Plugin Registry
- Include screenshots
- Provide demo/sandbox
- List dependencies
- Note compatibility

## Examples

See these built-in plugins for reference:
- `sitemap_generator` - File generation, hooks
- `related_posts` - Helper injection, filters
- `spam_protection` - Security, validation
- `email_notifications` - Mailers, background jobs
- `social_sharing` - View helpers, shortcodes
- `advanced_shortcodes` - Multiple shortcodes
- `reading_time` - Content analysis
- `image_optimizer` - File processing

## Support

- Documentation: `/docs/plugins`
- Plugin Base: `lib/railspress/plugin_base.rb`
- Examples: `lib/plugins/`
- Issues: GitHub Issues

---

**Happy Plugin Development!** 🔌

Build powerful extensions for RailsPress with this standardized architecture.




