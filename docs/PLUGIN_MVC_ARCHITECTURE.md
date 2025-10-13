# Plugin MVC Architecture Guide

## Overview

RailsPress plugins follow a professional MVC (Model-View-Controller) architecture, allowing plugins to have their own:
- **Models** - Database tables and ActiveRecord models
- **Views** - Admin and frontend templates
- **Controllers** - Request handlers for admin and public routes
- **Routes** - Isolated routing namespaces
- **Assets** - JavaScript, CSS, and images
- **Jobs** - Background tasks
- **Mailers** - Email notifications

## Directory Structure

```
lib/plugins/my_plugin/
├── my_plugin.rb                      # Main plugin class (extends PluginBase)
├── models/                            # Plugin models
│   ├── my_plugin_model.rb
│   └── concerns/
│       └── my_plugin_validations.rb
├── controllers/                       # Plugin controllers
│   ├── admin/                         # Admin controllers
│   │   └── my_plugin_controller.rb
│   └── public/                        # Frontend controllers
│       └── my_plugin_controller.rb
├── views/                            # Plugin views
│   ├── admin/                        # Admin views
│   │   └── my_plugin/
│   │       ├── index.html.erb
│   │       ├── show.html.erb
│   │       ├── new.html.erb
│   │       └── edit.html.erb
│   └── public/                       # Frontend views
│       └── my_plugin/
│           └── index.html.erb
├── jobs/                             # Background jobs
│   └── my_plugin_job.rb
├── mailers/                          # Email templates
│   └── my_plugin_mailer.rb
├── assets/                           # Plugin assets
│   ├── stylesheets/
│   │   └── my_plugin.css
│   ├── javascripts/
│   │   └── my_plugin.js
│   └── images/
│       └── logo.png
├── config/                           # Plugin configuration
│   └── routes.rb                     # Optional: separate route file
└── db/                               # Database migrations
    └── migrations/
        └── 001_create_my_plugin_tables.rb

app/controllers/                      # Main app controllers (auto-loaded)
├── admin/
│   └── my_plugin/
│       ├── items_controller.rb       # Admin::MyPlugin::ItemsController
│       └── settings_controller.rb    # Admin::MyPlugin::SettingsController
└── plugins/
    └── my_plugin/
        └── items_controller.rb       # Plugins::MyPlugin::ItemsController

app/views/                            # Main app views (auto-loaded)
├── admin/
│   └── my_plugin/
│       └── items/
│           ├── index.html.erb
│           ├── show.html.erb
│           ├── new.html.erb
│           └── edit.html.erb
└── plugins/
    └── my_plugin/
        └── items/
            ├── index.html.erb
            └── show.html.erb

app/models/                           # Main app models (auto-loaded)
└── my_plugin_item.rb                 # MyPluginItem model
```

## 1. Creating Plugin Models

### Option A: Using ActiveRecord Models (Recommended)

Create models in `app/models/` (auto-loaded by Rails):

```ruby
# app/models/slick_form.rb
class SlickForm < ApplicationRecord
  # Multi-tenancy support
  acts_as_tenant(:tenant, optional: true)
  
  # Associations
  has_many :slick_form_submissions, dependent: :destroy
  belongs_to :user, optional: true
  
  # Validations
  validates :name, presence: true, uniqueness: { scope: :tenant_id }
  validates :title, presence: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }
  
  # JSON fields (Rails 7+ handles natively)
  # No need for serialize
  
  # Callbacks
  before_save :ensure_defaults
  after_create :log_creation
  
  # Instance methods
  def to_liquid
    {
      'id' => id,
      'name' => name,
      'title' => title,
      'fields' => fields,
      'submissions_count' => submissions_count
    }
  end
  
  private
  
  def ensure_defaults
    self.fields ||= []
    self.settings ||= {}
  end
  
  def log_creation
    Rails.logger.info "Created form: #{name} (ID: #{id})"
  end
end
```

### Option B: Using Plugin Database Helpers

For simple data storage without migrations:

```ruby
# In plugin setup method
def setup
  # Create table programmatically
  create_table :my_plugin_items do |t|
    t.string :title
    t.text :description
    t.boolean :active, default: true
    t.integer :tenant_id
    t.timestamps
  end
  
  # Or add column to existing table
  add_column :my_plugin_items, :priority, :integer, default: 0
end
```

### Creating Migrations

```ruby
# In plugin setup or activation method
def activate
  # Create migration
  create_plugin_migration('create_slick_forms') do |t|
    t.string :name, null: false
    t.string :title
    t.text :description
    t.json :fields, default: []
    t.json :settings, default: {}
    t.boolean :active, default: true
    t.integer :submissions_count, default: 0
    t.integer :tenant_id
    t.timestamps
    
    t.index :name
    t.index :active
    t.index :tenant_id
  end
  
  create_plugin_migration('create_slick_form_submissions') do |t|
    t.references :slick_form, null: false, foreign_key: true
    t.json :data
    t.string :ip_address
    t.string :user_agent
    t.string :referrer
    t.boolean :spam, default: false
    t.integer :tenant_id
    t.timestamps
    
    t.index :spam
    t.index :created_at
    t.index :tenant_id
  end
end
```

## 2. Creating Plugin Controllers

### Admin Controllers

Create in `app/controllers/admin/plugin_name/`:

```ruby
# app/controllers/admin/slick_forms/forms_controller.rb
class Admin::SlickForms::FormsController < Admin::BaseController
  before_action :set_form, only: [:show, :edit, :update, :destroy]
  
  # GET /admin/slick_forms/forms
  def index
    @forms = SlickForm.accessible_by(current_tenant)
                      .order(created_at: :desc)
                      .page(params[:page])
  end
  
  # GET /admin/slick_forms/forms/:id
  def show
    @submissions = @form.slick_form_submissions
                        .recent
                        .page(params[:page])
  end
  
  # GET /admin/slick_forms/forms/new
  def new
    @form = SlickForm.new
  end
  
  # POST /admin/slick_forms/forms
  def create
    @form = SlickForm.new(form_params)
    @form.tenant = current_tenant
    @form.user = current_user
    
    if @form.save
      redirect_to admin_slick_forms_form_path(@form), 
                  notice: 'Form was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  # GET /admin/slick_forms/forms/:id/edit
  def edit
  end
  
  # PATCH/PUT /admin/slick_forms/forms/:id
  def update
    if @form.update(form_params)
      redirect_to admin_slick_forms_form_path(@form),
                  notice: 'Form was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  # DELETE /admin/slick_forms/forms/:id
  def destroy
    @form.destroy
    redirect_to admin_slick_forms_forms_path,
                notice: 'Form was successfully deleted.'
  end
  
  private
  
  def set_form
    @form = SlickForm.accessible_by(current_tenant).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_slick_forms_forms_path, 
                alert: 'Form not found.'
  end
  
  def form_params
    params.require(:slick_form).permit(
      :name, :title, :description, :active,
      fields: [], settings: {}
    )
  end
end
```

### Frontend/Public Controllers

Create in `app/controllers/plugins/plugin_name/`:

```ruby
# app/controllers/plugins/slick_forms/submissions_controller.rb
class Plugins::SlickForms::SubmissionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]
  before_action :set_form, only: [:create]
  
  # POST /plugins/slick_forms/submissions
  def create
    @submission = @form.slick_form_submissions.new(submission_params)
    @submission.tenant = current_tenant
    @submission.ip_address = request.remote_ip
    @submission.user_agent = request.user_agent
    @submission.referrer = request.referrer
    
    # Spam detection
    if detect_spam(@submission)
      @submission.spam = true
    end
    
    if @submission.save
      # Trigger webhooks
      trigger_webhook('form.submitted', {
        form: @form.to_liquid,
        submission: @submission.to_liquid
      })
      
      # Send notifications
      notify_admin("New form submission: #{@form.name}", :info, {
        form_id: @form.id,
        submission_id: @submission.id
      })
      
      render json: { success: true, message: 'Form submitted successfully!' }
    else
      render json: { success: false, errors: @submission.errors.full_messages },
             status: :unprocessable_entity
    end
  end
  
  private
  
  def set_form
    @form = SlickForm.active.find(params[:form_id])
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: 'Form not found' },
           status: :not_found
  end
  
  def submission_params
    params.require(:submission).permit(data: {})
  end
  
  def detect_spam(submission)
    # Implement spam detection logic
    false
  end
end
```

## 3. Creating Plugin Views

### Admin Views

Create in `app/views/admin/plugin_name/`:

```erb
<!-- app/views/admin/slick_forms/forms/index.html.erb -->
<div class="space-y-6">
  <div class="flex items-center justify-between">
    <h1 class="text-2xl font-bold text-white">Forms</h1>
    <%= link_to new_admin_slick_forms_form_path, 
        class: "btn-primary" do %>
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
      </svg>
      New Form
    <% end %>
  </div>
  
  <!-- Stats Cards -->
  <div class="grid grid-cols-3 gap-4">
    <div class="bg-[#111111] rounded-lg p-6">
      <div class="text-gray-400 text-sm mb-2">Total Forms</div>
      <div class="text-3xl font-bold text-white"><%= @forms.total_count %></div>
    </div>
    <!-- More stats... -->
  </div>
  
  <!-- Forms Table -->
  <div class="bg-[#111111] rounded-lg overflow-hidden">
    <table class="w-full">
      <thead class="bg-[#0a0a0a] border-b border-[#2a2a2a]">
        <tr>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
            Name
          </th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
            Submissions
          </th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
            Status
          </th>
          <th class="px-6 py-3 text-right text-xs font-medium text-gray-400 uppercase tracking-wider">
            Actions
          </th>
        </tr>
      </thead>
      <tbody class="divide-y divide-[#2a2a2a]">
        <% @forms.each do |form| %>
          <tr class="hover:bg-[#1a1a1a]">
            <td class="px-6 py-4">
              <%= link_to form.title, admin_slick_forms_form_path(form),
                  class: "text-white hover:text-blue-400" %>
            </td>
            <td class="px-6 py-4 text-gray-300">
              <%= form.submissions_count %>
            </td>
            <td class="px-6 py-4">
              <% if form.active? %>
                <span class="px-2 py-1 text-xs rounded bg-green-900/20 text-green-400">
                  Active
                </span>
              <% else %>
                <span class="px-2 py-1 text-xs rounded bg-gray-700 text-gray-400">
                  Inactive
                </span>
              <% end %>
            </td>
            <td class="px-6 py-4 text-right">
              <%= link_to 'Edit', edit_admin_slick_forms_form_path(form),
                  class: "text-blue-400 hover:text-blue-300 mr-3" %>
              <%= link_to 'Delete', admin_slick_forms_form_path(form),
                  data: { turbo_method: :delete, turbo_confirm: 'Are you sure?' },
                  class: "text-red-400 hover:text-red-300" %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
  
  <!-- Pagination -->
  <%= paginate @forms %>
</div>
```

### Frontend Views

Create in `app/views/plugins/plugin_name/`:

```erb
<!-- app/views/plugins/slick_forms/forms/show.html.erb -->
<div class="max-w-2xl mx-auto p-6">
  <div class="bg-white rounded-lg shadow-lg p-8">
    <h1 class="text-3xl font-bold mb-4"><%= @form.title %></h1>
    
    <% if @form.description.present? %>
      <p class="text-gray-600 mb-6"><%= @form.description %></p>
    <% end %>
    
    <%= form_with url: plugins_slick_forms_submissions_path(form_id: @form.id),
        method: :post,
        data: { turbo: false },
        html: { class: "space-y-4" } do |f| %>
      
      <% @form.fields.each do |field| %>
        <div class="form-field">
          <%= label_tag field['name'], field['label'], class: "block text-sm font-medium text-gray-700 mb-2" %>
          
          <% case field['type'] %>
          <% when 'text', 'email' %>
            <%= text_field_tag "submission[data][#{field['name']}]", nil,
                type: field['type'],
                required: field['required'],
                placeholder: field['placeholder'],
                class: "w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500" %>
          
          <% when 'textarea' %>
            <%= text_area_tag "submission[data][#{field['name']}]", nil,
                required: field['required'],
                placeholder: field['placeholder'],
                rows: field['rows'] || 4,
                class: "w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500" %>
          
          <% when 'select' %>
            <%= select_tag "submission[data][#{field['name']}]",
                options_for_select(field['options']),
                required: field['required'],
                class: "w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500" %>
          
          <% when 'checkbox' %>
            <div class="flex items-center">
              <%= check_box_tag "submission[data][#{field['name']}]", "1",
                  false,
                  required: field['required'],
                  class: "h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded" %>
              <label class="ml-2 text-sm text-gray-700">
                <%= field['description'] %>
              </label>
            </div>
          <% end %>
          
          <% if field['description'].present? && field['type'] != 'checkbox' %>
            <p class="mt-1 text-sm text-gray-500"><%= field['description'] %></p>
          <% end %>
        </div>
      <% end %>
      
      <%= f.submit 'Submit', class: "w-full btn-primary py-3" %>
    <% end %>
  </div>
</div>
```

## 4. Registering Routes

### In Plugin Class

```ruby
class SlickForms < Railspress::PluginBase
  def setup
    # Register admin routes (automatically scoped under /admin/slick_forms)
    register_admin_routes do
      resources :forms do
        member do
          post :duplicate
          get :preview
        end
        collection do
          post :import
          get :export
        end
      end
      
      resources :submissions, only: [:index, :show, :destroy] do
        member do
          patch :mark_as_spam
          patch :mark_as_ham
        end
      end
      
      get 'settings', to: 'settings#index'
      patch 'settings', to: 'settings#update'
    end
    
    # Register frontend routes (automatically scoped under /plugins/slick_forms)
    register_frontend_routes do
      get 'forms/:id', to: 'forms#show', as: 'form'
      post 'submissions', to: 'submissions#create'
      get 'embed/:id', to: 'forms#embed', as: 'embed'
    end
  end
end
```

### Generated Routes

Admin routes:
- `GET    /admin/slick_forms/forms` → `Admin::SlickForms::FormsController#index`
- `POST   /admin/slick_forms/forms` → `Admin::SlickForms::FormsController#create`
- `GET    /admin/slick_forms/forms/:id` → `Admin::SlickForms::FormsController#show`
- `PATCH  /admin/slick_forms/forms/:id` → `Admin::SlickForms::FormsController#update`
- `DELETE /admin/slick_forms/forms/:id` → `Admin::SlickForms::FormsController#destroy`

Frontend routes:
- `GET  /plugins/slick_forms/forms/:id` → `Plugins::SlickForms::FormsController#show`
- `POST /plugins/slick_forms/submissions` → `Plugins::SlickForms::SubmissionsController#create`

## 5. Using Plugin Assets

### Registering Assets

```ruby
def setup
  # Register stylesheets
  register_stylesheet('slick_forms.css', { admin_only: true })
  register_stylesheet('slick_forms_frontend.css', { frontend_only: true })
  
  # Register JavaScripts
  register_javascript('slick_forms.js', { admin_only: true })
  register_javascript('slick_forms_frontend.js', { frontend_only: true })
  
  # Register images
  register_image('logo.png')
end
```

### Asset Locations

Place assets in plugin directory:
```
lib/plugins/slick_forms/
└── assets/
    ├── stylesheets/
    │   ├── slick_forms.css
    │   └── slick_forms_frontend.css
    ├── javascripts/
    │   ├── slick_forms.js
    │   └── slick_forms_frontend.js
    └── images/
        └── logo.png
```

### Accessing Assets in Views

```erb
<!-- In admin views -->
<%= stylesheet_link_tag 'slick_forms' %>
<%= javascript_include_tag 'slick_forms' %>

<!-- In frontend views -->
<%= stylesheet_link_tag 'slick_forms_frontend' %>
<%= javascript_include_tag 'slick_forms_frontend' %>

<!-- Images -->
<%= image_tag plugin_asset_path('slick_forms', 'logo.png') %>
```

## 6. Background Jobs

```ruby
# app/jobs/slick_forms_notification_job.rb
class SlickFormsNotificationJob < ApplicationJob
  queue_as :default
  
  def perform(form_id, submission_id)
    form = SlickForm.find(form_id)
    submission = SlickFormSubmission.find(submission_id)
    
    # Send email notification
    SlickFormsMailer.submission_notification(form, submission).deliver_later
    
    # Trigger webhooks
    plugin = Railspress::PluginSystem.get_plugin('slick_forms')
    plugin.trigger_webhook('form.submitted', {
      form: form.to_liquid,
      submission: submission.to_liquid
    })
  end
end
```

Register job in plugin:

```ruby
def setup
  # Register background job
  create_job('notification', SlickFormsNotificationJob)
  
  # Schedule recurring job
  schedule_recurring_job('cleanup', '0 2 * * *', SlickFormsCleanupJob)
end
```

## 7. Mailers

```ruby
# app/mailers/slick_forms_mailer.rb
class SlickFormsMailer < ApplicationMailer
  default from: 'noreply@example.com'
  
  def submission_notification(form, submission)
    @form = form
    @submission = submission
    
    mail(
      to: form.notification_email || 'admin@example.com',
      subject: "New submission for #{form.title}"
    )
  end
end
```

Email template:

```erb
<!-- app/views/slick_forms_mailer/submission_notification.html.erb -->
<h1>New Form Submission</h1>

<p>You have received a new submission for the form: <strong><%= @form.title %></strong></p>

<h2>Submission Details:</h2>
<table>
  <% @submission.data.each do |key, value| %>
    <tr>
      <th><%= key.titleize %>:</th>
      <td><%= value %></td>
    </tr>
  <% end %>
</table>

<p>
  <%= link_to 'View in Admin', admin_slick_forms_submission_url(@submission) %>
</p>
```

## 8. Complete Example: SlickForms Plugin

See `lib/plugins/slick_forms/` for a complete working example implementing all these patterns.

## Best Practices

### 1. Naming Conventions

- **Models**: `PluginNameModel` (e.g., `SlickForm`, `SlickFormSubmission`)
- **Controllers**: `Admin::PluginName::*Controller` or `Plugins::PluginName::*Controller`
- **Jobs**: `PluginName*Job` (e.g., `SlickFormsNotificationJob`)
- **Mailers**: `PluginName*Mailer` (e.g., `SlickFormsMailer`)

### 2. Security

- Always inherit admin controllers from `Admin::BaseController`
- Use `before_action` callbacks for authorization
- Sanitize user inputs
- Implement CSRF protection
- Use strong parameters

### 3. Multi-tenancy

- Always scope queries by `current_tenant`
- Use `acts_as_tenant` in models
- Add `tenant_id` index to all tables

### 4. Performance

- Use database indexes appropriately
- Implement pagination for large datasets
- Use eager loading to avoid N+1 queries
- Cache expensive operations

### 5. Testing

Write tests for:
- Models (validations, associations, scopes)
- Controllers (CRUD operations, authorization)
- Jobs (background processing)
- Mailers (email content)

### 6. Documentation

Document:
- API endpoints
- Configuration options
- Database schema
- Customization points

## Troubleshooting

### Controllers Not Found

Ensure controllers are in the correct namespace:
- Admin: `Admin::PluginName::*Controller`
- Frontend: `Plugins::PluginName::*Controller`

### Routes Not Loading

Check that:
1. Routes are registered in plugin `setup` method
2. Plugin is activated in database
3. Rails server was restarted after adding routes

### Views Not Rendering

Verify:
1. Views are in correct directory structure
2. Controller action names match view names
3. Layout is properly configured

### Assets Not Loading

Confirm:
1. Assets are registered in plugin setup
2. Asset pipeline is configured correctly
3. Assets are in `lib/plugins/plugin_name/assets/`

## Additional Resources

- [Plugin Developer Guide](./PLUGIN_DEVELOPER_GUIDE.md)
- [Plugin API Reference](./PLUGIN_API_REFERENCE.md)
- [Admin Design System](./design/ADMIN_DESIGN_SYSTEM.md)
- [Testing Plugins](./testing/PLUGIN_TESTING.md)

