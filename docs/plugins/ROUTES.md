# Plugin Routes System

Complete guide to registering custom routes for your RailsPress plugins.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Route Registration](#route-registration)
3. [Admin Routes](#admin-routes)
4. [Public Routes](#public-routes)
5. [API Routes](#api-routes)
6. [Examples](#examples)
7. [Best Practices](#best-practices)

---

## Quick Start

Register routes in your plugin's `setup` method:

```ruby
class MyPlugin < Railspress::PluginBase
  def setup
    register_routes do
      # Admin routes
      namespace :admin do
        get 'my-plugin/dashboard', to: 'my_plugin#dashboard'
      end
      
      # Public routes
      get '/my-plugin/public-page', to: 'my_plugin/public#index'
    end
  end
end
```

---

## Route Registration

### Basic Syntax

```ruby
register_routes do
  # Standard Rails routing syntax
  get '/path', to: 'controller#action'
  post '/path', to: 'controller#action'
  resources :items
end
```

### Routes are Loaded Automatically

When your plugin is activated, routes are:
1. Registered with the `PluginSystem`
2. Automatically loaded into Rails router
3. Available immediately after plugin activation

---

## Admin Routes

### Creating Admin Pages

```ruby
register_routes do
  namespace :admin do
    namespace :my_plugin do
      get 'dashboard', to: 'dashboard#index'
      get 'reports', to: 'reports#index'
      post 'sync', to: 'sync#create'
      
      resources :items
    end
  end
end
```

**URLs Generated:**
- `/admin/my_plugin/dashboard`
- `/admin/my_plugin/reports`
- `/admin/my_plugin/sync`
- `/admin/my_plugin/items`

### Creating Controllers

Create your plugin controllers in `lib/plugins/my_plugin/controllers/`:

```ruby
# lib/plugins/my_plugin/controllers/admin/my_plugin/dashboard_controller.rb
module Admin
  module MyPlugin
    class DashboardController < Admin::BaseController
      def index
        @stats = calculate_stats
      end
      
      private
      
      def calculate_stats
        # Your logic here
      end
    end
  end
end
```

---

## Public Routes

### Creating Public Pages

```ruby
register_routes do
  # Public routes accessible to everyone
  get '/my-plugin', to: 'my_plugin/public#index'
  get '/my-plugin/about', to: 'my_plugin/public#about'
  post '/my-plugin/subscribe', to: 'my_plugin/public#subscribe'
end
```

### Public Controllers

```ruby
# lib/plugins/my_plugin/controllers/my_plugin/public_controller.rb
module MyPlugin
  class PublicController < ApplicationController
    def index
      # Public page logic
    end
    
    def about
      render json: { message: 'About our plugin' }
    end
  end
end
```

---

## API Routes

### RESTful API Endpoints

```ruby
register_routes do
  namespace :api do
    namespace :v1 do
      namespace :my_plugin do
        resources :items, only: [:index, :show, :create, :update, :destroy]
        
        post 'process', to: 'processor#process'
        get 'status', to: 'status#index'
      end
    end
  end
end
```

**URLs Generated:**
- `GET    /api/v1/my_plugin/items`
- `POST   /api/v1/my_plugin/items`
- `GET    /api/v1/my_plugin/items/:id`
- `PATCH  /api/v1/my_plugin/items/:id`
- `DELETE /api/v1/my_plugin/items/:id`
- `POST   /api/v1/my_plugin/process`
- `GET    /api/v1/my_plugin/status`

### API Controllers

```ruby
# lib/plugins/my_plugin/controllers/api/v1/my_plugin/items_controller.rb
module Api
  module V1
    module MyPlugin
      class ItemsController < Api::V1::BaseController
        def index
          items = fetch_items
          render json: { items: items }
        end
        
        def create
          item = create_item(params[:item])
          render json: { item: item }, status: :created
        end
      end
    end
  end
end
```

---

## Complete Examples

### Example 1: Simple Dashboard Plugin

```ruby
class DashboardPlugin < Railspress::PluginBase
  plugin_name 'Dashboard Plugin'
  
  def setup
    register_routes do
      namespace :admin do
        namespace :dashboard_plugin do
          get 'stats', to: 'stats#index'
          get 'charts', to: 'charts#show'
        end
      end
    end
  end
end
```

### Example 2: Public API Plugin

```ruby
class WeatherPlugin < Railspress::PluginBase
  plugin_name 'Weather Plugin'
  
  def setup
    register_routes do
      # Public endpoints
      get '/weather/current', to: 'weather#current'
      get '/weather/forecast', to: 'weather#forecast'
      
      # Admin configuration
      namespace :admin do
        namespace :weather do
          get 'settings', to: 'settings#index'
          patch 'settings', to: 'settings#update'
        end
      end
    end
  end
end
```

### Example 3: Full CRUD Resource

```ruby
class ProductsPlugin < Railspress::PluginBase
  plugin_name 'Products Plugin'
  
  def setup
    register_routes do
      # Admin CRUD
      namespace :admin do
        resources :products do
          member do
            patch :publish
            patch :unpublish
          end
          collection do
            post :bulk_action
          end
        end
      end
      
      # Public product pages
      get '/products', to: 'products#index'
      get '/products/:slug', to: 'products#show'
      
      # API
      namespace :api do
        namespace :v1 do
          resources :products, only: [:index, :show]
        end
      end
    end
  end
end
```

### Example 4: Webhook Handler

```ruby
class WebhookPlugin < Railspress::PluginBase
  plugin_name 'Webhook Plugin'
  
  def setup
    register_routes do
      # Webhook endpoints
      post '/webhooks/stripe', to: 'webhooks#stripe'
      post '/webhooks/github', to: 'webhooks#github'
      post '/webhooks/custom/:id', to: 'webhooks#custom'
      
      # Admin management
      namespace :admin do
        namespace :webhooks do
          resources :endpoints
          get 'logs', to: 'logs#index'
        end
      end
    end
  end
end
```

---

## Advanced Routing

### Constraints

```ruby
register_routes do
  get '/premium-content', 
    to: 'premium#show',
    constraints: lambda { |req| req.session[:premium_user] }
end
```

### Route Parameters

```ruby
register_routes do
  get '/items/:category/:id', to: 'items#show'
  get '/archive/:year/:month', to: 'archive#show'
end
```

### Custom Route Names

```ruby
register_routes do
  get '/special-page', to: 'special#show', as: 'my_plugin_special'
end

# Use in views:
<%= link_to 'Special Page', my_plugin_special_path %>
```

### Nested Resources

```ruby
register_routes do
  namespace :admin do
    resources :categories do
      resources :items
    end
  end
end
```

### Subdomain Routes

```ruby
register_routes do
  constraints subdomain: 'api' do
    namespace :api do
      get '/status', to: 'status#show'
    end
  end
end
```

---

## Controller Organization

### Recommended Structure

```
lib/plugins/my_plugin/
├── my_plugin.rb                    # Main plugin file
├── controllers/
│   ├── admin/
│   │   └── my_plugin/
│   │       ├── dashboard_controller.rb
│   │       ├── settings_controller.rb
│   │       └── items_controller.rb
│   ├── api/
│   │   └── v1/
│   │       └── my_plugin/
│   │           └── items_controller.rb
│   └── my_plugin/
│       └── public_controller.rb
├── views/
│   ├── admin/
│   │   └── my_plugin/
│   │       ├── dashboard/
│   │       │   └── index.html.erb
│   │       └── settings/
│   │           └── index.html.erb
│   └── my_plugin/
│       └── public/
│           └── index.html.erb
└── assets/
    ├── javascripts/
    └── stylesheets/
```

### Autoloading Controllers

RailsPress automatically loads plugin controllers if placed in:
- `lib/plugins/your_plugin/controllers/`

Add to your plugin's initialization:

```ruby
def setup
  # Add plugin controllers to autoload paths
  controller_path = File.expand_path('../controllers', __FILE__)
  Rails.application.config.paths['app/controllers'] << controller_path if Dir.exist?(controller_path)
  
  register_routes do
    # Your routes
  end
end
```

---

## Route Helpers

### Using Route Helpers

Routes registered by plugins generate standard Rails helpers:

```ruby
register_routes do
  namespace :admin do
    namespace :my_plugin do
      get 'dashboard', to: 'dashboard#index', as: 'dashboard'
    end
  end
end

# In views:
<%= link_to 'Dashboard', admin_my_plugin_dashboard_path %>
```

### Accessing Plugin Routes

```ruby
# In your plugin
def some_method
  # Use Rails.application.routes.url_helpers
  Rails.application.routes.url_helpers.admin_my_plugin_dashboard_path
end
```

---

## Middleware and Filters

### Adding Middleware to Plugin Routes

```ruby
class MyPlugin < Railspress::PluginBase
  def setup
    register_routes do
      scope module: 'my_plugin' do
        get '/protected', to: 'protected#show'
      end
    end
    
    # Add custom middleware
    add_middleware_for_routes
  end
  
  private
  
  def add_middleware_for_routes
    Rails.application.config.middleware.use MyPlugin::CustomMiddleware
  end
end
```

---

## Testing Plugin Routes

### Request Specs

```ruby
require 'rails_helper'

RSpec.describe "MyPlugin Routes", type: :request do
  it "responds to dashboard" do
    get '/admin/my_plugin/dashboard'
    expect(response).to have_http_status(200)
  end
  
  it "responds to API endpoint" do
    post '/api/v1/my_plugin/items', params: { item: { name: 'Test' } }
    expect(response).to have_http_status(:created)
  end
end
```

### Integration Tests

```ruby
require 'test_helper'

class MyPluginRoutesTest < ActionDispatch::IntegrationTest
  test "admin dashboard accessible" do
    sign_in users(:admin)
    get '/admin/my_plugin/dashboard'
    assert_response :success
  end
  
  test "public page accessible" do
    get '/my-plugin'
    assert_response :success
  end
end
```

---

## Debugging Routes

### List All Plugin Routes

```bash
rails routes | grep my_plugin
```

### Check Registered Routes

```ruby
# In Rails console
Railspress::PluginSystem.all_plugin_routes
```

### Verify Route Exists

```ruby
# In Rails console
Rails.application.routes.recognize_path('/admin/my_plugin/dashboard')
```

---

## Common Patterns

### RESTful Resource

```ruby
register_routes do
  namespace :admin do
    resources :products do
      member do
        post :duplicate
        patch :publish
      end
      collection do
        get :export
        post :import
      end
    end
  end
end
```

### Namespaced Routes

```ruby
register_routes do
  namespace :admin do
    namespace :my_plugin do
      root to: 'dashboard#index'
      
      resources :items
      resources :categories
      
      get 'settings', to: 'settings#show'
      patch 'settings', to: 'settings#update'
    end
  end
end
```

### Catch-All Routes

```ruby
register_routes do
  # Must be last in your routes
  get '/my-plugin/*path', to: 'my_plugin#catch_all'
end
```

---

## Integration with Admin Menu

Combine routes with admin pages for seamless integration:

```ruby
def setup
  # Register admin page (adds to sidebar)
  register_admin_page(
    slug: 'dashboard',
    title: 'My Plugin Dashboard',
    menu_title: 'Dashboard',
    icon: 'chart'
  )
  
  # Register the route to handle the page
  register_routes do
    namespace :admin do
      namespace :my_plugin do
        get 'dashboard', to: 'dashboard#index'
      end
    end
  end
end
```

The admin page registration creates a sidebar link that points to the route!

---

## Security Considerations

### Authentication

```ruby
# Use Admin::BaseController for protected routes
class Admin::MyPlugin::DashboardController < Admin::BaseController
  # Automatically requires authentication and admin access
end
```

### Authorization

```ruby
class Admin::MyPlugin::SettingsController < Admin::BaseController
  before_action :ensure_admin # Only administrators
  
  def index
    # Settings logic
  end
end
```

### CSRF Protection

```ruby
# For API routes, skip CSRF
class Api::V1::MyPlugin::ItemsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_api_user!
end
```

---

## Route Conflicts

### Avoiding Conflicts

1. **Always namespace your routes:**
   ```ruby
   # Good
   namespace :admin do
     namespace :my_plugin do
       get 'dashboard'
     end
   end
   
   # Bad - might conflict with other plugins
   get 'dashboard'
   ```

2. **Use unique prefixes:**
   ```ruby
   get '/my-unique-plugin/page', to: 'controller#action'
   ```

3. **Check for conflicts:**
   ```bash
   rails routes | grep "path_pattern"
   ```

---

## Dynamic Routes

### Routes Based on Settings

```ruby
def setup
  register_routes do
    if get_setting(:enable_public_api, false)
      namespace :api do
        namespace :v1 do
          resources :plugin_items
        end
      end
    end
    
    if get_setting(:enable_admin_dashboard, true)
      namespace :admin do
        get 'plugin-dashboard', to: 'plugin#dashboard'
      end
    end
  end
end
```

### Conditional Routes

```ruby
register_routes do
  if Rails.env.development?
    namespace :admin do
      get 'debug', to: 'debug#show'
    end
  end
end
```

---

## Full Plugin Example

```ruby
class AdvancedRoutingPlugin < Railspress::PluginBase
  plugin_name 'Advanced Routing Plugin'
  plugin_version '1.0.0'
  
  def setup
    # Register comprehensive routes
    register_routes do
      # ==================
      # ADMIN ROUTES
      # ==================
      namespace :admin do
        namespace :advanced_routing do
          # Dashboard
          root to: 'dashboard#index', as: 'dashboard'
          
          # Resources
          resources :items do
            member do
              post :duplicate
              patch :publish
              patch :archive
            end
            
            collection do
              get :export
              post :import
              post :bulk_action
            end
          end
          
          resources :categories, only: [:index, :create, :update, :destroy]
          
          # Settings
          get 'settings', to: 'settings#show'
          patch 'settings', to: 'settings#update'
          
          # Reports
          get 'reports', to: 'reports#index'
          get 'reports/:type', to: 'reports#show', as: 'report'
          
          # Tools
          post 'tools/sync', to: 'tools#sync'
          post 'tools/cleanup', to: 'tools#cleanup'
        end
      end
      
      # ==================
      # PUBLIC ROUTES
      # ==================
      scope module: 'advanced_routing' do
        get '/showcase', to: 'public#showcase'
        get '/showcase/:id', to: 'public#item'
        post '/showcase/:id/vote', to: 'public#vote'
      end
      
      # ==================
      # API ROUTES
      # ==================
      namespace :api do
        namespace :v1 do
          namespace :advanced_routing do
            # Items API
            resources :items, only: [:index, :show, :create, :update, :destroy] do
              collection do
                get 'search', to: 'items#search'
                get 'featured', to: 'items#featured'
              end
            end
            
            # Custom endpoints
            post 'process', to: 'processor#process'
            get 'status', to: 'status#show'
            get 'health', to: 'health#check'
          end
        end
      end
      
      # ==================
      # WEBHOOKS
      # ==================
      post '/webhooks/advanced-routing/:event', to: 'webhooks#handle'
    end
    
    # Register corresponding admin pages
    register_admin_page(
      slug: 'dashboard',
      title: 'Advanced Routing Dashboard',
      callback: :render_dashboard
    )
    
    register_admin_page(
      slug: 'settings',
      title: 'Advanced Routing Settings',
      callback: :render_settings
    )
  end
  
  def render_dashboard
    {
      title: 'Dashboard',
      stats: {
        total_items: 100,
        active_items: 75
      }
    }
  end
  
  def render_settings
    {
      title: 'Settings',
      settings: @settings_schema
    }
  end
end
```

---

## Mounting Rack Apps

### Mount External Apps

```ruby
register_routes do
  mount MyPlugin::RackApp.new, at: '/my-plugin'
end
```

### Example Rack App

```ruby
module MyPlugin
  class RackApp
    def call(env)
      request = Rack::Request.new(env)
      
      case request.path_info
      when '/status'
        [200, {'Content-Type' => 'application/json'}, [{ status: 'ok' }.to_json]]
      else
        [404, {'Content-Type' => 'text/plain'}, ['Not Found']]
      end
    end
  end
end
```

---

## Route Reloading

### Development Mode

Routes are automatically reloaded when:
- Plugin is activated/deactivated
- Server is restarted

### Manual Reload

```ruby
# In Rails console
Railspress::PluginSystem.reload_routes!
Rails.application.reload_routes!
```

---

## Best Practices

### 1. Always Use Namespaces

```ruby
# Good
namespace :admin do
  namespace :my_plugin do
    get 'dashboard'
  end
end

# Bad - potential conflicts
get '/admin/dashboard'
```

### 2. Follow RESTful Conventions

```ruby
resources :items # instead of custom actions for each CRUD operation
```

### 3. Use Descriptive Names

```ruby
# Good
get 'export-csv', to: 'export#csv', as: 'export_csv'

# Bad
get 'exp', to: 'e#c', as: 'ec'
```

### 4. Document Your Routes

```ruby
register_routes do
  # ==================
  # ADMIN DASHBOARD
  # Provides analytics and reporting
  # ==================
  namespace :admin do
    get 'analytics', to: 'analytics#index'
  end
end
```

### 5. Handle Errors Gracefully

```ruby
class MyController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  
  private
  
  def not_found
    render json: { error: 'Not found' }, status: 404
  end
end
```

---

## Troubleshooting

### Route Not Found

1. Check if plugin is active
2. Verify route registration in `setup` method
3. Check Rails routes: `rails routes | grep my_plugin`
4. Restart server to reload routes

### Controller Not Found

1. Check controller file location
2. Ensure proper namespacing
3. Check class name matches route
4. Verify autoload paths include plugin controllers

### Permission Denied

1. Check controller inherits from correct base class
2. Verify user has required capability
3. Check before_action filters

---

## Resources

- [Admin Pages Guide](admin-pages.md)
- [Form Builder](FORM_BUILDER.md)
- [Plugin Architecture](architecture.md)
- [Rails Routing Guide](https://guides.rubyonrails.org/routing.html)

---

Built with ❤️ for RailsPress



