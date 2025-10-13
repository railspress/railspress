# Plugin Admin Pages - Quick Guide

Create custom admin pages for your plugins that integrate seamlessly into the RailsPress admin panel.

## Quick Start

```ruby
class MyPlugin < Railspress::PluginBase
  plugin_name 'My Plugin'
  
  def activate
    super
    
    # Register admin page
    register_admin_page(
      slug: 'dashboard',
      title: 'My Plugin Dashboard',
      menu_title: 'My Plugin',
      icon: 'chart-bar',
      callback: :render_dashboard
    )
  end
  
  private
  
  def render_dashboard
    {
      view: plugin_view('dashboard'),
      data: { stats: calculate_stats }
    }
  end
end
```

## Registration Options

```ruby
register_admin_page(
  slug: 'settings',              # URL: /admin/plugins/my_plugin/settings
  title: 'Plugin Settings',      # Page title
  menu_title: 'Settings',         # Sidebar label
  icon: 'cog',                    # Icon name
  capability: 'administrator',    # Permission required
  position: 50,                   # Menu order (lower = higher)
  parent: 'plugins',              # 'plugins', 'tools', 'settings', or nil
  callback: :render_page          # Method to render (optional)
)
```

## Auto-Generated Settings Page

If you define `settings_schema` and register a page WITHOUT a callback:

```ruby
settings_schema do
  section 'API Settings' do
    text 'api_key', 'API Key', required: true
    checkbox 'enabled', 'Enable', default: true
  end
end

register_admin_page(
  slug: 'settings',
  title: 'Settings'
  # No callback = auto-generated form!
)
```

**Result:** Beautiful settings UI with validation, automatically generated!

## Multiple Pages (Submenu)

```ruby
# Main page
register_admin_page(
  slug: 'main',
  title: 'Analytics',
  menu_title: 'Analytics',
  icon: 'chart-bar'
)

# Subpages
register_admin_page(
  slug: 'reports',
  title: 'Reports',
  menu_title: 'Reports',
  parent: plugin_identifier  # Creates submenu
)

register_admin_page(
  slug: 'settings',
  title: 'Settings',
  menu_title: 'Settings',
  parent: plugin_identifier
)
```

**Sidebar:**
```
📊 Analytics
   ├─ Reports
   └─ Settings
```

## Custom Page Rendering

### Option 1: View + Data

```ruby
def render_custom_page
  {
    view: plugin_view('my_view'),  # lib/plugins/my_plugin/views/my_view.html.erb
    data: {
      items: Item.all,
      count: Item.count
    }
  }
end
```

### Option 2: Inline HTML

```ruby
def render_simple_page
  {
    html: '<div class="admin-card"><h2>Hello</h2></div>'
  }
end
```

## Permission Levels

- `'administrator'` - Admin only
- `'editor'` - Editors and above
- `'author'` - Authors and above
- `'contributor'` - Contributors and above

## Parent Menus

- `nil` - Top-level menu
- `'plugins'` - Under Plugins section
- `'tools'` - Under Tools section
- `'settings'` - Under Settings section
- `plugin_identifier` - Under your plugin's main page

## Icon Names

Common icons:
- `'cog'` - Settings
- `'chart-bar'` - Dashboard
- `'chart-line'` - Analytics
- `'puzzle'` - Plugin
- `'document'` - Docs
- `'mail'` - Email
- `'users'` - Users
- `'wrench'` - Tools

## Complete Example

See [Plugin Template](../../lib/plugins/PLUGIN_TEMPLATE.rb) for a complete working example.

## Related Docs

- [Settings Schema](./settings-schema.md) - Auto-generated settings forms
- [Architecture](./architecture.md) - Plugin system overview
- [Settings Quick Reference](./settings-quick-reference.md) - Settings cheat sheet
