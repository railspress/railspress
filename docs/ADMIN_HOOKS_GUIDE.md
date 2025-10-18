# RailsPress Admin Hooks Guide

This guide documents all available hooks in the RailsPress admin interface that plugins can use to integrate their functionality.

## Overview

RailsPress provides a comprehensive hook system that allows plugins to inject content, scripts, and functionality into various parts of the admin interface. All hooks use the `Railspress::PluginSystem.do_action()` method.

## Available Admin Hooks

### 1. `admin_left_topbar_content`
**Location:** Left side of the admin topbar, before the page title
**Purpose:** Add content to the left side of the topbar
**Use Cases:** 
- Breadcrumb navigation
- Quick action buttons
- Status indicators
- Back/forward navigation

**Example:**
```ruby
add_action('admin_left_topbar_content') do
  "<div class='breadcrumb-nav text-sm text-gray-400'>
    <a href='/admin' class='hover:text-white'>Dashboard</a> > 
    <span class='text-white'>Current Page</span>
  </div>".html_safe
end
```

### 2. `admin_right_topbar_content`
**Location:** Right side of the admin topbar, before the "Go to Site" button
**Purpose:** Add content to the right side of the topbar
**Use Cases:**
- Notifications
- Quick stats
- Plugin-specific widgets
- User-specific content

**Example:**
```ruby
add_action('admin_right_topbar_content') do
  "<div class='notification-badge bg-red-500 text-white px-2 py-1 rounded-full text-xs'>
    #{unread_count}
  </div>".html_safe
end
```

### 3. `admin_sidebar_bottom`
**Location:** Bottom of the admin sidebar navigation
**Purpose:** Add navigation items to the sidebar
**Use Cases:**
- Plugin-specific menu items
- Custom admin pages
- External links
- Plugin settings shortcuts

**Example:**
```ruby
add_action('admin_sidebar_bottom') do
  "<%= link_to admin_plugin_custom_page_path, 
      class: 'nav-link flex items-center space-x-3 px-3 py-2 rounded-lg hover:bg-[#1a1a1a] text-gray-300 hover:text-white transition' do %>
    <svg class='w-5 h-5' fill='none' stroke='currentColor' viewBox='0 0 24 24'>
      <path stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z'/>
    </svg>
    <span class='sidebar-text'>My Plugin</span>
  <% end %>".html_safe
end
```

### 4. `admin_content_top`
**Location:** Before the main page content
**Purpose:** Add content above the main page content
**Use Cases:**
- Page-specific notices
- Content warnings
- Quick action bars
- Plugin-specific headers

**Example:**
```ruby
add_action('admin_content_top') do
  "<div class='bg-blue-500/10 border border-blue-500/20 rounded-lg p-4 mb-6'>
    <div class='flex items-center space-x-2'>
      <svg class='w-5 h-5 text-blue-400' fill='currentColor' viewBox='0 0 20 20'>
        <path fill-rule='evenodd' d='M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z' clip-rule='evenodd'/>
      </svg>
      <span class='text-blue-200'>Plugin notice: This feature is in beta.</span>
    </div>
  </div>".html_safe
end
```

### 5. `admin_content_bottom`
**Location:** After the main page content
**Purpose:** Add content below the main page content
**Use Cases:**
- Related content
- Plugin-specific footers
- Additional information
- Call-to-action sections

**Example:**
```ruby
add_action('admin_content_bottom') do
  "<div class='mt-8 p-6 bg-gray-800 rounded-lg'>
    <h3 class='text-lg font-semibold text-white mb-4'>Plugin Information</h3>
    <p class='text-gray-300'>This content was added by My Plugin.</p>
  </div>".html_safe
end
```

### 6. `admin_footer`
**Location:** Before the closing `</body>` tag
**Purpose:** Add scripts, styles, or content to the page footer
**Use Cases:**
- JavaScript initialization
- CSS styles
- Analytics scripts
- Plugin-specific scripts

**Example:**
```ruby
add_action('admin_footer') do
  "<script>
    // Initialize plugin functionality
    document.addEventListener('DOMContentLoaded', function() {
      console.log('My Plugin initialized');
    });
  </script>
  <style>
    .my-plugin-style {
      background: linear-gradient(45deg, #667eea 0%, #764ba2 100%);
    }
  </style>".html_safe
end
```

## Hook Registration

All hooks are registered using the `add_action` method in your plugin's `activate` method:

```ruby
def activate
  super
  
  # Register hooks
  add_action('admin_right_topbar_content') do
    render_my_widget
  end
  
  add_action('admin_sidebar_bottom') do
    render_sidebar_menu
  end
end
```

## Best Practices

### 1. HTML Structure
- Always use proper HTML structure
- Include appropriate CSS classes for styling
- Use semantic HTML elements
- Ensure accessibility (ARIA labels, proper contrast)

### 2. Styling
- Use Tailwind CSS classes that match the admin theme
- Follow the dark theme color scheme (`#111111`, `#1a1a1a`, etc.)
- Use consistent spacing and sizing
- Test on different screen sizes

### 3. Performance
- Keep hook content lightweight
- Avoid heavy JavaScript in hooks
- Use efficient HTML structures
- Consider caching for expensive operations

### 4. Error Handling
- Always wrap hook content in error handling
- Use `rescue` blocks for potential errors
- Log errors appropriately
- Provide fallback content when possible

### 5. Conditional Rendering
- Only render content when appropriate
- Check user permissions
- Consider current page context
- Use conditional logic for different scenarios

## Example Plugin Implementation

Here's a complete example of a plugin that uses multiple admin hooks:

```ruby
class MyAdminPlugin < Railspress::PluginBase
  plugin_name 'My Admin Plugin'
  plugin_version '1.0.0'
  plugin_description 'Demonstrates admin hook usage'
  plugin_author 'RailsPress Team'

  def activate
    super
    
    # Register all hooks
    register_admin_hooks
  end

  private

  def register_admin_hooks
    # Topbar widget
    add_action('admin_right_topbar_content') do
      render_topbar_widget
    end
    
    # Sidebar menu item
    add_action('admin_sidebar_bottom') do
      render_sidebar_menu
    end
    
    # Content notices
    add_action('admin_content_top') do
      render_content_notice
    end
    
    # Footer scripts
    add_action('admin_footer') do
      render_footer_scripts
    end
  end

  def render_topbar_widget
    "<div class='plugin-widget bg-purple-500/10 border border-purple-500/20 rounded-lg px-3 py-1'>
      <span class='text-purple-200 text-xs'>My Plugin Active</span>
    </div>".html_safe
  end

  def render_sidebar_menu
    "<%= link_to admin_my_plugin_path, 
        class: 'nav-link flex items-center space-x-3 px-3 py-2 rounded-lg hover:bg-[#1a1a1a] text-gray-300 hover:text-white transition' do %>
      <svg class='w-5 h-5' fill='none' stroke='currentColor' viewBox='0 0 24 24'>
        <path stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z'/>
      </svg>
      <span class='sidebar-text'>My Plugin</span>
    <% end %>".html_safe
  end

  def render_content_notice
    "<div class='bg-blue-500/10 border border-blue-500/20 rounded-lg p-4 mb-6'>
      <div class='flex items-center space-x-2'>
        <svg class='w-5 h-5 text-blue-400' fill='currentColor' viewBox='0 0 20 20'>
          <path fill-rule='evenodd' d='M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z' clip-rule='evenodd'/>
        </svg>
        <span class='text-blue-200'>My Plugin is active and ready to use!</span>
      </div>
    </div>".html_safe
  end

  def render_footer_scripts
    "<script>
      document.addEventListener('DOMContentLoaded', function() {
        console.log('My Admin Plugin loaded successfully');
      });
    </script>".html_safe
  end
end
```

## Troubleshooting

### Common Issues

1. **Hook not rendering:** Check if the plugin is active and the hook is properly registered
2. **Styling issues:** Ensure you're using the correct Tailwind classes
3. **JavaScript errors:** Check browser console for errors
4. **Performance issues:** Optimize hook content and avoid heavy operations

### Debugging

Enable debug logging to see hook execution:

```ruby
Rails.logger.info "Hook executed: #{hook_name}"
```

### Testing

Test your hooks in different admin pages to ensure they work correctly across the interface.

## Conclusion

The RailsPress admin hook system provides powerful integration points for plugins. Use these hooks responsibly and follow the best practices outlined in this guide to create seamless admin experiences.

For more information about the RailsPress plugin system, see the [Plugin Developer Guide](PLUGIN_DEVELOPER_GUIDE.md).
