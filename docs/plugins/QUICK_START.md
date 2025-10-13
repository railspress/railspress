# Plugin Quick Start Guide

Get started creating RailsPress plugins in 5 minutes!

## 1. Create Your Plugin File

Create a new file in `lib/plugins/my_plugin/my_plugin.rb`:

```ruby
class MyPlugin < Railspress::PluginBase
  plugin_name 'My Awesome Plugin'
  plugin_version '1.0.0'
  plugin_description 'Does something amazing'
  plugin_author 'Your Name'
  plugin_url 'https://yoursite.com'
  plugin_license 'MIT'
  
  def setup
    # Plugin initialization code goes here
  end
end

# Register the plugin
Railspress::PluginSystem.register_plugin('my_plugin', MyPlugin.new)
```

## 2. Add a Settings Form

```ruby
def setup
  create_form :settings do |f|
    f.section 'Basic Settings' do
      f.text_field :api_key, 
        label: 'API Key',
        required: true,
        help: 'Enter your API key from the provider'
      
      f.checkbox :enabled,
        label: 'Enable Plugin',
        default: true
    end
  end
end
```

## 3. Register an Admin Page

```ruby
def setup
  # ... form creation ...
  
  register_admin_page(
    slug: 'settings',
    title: 'Plugin Settings',
    icon: 'cog',
    parent: 'plugins' # Shows under Plugins in sidebar
  )
end
```

## 4. Add Custom Routes

```ruby
def setup
  # ... previous code ...
  
  register_routes do
    # Admin routes
    namespace :admin do
      namespace :my_plugin do
        get 'dashboard', to: 'dashboard#index'
      end
    end
    
    # Public routes
    get '/my-plugin', to: 'my_plugin#show'
  end
end
```

## 5. Add to Database

Create a database entry for your plugin:

```ruby
# db/seeds.rb or Rails console
Plugin.create!(
  name: 'MyPlugin',
  description: 'Does something amazing',
  author: 'Your Name',
  version: '1.0.0',
  active: true
)
```

## 6. Activate Your Plugin

Go to **Admin → Plugins** and click **Activate** next to your plugin.

---

## Complete Minimal Example

```ruby
# lib/plugins/hello_world/hello_world.rb
class HelloWorld < Railspress::PluginBase
  plugin_name 'Hello World'
  plugin_version '1.0.0'
  plugin_description 'A simple hello world plugin'
  plugin_author 'RailsPress'
  
  def setup
    # Create settings form
    create_form :settings do |f|
      f.text_field :greeting,
        label: 'Greeting Message',
        default: 'Hello, World!',
        help: 'Customize your greeting'
    end
    
    # Register admin page
    register_admin_page(
      slug: 'settings',
      title: 'Hello World Settings'
    )
    
    # Add a public route
    register_routes do
      get '/hello', to: 'hello#show'
    end
    
    # Add a filter
    add_filter('post_content', :add_greeting)
  end
  
  def activate
    super
    set_setting(:greeting, 'Hello, World!')
  end
  
  private
  
  def add_greeting(content, post)
    greeting = get_setting(:greeting, 'Hello!')
    "#{greeting}\n\n#{content}"
  end
end

Railspress::PluginSystem.register_plugin('hello_world', HelloWorld.new)
```

---

## Next Steps

1. **Read the Documentation:**
   - [Form Builder](FORM_BUILDER.md) - All field types and options
   - [Routes](ROUTES.md) - Route registration patterns
   - [Admin Pages](admin-pages.md) - Custom admin UI
   - [Architecture](architecture.md) - Plugin system overview

2. **Check the Example:**
   - `lib/plugins/EXAMPLE_FORM_PLUGIN.rb` - Full-featured example
   - `lib/plugins/PLUGIN_TEMPLATE.rb` - Starter template

3. **Use Advanced Features:**
   - Background jobs for async processing
   - Hooks & filters for extending functionality
   - AI agent integration
   - API endpoints

---

## Cheat Sheet

```ruby
# Metadata
plugin_name 'Name'
plugin_version '1.0.0'
plugin_description 'Description'

# Forms
create_form :name do |f|
  f.text_field :field
  f.checkbox :enabled
  f.select_field :type, choices: {}
end

# Admin Pages
register_admin_page(
  slug: 'page',
  title: 'Title'
)

# Routes
register_routes do
  namespace :admin do
    # routes
  end
end

# Settings
set_setting(:key, value)
get_setting(:key, default)

# Jobs
create_job 'JobName' do
  def perform
    # logic
  end
end

# Hooks
add_action('hook_name', :method_name)
add_filter('filter_name', :method_name)
```

---

Happy Plugin Building! 🚀


