# Dynamic Plugin Routes System

Plugins can now register their own routes **without modifying** `config/routes.rb`.

## Problem Solved

Previously, plugins required manually adding routes to `config/routes.rb`, which:
- Modified core application files
- Created version control conflicts
- Made plugin installation/removal messy
- Required manual intervention

Now plugins are **fully self-contained** and manage their own routes automatically.

## How to Use in Your Plugin

### 1. Register Routes in Your Plugin

```ruby
class MyPlugin < Railspress::PluginBase
  plugin_name 'My Plugin'
  plugin_version '1.0.0'
  
  def activate
    super
    register_plugin_routes
  end
  
  private
  
  def register_plugin_routes
    register_routes do
      # Public routes
      get '/my-plugin', to: 'my_plugin#index'
      post '/my-plugin/action', to: 'my_plugin#action'
      
      # Admin routes
      namespace :admin do
        resources :my_plugin do
          member do
            post :custom_action
          end
          
          collection do
            get :settings
          end
        end
      end
      
      # API routes
      namespace :api do
        namespace :v1 do
          resources :my_plugin, only: [:index, :show]
        end
      end
    end
  end
end
```

### 2. Routes Are Automatically Loaded

The `register_routes` method:
1. Stores the route block in the plugin instance
2. Registers it with `Railspress::PluginSystem`
3. Routes are loaded automatically on app initialization
4. No manual intervention needed!

## Architecture

### PluginBase Enhancement

```ruby
# lib/railspress/plugin_base.rb
def register_routes(&block)
  @routes_block = block
  Railspress::PluginSystem.register_plugin_routes(plugin_identifier, block)
  log("Routes registered for #{name}", :debug)
end
```

### PluginSystem Enhancement

```ruby
# lib/railspress/plugin_system.rb
def register_plugin_routes(plugin_identifier, routes_block)
  @plugin_routes ||= {}
  @plugin_routes[plugin_identifier] = routes_block
end

def load_plugin_routes!
  Rails.application.routes.append do
    @plugin_routes.each do |plugin_identifier, routes_block|
      instance_eval(&routes_block) if routes_block
    end
  end
end
```

### Initializer

```ruby
# config/initializers/plugin_system.rb
Rails.application.config.after_initialize do
  Railspress::PluginSystem.initialize_system
  Railspress::PluginSystem.load_plugins
  Railspress::PluginSystem.load_plugin_routes!  # ← Loads all plugin routes
end
```

## Route Scoping

### Namespace Your Public Routes

Avoid conflicts by namespacing public routes:

```ruby
register_routes do
  # Good - namespaced
  scope '/my-plugin' do
    get '/', to: 'my_plugin#index'
    get '/settings', to: 'my_plugin#settings'
  end
  
  # Bad - could conflict
  get '/settings', to: 'my_plugin#settings'
end
```

### Use Controller Namespace

Keep controllers organized:

```ruby
# app/controllers/my_plugin_controller.rb
class MyPluginController < ApplicationController
  # ...
end

# Or namespaced
# app/controllers/plugins/my_plugin_controller.rb
module Plugins
  class MyPluginController < ApplicationController
    # ...
  end
end

# Then in routes:
register_routes do
  namespace :plugins do
    get '/my-plugin', to: 'my_plugin#index'
  end
end
```

## Debugging Routes

### View All Plugin Routes

```ruby
# In Rails console
Railspress::PluginSystem.all_plugin_routes

# Returns:
# {
#   "fluent_forms_pro" => #<Proc>,
#   "my_plugin" => #<Proc>
# }
```

### Check If Routes Loaded

```bash
rails routes | grep my-plugin
```

Or programmatically:

```ruby
Rails.application.routes.routes.map(&:path).grep(/my-plugin/)
```

### Force Reload Routes

```ruby
# In development, if routes don't update:
Rails.application.reload_routes!
```

## Best Practices

### ✅ DO

- Namespace your public routes (e.g., `/my-plugin/*`)
- Use `namespace :admin` for admin routes
- Document your routes in plugin README
- Test route presence in specs
- Use RESTful routes where possible

### ❌ DON'T

- Use root path (could conflict)
- Override existing application routes
- Create routes outside your plugin's scope
- Forget to namespace admin routes

## Examples

### Simple Plugin Routes

```ruby
register_routes do
  get '/hello', to: 'hello#index'
  post '/hello/greet', to: 'hello#greet'
end
```

### Complex Plugin Routes

```ruby
register_routes do
  # Public facing
  scope '/booking' do
    resources :appointments, only: [:index, :show, :create] do
      member do
        post :confirm
        post :cancel
      end
    end
  end
  
  # Admin interface
  namespace :admin do
    resources :appointments do
      collection do
        get :calendar
        get :export
      end
      
      member do
        post :approve
        post :reject
      end
    end
    
    resource :booking_settings, only: [:show, :update]
  end
  
  # API endpoints
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :appointments, only: [:index, :show, :create]
    end
  end
end
```

### Multi-Step Form Routes

```ruby
register_routes do
  scope '/wizard' do
    get '/', to: 'wizard#start', as: :wizard_start
    get '/step/:step', to: 'wizard#step', as: :wizard_step
    post '/step/:step', to: 'wizard#process_step'
    get '/complete', to: 'wizard#complete', as: :wizard_complete
  end
end
```

## Testing Plugin Routes

### RSpec Example

```ruby
# spec/routing/my_plugin_routes_spec.rb
require 'rails_helper'

RSpec.describe 'MyPlugin routes', type: :routing do
  before(:all) do
    MyPlugin.new.activate
    Rails.application.reload_routes!
  end
  
  it 'routes to my_plugin#index' do
    expect(get: '/my-plugin').to route_to('my_plugin#index')
  end
  
  it 'routes to admin my_plugin' do
    expect(get: '/admin/my-plugin').to route_to('admin/my_plugin#index')
  end
end
```

### Integration Test

```ruby
# test/integration/my_plugin_test.rb
require 'test_helper'

class MyPluginTest < ActionDispatch::IntegrationTest
  setup do
    @plugin = MyPlugin.new
    @plugin.activate
  end
  
  test 'can access plugin route' do
    get '/my-plugin'
    assert_response :success
  end
  
  test 'can access admin plugin route' do
    sign_in users(:admin)
    get '/admin/my-plugin'
    assert_response :success
  end
end
```

## Migration Guide

### If Your Plugin Currently Uses Manual Routes

**Before (in config/routes.rb):**
```ruby
# config/routes.rb
get '/my-plugin', to: 'my_plugin#index'

namespace :admin do
  resources :my_plugin
end
```

**After (in your plugin):**
```ruby
# lib/plugins/my_plugin/my_plugin.rb
class MyPlugin < Railspress::PluginBase
  def activate
    super
    register_plugin_routes
  end
  
  private
  
  def register_plugin_routes
    register_routes do
      get '/my-plugin', to: 'my_plugin#index'
      
      namespace :admin do
        resources :my_plugin
      end
    end
  end
end
```

**Then:**
1. Remove routes from `config/routes.rb`
2. Deactivate and reactivate plugin
3. Routes will work automatically!

## Troubleshooting

### Routes Not Working?

**Check plugin is activated:**
```ruby
Plugin.find_by(name: 'My Plugin')&.active?
```

**Check routes are registered:**
```ruby
plugin = MyPlugin.new
plugin.has_routes?  # Should return true
```

**Check PluginSystem has routes:**
```ruby
Railspress::PluginSystem.all_plugin_routes.keys
# Should include 'my_plugin'
```

**Reload routes manually:**
```ruby
Rails.application.reload_routes!
```

### Route Conflicts?

If you get "route already exists" errors:

1. Check for duplicate route definitions
2. Ensure route paths are unique
3. Use namespace to avoid conflicts
4. Check if core app has same route

### Routes Disappear After Server Restart?

Make sure:
1. Plugin is marked as `active` in database
2. Plugin file is in correct location
3. `plugin_system.rb` initializer exists
4. No errors in plugin activation

## Summary

✨ **Plugins now manage their own routes automatically!**

- No manual `routes.rb` editing
- Self-contained plugins
- Easy install/uninstall
- Version control friendly
- No conflicts with core app

This makes the plugin system truly modular and production-ready! 🚀


