# RailsPress CLI Generators Guide

Complete guide for generating plugins and themes using `railspress-cli`.

---

## Table of Contents

1. [Overview](#overview)
2. [Theme Generator](#theme-generator)
3. [Plugin Generator](#plugin-generator)
4. [Examples](#examples)
5. [Best Practices](#best-practices)
6. [Troubleshooting](#troubleshooting)

---

## Overview

The RailsPress CLI includes powerful generators to scaffold new themes and plugins with all the boilerplate code you need to get started quickly.

### Benefits

- ✅ **Fast Setup** - Generate complete themes/plugins in seconds
- ✅ **Best Practices** - Follow Rails and RailsPress conventions
- ✅ **Customizable** - Multiple options for different use cases
- ✅ **Production Ready** - Generated code is clean and documented
- ✅ **Modern Stack** - Tailwind CSS, Stimulus, Turbo ready

---

## Theme Generator

### Basic Usage

```bash
./bin/railspress-cli theme:generate <name> [options]
```

### Options

| Option | Description | Example |
|--------|-------------|---------|
| `--description` | Theme description | `--description="My custom theme"` |
| `--author` | Author name | `--author="John Doe"` |
| `--version` | Version number | `--version="2.0.0"` |
| `--with-dark-mode` | Include dark mode support | `--with-dark-mode` |

### Generated Structure

```
app/themes/your_theme/
├── views/
│   ├── layouts/
│   │   └── application.html.erb      # Main layout
│   ├── shared/
│   │   ├── _header.html.erb          # Header partial
│   │   └── _footer.html.erb          # Footer partial
│   ├── posts/                        # Post templates (optional)
│   └── pages/                        # Page templates (optional)
├── assets/
│   ├── stylesheets/
│   │   └── custom.css                # Custom styles
│   ├── javascripts/                  # JavaScript files
│   └── images/                       # Theme images
├── theme.json                        # Theme metadata
└── README.md                         # Documentation
```

### theme.json

```json
{
  "name": "Your Theme",
  "slug": "your_theme",
  "version": "1.0.0",
  "description": "A custom RailsPress theme",
  "author": "Your Name",
  "license": "MIT",
  "supports": {
    "customizer": true,
    "dark_mode": false,
    "responsive": true
  },
  "settings": {
    "colors": {
      "primary": "#3B82F6",
      "secondary": "#8B5CF6"
    },
    "typography": {
      "heading_font": "Inter",
      "body_font": "Inter"
    }
  }
}
```

### Generated Layout Features

**application.html.erb includes:**
- Responsive meta tags
- CSRF protection
- CSP headers
- Tailwind CSS integration
- JavaScript import maps
- Analytics tracker integration
- Pixel tracking integration
- Custom CSS variables
- Dark mode support (if enabled)

**Header partial includes:**
- Logo/site title
- Navigation menu
- Responsive design
- Tailwind styling

**Footer partial includes:**
- Multi-column layout
- Quick links
- Newsletter signup form
- Copyright info
- Social links (optional)

### Example Commands

**Basic theme:**
```bash
./bin/railspress-cli theme:generate mybrand
```

**Theme with all options:**
```bash
./bin/railspress-cli theme:generate mybrand \
  --description="My Brand Theme" \
  --author="John Doe" \
  --version="1.0.0" \
  --with-dark-mode
```

**Professional theme:**
```bash
./bin/railspress-cli theme:generate corporate \
  --description="Corporate Business Theme" \
  --author="Acme Corp" \
  --with-dark-mode
```

### After Generation

1. **Review generated files:**
   ```bash
   cd app/themes/your_theme
   cat README.md
   ```

2. **Customize the theme:**
   - Edit views/layouts/application.html.erb
   - Modify views/shared/_header.html.erb
   - Update assets/stylesheets/custom.css
   - Adjust theme.json settings

3. **Activate the theme:**
   ```bash
   ./bin/railspress-cli theme:activate your_theme
   ```

4. **Visit your site:**
   Open http://localhost:3000 to see your new theme!

---

## Plugin Generator

### Basic Usage

```bash
./bin/railspress-cli plugin:generate <name> [options]
```

### Options

| Option | Description | Example |
|--------|-------------|---------|
| `--description` | Plugin description | `--description="SEO optimizer"` |
| `--author` | Author name | `--author="John Doe"` |
| `--version` | Version number | `--version="1.0.0"` |
| `--with-settings` | Include settings page | `--with-settings` |
| `--with-blocks` | Include block support | `--with-blocks` |
| `--with-hooks` | Include hooks/filters | `--with-hooks` |

### Generated Structure

**Basic plugin:**
```
lib/plugins/your_plugin/
├── your_plugin.rb              # Main plugin file
├── README.md                    # Documentation
└── migration_template.rb        # Database template
```

**Plugin with settings:**
```
lib/plugins/your_plugin/
├── your_plugin.rb
├── views/
│   └── settings.html.erb        # Settings page
├── README.md
└── migration_template.rb
```

**Plugin with blocks:**
```
lib/plugins/your_plugin/
├── your_plugin.rb
├── views/
│   └── _sidebar_block.html.erb  # Block partial
├── assets/
│   ├── javascripts/
│   │   └── your_plugin.js       # Plugin JS
│   └── stylesheets/
│       └── your_plugin.css      # Plugin CSS
├── README.md
└── migration_template.rb
```

### Generated Plugin File

```ruby
# frozen_string_literal: true

# Your Plugin
# A custom RailsPress plugin
# Version: 1.0.0
# Author: Your Name

module Plugins
  class YourPlugin < Railspress::PluginBase
    def initialize
      super
      
      @name = 'Your Plugin'
      @slug = 'your_plugin'
      @version = '1.0.0'
      @description = 'A custom RailsPress plugin'
      @author = 'Your Name'
      
      # Initialize plugin
      setup_hooks if enabled?
    end
    
    def enabled?
      # Check if plugin should be active
      plugin_record = Plugin.find_by(slug: @slug)
      plugin_record&.active? || false
    end
    
    private
    
    def setup_hooks
      # Register activation/deactivation hooks
      on_activation { activate_plugin }
      on_deactivation { deactivate_plugin }
      
      # Add your hooks here
    end
    
    def activate_plugin
      Rails.logger.info "Activating #{@name}..."
      # Your activation code
      Rails.logger.info "#{@name} activated successfully!"
    end
    
    def deactivate_plugin
      Rails.logger.info "Deactivating #{@name}..."
      # Your deactivation code
      Rails.logger.info "#{@name} deactivated successfully!"
    end
  end
end

# Register plugin
Plugins::YourPlugin.new
```

### With Hooks (--with-hooks)

Adds WordPress-style action hooks and filters:

```ruby
def register_hooks
  # Add action hooks
  Railspress::Hooks.add_action('init', method(:init_plugin))
  Railspress::Hooks.add_action('post_published', method(:on_post_published))
end

def register_filters
  # Add filter hooks
  Railspress::Hooks.add_filter('post_content', method(:modify_content))
end

def init_plugin
  Rails.logger.info "#{@name} initialized!"
end

def on_post_published(post)
  # Called when a post is published
end

def modify_content(content)
  # Modify post content before display
  content
end
```

### With Blocks (--with-blocks)

Adds Shopify-style editor blocks:

```ruby
def register_ui_blocks
  # Register blocks for post/page editor
  register_block :your_plugin_sidebar, {
    location: :post,
    position: :sidebar,
    partial: 'plugins/your_plugin/_sidebar_block',
    can_render: ->(record, user) { user.administrator? || user.editor? }
  }
  
  register_block :your_plugin_toolbar, {
    location: :post,
    position: :toolbar,
    partial: 'plugins/your_plugin/_toolbar_block'
  }
end
```

**Generated block view (_sidebar_block.html.erb):**
```erb
<div class="plugin-block bg-white border border-gray-200 rounded-lg p-4 mb-4">
  <h4 class="font-semibold text-gray-900 mb-2">Your Plugin</h4>
  <p class="text-sm text-gray-600 mb-3">
    A custom RailsPress plugin
  </p>
  
  <!-- Add your block UI here -->
  <button class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition">
    Action Button
  </button>
</div>
```

### With Settings (--with-settings)

Adds declarative settings schema:

```ruby
def register_settings
  # Define plugin settings schema
  define_settings_schema do
    section 'general', 'General Settings' do
      field 'enabled', 'boolean', 'Enable Your Plugin', default: true
      field 'api_key', 'string', 'API Key', placeholder: 'Enter your API key'
    end
    
    section 'advanced', 'Advanced Options' do
      field 'timeout', 'number', 'Timeout (seconds)', default: 30
      field 'mode', 'select', 'Operating Mode', 
        options: ['development', 'production'],
        default: 'production'
    end
  end
end

# Settings page route
def settings_path
  '/admin/plugins/your_plugin/settings'
end
```

**Generated settings view:**
```erb
<div class="max-w-4xl mx-auto">
  <h2 class="text-2xl font-bold text-white mb-6">Your Plugin Settings</h2>
  
  <div class="bg-[#111111] border border-[#2a2a2a] rounded-xl p-6">
    <%= form_with url: update_plugin_settings_path('your_plugin'), method: :post do |f| %>
      <div>
        <label class="block text-sm font-medium text-gray-300 mb-2">
          Enable Your Plugin
        </label>
        <%= check_box_tag 'settings[enabled]', '1', true, class: "rounded" %>
      </div>
      
      <div>
        <label class="block text-sm font-medium text-gray-300 mb-2">
          API Key
        </label>
        <%= text_field_tag 'settings[api_key]', '', class: "w-full px-4 py-2 bg-[#0a0a0a] border border-[#2a2a2a] text-white rounded-lg" %>
      </div>
      
      <div class="flex justify-end">
        <%= f.submit "Save Settings", class: "px-6 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition" %>
      </div>
    <% end %>
  </div>
</div>
```

### Example Commands

**Simple plugin:**
```bash
./bin/railspress-cli plugin:generate my_feature
```

**Plugin with settings:**
```bash
./bin/railspress-cli plugin:generate seo_optimizer \
  --description="SEO optimization tools" \
  --with-settings
```

**Full-featured plugin:**
```bash
./bin/railspress-cli plugin:generate analytics \
  --description="Advanced analytics tracking" \
  --author="John Doe" \
  --with-settings \
  --with-blocks \
  --with-hooks
```

**Content modification plugin:**
```bash
./bin/railspress-cli plugin:generate content_enhancer \
  --description="Enhance post content automatically" \
  --with-hooks
```

**Editor extension plugin:**
```bash
./bin/railspress-cli plugin:generate editor_tools \
  --description="Additional tools for the editor" \
  --with-blocks
```

### After Generation

1. **Create database entry:**
   ```ruby
   # In Rails console
   Plugin.create!(
     name: 'Your Plugin',
     slug: 'your_plugin',
     version: '1.0.0',
     description: 'A custom RailsPress plugin',
     active: false
   )
   ```

2. **Review generated files:**
   ```bash
   cd lib/plugins/your_plugin
   cat README.md
   cat your_plugin.rb
   ```

3. **Customize the plugin:**
   - Edit your_plugin.rb
   - Add your logic to hooks/methods
   - Customize views if included
   - Update settings schema if needed

4. **Activate the plugin:**
   ```bash
   ./bin/railspress-cli plugin:activate your_plugin
   ```

5. **Restart Rails server:**
   ```bash
   ./railspress restart
   ```

---

## Examples

### Example 1: Blog Theme

Generate a clean blog theme:

```bash
./bin/railspress-cli theme:generate techblog \
  --description="Modern tech blog theme" \
  --author="Tech Writer" \
  --with-dark-mode
```

**Customize:**
1. Edit `app/themes/techblog/views/layouts/application.html.erb`
2. Add blog-specific styles to `assets/stylesheets/custom.css`
3. Customize header navigation
4. Add social media links to footer

**Activate:**
```bash
./bin/railspress-cli theme:activate techblog
```

### Example 2: SEO Plugin

Generate an SEO optimization plugin with settings:

```bash
./bin/railspress-cli plugin:generate seo_master \
  --description="Complete SEO optimization suite" \
  --author="SEO Expert" \
  --with-settings \
  --with-hooks
```

**Customize:**
1. Open `lib/plugins/seo_master/seo_master.rb`
2. Add SEO analysis logic to hooks
3. Configure settings schema for:
   - Meta description templates
   - Social media settings
   - Sitemap options
4. Create settings view with fields

**Database & Activate:**
```ruby
Plugin.create!(name: 'SEO Master', slug: 'seo_master', version: '1.0.0', description: 'Complete SEO optimization suite', active: false)
```

```bash
./bin/railspress-cli plugin:activate seo_master
```

### Example 3: Content Block Plugin

Generate a plugin that adds custom blocks to the editor:

```bash
./bin/railspress-cli plugin:generate custom_blocks \
  --description="Add custom content blocks to editor" \
  --with-blocks
```

**Customize:**
1. Open `lib/plugins/custom_blocks/custom_blocks.rb`
2. Add more block registrations:
   ```ruby
   register_block :callout_box, { ... }
   register_block :stats_counter, { ... }
   register_block :testimonial, { ... }
   ```
3. Create views for each block
4. Add JavaScript for interactive blocks
5. Style blocks with CSS

**Activate:**
```ruby
Plugin.create!(name: 'Custom Blocks', slug: 'custom_blocks', version: '1.0.0', active: false)
```

```bash
./bin/railspress-cli plugin:activate custom_blocks
```

### Example 4: E-commerce Theme

Generate an e-commerce ready theme:

```bash
./bin/railspress-cli theme:generate shopfront \
  --description="E-commerce theme with product showcase" \
  --author="Store Owner" \
  --with-dark-mode
```

**Customize:**
1. Add product grid layouts
2. Create product detail templates
3. Add cart UI components
4. Style checkout pages
5. Add product filtering

**Activate:**
```bash
./bin/railspress-cli theme:activate shopfront
```

### Example 5: Social Sharing Plugin

Generate a social sharing plugin:

```bash
./bin/railspress-cli plugin:generate social_share \
  --description="Add social sharing buttons to posts" \
  --with-settings \
  --with-hooks
```

**Customize:**
1. Add sharing button logic
2. Configure which platforms to support
3. Add tracking for shares
4. Style sharing buttons
5. Add settings for button placement

---

## Best Practices

### Theme Development

**1. Follow naming conventions:**
```bash
# Good names
./bin/railspress-cli theme:generate corporate_blue
./bin/railspress-cli theme:generate minimalist_2024

# Avoid
./bin/railspress-cli theme:generate "My Theme!" # Special chars
```

**2. Use semantic versioning:**
```bash
./bin/railspress-cli theme:generate mytheme --version="1.0.0"  # Initial
# After bug fix: 1.0.1
# After feature: 1.1.0
# After breaking change: 2.0.0
```

**3. Document customizations:**
- Update README.md with changes
- Comment complex CSS/JS
- Document template variables

**4. Test responsive design:**
- Mobile (375px)
- Tablet (768px)
- Desktop (1024px+)

**5. Optimize assets:**
- Minimize CSS/JS
- Compress images
- Use CSS variables for theming

### Plugin Development

**1. Use descriptive slugs:**
```bash
# Good
./bin/railspress-cli plugin:generate image_optimizer
./bin/railspress-cli plugin:generate email_validator

# Less clear
./bin/railspress-cli plugin:generate plugin1
```

**2. Choose the right options:**

Use `--with-settings` when:
- Plugin needs configuration
- Users should customize behavior
- API keys required

Use `--with-blocks` when:
- Adding editor functionality
- Creating custom UI elements
- Need sidebar/toolbar integration

Use `--with-hooks` when:
- Modifying core behavior
- Listening to events
- Filtering content

**3. Handle activation/deactivation:**
```ruby
def activate_plugin
  # Create tables
  # Set default settings
  # Schedule background jobs
  # Send activation notification
end

def deactivate_plugin
  # Keep data (don't delete)
  # Stop background jobs
  # Clean up temporary files
end
```

**4. Error handling:**
```ruby
def some_method
  # Do something
rescue => e
  Rails.logger.error "Plugin error: #{e.message}"
  # Graceful fallback
end
```

**5. Performance considerations:**
- Cache expensive operations
- Use background jobs for slow tasks
- Lazy load assets
- Database indexes

---

## Troubleshooting

### Theme Issues

**Theme not showing:**
1. Check if activated:
   ```bash
   ./bin/railspress-cli theme:status
   ```
2. Verify files exist:
   ```bash
   ls app/themes/your_theme
   ```
3. Check for syntax errors in ERB files
4. Restart Rails server

**Styling not working:**
1. Ensure custom.css is linked
2. Check CSS file for syntax errors
3. Clear browser cache
4. Inspect with dev tools

**Layout breaks:**
1. Validate HTML structure
2. Check for missing end tags
3. Review Tailwind class names
4. Test without custom CSS

### Plugin Issues

**Plugin not loading:**
1. Check database entry exists:
   ```ruby
   Plugin.find_by(slug: 'your_plugin')
   ```
2. Verify plugin file syntax:
   ```bash
   ruby -c lib/plugins/your_plugin/your_plugin.rb
   ```
3. Check Rails logs for errors
4. Restart server after changes

**Hooks not firing:**
1. Ensure plugin is activated
2. Check hook names match exactly
3. Verify hook is registered in `setup_hooks`
4. Add debug logging:
   ```ruby
   Rails.logger.info "Hook fired: #{method_name}"
   ```

**Settings not saving:**
1. Check form `action` URL
2. Verify CSRF token present
3. Review controller logic
4. Check database permissions

**Blocks not appearing:**
1. Verify block registration
2. Check `can_render` condition
3. Ensure partial path is correct
4. Test with different user roles

### CLI Issues

**Permission denied:**
```bash
chmod +x bin/railspress-cli
```

**Command not found:**
```bash
# Use ./bin/railspress-cli instead of railspress-cli
./bin/railspress-cli theme:list
```

**Rails not booting:**
```bash
# Check Ruby version
ruby -v

# Install dependencies
bundle install

# Check database
rails db:migrate
```

---

## Advanced Usage

### Custom Theme Templates

After generating, add custom templates:

```bash
# Generate theme
./bin/railspress-cli theme:generate myblog

# Add custom templates
cd app/themes/myblog/views/
mkdir posts pages

# Create custom post template
cat > posts/show.html.erb << 'EOF'
<article class="max-w-4xl mx-auto">
  <h1><%= @post.title %></h1>
  <div class="prose">
    <%= @post.content %>
  </div>
</article>
EOF
```

### Plugin with Database Tables

After generating plugin with database needs:

```bash
# Generate plugin
./bin/railspress-cli plugin:generate analytics

# Create migration from template
cd lib/plugins/analytics
cat migration_template.rb

# Generate actual migration
rails generate migration CreateAnalyticsTables

# Edit migration
# db/migrate/xxx_create_analytics_tables.rb

# Run migration
rails db:migrate
```

### Multi-Plugin Architecture

Create a suite of related plugins:

```bash
# Core plugin
./bin/railspress-cli plugin:generate ecommerce_core \
  --with-settings --with-hooks

# Payment plugin (depends on core)
./bin/railspress-cli plugin:generate ecommerce_payments \
  --with-settings

# Shipping plugin
./bin/railspress-cli plugin:generate ecommerce_shipping \
  --with-settings

# Analytics plugin
./bin/railspress-cli plugin:generate ecommerce_analytics \
  --with-blocks --with-hooks
```

---

## Quick Reference

### Theme Commands

```bash
# Generate
./bin/railspress-cli theme:generate <name> [options]

# List
./bin/railspress-cli theme:list

# Activate
./bin/railspress-cli theme:activate <name>

# Status
./bin/railspress-cli theme:status

# Delete
./bin/railspress-cli theme:delete <name>
```

### Plugin Commands

```bash
# Generate
./bin/railspress-cli plugin:generate <name> [options]

# List
./bin/railspress-cli plugin:list

# Activate
./bin/railspress-cli plugin:activate <name>

# Deactivate
./bin/railspress-cli plugin:deactivate <name>

# Delete
./bin/railspress-cli plugin:delete <name>
```

### Common Options

```bash
--description="Your description"
--author="Your Name"
--version="1.0.0"

# Theme specific
--with-dark-mode

# Plugin specific
--with-settings
--with-blocks
--with-hooks
```

---

## Resources

- **RailsPress Documentation**: Main README.md
- **Theme Development**: THEME_SYSTEM_GUIDE.md
- **Plugin Development**: PLUGIN_ARCHITECTURE.md
- **Plugin Blocks**: PLUGIN_BLOCKS_GUIDE.md
- **CLI Reference**: RAILSPRESS_CLI_SUMMARY.md

---

## Support

For issues or questions:
1. Check the generated README.md files
2. Review existing themes/plugins for examples
3. Check Rails logs for errors
4. Open an issue on GitHub

---

**Status**: ✅ Production Ready  
**Version**: 1.0.0  
**Last Updated**: October 12, 2025



