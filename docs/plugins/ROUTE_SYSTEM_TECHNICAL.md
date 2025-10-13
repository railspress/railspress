# Plugin Route System - Technical Documentation

Complete technical reference for the RailsPress plugin route registration system.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [System Flow](#system-flow)
3. [API Reference](#api-reference)
4. [Implementation Details](#implementation-details)
5. [Testing Guide](#testing-guide)
6. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Components

The plugin route system consists of four main components:

1. **PluginBase** (`lib/railspress/plugin_base.rb`)
   - Provides `register_routes(&block)` method
   - Stores routes block in `@routes_block`
   - Delegates to PluginSystem for registration

2. **PluginSystem** (`lib/railspress/plugin_system.rb`)
   - Maintains global registry of plugin routes
   - Provides `load_plugin_routes!` method
   - Appends routes to Rails router

3. **Plugin Initializer** (`config/initializers/plugin_system.rb`)
   - Initializes PluginSystem
   - Loads active plugins
   - Triggers route loading

4. **Routes File** (`config/routes.rb`)
   - Contains core application routes
   - Has placeholder comment for plugin routes
   - Plugin routes are dynamically appended

### Data Flow

```
Plugin.setup() 
  → register_routes(&block)
    → PluginSystem.register_plugin_routes(id, block)
      → @plugin_routes[id] = block
        → (stored in memory)

Rails.application.config.after_initialize
  → PluginSystem.load_plugins
    → Requires plugin files
      → Plugin.setup() called
        → Routes registered
  → PluginSystem.load_plugin_routes!
    → Rails.application.routes.append do
      → instance_eval(&block) for each plugin
        → Routes added to Rails router
```

---

## System Flow

### 1. Initialization Phase

```ruby
# config/initializers/plugin_system.rb
Rails.application.config.after_initialize do
  # Step 1: Initialize system
  Railspress::PluginSystem.initialize_system
  # → Creates @plugins, @hooks, @filters, @admin_pages, @plugin_routes hashes
  
  # Step 2: Load active plugins
  Railspress::PluginSystem.load_plugins
  # → Finds active plugins in database
  # → Requires plugin files from lib/plugins/
  # → Calls PluginBase.new which calls setup()
  
  # Step 3: Load plugin routes
  Railspress::PluginSystem.load_plugin_routes!
  # → Appends all registered routes to Rails router
end
```

### 2. Plugin Registration Phase

```ruby
# lib/plugins/my_plugin/my_plugin.rb
class MyPlugin < Railspress::PluginBase
  def setup
    # Routes registered here
    register_routes do
      get '/my-path', to: 'my_controller#action'
    end
    # → Calls PluginSystem.register_plugin_routes()
    # → Stores block in @plugin_routes hash
  end
end
```

### 3. Route Loading Phase

```ruby
# lib/railspress/plugin_system.rb
def load_plugin_routes!
  return unless @plugin_routes&.any?
  
  Rails.application.routes.append do
    @plugin_routes.each do |plugin_identifier, routes_block|
      # Execute route block in Rails router context
      instance_eval(&routes_block) if routes_block
    end
  end
end
```

---

## API Reference

### PluginBase Methods

#### `register_routes(&block)`

Registers routes for the plugin.

**Parameters:**
- `block` - Block containing Rails routing DSL

**Returns:** `nil`

**Example:**
```ruby
register_routes do
  get '/my-plugin', to: 'my_plugin#index'
  namespace :admin do
    resources :items
  end
end
```

**Internal Behavior:**
1. Stores block in `@routes_block` instance variable
2. Calls `PluginSystem.register_plugin_routes(plugin_identifier, block)`
3. Logs registration for debugging

---

#### `has_routes?`

Checks if plugin has registered routes.

**Returns:** `Boolean`

**Example:**
```ruby
plugin = MyPlugin.new
plugin.has_routes? # => true if routes registered
```

---

### PluginSystem Methods

#### `register_plugin_routes(plugin_identifier, routes_block)`

Stores route block in global registry.

**Parameters:**
- `plugin_identifier` - String identifier (e.g., 'my_plugin')
- `routes_block` - Proc containing routes

**Returns:** `nil`

**Example:**
```ruby
Railspress::PluginSystem.register_plugin_routes('my_plugin', -> {
  get '/test', to: 'test#index'
})
```

---

#### `load_plugin_routes!`

Loads all registered plugin routes into Rails router.

**Returns:** `nil`

**Side Effects:**
- Appends routes to `Rails.application.routes`
- Logs success/error messages

**Example:**
```ruby
Railspress::PluginSystem.load_plugin_routes!
```

**Error Handling:**
- Catches and logs individual plugin route errors
- Continues loading other plugin routes on error
- Logs stack trace for debugging

---

#### `all_plugin_routes`

Returns hash of all registered route blocks.

**Returns:** `Hash<String, Proc>`

**Example:**
```ruby
routes = Railspress::PluginSystem.all_plugin_routes
# => { "my_plugin" => #<Proc>, "another_plugin" => #<Proc> }
```

---

## Implementation Details

### Route Block Context

When `instance_eval(&routes_block)` is called, the block executes in the context of Rails router:

```ruby
# This block:
register_routes do
  get '/test', to: 'test#index'
end

# Becomes equivalent to:
Rails.application.routes.append do
  get '/test', to: 'test#index'
end
```

### Route Helpers

Rails automatically generates helper methods:

```ruby
register_routes do
  get '/my-plugin/dashboard', to: 'my_plugin#dashboard', as: 'my_plugin_dashboard'
end

# Generates helpers:
my_plugin_dashboard_path     # => "/my-plugin/dashboard"
my_plugin_dashboard_url      # => "http://example.com/my-plugin/dashboard"
```

### Namespace Isolation

Routes are isolated by namespace:

```ruby
register_routes do
  namespace :admin do
    namespace :my_plugin do
      root to: 'dashboard#index'
      # Path: /admin/my_plugin
      # Helper: admin_my_plugin_root_path
    end
  end
end
```

### Route Priority

Plugin routes are appended AFTER core routes using `routes.append`:

```ruby
# Core routes loaded first (config/routes.rb)
Rails.application.routes.draw do
  root 'home#index'
  # ... core routes ...
end

# Plugin routes appended after
Rails.application.routes.append do
  # Plugin routes here
  # Will match only if core routes don't match first
end
```

**This means:**
- Core routes take precedence
- Plugin routes won't override core routes
- Safe from conflicts

---

## Testing Guide

### Testing Route Registration

```ruby
# test/lib/railspress/plugin_route_system_test.rb
require 'test_helper'

class PluginRouteSystemTest < ActiveSupport::TestCase
  setup do
    @plugin = MyTestPlugin.new
  end
  
  test "plugin can register routes" do
    assert_nothing_raised do
      @plugin.register_routes do
        get '/test', to: 'test#index'
      end
    end
    
    assert @plugin.has_routes?
  end
  
  test "routes are stored in PluginSystem" do
    @plugin.register_routes do
      get '/test', to: 'test#index'
    end
    
    routes = Railspress::PluginSystem.all_plugin_routes
    assert_includes routes.keys, 'my_test_plugin'
  end
  
  test "routes are loaded into Rails router" do
    @plugin.register_routes do
      get '/unique-test-path', to: 'test#index'
    end
    
    Railspress::PluginSystem.load_plugin_routes!
    
    # Check route exists
    route_exists = Rails.application.routes.routes.any? do |route|
      route.path.spec.to_s.include?('unique-test-path')
    end
    
    assert route_exists, "Plugin route was not loaded"
  end
end
```

### Testing Routes Work

```ruby
# test/integration/my_plugin_routes_test.rb
require 'test_helper'

class MyPluginRoutesTest < ActionDispatch::IntegrationTest
  test "can access plugin public route" do
    get '/my-plugin'
    assert_response :success
  end
  
  test "can access plugin admin route" do
    sign_in users(:admin)
    get '/admin/my-plugin/dashboard'
    assert_response :success
  end
  
  test "can access plugin API route" do
    get '/api/v1/my-plugin/items'
    assert_response :success
  end
end
```

---

## Troubleshooting

### Issue: Routes Not Loading

**Symptoms:**
- `rails routes` doesn't show plugin routes
- 404 errors when accessing plugin paths
- No errors in logs

**Solutions:**

1. **Check plugin is active:**
   ```ruby
   Plugin.find_by(name: 'MyPlugin')&.active?
   ```

2. **Check routes are registered:**
   ```ruby
   Railspress::PluginSystem.all_plugin_routes.keys
   # Should include 'my_plugin'
   ```

3. **Check initializer runs:**
   ```bash
   # In server logs, look for:
   "Plugin system initialized"
   "Loaded plugin: MyPlugin"
   "Registered routes for plugin: my_plugin"
   "Loading routes for X plugin(s)..."
   ```

4. **Manually reload routes:**
   ```ruby
   # In Rails console
   Railspress::PluginSystem.load_plugin_routes!
   Rails.application.reload_routes!
   ```

---

### Issue: Route Conflicts

**Symptoms:**
- Error: "Route already exists"
- Unexpected behavior on certain paths

**Solutions:**

1. **Check for duplicates:**
   ```bash
   rails routes | grep "/your-path"
   ```

2. **Use unique namespaces:**
   ```ruby
   # Instead of:
   get '/settings', to: 'plugin#settings'
   
   # Use:
   scope '/my-plugin' do
     get '/settings', to: 'plugin#settings'
   end
   ```

3. **Check plugin load order:**
   Plugin routes load in the order they're registered. If two plugins register the same route, the first one wins.

---

### Issue: Controllers Not Found

**Symptoms:**
- Error: "uninitialized constant MyPluginController"
- 500 errors when accessing routes

**Solutions:**

1. **Check controller location:**
   ```
   lib/plugins/my_plugin/
   ├── controllers/
   │   └── my_plugin_controller.rb
   ```

2. **Check controller autoloading:**
   ```ruby
   # In plugin setup:
   def setup
     controllers_path = File.expand_path('../controllers', __FILE__)
     Rails.application.config.paths['app/controllers'] << controllers_path
   end
   ```

3. **Check controller class name:**
   ```ruby
   # File: my_plugin_controller.rb
   class MyPluginController < ApplicationController
     # Must match route: to: 'my_plugin#index'
   end
   ```

---

### Issue: Routes Disappear in Development

**Symptoms:**
- Routes work initially
- Disappear after code changes
- Need to restart server

**Cause:**
Rails reloads code in development, but routes aren't automatically reloaded.

**Solution:**

Add to your plugin:
```ruby
# In config/initializers/plugin_system.rb
if Rails.env.development?
  Rails.application.config.to_prepare do
    Railspress::PluginSystem.load_plugins
    Railspress::PluginSystem.load_plugin_routes!
  end
end
```

---

## Advanced Usage

### Dynamic Route Generation

Generate routes based on plugin settings:

```ruby
def setup
  register_routes do
    # Always available
    namespace :admin do
      get 'my-plugin/settings', to: 'my_plugin/settings#show'
    end
    
    # Conditional based on settings
    if get_setting(:enable_public_api, false)
      namespace :api do
        namespace :v1 do
          resources :my_plugin_items
        end
      end
    end
    
    # Multiple endpoints based on config
    endpoints = get_setting(:enabled_endpoints, ['basic'])
    endpoints.each do |endpoint|
      get "/my-plugin/#{endpoint}", to: "my_plugin##{endpoint}"
    end
  end
end
```

### Route Constraints

```ruby
register_routes do
  # Admin only
  constraints lambda { |req| req.session[:admin] } do
    get '/my-plugin/admin-only', to: 'my_plugin#admin'
  end
  
  # Premium users only
  constraints lambda { |req| req.session[:premium_user] } do
    get '/my-plugin/premium', to: 'my_plugin#premium'
  end
  
  # Subdomain-based
  constraints subdomain: 'api' do
    get '/my-plugin', to: 'my_plugin/api#index'
  end
end
```

### Mounting Rack Apps

```ruby
register_routes do
  mount MyPlugin::RackApp.new, at: '/my-plugin'
end

# lib/plugins/my_plugin/rack_app.rb
module MyPlugin
  class RackApp
    def call(env)
      [200, {'Content-Type' => 'text/plain'}, ['Hello from Rack app!']]
    end
  end
end
```

---

## Performance Considerations

### Route Loading Time

- Routes load once at application startup
- Negligible performance impact (<1ms per plugin)
- Routes cached in memory by Rails

### Memory Usage

- Each route block stored as Proc (~200 bytes)
- 100 plugins = ~20KB memory
- Insignificant overhead

### Optimization Tips

1. **Minimize dynamic route generation:**
   ```ruby
   # Good - static routes
   register_routes do
     resources :items
   end
   
   # Bad - generates 100 routes dynamically
   register_routes do
     (1..100).each do |i|
       get "/item-#{i}", to: "items#show_#{i}"
     end
   end
   ```

2. **Use resourceful routing:**
   ```ruby
   # Good - 7 routes with 1 declaration
   resources :items
   
   # Bad - 7 individual route declarations
   get '/items', to: 'items#index'
   get '/items/new', to: 'items#new'
   # ... etc
   ```

---

## Security Considerations

### 1. Authentication

Always protect admin routes:

```ruby
register_routes do
  namespace :admin do
    # These routes require authentication
    # Admin::BaseController handles this
    namespace :my_plugin do
      resources :sensitive_data
    end
  end
end
```

### 2. Authorization

Use capability checks:

```ruby
# In your controller
class Admin::MyPlugin::ItemsController < Admin::BaseController
  before_action :ensure_admin # Only administrators
  
  def index
    # ...
  end
end
```

### 3. CSRF Protection

For API routes, handle CSRF appropriately:

```ruby
# In API controller
class Api::V1::MyPlugin::ItemsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_api_token!
  
  private
  
  def authenticate_api_token!
    token = request.headers['Authorization']&.split(' ')&.last
    @current_user = User.find_by_api_token(token)
    head :unauthorized unless @current_user
  end
end
```

### 4. Input Validation

Always validate params:

```ruby
def create
  @item = Item.new(item_params)
  
  if @item.save
    render json: @item, status: :created
  else
    render json: { errors: @item.errors }, status: :unprocessable_entity
  end
end

private

def item_params
  params.require(:item).permit(:name, :description)
end
```

---

## Debugging Tools

### 1. List All Plugin Routes

```ruby
# Rails console
Railspress::PluginSystem.all_plugin_routes.each do |plugin_id, block|
  puts "#{plugin_id}:"
  puts "  Block: #{block.source_location}"
end
```

### 2. Inspect Loaded Routes

```bash
# Command line
rails routes | grep "my_plugin"
```

```ruby
# Rails console
Rails.application.routes.routes.select { |r| 
  r.path.spec.to_s.include?('my-plugin') 
}.map { |r| 
  "#{r.verb} #{r.path.spec}" 
}
```

### 3. Test Route Recognition

```ruby
# Rails console
path = '/admin/my-plugin/dashboard'
Rails.application.routes.recognize_path(path)
# => {:controller=>"admin/my_plugin/dashboard", :action=>"index"}
```

### 4. Generate Route URL

```ruby
# Rails console
Rails.application.routes.url_helpers.admin_my_plugin_dashboard_path
# => "/admin/my_plugin/dashboard"
```

---

## Common Patterns

### Pattern 1: RESTful Resource with Custom Actions

```ruby
register_routes do
  namespace :admin do
    resources :products do
      member do
        post :duplicate
        patch :publish
        patch :unpublish
      end
      
      collection do
        get :export
        post :import
        post :bulk_delete
      end
    end
  end
end
```

**Generates:**
- `POST /admin/products/:id/duplicate`
- `PATCH /admin/products/:id/publish`
- `GET /admin/products/export`
- `POST /admin/products/import`

---

### Pattern 2: Versioned API

```ruby
register_routes do
  namespace :api do
    namespace :v1 do
      namespace :my_plugin do
        resources :items
        get 'stats', to: 'stats#index'
      end
    end
    
    namespace :v2 do
      namespace :my_plugin do
        resources :items
        get 'analytics', to: 'analytics#index'
      end
    end
  end
end
```

---

### Pattern 3: Wizard/Multi-Step Form

```ruby
register_routes do
  scope '/my-plugin/wizard' do
    get '/', to: 'wizard#start', as: 'wizard_start'
    
    (1..5).each do |step|
      get "/step-#{step}", to: 'wizard#show', defaults: { step: step }
      post "/step-#{step}", to: 'wizard#update', defaults: { step: step }
    end
    
    get '/complete', to: 'wizard#complete', as: 'wizard_complete'
  end
end
```

---

### Pattern 4: Webhook Endpoints

```ruby
register_routes do
  # Single webhook
  post '/webhooks/stripe', to: 'webhooks#stripe'
  
  # Dynamic webhook with ID
  post '/webhooks/:provider/:id', to: 'webhooks#handle'
  
  # Webhook verification
  get '/webhooks/:provider/verify', to: 'webhooks#verify'
end
```

---

## Migration Guide

### From Manual Routes to Plugin Routes

**Step 1:** Identify routes in `config/routes.rb`

**Step 2:** Move to plugin

**Step 3:** Remove from `config/routes.rb`

**Step 4:** Test

**Example:**

**Before:**
```ruby
# config/routes.rb
get '/booking', to: 'booking#index'
post '/booking/reserve', to: 'booking#reserve'

namespace :admin do
  resources :bookings
end
```

**After:**
```ruby
# lib/plugins/booking_plugin/booking_plugin.rb
class BookingPlugin < Railspress::PluginBase
  def setup
    register_routes do
      get '/booking', to: 'booking#index'
      post '/booking/reserve', to: 'booking#reserve'
      
      namespace :admin do
        resources :bookings
      end
    end
  end
end
```

---

## Best Practices

### ✅ DO

1. **Always use namespaces for admin routes:**
   ```ruby
   namespace :admin do
     namespace :my_plugin do
       # routes
     end
   end
   ```

2. **Prefix public routes:**
   ```ruby
   scope '/my-plugin' do
     # routes
   end
   ```

3. **Use RESTful conventions:**
   ```ruby
   resources :items # instead of individual routes
   ```

4. **Document your routes:**
   ```ruby
   register_routes do
     # Public API
     # GET /my-plugin/items - List all items
     # POST /my-plugin/items - Create item
     resources :items, only: [:index, :create]
   end
   ```

5. **Test your routes:**
   ```ruby
   test "my plugin route works" do
     get '/my-plugin'
     assert_response :success
   end
   ```

### ❌ DON'T

1. **Don't override core routes:**
   ```ruby
   # Bad - overrides homepage
   root to: 'my_plugin#index'
   ```

2. **Don't use generic paths:**
   ```ruby
   # Bad - conflicts likely
   get '/settings', to: 'plugin#settings'
   
   # Good
   get '/my-plugin/settings', to: 'plugin#settings'
   ```

3. **Don't hardcode domains:**
   ```ruby
   # Bad
   get '/my-plugin', to: 'plugin#index', defaults: { host: 'example.com' }
   ```

4. **Don't forget error handling:**
   ```ruby
   # Add proper error handling in controllers
   rescue_from ActiveRecord::RecordNotFound, with: :not_found
   ```

---

## Examples from Real Plugins

### SEO Optimizer Plugin

```ruby
register_routes do
  # Sitemap (public)
  get '/sitemap.xml', to: 'seo_optimizer/sitemap#index', defaults: { format: :xml }
  get '/sitemap-:page.xml', to: 'seo_optimizer/sitemap#page', defaults: { format: :xml }
  
  # Admin
  namespace :admin do
    namespace :seo_optimizer do
      get 'dashboard', to: 'dashboard#index'
      get 'analysis', to: 'analysis#show'
      post 'analyze', to: 'analysis#create'
      resources :redirects
    end
  end
end
```

### E-Commerce Plugin

```ruby
register_routes do
  # Shop (public)
  scope '/shop' do
    resources :products, only: [:index, :show]
    resource :cart, only: [:show, :update, :destroy]
    resources :orders, only: [:create, :show]
    get '/checkout', to: 'checkout#new'
    post '/checkout', to: 'checkout#create'
  end
  
  # Admin
  namespace :admin do
    namespace :shop do
      resources :products
      resources :orders do
        member do
          patch :fulfill
          patch :refund
        end
      end
      get 'reports', to: 'reports#index'
    end
  end
  
  # API
  namespace :api do
    namespace :v1 do
      namespace :shop do
        resources :products, only: [:index, :show]
      end
    end
  end
end
```

---

## Route System Checklist

When implementing plugin routes, verify:

- [ ] Plugin inherits from `Railspress::PluginBase`
- [ ] Routes registered in `setup()` method using `register_routes`
- [ ] Routes use appropriate namespaces
- [ ] Controllers exist and are properly namespaced
- [ ] Controllers inherit from correct base class
- [ ] Routes tested with integration tests
- [ ] Route helpers used in views
- [ ] No conflicts with core routes
- [ ] Authentication/authorization implemented
- [ ] Error handling in place
- [ ] Routes documented in plugin README

---

## Summary

The RailsPress plugin route system provides:

✅ **Automatic route loading** - No manual editing of `routes.rb`
✅ **Namespace isolation** - Prevents conflicts
✅ **Standard Rails syntax** - Familiar to all Rails developers
✅ **Dynamic loading** - Routes load when plugins activate
✅ **Error handling** - Individual plugin failures don't break others
✅ **Development-friendly** - Auto-reload in development mode
✅ **Production-ready** - Tested and proven architecture

---

## References

- [Plugin Quick Start](QUICK_START.md)
- [Form Builder](FORM_BUILDER.md)
- [Admin Pages](admin-pages.md)
- [Rails Routing Guide](https://guides.rubyonrails.org/routing.html)

---

Built with ❤️ for RailsPress



