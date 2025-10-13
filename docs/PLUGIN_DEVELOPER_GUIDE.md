# RailsPress Plugin Developer Guide

## 🚀 The Most Powerful Plugin System Ever Built

Welcome to RailsPress - the plugin system that developers will absolutely love! This guide covers everything you need to know to create amazing plugins that integrate seamlessly with RailsPress.

## 📋 Table of Contents

1. [Getting Started](#getting-started)
2. [Plugin Structure](#plugin-structure)
3. [Core Features](#core-features)
4. [Advanced Features](#advanced-features)
5. [Security & Best Practices](#security--best-practices)
6. [Examples](#examples)
7. [API Reference](#api-reference)

## 🎯 Getting Started

### Creating Your First Plugin

```ruby
# lib/plugins/my_awesome_plugin/my_awesome_plugin.rb
module MyAwesomePlugin
  class MyAwesomePlugin < Railspress::PluginBase
    plugin_name 'My Awesome Plugin'
    plugin_version '1.0.0'
    plugin_description 'The most awesome plugin ever created'
    plugin_author 'Your Name'
    plugin_url 'https://github.com/yourname/my-awesome-plugin'
    plugin_license 'MIT'

    def setup
      # Your plugin initialization code here
      register_settings
      register_admin_pages
      register_routes
    end

    private

    def register_settings
      add_setting :api_key, :string, 'API Key', 'Your service API key'
      add_setting :enabled, :boolean, 'Enable Plugin', 'Enable this plugin', true
    end

    def register_admin_pages
      add_admin_page 'My Plugin', 'my-plugin', 'My Awesome Plugin Settings'
    end
    end
  end
end
```

## 🏗️ Plugin Structure

```
lib/plugins/your_plugin/
├── your_plugin.rb                 # Main plugin file
├── controllers/                   # Plugin controllers
│   ├── admin/                     # Admin controllers
│   └── plugins/                   # Public controllers
├── models/                        # Plugin models
├── views/                         # Plugin views
│   ├── admin/                     # Admin views
│   └── plugins/                   # Public views
├── assets/                        # CSS, JS, images
├── migrations/                    # Database migrations
├── jobs/                          # Background jobs
├── middleware/                    # Custom middleware
└── specs/                         # Tests
```

## 🔧 Core Features

### 1. Settings Management

```ruby
# Register settings with validation
add_setting :api_key, :string, 'API Key', 'Your service API key'
add_setting :max_requests, :integer, 'Max Requests', 'Maximum requests per hour', 100
add_setting :enabled, :boolean, 'Enable Plugin', 'Enable this plugin', true

# Access settings
api_key = get_setting(:api_key)
max_requests = get_setting(:max_requests, 100)

# Update settings
set_setting(:api_key, 'new-key-value')
```

### 2. Admin Pages

```ruby
# Add admin page
add_admin_page 'Plugin Name', 'plugin-slug', 'Plugin Description'

# Add admin page with custom renderer
add_admin_page 'Advanced Settings', 'advanced', 'Advanced plugin settings' do
  # Custom rendering logic
  render 'admin/my_plugin/advanced'
end
```

### 3. Secure Route System

```ruby
# Admin routes (automatically scoped under /admin)
register_admin_routes do
  namespace :my_plugin do
    resources :items do
      member do
        post :activate
        post :deactivate
      end
      collection do
        post :bulk_action
        get :export
      end
    end
  end
end

# Frontend routes (automatically scoped under /plugins)
register_frontend_routes do
  # Public API endpoints
  post 'api/submit', to: 'my_plugin/api#submit'
  get 'widget/:id', to: 'my_plugin/widgets#show'
end
```

### 4. Background Jobs

```ruby
# Create background job
create_job 'DataProcessorJob' do
  def perform(data_id)
    # Process data asynchronously
    data = MyModel.find(data_id)
    data.process!
  end
end

# Schedule recurring job
schedule_recurring_job 'CleanupJob', '0 2 * * *' do
  # Run daily at 2 AM
  MyModel.cleanup_old_records
end
```

## 🚀 Advanced Features

### 1. Webhook System

```ruby
# Register webhooks for external integrations
register_webhook('user.registered', 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK', {
  method: 'POST',
  headers: { 'Content-Type' => 'application/json' },
  secret: 'your-webhook-secret',
  retry_count: 3,
  timeout: 30
})

register_webhook('payment.completed', 'https://api.stripe.com/webhooks', {
  method: 'POST',
  secret: Rails.application.credentials.stripe_webhook_secret
})

# Trigger webhooks
trigger_webhook('user.registered', {
  user: user_data,
  timestamp: Time.current
})
```

### 2. Event System

```ruby
# Listen for events
on('user.registered') do |data|
  log("New user registered: #{data[:user][:email]}", :info)
  notify_admin("New user registration", :success, { user: data[:user] })
end

on('payment.failed') do |data|
  log("Payment failed: #{data[:error]}", :error)
  notify_user(data[:user_id], "Payment failed", :error)
end

on('plugin.activated') do |data|
  # Plugin-specific activation logic
  setup_plugin_data
end

# Emit events
emit('custom.event', { custom_data: 'value' })
```

### 3. Asset Management

```ruby
# Register CSS assets
register_stylesheet('my_plugin.css', { admin_only: true })
register_stylesheet('my_plugin_frontend.css', { frontend_only: true })

# Register JavaScript assets
register_javascript('my_plugin.js', { admin_only: true })
register_javascript('my_plugin_frontend.js', { frontend_only: true })

# Register images
register_image('logo.png', { public: true })

# Assets with dependencies and priority
register_stylesheet('advanced.css', {
  admin_only: true,
  priority: 20,
  dependencies: ['bootstrap']
})
```

### 4. API Endpoints

```ruby
# Register REST API endpoints
register_api_endpoint('GET', 'users', { 
  controller: 'api/my_plugin/users', 
  action: 'index' 
}, {
  authentication: :token,
  rate_limit: 100,
  version: 'v1'
})

register_api_endpoint('POST', 'process', { 
  controller: 'api/my_plugin/processor', 
  action: 'create' 
}, {
  authentication: :api_key,
  rate_limit: 50
})

# API routes automatically become:
# GET /api/my_plugin/users
# POST /api/my_plugin/process
```

### 5. Theme Integration

```ruby
# Register theme templates
register_theme_template('contact_form', <<~LIQUID, { type: :page })
  <div class="my-plugin-form">
    <h2>{{ form.title }}</h2>
    <form action="/plugins/my_plugin/submit" method="post">
      {% for field in form.fields %}
        <div class="form-field">
          <label>{{ field.label }}</label>
          <input type="{{ field.type }}" name="{{ field.name }}" required="{{ field.required }}">
        </div>
      {% endfor %}
      <button type="submit">Submit</button>
    </form>
  </div>
LIQUID

# Register theme settings
register_theme_setting('form_style', :select, {
  label: 'Form Style',
  description: 'Choose the form styling',
  default: 'modern',
  options: { 'modern' => 'Modern', 'classic' => 'Classic' }
})

register_theme_setting('show_labels', :boolean, {
  label: 'Show Field Labels',
  description: 'Display field labels above inputs',
  default: true
})
```

### 6. Custom Validators

```ruby
# Register custom validators
register_validator('email_domain') do |email|
  allowed_domains = get_setting(:allowed_email_domains, []).split(',')
  return true if allowed_domains.empty?
  
  domain = email.split('@').last
  allowed_domains.include?(domain.strip)
end

register_validator('strong_password') do |password|
  return false if password.length < 8
  return false unless password.match?(/[A-Z]/)  # Uppercase
  return false unless password.match?(/[a-z]/)  # Lowercase
  return false unless password.match?(/\d/)     # Number
  return false unless password.match?(/[^A-Za-z0-9]/)  # Special char
  true
end

# Use in your models
validates :email, with: -> { validate_with_plugin('email_domain') }
validates :password, with: -> { validate_with_plugin('strong_password') }
```

### 7. Custom Commands

```ruby
# Register custom rake tasks
register_command('cleanup', 'Clean up old records') do
  cutoff_date = 6.months.ago
  deleted_count = MyModel.where('created_at < ?', cutoff_date).delete_all
  puts "Cleaned up #{deleted_count} old records"
end

register_command('stats', 'Show plugin statistics') do
  total_records = MyModel.count
  active_records = MyModel.where(active: true).count
  
  puts "=== My Plugin Statistics ==="
  puts "Total Records: #{total_records}"
  puts "Active Records: #{active_records}"
end

# Run with: rails my_plugin:cleanup
# Run with: rails my_plugin:stats
```

### 8. Middleware Support

```ruby
# Add custom middleware
add_middleware(MyPlugin::AuthenticationMiddleware)
add_middleware(MyPlugin::RateLimitMiddleware, max_requests: 100)
add_middleware(MyPlugin::AnalyticsMiddleware) do |request|
  # Custom middleware logic
  track_request(request)
end
```

### 9. Notification System

```ruby
# Send notifications to admins
notify_admin("Plugin activated successfully", :success, { 
  plugin: name,
  timestamp: Time.current 
})

notify_admin("Critical error occurred", :error, { 
  error: error_message,
  stack_trace: error.backtrace 
})

# Send notifications to specific users
notify_user(user_id, "Your data has been processed", :info, { 
  processing_time: duration 
})
```

### 10. Cache System

```ruby
# Plugin-specific caching
cache('user_stats', { total: 100, active: 80 }, expires_in: 1.hour)

# Retrieve cached data
stats = cache('user_stats')

# Clear plugin cache
clear_cache('user_stats')
clear_cache  # Clear all plugin cache
```

### 11. Database Helpers

```ruby
# Create plugin tables
create_table('my_plugin_data') do |t|
  t.string :name
  t.text :description
  t.json :metadata
  t.boolean :active, default: true
  t.timestamps
end

# Add columns to existing tables
add_column('my_plugin_data', 'priority', :integer, default: 0)
add_column('my_plugin_data', 'tags', :json, default: [])
```

### 12. Scheduler System

```ruby
# Schedule recurring tasks with cron expressions
schedule_task('cleanup_spam', '0 2 * * *') do
  # Clean up spam records daily at 2 AM
  cutoff_date = 30.days.ago
  spam_count = MyModel.where(spam: true, created_at: ...cutoff_date).delete_all
  log("Cleaned up #{spam_count} old spam records", :info)
end

schedule_task('generate_reports', '0 8 * * 1') do
  # Generate weekly reports every Monday at 8 AM
  week_start = 1.week.ago.beginning_of_day
  week_end = Time.current.end_of_day
  
  data = MyModel.where(created_at: week_start..week_end)
  
  notify_admin("Weekly Report: #{data.count} records processed", :info, {
    period: 'weekly',
    count: data.count
  })
end
```

## 🛡️ Security & Best Practices

### 1. Route Security

- **Admin routes** are automatically scoped under `/admin` and require authentication
- **Frontend routes** are scoped under `/plugins` and are public by default
- **API routes** support multiple authentication methods (token, api_key, oauth)

### 2. Input Validation

```ruby
# Always validate user input
def process_submission(data)
  return false unless validate_input(data)
  
  # Process safely
  save_data(data)
end

private

def validate_input(data)
  return false if data.blank?
  return false unless data[:email].present?
  return false unless valid_email?(data[:email])
  true
end
```

### 3. Error Handling

```ruby
# Always handle errors gracefully
def safe_operation
  begin
    risky_operation
  rescue => e
    log("Operation failed: #{e.message}", :error)
    notify_admin("Plugin error", :error, { error: e.message })
    false
  end
end
```

### 4. Logging

```ruby
# Use the built-in logging system
log("User registered successfully", :info)
log("API request failed", :warn)
log("Critical error occurred", :error)
```

## 📚 Examples

### Complete E-commerce Plugin

```ruby
module EcommercePlugin
  class EcommercePlugin < Railspress::PluginBase
    plugin_name 'E-commerce Plugin'
    plugin_version '2.0.0'
    plugin_description 'Complete e-commerce solution'
    plugin_author 'Your Company'

    def setup
      register_settings
      register_admin_pages
      register_routes
      register_webhooks
      register_events
      register_assets
      register_api_endpoints
      register_theme_templates
      register_validators
      register_commands
      schedule_tasks
    end

    private

    def register_settings
      add_setting :stripe_public_key, :string, 'Stripe Public Key', 'Your Stripe public key'
      add_setting :stripe_secret_key, :string, 'Stripe Secret Key', 'Your Stripe secret key'
      add_setting :currency, :string, 'Currency', 'Default currency', 'USD'
      add_setting :tax_rate, :decimal, 'Tax Rate', 'Default tax rate (%)', 8.5
    end

    def register_admin_pages
      add_admin_page 'E-commerce', 'ecommerce', 'E-commerce Settings'
      add_admin_page 'Orders', 'orders', 'Manage Orders'
      add_admin_page 'Products', 'products', 'Manage Products'
    end

    def register_routes
      register_admin_routes do
        namespace :ecommerce do
          resources :products do
            member do
              post :toggle_active
            end
          end
          
          resources :orders do
            member do
              post :fulfill
              post :cancel
            end
            collection do
              get :export
            end
          end
        end
      end

      register_frontend_routes do
        get 'products', to: 'ecommerce/products#index'
        get 'products/:id', to: 'ecommerce/products#show'
        post 'cart/add', to: 'ecommerce/cart#add'
        post 'checkout', to: 'ecommerce/checkout#create'
      end
    end

    def register_webhooks
      register_webhook('order.created', 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK')
      register_webhook('payment.completed', 'https://api.stripe.com/webhooks', {
        secret: Rails.application.credentials.stripe_webhook_secret
      })
    end

    def register_events
      on('order.created') do |data|
        notify_admin("New order received: #{data[:order][:id]}", :success)
        trigger_webhook('order.created', data)
      end

      on('payment.completed') do |data|
        order = Order.find(data[:order_id])
        order.mark_as_paid!
        notify_user(order.user_id, "Payment successful", :success)
      end
    end

    def register_assets
      register_stylesheet('ecommerce.css', { admin_only: true })
      register_javascript('ecommerce.js', { admin_only: true })
      register_stylesheet('ecommerce_frontend.css', { frontend_only: true })
      register_javascript('ecommerce_frontend.js', { frontend_only: true })
    end

    def register_api_endpoints
      register_api_endpoint('GET', 'products', { 
        controller: 'api/ecommerce/products', 
        action: 'index' 
      }, { authentication: :token })

      register_api_endpoint('POST', 'orders', { 
        controller: 'api/ecommerce/orders', 
        action: 'create' 
      }, { authentication: :api_key })
    end

    def register_theme_templates
      register_theme_template('product_grid', <<~LIQUID, { type: :page })
        <div class="product-grid">
          {% for product in products %}
            <div class="product-card">
              <img src="{{ product.image_url }}" alt="{{ product.name }}">
              <h3>{{ product.name }}</h3>
              <p class="price">${{ product.price }}</p>
              <button onclick="addToCart({{ product.id }})">Add to Cart</button>
            </div>
          {% endfor %}
        </div>
      LIQUID
    end

    def register_validators
      register_validator('valid_sku') do |sku|
        return false if sku.blank?
        return false unless sku.match?(/^[A-Z0-9-]+$/)
        return false if sku.length < 3 || sku.length > 20
        true
      end
    end

    def register_commands
      register_command('sync_inventory', 'Sync inventory with external system') do
        # Sync logic here
        puts "Inventory synced successfully"
      end

      register_command('generate_reports', 'Generate sales reports') do
        # Report generation logic
        puts "Reports generated successfully"
      end
    end

    def schedule_tasks
      schedule_task('sync_inventory', '0 */6 * * *') do
        # Sync inventory every 6 hours
        sync_with_external_system
      end

      schedule_task('cleanup_old_carts', '0 1 * * *') do
        # Clean up abandoned carts daily
        Cart.where('updated_at < ?', 7.days.ago).delete_all
      end
    end
  end
end
```

## 📖 API Reference

### PluginBase Methods

#### Core Methods
- `plugin_name(name)` - Set plugin name
- `plugin_version(version)` - Set plugin version
- `plugin_description(description)` - Set plugin description
- `plugin_author(author)` - Set plugin author
- `plugin_url(url)` - Set plugin URL
- `plugin_license(license)` - Set plugin license

#### Settings
- `add_setting(key, type, label, description, default = nil)`
- `get_setting(key, default = nil)`
- `set_setting(key, value)`

#### Admin Pages
- `add_admin_page(title, slug, description, &block)`

#### Routes
- `register_admin_routes(&block)`
- `register_frontend_routes(&block)`

#### Background Jobs
- `create_job(name, &block)`
- `schedule_recurring_job(name, schedule, &block)`

#### Enhanced Features
- `register_webhook(event, url, options = {})`
- `trigger_webhook(event, data = {})`
- `on(event, &block)`
- `emit(event, data = {})`
- `add_middleware(middleware_class, *args, &block)`
- `register_asset(path, type, options = {})`
- `register_stylesheet(path, options = {})`
- `register_javascript(path, options = {})`
- `register_api_endpoint(method, path, controller_action, options = {})`
- `register_theme_template(name, content, options = {})`
- `register_theme_setting(key, type, options = {})`
- `register_validator(name, &block)`
- `register_command(name, description, &block)`
- `schedule_task(name, cron_expression, &block)`
- `cache(key, data = nil, expires_in: 1.hour)`
- `clear_cache(pattern = nil)`
- `notify_admin(message, type, options = {})`
- `notify_user(user_id, message, type, options = {})`
- `create_table(table_name, &block)`
- `add_column(table_name, column_name, type, options = {})`

#### Utility Methods
- `plugin_path` - Get plugin root path
- `plugin_url(path = '')` - Get plugin public URL
- `admin_url(path = '')` - Get plugin admin URL
- `feature_enabled?(feature_name)` - Check if feature is enabled
- `set_feature(feature_name, enabled)` - Enable/disable feature

## 🎉 Conclusion

The RailsPress plugin system is designed to be the most powerful and developer-friendly plugin system ever created. With features like webhooks, events, asset management, API endpoints, theme integration, custom validators, commands, middleware, and much more, you can build virtually anything.

The system is:
- **Secure** - Automatic route isolation and authentication
- **Powerful** - Every feature a developer could want
- **Flexible** - Supports any type of plugin
- **Well-documented** - Comprehensive guides and examples
- **Production-ready** - Battle-tested and reliable

Start building amazing plugins today! 🚀
