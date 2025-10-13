# Plugin Quick Start Guide

Get started with RailsPress plugin development in minutes!

## 🚀 Quick Start (5 minutes)

### 1. Generate Plugin

```bash
rails generate plugin MyAwesomePlugin --full --author="Your Name" --description="My awesome plugin"
```

This creates:
- ✅ Plugin class with settings, routes, and hooks
- ✅ Admin controller with full CRUD
- ✅ Frontend controller
- ✅ ActiveRecord models
- ✅ Admin and frontend views
- ✅ Asset files (CSS/JS)
- ✅ Background jobs
- ✅ Tests
- ✅ README

### 2. Run Migrations

```bash
rails db:migrate
```

### 3. Install & Activate

```bash
# Install plugin (create database record)
rails plugin:install NAME=MyAwesomePlugin

# Activate plugin
rails plugin:activate NAME=MyAwesomePlugin
```

### 4. Restart Server

```bash
# Stop server (Ctrl+C)
# Start server
rails server
```

### 5. Access Your Plugin

- **Admin**: http://localhost:3000/admin/my_awesome_plugin/items
- **Frontend**: http://localhost:3000/plugins/my_awesome_plugin/items
- **Settings**: http://localhost:3000/admin/plugins

## 📁 Generated Structure

```
lib/plugins/my_awesome_plugin/
├── my_awesome_plugin.rb              # Main plugin class
├── assets/
│   ├── stylesheets/
│   │   ├── my_awesome_plugin.css              # Admin CSS
│   │   └── my_awesome_plugin_frontend.css     # Frontend CSS
│   └── javascripts/
│       ├── my_awesome_plugin.js               # Admin JS
│       └── my_awesome_plugin_frontend.js      # Frontend JS
└── README.md

app/
├── models/
│   └── my_awesome_plugin_item.rb     # ActiveRecord model
├── controllers/
│   ├── admin/my_awesome_plugin/
│   │   └── items_controller.rb       # Admin CRUD
│   └── plugins/my_awesome_plugin/
│       └── items_controller.rb       # Frontend display
├── views/
│   ├── admin/my_awesome_plugin/items/
│   │   ├── index.html.erb
│   │   ├── new.html.erb
│   │   ├── edit.html.erb
│   │   └── _form.html.erb
│   └── plugins/my_awesome_plugin/items/
│       ├── index.html.erb
│       └── show.html.erb
└── jobs/
    └── my_awesome_plugin_job.rb
```

## 🎯 Common Tasks

### Add a Setting

```ruby
# In lib/plugins/my_awesome_plugin/my_awesome_plugin.rb
def setup
  define_setting :api_key,
    type: 'string',
    label: 'API Key',
    description: 'Your API key',
    required: true
end
```

### Add an Admin Page

```ruby
register_admin_page(
  slug: 'analytics',
  title: 'Analytics Dashboard',
  menu_title: 'Analytics',
  icon: 'chart-bar',
  callback: :render_analytics
)

def render_analytics
  <<~HTML
    <div class="space-y-6">
      <h1 class="text-2xl font-bold text-white">Analytics</h1>
      <!-- Your content here -->
    </div>
  HTML
end
```

### Add a Route

```ruby
# Admin route (automatically scoped to /admin/my_awesome_plugin)
register_admin_routes do
  resources :reports
  get 'export', to: 'reports#export'
end

# Frontend route (automatically scoped to /plugins/my_awesome_plugin)
register_frontend_routes do
  get 'search', to: 'items#search'
  post 'submit', to: 'items#submit'
end
```

### Create a Background Job

```ruby
# In plugin setup
schedule_task('daily_report', '0 8 * * *') do
  # Send daily report
  MyAwesomePluginMailer.daily_report.deliver_later
end
```

### Add a Webhook

```ruby
# In plugin setup
register_webhook('item.created', 'https://hooks.slack.com/...', {
  method: 'POST',
  headers: { 'Content-Type' => 'application/json' }
})

# Trigger webhook in controller
def create
  @item = MyAwesomePluginItem.new(item_params)
  if @item.save
    trigger_webhook('item.created', { item: @item.to_liquid })
    redirect_to @item
  end
end
```

### Listen for Events

```ruby
# In plugin setup
on('user.registered') do |data|
  # Do something when user registers
  log("New user: #{data[:user][:email]}")
  notify_admin("New user registered", :info)
end

# Emit custom event
emit('item.viewed', { item_id: @item.id, user: current_user })
```

### Add Database Table

```ruby
def activate
  super
  
  create_plugin_migration('create_my_items') do |t|
    t.string :title, null: false
    t.text :description
    t.json :metadata, default: {}
    t.boolean :active, default: true
    t.integer :tenant_id
    t.timestamps
    
    t.index :title
    t.index :tenant_id
  end
end
```

## 🛠️ Available Commands

```bash
# Generate new plugin
rails generate plugin MyPlugin [--full] [--with-models] [--with-admin-ui]

# Install plugin (create DB record)
rails plugin:install NAME=MyPlugin

# Activate/deactivate
rails plugin:activate NAME=MyPlugin
rails plugin:deactivate NAME=MyPlugin

# List all plugins
rails plugin:list

# Show plugin info
rails plugin:info NAME=MyPlugin

# Show plugin routes
rails plugin:routes NAME=MyPlugin

# Uninstall (remove from DB)
rails plugin:uninstall NAME=MyPlugin

# Uninstall and delete files
rails plugin:uninstall NAME=MyPlugin DELETE_FILES=true
```

## 🎨 UI Components

### Admin Table

```erb
<div class="bg-[#111111] rounded-lg overflow-hidden">
  <table class="w-full">
    <thead class="bg-[#0a0a0a] border-b border-[#2a2a2a]">
      <tr>
        <th class="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase">
          Title
        </th>
        <th class="px-6 py-3 text-right text-xs font-medium text-gray-400 uppercase">
          Actions
        </th>
      </tr>
    </thead>
    <tbody class="divide-y divide-[#2a2a2a]">
      <% @items.each do |item| %>
        <tr class="hover:bg-[#1a1a1a]">
          <td class="px-6 py-4 text-white"><%= item.title %></td>
          <td class="px-6 py-4 text-right">
            <%= link_to 'Edit', edit_path(item), class: "text-blue-400" %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

### Admin Form

```erb
<div class="bg-[#111111] rounded-lg p-6">
  <%= form_with model: @item, class: "space-y-4" do |f| %>
    <div>
      <%= f.label :title, class: "block text-sm font-medium text-gray-300 mb-2" %>
      <%= f.text_field :title, 
          class: "w-full px-4 py-2 bg-[#0a0a0a] border border-[#2a2a2a] rounded-lg text-white" %>
    </div>
    
    <%= f.submit "Save", class: "btn-primary" %>
  <% end %>
</div>
```

### Stats Card

```erb
<div class="bg-[#111111] rounded-lg p-6">
  <div class="text-gray-400 text-sm mb-2">Total Items</div>
  <div class="text-3xl font-bold text-white"><%= @count %></div>
  <div class="text-sm text-green-400 mt-2">↑ 12% from last month</div>
</div>
```

## 📚 Full Documentation

- [Plugin MVC Architecture](./PLUGIN_MVC_ARCHITECTURE.md) - Complete guide to plugin structure
- [Plugin Developer Guide](./PLUGIN_DEVELOPER_GUIDE.md) - Advanced features and best practices
- [Admin Design System](./design/ADMIN_DESIGN_SYSTEM.md) - UI components and styling

## 💡 Examples

### Real-World Plugins

Check out these production-ready plugins for inspiration:

- **SlickForms** - Form builder with spam protection
  - Location: `lib/plugins/slick_forms/`
  - Models, admin UI, frontend forms, webhooks
  
- **SlickFormsPro** - Advanced form features
  - Location: `lib/plugins/slick_forms_pro/`
  - Payments, calculations, conditional logic

- **SitemapGenerator** - XML sitemap generation
  - Location: `lib/plugins/sitemap_generator/`
  - Background jobs, cron scheduling

## 🐛 Troubleshooting

### Routes Not Working

1. Make sure plugin is activated: `rails plugin:list`
2. Restart Rails server
3. Check routes: `rails plugin:routes NAME=MyPlugin`

### Controllers Not Found

Controllers must be in correct namespace:
- Admin: `Admin::MyPlugin::ItemsController`
- Frontend: `Plugins::MyPlugin::ItemsController`

### Models Not Loading

Models should be in `app/models/` with table name matching:
- Class: `MyPluginItem`
- Table: `my_plugin_items`

### Assets Not Loading

1. Register assets in plugin `setup` method
2. Place files in `lib/plugins/my_plugin/assets/`
3. Restart server

## 🎓 Best Practices

1. **Always scope by tenant** - Use `accessible_by(current_tenant)`
2. **Use strong parameters** - Prevent mass assignment vulnerabilities
3. **Add indexes** - Index foreign keys and frequently queried columns
4. **Write tests** - Test models, controllers, and business logic
5. **Document settings** - Clear labels and descriptions for all settings
6. **Handle errors gracefully** - Use proper error messages and logging
7. **Follow naming conventions** - Consistent naming makes code maintainable

## 🚀 Next Steps

1. Read [Plugin MVC Architecture](./PLUGIN_MVC_ARCHITECTURE.md)
2. Explore example plugins in `lib/plugins/`
3. Join our Discord community
4. Share your plugin!

Happy plugin development! 🎉



