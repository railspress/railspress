# Fluent Forms Pro - Dynamic Routes

This plugin uses the **RailsPress Dynamic Plugin Routes System** which means it does **NOT** modify your `config/routes.rb` file.

## How It Works

Routes are registered dynamically when the plugin is activated:

```ruby
def register_plugin_routes
  register_routes do
    # Public form routes
    get '/fluent-forms/:id', to: 'fluent_forms#show'
    post '/fluent-forms/submit', to: 'fluent_forms#submit'
    
    # Admin routes
    namespace :admin do
      resources :fluent_forms, path: 'fluent-forms' do
        # ... routes defined here
      end
    end
  end
end
```

The routes are automatically:
1. Registered when plugin activates
2. Loaded by the PluginSystem initializer
3. Appended to Rails routes dynamically
4. Available immediately without server restart

## Viewing Plugin Routes

To see all routes including plugin routes:

```bash
rails routes | grep fluent
```

Or in Rails console:

```ruby
Railspress::PluginSystem.all_plugin_routes
```

## Available Routes

### Public Routes
- `GET /fluent-forms/:id` - Display a form
- `POST /fluent-forms/submit` - Submit form data

### Admin Routes
- `GET /admin/fluent-forms` - List all forms
- `GET /admin/fluent-forms/new` - Create new form
- `POST /admin/fluent-forms` - Save new form
- `GET /admin/fluent-forms/:id/edit` - Edit form builder
- `PATCH /admin/fluent-forms/:id` - Update form
- `DELETE /admin/fluent-forms/:id` - Delete form
- `POST /admin/fluent-forms/:id/duplicate` - Duplicate form
- `POST /admin/fluent-forms/:id/toggle-status` - Publish/unpublish
- `GET /admin/fluent-forms/entries` - View entries
- `GET /admin/fluent-forms/analytics` - View analytics
- `GET /admin/fluent-forms/integrations` - Manage integrations
- `GET /admin/fluent-forms/settings` - Plugin settings

## Benefits of Dynamic Routes

✅ **No route conflicts** - Your routes.rb stays clean  
✅ **Easy uninstall** - Routes removed when plugin deactivated  
✅ **Portable** - Plugin is self-contained  
✅ **Version control friendly** - No core file modifications  
✅ **Multiple plugins** - Each plugin manages its own routes  

## Troubleshooting

If routes are not working:

1. Check plugin is activated:
   ```ruby
   Plugin.find_by(name: 'Fluent Forms Pro', active: true)
   ```

2. Restart server:
   ```bash
   rails restart
   ```

3. Check routes are registered:
   ```ruby
   Railspress::PluginSystem.all_plugin_routes.keys
   ```

4. Verify initializer loaded:
   ```ruby
   Rails.logger.info Railspress::PluginSystem.plugin_routes
   ```

