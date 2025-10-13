# RailsPress Theme System

## Overview

The RailsPress theme system allows you to create fully customizable themes with complete control over views, assets, and behavior. Each theme is self-contained in its own directory.

## Theme Structure

```
app/themes/your_theme/
├── config.yml          # Theme configuration and metadata
├── theme.rb            # Theme initializer (optional)
├── views/              # Theme templates
│   ├── layouts/
│   │   └── application.html.erb
│   ├── shared/
│   │   ├── _header.html.erb
│   │   └── _footer.html.erb
│   ├── posts/
│   ├── pages/
│   └── home/
├── assets/             # Theme assets
│   ├── stylesheets/
│   ├── javascripts/
│   └── images/
└── helpers/            # Theme helper modules
    └── theme_helper.rb
```

## Creating a Theme

### 1. Create Theme Directory

```bash
mkdir -p app/themes/my_theme/{views,assets,helpers,config}
mkdir -p app/themes/my_theme/assets/{stylesheets,javascripts,images}
mkdir -p app/themes/my_theme/views/{layouts,shared}
```

### 2. Create config.yml

```yaml
name: "My Awesome Theme"
version: "1.0.0"
author: "Your Name"
description: "A brief description of your theme"
screenshot: "screenshot.png"

# Theme features
features:
  - responsive_design
  - dark_mode_support
  - custom_colors
  - widget_areas
  - custom_menus

# Widget areas
widget_areas:
  - id: sidebar
    name: "Main Sidebar"
    description: "Appears on blog posts and pages"
  - id: footer
    name: "Footer Widgets"
    description: "Footer widget area"

# Menu locations
menu_locations:
  - id: primary
    name: "Primary Menu"
    description: "Main navigation menu"

# Custom settings
settings:
  primary_color: "#6366f1"
  secondary_color: "#8b5cf6"
  text_color: "#1f2937"
  background_color: "#ffffff"
  posts_per_page: 10
```

### 3. Create theme.rb (Optional)

```ruby
# app/themes/my_theme/theme.rb

module Themes
  module MyTheme
    class << self
      def setup
        Rails.logger.info "Setting up My Theme..."
        register_hooks
      end

      def register_hooks
        # Add custom filters
        Railspress::PluginSystem.add_filter('post_excerpt_length', method(:custom_excerpt_length))
      end

      def custom_excerpt_length(length)
        150 # Custom excerpt length
      end

      def get_option(key, default = nil)
        config = YAML.load_file(
          Rails.root.join('app', 'themes', 'my_theme', 'config.yml')
        )
        config.dig('settings', key) || default
      end
    end
  end
end

Themes::MyTheme.setup
```

### 4. Create Layout

```erb
<!-- app/themes/my_theme/views/layouts/application.html.erb -->
<!DOCTYPE html>
<html>
  <head>
    <title><%= content_for?(:title) ? yield(:title) + " - " : "" %>Site Title</title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "application" %>
    <%= javascript_importmap_tags %>
    
    <style>
      :root {
        --primary-color: <%= theme_option('primary_color', '#6366f1') %>;
      }
    </style>
  </head>
  <body>
    <%= render 'shared/header' %>
    <%= yield %>
    <%= render 'shared/footer' %>
  </body>
</html>
```

## Theme Helpers

### Available Helper Methods

- `theme_option(key, default)` - Get theme configuration option
- `theme_name` - Get theme name
- `theme_version` - Get theme version
- `theme_supports?(feature)` - Check if theme supports a feature
- `render_widget_area(area_id)` - Render widget area
- `theme_menu(location)` - Get menu by location
- `render_theme_menu(location, options)` - Render menu

### Example Usage

```erb
<!-- In your views -->
<h1 style="color: <%= theme_option('primary_color') %>;">
  <%= theme_name %>
</h1>

<% if theme_supports?(:custom_logo) %>
  <%= render 'shared/logo' %>
<% end %>

<!-- Render widget area -->
<aside>
  <%= render_widget_area('sidebar') %>
</aside>

<!-- Render menu -->
<%= render_theme_menu('primary', class: 'main-menu') %>
```

## Theme Activation

### From Admin Panel

1. Navigate to **Admin > Themes**
2. Find your theme in the list
3. Click **Activate**

### Programmatically

```ruby
Railspress::ThemeLoader.activate_theme('my_theme')
```

## Best Practices

### 1. Follow Rails Conventions

- Use partials for reusable components
- Keep views DRY (Don't Repeat Yourself)
- Use proper ERB syntax

### 2. Make Themes Configurable

- Use `config.yml` for theme settings
- Provide sensible defaults
- Document all configuration options

### 3. Responsive Design

- Use mobile-first approach
- Test on multiple devices
- Use CSS frameworks (like Tailwind)

### 4. Performance

- Optimize images
- Minimize CSS/JS
- Use asset pipeline properly
- Lazy load when appropriate

### 5. Accessibility

- Use semantic HTML
- Include proper ARIA labels
- Ensure keyboard navigation
- Maintain color contrast

### 6. Documentation

- Document theme features
- Provide setup instructions
- Include example configurations

## Template Hierarchy

Themes follow a template hierarchy similar to WordPress:

1. Theme-specific template (`app/themes/my_theme/views/posts/show.html.erb`)
2. Default application template (`app/views/posts/show.html.erb`)

## Assets

### Stylesheets

Place CSS files in `assets/stylesheets/`:

```
app/themes/my_theme/assets/stylesheets/
├── main.css
└── components/
    ├── header.css
    └── footer.css
```

### JavaScript

Place JS files in `assets/javascripts/`:

```
app/themes/my_theme/assets/javascripts/
├── main.js
└── components/
    └── menu.js
```

### Images

Place images in `assets/images/`:

```
app/themes/my_theme/assets/images/
├── logo.png
├── background.jpg
└── screenshot.png
```

## Theme Features

### Supported Features

- `responsive_design` - Mobile-friendly design
- `dark_mode_support` - Dark mode capability
- `custom_colors` - Customizable color scheme
- `widget_areas` - Widget support
- `custom_menus` - Menu management
- `post_thumbnails` - Featured images
- `custom_header` - Custom header
- `custom_background` - Custom background
- `custom_logo` - Logo support

## Widget Areas

Define widget areas in `config.yml`:

```yaml
widget_areas:
  - id: sidebar
    name: "Main Sidebar"
    description: "Primary sidebar widget area"
  - id: footer_1
    name: "Footer Column 1"
    description: "First footer column"
```

Render in templates:

```erb
<aside class="sidebar">
  <%= render_widget_area('sidebar') %>
</aside>
```

## Menu Locations

Define menu locations in `config.yml`:

```yaml
menu_locations:
  - id: primary
    name: "Primary Menu"
    description: "Main site navigation"
  - id: footer
    name: "Footer Menu"
    description: "Footer navigation links"
```

Render in templates:

```erb
<nav>
  <%= render_theme_menu('primary') %>
</nav>
```

## Troubleshooting

### Theme Not Showing

- Check theme directory name matches database record
- Ensure `config.yml` is valid YAML
- Check Rails logs for errors
- Verify theme is activated in admin panel

### Assets Not Loading

- Ensure assets are in correct directories
- Check asset pipeline configuration
- Verify file permissions
- Clear asset cache

### Views Not Rendering

- Check view file names match Rails conventions
- Verify directory structure
- Ensure theme is activated
- Check for Ruby/ERB syntax errors

## Example Themes

- **Default Theme** - Clean, modern design
- **Dark Theme** - Sleek dark interface

Study these themes as examples when creating your own.

## Support

For issues or questions, check:
- Rails logs: `log/development.log`
- Theme loader: `lib/railspress/theme_loader.rb`
- Documentation: README.md

## License

Themes follow the same license as RailsPress.




