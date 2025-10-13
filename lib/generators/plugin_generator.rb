# Plugin Generator for RailsPress
#
# Usage:
#   rails generate plugin MyPlugin
#   rails generate plugin MyPlugin --with-models
#   rails generate plugin MyPlugin --with-admin-ui
#   rails generate plugin MyPlugin --full
#
# This will create:
#   - Plugin class in lib/plugins/my_plugin/my_plugin.rb
#   - Model in app/models/ (if --with-models)
#   - Admin controller in app/controllers/admin/my_plugin/
#   - Frontend controller in app/controllers/plugins/my_plugin/
#   - Admin views in app/views/admin/my_plugin/
#   - Frontend views in app/views/plugins/my_plugin/
#   - Migration files
#   - Asset files

class PluginGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)
  
  class_option :with_models, type: :boolean, default: false, 
               desc: 'Generate ActiveRecord models'
  class_option :with_admin_ui, type: :boolean, default: true, 
               desc: 'Generate admin UI (controllers and views)'
  class_option :with_frontend, type: :boolean, default: false, 
               desc: 'Generate frontend UI (controllers and views)'
  class_option :full, type: :boolean, default: false, 
               desc: 'Generate everything (models, admin, frontend, assets)'
  class_option :author, type: :string, default: 'RailsPress', 
               desc: 'Plugin author name'
  class_option :description, type: :string, 
               desc: 'Plugin description'
  
  def create_plugin_structure
    @plugin_name = name
    @plugin_class = name.camelize
    @plugin_underscore = name.underscore
    @plugin_identifier = @plugin_underscore
    @author = options[:author]
    @description = options[:description] || "A RailsPress plugin"
    @full = options[:full]
    
    create_plugin_class
    create_models if options[:with_models] || @full
    create_controllers if options[:with_admin_ui] || options[:with_frontend] || @full
    create_views if options[:with_admin_ui] || options[:with_frontend] || @full
    create_assets if @full
    create_jobs if @full
    create_tests if @full
    create_readme
    create_database_record
    
    say "\n✓ Plugin '#{@plugin_name}' created successfully!", :green
    say "\nNext steps:", :yellow
    say "  1. Run: rails db:migrate"
    say "  2. Activate plugin in admin panel at /admin/plugins"
    say "  3. Configure plugin settings"
    say "  4. Restart Rails server\n"
  end
  
  private
  
  def create_plugin_class
    template_file = 'plugin_template.rb'
    destination = "lib/plugins/#{@plugin_underscore}/#{@plugin_underscore}.rb"
    
    content = <<~RUBY
      # #{@plugin_class} - #{@description}
      #
      # A professional RailsPress plugin with full MVC support
      
      class #{@plugin_class} < Railspress::PluginBase
        plugin_name '#{@plugin_name}'
        plugin_version '1.0.0'
        plugin_description '#{@description}'
        plugin_author '#{@author}'
        plugin_url 'https://example.com/plugins/#{@plugin_underscore}'
        plugin_license 'GPL-2.0'
        
        def setup
          # ========================================
          # SETTINGS
          # ========================================
          
          define_setting :enabled,
            type: 'boolean',
            label: 'Enable Plugin',
            description: 'Enable or disable this plugin',
            default: true
          
          define_setting :api_key,
            type: 'string',
            label: 'API Key',
            description: 'Your API key for external services',
            placeholder: 'sk-...',
            required: false
          
          # ========================================
          # ADMIN PAGES
          # ========================================
          
          register_admin_page(
            slug: 'dashboard',
            title: '#{@plugin_name} Dashboard',
            menu_title: 'Dashboard',
            icon: 'chart-bar',
            callback: :render_dashboard
          )
          
          register_admin_page(
            slug: 'settings',
            title: '#{@plugin_name} Settings',
            menu_title: 'Settings',
            icon: 'cog'
          )
          
          # ========================================
          # ROUTES
          # ========================================
          
          # Admin routes (scoped under /admin/#{@plugin_underscore})
          register_admin_routes do
            resources :items do
              member do
                post :duplicate
              end
              collection do
                get :export
                post :import
              end
            end
            
            get 'dashboard', to: 'dashboard#index'
            get 'settings', to: 'settings#index'
            patch 'settings', to: 'settings#update'
          end
          
          # Frontend routes (scoped under /plugins/#{@plugin_underscore})
          register_frontend_routes do
            resources :items, only: [:index, :show]
            get 'search', to: 'items#search'
          end
          
          # ========================================
          # ASSETS
          # ========================================
          
          register_stylesheet('#{@plugin_underscore}.css', admin_only: true)
          register_javascript('#{@plugin_underscore}.js', admin_only: true)
          register_stylesheet('#{@plugin_underscore}_frontend.css', frontend_only: true)
          register_javascript('#{@plugin_underscore}_frontend.js', frontend_only: true)
          
          # ========================================
          # WEBHOOKS & EVENTS
          # ========================================
          
          register_webhook('item.created', ENV['WEBHOOK_URL'], {
            method: 'POST',
            headers: { 'Content-Type' => 'application/json' }
          })
          
          on('user.registered') do |data|
            log("New user registered: \#{data[:user][:email]}", :info)
          end
          
          # ========================================
          # BACKGROUND JOBS
          # ========================================
          
          schedule_task('daily_cleanup', '0 2 * * *') do
            log("Running daily cleanup for #{@plugin_name}", :info)
            # Cleanup logic here
          end
          
          # ========================================
          # HOOKS & FILTERS
          # ========================================
          
          add_action('init', :initialize_plugin)
          add_filter('post_content', :modify_content)
        end
        
        # ========================================
        # ACTIVATION / DEACTIVATION
        # ========================================
        
        def activate
          super
          log("Activating #{@plugin_name}", :info)
          
          # Create database tables
          create_migrations
          
          # Set default settings
          set_setting(:enabled, true)
          
          log("#{@plugin_name} activated successfully", :success)
        end
        
        def deactivate
          super
          log("Deactivating #{@plugin_name}", :info)
        end
        
        def uninstall
          super
          log("Uninstalling #{@plugin_name}", :info)
          
          # Remove database tables
          drop_tables
          
          log("#{@plugin_name} uninstalled", :success)
        end
        
        # ========================================
        # CUSTOM METHODS
        # ========================================
        
        def initialize_plugin
          log("Initializing #{@plugin_name}", :debug)
        end
        
        def modify_content(content)
          # Modify post content
          content
        end
        
        def render_dashboard
          # Custom dashboard rendering logic
          items_count = #{@plugin_class}Item.count rescue 0
          
          <<~HTML
            <div class="space-y-6">
              <h1 class="text-2xl font-bold text-white">#{@plugin_name} Dashboard</h1>
              
              <div class="grid grid-cols-3 gap-4">
                <div class="bg-[#111111] rounded-lg p-6">
                  <div class="text-gray-400 text-sm mb-2">Total Items</div>
                  <div class="text-3xl font-bold text-white">\#{items_count}</div>
                </div>
              </div>
              
              <div class="bg-[#111111] rounded-lg p-6">
                <p class="text-gray-300">Welcome to #{@plugin_name}!</p>
                <p class="text-gray-400 mt-2">Configure your settings and start using the plugin.</p>
              </div>
            </div>
          HTML
        end
        
        private
        
        def create_migrations
          # Create plugin tables
          create_plugin_migration('create_#{@plugin_underscore}_items') do |t|
            t.string :title, null: false
            t.text :description
            t.json :metadata, default: {}
            t.boolean :active, default: true
            t.integer :tenant_id
            t.timestamps
            
            t.index :title
            t.index :active
            t.index :tenant_id
          end
        end
        
        def drop_tables
          # Remove plugin tables
          ActiveRecord::Base.connection.drop_table(:#{@plugin_underscore}_items) if table_exists?(:#{@plugin_underscore}_items)
        end
        
        def table_exists?(table_name)
          ActiveRecord::Base.connection.table_exists?(table_name)
        end
      end
      
      # Register plugin
      Railspress::PluginSystem.register_plugin('#{@plugin_identifier}', #{@plugin_class}.new)
    RUBY
    
    create_file destination, content
  end
  
  def create_models
    return unless options[:with_models] || @full
    
    model_name = "#{@plugin_class}Item"
    model_file = "app/models/#{@plugin_underscore}_item.rb"
    
    content = <<~RUBY
      # #{model_name} Model
      # Belongs to #{@plugin_class} plugin
      
      class #{model_name} < ApplicationRecord
        # Multi-tenancy
        acts_as_tenant(:tenant, optional: true)
        
        # Associations
        belongs_to :user, optional: true
        
        # Validations
        validates :title, presence: true
        
        # Scopes
        scope :active, -> { where(active: true) }
        scope :recent, -> { order(created_at: :desc) }
        
        # Callbacks
        before_save :ensure_defaults
        after_create :log_creation
        
        # Instance methods
        def to_liquid
          {
            'id' => id,
            'title' => title,
            'description' => description,
            'active' => active,
            'created_at' => created_at,
            'updated_at' => updated_at
          }
        end
        
        private
        
        def ensure_defaults
          self.metadata ||= {}
        end
        
        def log_creation
          Rails.logger.info "Created #{model_name}: \#{title} (ID: \#{id})"
        end
      end
    RUBY
    
    create_file model_file, content
  end
  
  def create_controllers
    create_admin_controller if options[:with_admin_ui] || @full
    create_frontend_controller if options[:with_frontend] || @full
  end
  
  def create_admin_controller
    controller_file = "app/controllers/admin/#{@plugin_underscore}/items_controller.rb"
    
    content = <<~RUBY
      # Admin Controller for #{@plugin_class}
      # Handles CRUD operations for #{@plugin_class} items
      
      class Admin::#{@plugin_class}::ItemsController < Admin::BaseController
        before_action :set_item, only: [:show, :edit, :update, :destroy, :duplicate]
        
        # GET /admin/#{@plugin_underscore}/items
        def index
          @items = #{@plugin_class}Item.accessible_by(current_tenant)
                                       .recent
                                       .page(params[:page])
        end
        
        # GET /admin/#{@plugin_underscore}/items/:id
        def show
        end
        
        # GET /admin/#{@plugin_underscore}/items/new
        def new
          @item = #{@plugin_class}Item.new
        end
        
        # POST /admin/#{@plugin_underscore}/items
        def create
          @item = #{@plugin_class}Item.new(item_params)
          @item.tenant = current_tenant
          @item.user = current_user
          
          if @item.save
            redirect_to admin_#{@plugin_underscore}_item_path(@item),
                        notice: 'Item was successfully created.'
          else
            render :new, status: :unprocessable_entity
          end
        end
        
        # GET /admin/#{@plugin_underscore}/items/:id/edit
        def edit
        end
        
        # PATCH/PUT /admin/#{@plugin_underscore}/items/:id
        def update
          if @item.update(item_params)
            redirect_to admin_#{@plugin_underscore}_item_path(@item),
                        notice: 'Item was successfully updated.'
          else
            render :edit, status: :unprocessable_entity
          end
        end
        
        # DELETE /admin/#{@plugin_underscore}/items/:id
        def destroy
          @item.destroy
          redirect_to admin_#{@plugin_underscore}_items_path,
                      notice: 'Item was successfully deleted.'
        end
        
        # POST /admin/#{@plugin_underscore}/items/:id/duplicate
        def duplicate
          new_item = @item.dup
          new_item.title = "\#{@item.title} (Copy)"
          
          if new_item.save
            redirect_to admin_#{@plugin_underscore}_item_path(new_item),
                        notice: 'Item was successfully duplicated.'
          else
            redirect_to admin_#{@plugin_underscore}_items_path,
                        alert: 'Failed to duplicate item.'
          end
        end
        
        # GET /admin/#{@plugin_underscore}/items/export
        def export
          @items = #{@plugin_class}Item.accessible_by(current_tenant).all
          
          respond_to do |format|
            format.csv do
              send_data generate_csv(@items),
                        filename: "#{@plugin_underscore}_items_\#{Date.today}.csv"
            end
            format.json do
              render json: @items
            end
          end
        end
        
        private
        
        def set_item
          @item = #{@plugin_class}Item.accessible_by(current_tenant).find(params[:id])
        rescue ActiveRecord::RecordNotFound
          redirect_to admin_#{@plugin_underscore}_items_path,
                      alert: 'Item not found.'
        end
        
        def item_params
          params.require(:#{@plugin_underscore}_item).permit(
            :title, :description, :active, metadata: {}
          )
        end
        
        def generate_csv(items)
          CSV.generate(headers: true) do |csv|
            csv << ['ID', 'Title', 'Description', 'Active', 'Created At']
            
            items.each do |item|
              csv << [item.id, item.title, item.description, item.active, item.created_at]
            end
          end
        end
      end
    RUBY
    
    create_file controller_file, content
  end
  
  def create_frontend_controller
    controller_file = "app/controllers/plugins/#{@plugin_underscore}/items_controller.rb"
    
    content = <<~RUBY
      # Frontend Controller for #{@plugin_class}
      # Handles public-facing item display
      
      class Plugins::#{@plugin_class}::ItemsController < ApplicationController
        before_action :set_item, only: [:show]
        
        # GET /plugins/#{@plugin_underscore}/items
        def index
          @items = #{@plugin_class}Item.active
                                       .accessible_by(current_tenant)
                                       .recent
                                       .page(params[:page])
        end
        
        # GET /plugins/#{@plugin_underscore}/items/:id
        def show
        end
        
        # GET /plugins/#{@plugin_underscore}/search
        def search
          @query = params[:q]
          @items = #{@plugin_class}Item.active
                                       .accessible_by(current_tenant)
                                       .where('title LIKE ? OR description LIKE ?', "%\#{@query}%", "%\#{@query}%")
                                       .recent
                                       .page(params[:page])
          
          render :index
        end
        
        private
        
        def set_item
          @item = #{@plugin_class}Item.active
                                      .accessible_by(current_tenant)
                                      .find(params[:id])
        rescue ActiveRecord::RecordNotFound
          redirect_to plugins_#{@plugin_underscore}_items_path,
                      alert: 'Item not found.'
        end
      end
    RUBY
    
    create_file controller_file, content
  end
  
  def create_views
    create_admin_views if options[:with_admin_ui] || @full
    create_frontend_views if options[:with_frontend] || @full
  end
  
  def create_admin_views
    # Index view
    create_file "app/views/admin/#{@plugin_underscore}/items/index.html.erb", <<~ERB
      <div class="space-y-6">
        <div class="flex items-center justify-between">
          <h1 class="text-2xl font-bold text-white">#{@plugin_name} Items</h1>
          <%= link_to new_admin_#{@plugin_underscore}_item_path, 
              class: "btn-primary flex items-center gap-2" do %>
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
            </svg>
            New Item
          <% end %>
        </div>
        
        <div class="bg-[#111111] rounded-lg overflow-hidden">
          <table class="w-full">
            <thead class="bg-[#0a0a0a] border-b border-[#2a2a2a]">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase">Title</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase">Status</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase">Created</th>
                <th class="px-6 py-3 text-right text-xs font-medium text-gray-400 uppercase">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-[#2a2a2a]">
              <% @items.each do |item| %>
                <tr class="hover:bg-[#1a1a1a]">
                  <td class="px-6 py-4">
                    <%= link_to item.title, admin_#{@plugin_underscore}_item_path(item),
                        class: "text-white hover:text-blue-400" %>
                  </td>
                  <td class="px-6 py-4">
                    <% if item.active? %>
                      <span class="px-2 py-1 text-xs rounded bg-green-900/20 text-green-400">Active</span>
                    <% else %>
                      <span class="px-2 py-1 text-xs rounded bg-gray-700 text-gray-400">Inactive</span>
                    <% end %>
                  </td>
                  <td class="px-6 py-4 text-gray-300">
                    <%= time_ago_in_words(item.created_at) %> ago
                  </td>
                  <td class="px-6 py-4 text-right">
                    <%= link_to 'Edit', edit_admin_#{@plugin_underscore}_item_path(item),
                        class: "text-blue-400 hover:text-blue-300 mr-3" %>
                    <%= link_to 'Delete', admin_#{@plugin_underscore}_item_path(item),
                        data: { turbo_method: :delete, turbo_confirm: 'Are you sure?' },
                        class: "text-red-400 hover:text-red-300" %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
        
        <%= paginate @items %>
      </div>
    ERB
    
    # New/Edit form
    create_file "app/views/admin/#{@plugin_underscore}/items/_form.html.erb", <<~ERB
      <%= form_with model: [:admin, :#{@plugin_underscore}, @item], local: true, class: "space-y-6" do |f| %>
        <% if @item.errors.any? %>
          <div class="bg-red-900/20 border border-red-500/50 text-red-400 px-4 py-3 rounded-lg">
            <ul class="list-disc list-inside">
              <% @item.errors.full_messages.each do |message| %>
                <li><%= message %></li>
              <% end %>
            </ul>
          </div>
        <% end %>
        
        <div>
          <%= f.label :title, class: "block text-sm font-medium text-gray-300 mb-2" %>
          <%= f.text_field :title, 
              class: "w-full px-4 py-2 bg-[#0a0a0a] border border-[#2a2a2a] rounded-lg text-white focus:border-blue-500",
              placeholder: "Enter title",
              required: true %>
        </div>
        
        <div>
          <%= f.label :description, class: "block text-sm font-medium text-gray-300 mb-2" %>
          <%= f.text_area :description,
              rows: 4,
              class: "w-full px-4 py-2 bg-[#0a0a0a] border border-[#2a2a2a] rounded-lg text-white focus:border-blue-500",
              placeholder: "Enter description" %>
        </div>
        
        <div class="flex items-center">
          <%= f.check_box :active, class: "h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-600 rounded" %>
          <%= f.label :active, "Active", class: "ml-2 text-sm text-gray-300" %>
        </div>
        
        <div class="flex gap-3">
          <%= f.submit "Save", class: "btn-primary" %>
          <%= link_to "Cancel", admin_#{@plugin_underscore}_items_path, class: "btn-secondary" %>
        </div>
      <% end %>
    ERB
    
    create_file "app/views/admin/#{@plugin_underscore}/items/new.html.erb", <<~ERB
      <div class="max-w-3xl mx-auto">
        <h1 class="text-2xl font-bold text-white mb-6">New Item</h1>
        <%= render 'form' %>
      </div>
    ERB
    
    create_file "app/views/admin/#{@plugin_underscore}/items/edit.html.erb", <<~ERB
      <div class="max-w-3xl mx-auto">
        <h1 class="text-2xl font-bold text-white mb-6">Edit Item</h1>
        <%= render 'form' %>
      </div>
    ERB
  end
  
  def create_frontend_views
    create_file "app/views/plugins/#{@plugin_underscore}/items/index.html.erb", <<~ERB
      <div class="max-w-6xl mx-auto py-8 px-4">
        <h1 class="text-4xl font-bold mb-8">#{@plugin_name} Items</h1>
        
        <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          <% @items.each do |item| %>
            <div class="bg-white rounded-lg shadow-lg overflow-hidden">
              <div class="p-6">
                <h2 class="text-2xl font-bold mb-2">
                  <%= link_to item.title, plugins_#{@plugin_underscore}_item_path(item),
                      class: "text-gray-900 hover:text-blue-600" %>
                </h2>
                
                <% if item.description.present? %>
                  <p class="text-gray-600 mb-4">
                    <%= truncate(item.description, length: 150) %>
                  </p>
                <% end %>
                
                <div class="flex items-center justify-between">
                  <span class="text-sm text-gray-500">
                    <%= time_ago_in_words(item.created_at) %> ago
                  </span>
                  
                  <%= link_to 'View', plugins_#{@plugin_underscore}_item_path(item),
                      class: "text-blue-600 hover:text-blue-700 font-medium" %>
                </div>
              </div>
            </div>
          <% end %>
        </div>
        
        <div class="mt-8">
          <%= paginate @items %>
        </div>
      </div>
    ERB
    
    create_file "app/views/plugins/#{@plugin_underscore}/items/show.html.erb", <<~ERB
      <div class="max-w-4xl mx-auto py-8 px-4">
        <div class="bg-white rounded-lg shadow-lg p-8">
          <h1 class="text-4xl font-bold mb-4"><%= @item.title %></h1>
          
          <div class="text-sm text-gray-500 mb-6">
            <%= @item.created_at.strftime('%B %d, %Y') %>
          </div>
          
          <% if @item.description.present? %>
            <div class="prose max-w-none">
              <%= simple_format(@item.description) %>
            </div>
          <% end %>
          
          <div class="mt-8 pt-6 border-t">
            <%= link_to '← Back to Items', plugins_#{@plugin_underscore}_items_path,
                class: "text-blue-600 hover:text-blue-700" %>
          </div>
        </div>
      </div>
    ERB
  end
  
  def create_assets
    # Create asset directories and files
    empty_directory "lib/plugins/#{@plugin_underscore}/assets/stylesheets"
    empty_directory "lib/plugins/#{@plugin_underscore}/assets/javascripts"
    empty_directory "lib/plugins/#{@plugin_underscore}/assets/images"
    
    create_file "lib/plugins/#{@plugin_underscore}/assets/stylesheets/#{@plugin_underscore}.css", <<~CSS
      /* Admin styles for #{@plugin_name} */
      
      .#{@plugin_underscore}-container {
        padding: 1rem;
      }
      
      .#{@plugin_underscore}-card {
        background: #111111;
        border-radius: 0.5rem;
        padding: 1.5rem;
      }
    CSS
    
    create_file "lib/plugins/#{@plugin_underscore}/assets/javascripts/#{@plugin_underscore}.js", <<~JS
      // Admin JavaScript for #{@plugin_name}
      
      document.addEventListener('turbo:load', function() {
        console.log('#{@plugin_name} loaded');
        
        // Initialize plugin functionality
        init#{@plugin_class}();
      });
      
      function init#{@plugin_class}() {
        // Plugin initialization code
      }
    JS
    
    create_file "lib/plugins/#{@plugin_underscore}/assets/stylesheets/#{@plugin_underscore}_frontend.css", <<~CSS
      /* Frontend styles for #{@plugin_name} */
      
      .#{@plugin_underscore}-item {
        margin-bottom: 1rem;
      }
    CSS
    
    create_file "lib/plugins/#{@plugin_underscore}/assets/javascripts/#{@plugin_underscore}_frontend.js", <<~JS
      // Frontend JavaScript for #{@plugin_name}
      
      document.addEventListener('DOMContentLoaded', function() {
        console.log('#{@plugin_name} frontend loaded');
      });
    JS
  end
  
  def create_jobs
    create_file "app/jobs/#{@plugin_underscore}_job.rb", <<~RUBY
      # Background job for #{@plugin_name}
      
      class #{@plugin_class}Job < ApplicationJob
        queue_as :default
        
        def perform(*args)
          # Job logic here
          Rails.logger.info "Executing #{@plugin_class}Job"
        end
      end
    RUBY
  end
  
  def create_tests
    # Model tests
    create_file "test/models/#{@plugin_underscore}_item_test.rb", <<~RUBY
      require 'test_helper'
      
      class #{@plugin_class}ItemTest < ActiveSupport::TestCase
        test "should create item" do
          item = #{@plugin_class}Item.new(title: 'Test Item')
          assert item.save
        end
        
        test "should require title" do
          item = #{@plugin_class}Item.new
          assert_not item.save
          assert_includes item.errors[:title], "can't be blank"
        end
      end
    RUBY
    
    # Controller tests
    create_file "test/controllers/admin/#{@plugin_underscore}/items_controller_test.rb", <<~RUBY
      require 'test_helper'
      
      class Admin::#{@plugin_class}::ItemsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @admin = users(:admin)
          sign_in @admin
        end
        
        test "should get index" do
          get admin_#{@plugin_underscore}_items_url
          assert_response :success
        end
        
        test "should create item" do
          assert_difference('#{@plugin_class}Item.count') do
            post admin_#{@plugin_underscore}_items_url, params: {
              #{@plugin_underscore}_item: { title: 'Test Item' }
            }
          end
          
          assert_redirected_to admin_#{@plugin_underscore}_item_path(#{@plugin_class}Item.last)
        end
      end
    RUBY
  end
  
  def create_readme
    create_file "lib/plugins/#{@plugin_underscore}/README.md", <<~MD
      # #{@plugin_name}
      
      #{@description}
      
      ## Installation
      
      1. The plugin is installed in `lib/plugins/#{@plugin_underscore}/`
      2. Run migrations: `rails db:migrate`
      3. Activate the plugin in admin panel at `/admin/plugins`
      4. Configure settings at `/admin/plugins/#{@plugin_underscore}/settings`
      
      ## Features
      
      - Full CRUD operations for items
      - Admin and frontend interfaces
      - Multi-tenant support
      - Background job processing
      - Webhook integration
      - Event listeners
      
      ## Configuration
      
      Configure plugin settings in the admin panel:
      
      - **Enable Plugin**: Turn the plugin on/off
      - **API Key**: Configure external service integration
      
      ## Usage
      
      ### Admin Interface
      
      Access admin features at `/admin/#{@plugin_underscore}`
      
      ### Frontend Interface
      
      Access public features at `/plugins/#{@plugin_underscore}/items`
      
      ## Development
      
      ### File Structure
      
      ```
      lib/plugins/#{@plugin_underscore}/
      ├── #{@plugin_underscore}.rb      # Main plugin class
      ├── assets/                        # Plugin assets
      ├── README.md                      # This file
      
      app/
      ├── controllers/
      │   ├── admin/#{@plugin_underscore}/
      │   └── plugins/#{@plugin_underscore}/
      ├── views/
      │   ├── admin/#{@plugin_underscore}/
      │   └── plugins/#{@plugin_underscore}/
      ├── models/
      │   └── #{@plugin_underscore}_item.rb
      └── jobs/
          └── #{@plugin_underscore}_job.rb
      ```
      
      ### Testing
      
      Run tests:
      
      ```bash
      rails test test/models/#{@plugin_underscore}_item_test.rb
      rails test test/controllers/admin/#{@plugin_underscore}/
      ```
      
      ## API
      
      ### Admin Routes
      
      - `GET    /admin/#{@plugin_underscore}/items` - List items
      - `POST   /admin/#{@plugin_underscore}/items` - Create item
      - `GET    /admin/#{@plugin_underscore}/items/:id` - Show item
      - `PATCH  /admin/#{@plugin_underscore}/items/:id` - Update item
      - `DELETE /admin/#{@plugin_underscore}/items/:id` - Delete item
      
      ### Frontend Routes
      
      - `GET /plugins/#{@plugin_underscore}/items` - List items
      - `GET /plugins/#{@plugin_underscore}/items/:id` - Show item
      
      ## License
      
      GPL-2.0
      
      ## Author
      
      #{@author}
    MD
  end
  
  def create_database_record
    say "\n Creating database record for plugin...", :yellow
    
    # This will be run after generation
    # The actual database record should be created manually or via rake task
  end
end

