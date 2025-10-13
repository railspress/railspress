Rails.application.routes.draw do
  # Theme assets
  get '/themes/:theme/assets/*path', to: 'theme_assets#show', constraints: { theme: /[a-zA-Z0-9_-]+/ }, format: false
  
  # Devise routes for frontend
  devise_for :users, path: 'auth', controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  
  # Devise routes for admin (using scope to avoid conflicts)
  devise_scope :user do
    get '/admin/sign_in', to: 'admin/sessions#new', as: :new_admin_user_session
    post '/admin/sign_in', to: 'admin/sessions#create', as: :admin_user_session
    delete '/admin/sign_out', to: 'admin/sessions#destroy', as: :destroy_admin_user_session
    get '/admin/password/new', to: 'admin/passwords#new', as: :new_admin_user_password
    get '/admin/password/edit', to: 'admin/passwords#edit', as: :edit_admin_user_password
    patch '/admin/password', to: 'admin/passwords#update', as: :admin_user_password
    put '/admin/password', to: 'admin/passwords#update'
    post '/admin/password', to: 'admin/passwords#create'
  end
  
  # GraphQL API
  post "/graphql", to: "graphql#execute"
  
  # API v1
  namespace :api do
    namespace :v1 do
      # AI Providers API
      resources :ai_providers, only: [:index, :show, :create, :update, :destroy] do
        member do
          patch 'toggle', to: 'ai_providers#toggle'
        end
      end
      
      # AI Agents API
      resources :ai_agents, only: [:index, :show, :create, :update, :destroy] do
        member do
          post 'execute', to: 'ai_agents#execute'
        end
        collection do
          post 'execute/:agent_type', to: 'ai_agents#execute_by_type'
        end
      end
      # Documentation
      get 'docs', to: 'docs#index'
      
      # Authentication
      post 'auth/login', to: 'auth#login'
      post 'auth/register', to: 'auth#register'
      post 'auth/validate', to: 'auth#validate_token'
      
      # Content Types
      resources :content_types, only: [:index, :show], param: :id
      
      # Core Resources
      resources :posts do
        resources :comments, only: [:index, :create]
      end
      
      resources :pages do
        resources :comments, only: [:index, :create]
      end
      
      resources :categories
      resources :tags
      
      # Taxonomy System
      resources :taxonomies do
        collection do
          get ':id/terms', action: :terms, as: :taxonomy_terms
        end
        resources :terms
      end
      
      resources :terms, only: [:index, :show]
      
      resources :comments do
        member do
          patch :approve
          patch :spam
        end
      end
      
      resources :media, only: [:index, :show, :create, :update, :destroy]
      
      # User Management
      resources :users do
        collection do
          get :me
          patch :update_profile
          post :regenerate_token
        end
      end
      
      # Access Levels
      resources :access_levels, only: [:index] do
        collection do
          patch :update_permissions
        end
      end
      
      # Site Management
      resources :menus do
        resources :menu_items
      end
      
      resources :widgets
      resources :themes, only: [:index, :show]
      resources :plugins, only: [:index, :show]
      
      # Settings
      resources :settings, param: :key do
        collection do
          get 'get/:key', action: :get_value
        end
      end
      
      # System Info
      get 'system/info', to: 'system#info'
      get 'system/stats', to: 'system#stats'
      
      # AI SEO
      namespace :ai_seo do
        post 'generate', to: 'ai_seo#generate'
        post 'analyze', to: 'ai_seo#analyze'
        post 'batch_generate', to: 'ai_seo#batch_generate'
        get 'status', to: 'ai_seo#status'
      end
      
      # Newsletter Subscribers
      resources :subscribers do
        collection do
          post 'unsubscribe', to: 'subscribers#unsubscribe'
          post 'confirm', to: 'subscribers#confirm'
          get 'stats', to: 'subscribers#stats'
        end
      end
    end
  end
  
  # Flipper Feature Flags UI (admin only)
  authenticate :user, ->(user) { user.administrator? } do
    mount Flipper::UI.app(Flipper) => '/admin/flipper'
    
    # Mount Sidekiq if available
    if defined?(Sidekiq)
      require 'sidekiq/web'
      mount Sidekiq::Web => '/admin/sidekiq'
    end
  end
  
  # Admin panel
  namespace :admin do
    get 'terms/index'
    get 'terms/new'
    get 'terms/create'
    get 'terms/edit'
    get 'terms/update'
    get 'terms/destroy'
    get 'taxonomies/index'
    get 'taxonomies/new'
    get 'taxonomies/create'
    get 'taxonomies/edit'
    get 'taxonomies/update'
    get 'taxonomies/destroy'
    root 'dashboard#index'
    get 'dashboard', to: 'dashboard#index'
    
    resources :posts do
      collection do
        post :bulk_action
        get :write, action: :write_new  # Fullscreen editor for new post
      end
      member do
        patch :publish
        patch :unpublish
        patch :restore
        get :write  # Fullscreen editor for existing post
      end
    end
    
    resources :pages do
      collection do
        post :bulk_action
      end
      member do
        patch :publish
        patch :unpublish
      end
    end
    
    resources :categories
    resources :tags
    
    # Taxonomy System
    resources :taxonomies do
      resources :terms
    end
    resources :comments, except: [:new] do
      member do
        patch :approve
        patch :spam
      end
    end
    
    resources :media, except: [:show]
    resources :menus do
      resources :menu_items
    end
    resources :widgets
    
    # User Management
    resources :users do
      collection do
        post :bulk_action
        get :profile
        patch :update_profile
      end
      member do
        post :regenerate_token
      end
    end
    
    # Access Levels
    resources :access_levels, only: [:index] do
      collection do
        patch :update_permissions
      end
    end
    
    # Profile & Security
    resource :profile, only: [:show, :edit, :update], controller: 'profile' do
      delete :remove_avatar
    end
    
    resource :security, only: [:show], controller: 'security' do
      patch :update_password
      post :enable_2fa
      delete :disable_2fa
      post :regenerate_api_token
      delete :revoke_sessions
    end
    
    resources :themes do
      collection do
        get :preview
      end
      member do
        patch :activate
      end
      resources :templates
    end
    resources :plugins do
      collection do
        get :browse
        get :marketplace
        post :install
      end
      member do
        patch :activate
        patch :deactivate
        get :settings
        patch :update_settings
      end
    end
    
    # Integrations
    resources :integrations, only: [:index] do
      collection do
        get :uploadcare
      end
    end
    get 'integrations/:name', to: 'integrations#show', as: :integration
    resources :site_settings
    
    # Webhooks
    resources :webhooks do
      member do
        post :test
        patch :toggle_active
      end
    end
    
    # Settings sections
    get 'settings', to: 'settings#index', as: 'settings'
    get 'settings/general', to: 'settings#general', as: 'general_settings'
    get 'settings/writing', to: 'settings#writing', as: 'writing_settings'
    get 'settings/reading', to: 'settings#reading', as: 'reading_settings'
    get 'settings/media', to: 'settings#media', as: 'media_settings'
    get 'settings/permalinks', to: 'settings#permalinks', as: 'permalinks_settings'
    get 'settings/privacy', to: 'settings#privacy', as: 'privacy_settings'
    get 'settings/email', to: 'settings#email', as: 'email_settings'
    get 'settings/post_by_email', to: 'settings#post_by_email', as: 'post_by_email_settings'
    
    patch 'settings/general', to: 'settings#update_general'
    patch 'settings/writing', to: 'settings#update_writing'
    patch 'settings/reading', to: 'settings#update_reading'
    patch 'settings/media', to: 'settings#update_media'
    patch 'settings/permalinks', to: 'settings#update_permalinks'
    patch 'settings/privacy', to: 'settings#update_privacy'
    patch 'settings/email', to: 'settings#update_email'
    post 'settings/test_email', to: 'settings#test_email'
    patch 'settings/post_by_email', to: 'settings#update_post_by_email'
    post 'settings/test_post_by_email', to: 'settings#test_post_by_email', as: 'test_post_by_email'
    get 'settings/shortcuts', to: 'settings#shortcuts', as: 'shortcuts_settings'
    patch 'settings/shortcuts', to: 'settings#update_shortcuts'
    
    get 'settings/white_label', to: 'settings#white_label'
    patch 'settings/white_label', to: 'settings#update_white_label'
    
    get 'settings/appearance', to: 'settings#appearance'
    patch 'settings/appearance', to: 'settings#update_appearance'
    
    # Redirects
    resources :redirects do
      member do
        patch :toggle
      end
      collection do
        post :bulk_action
        get :import
        post :do_import
        get :export
      end
    end
    
    # Tracking Pixels
    resources :pixels do
      member do
        patch :toggle
        get :test
      end
      collection do
        post :bulk_action
      end
    end
    
    # Newsletter Subscribers
    resources :subscribers do
      member do
        patch :confirm
        patch :unsubscribe
      end
      collection do
        post :bulk_action
        get :import
        post :do_import
        get :export
        get :stats
      end
    end
    
    # Analytics
    get 'analytics', to: 'analytics#index', as: 'analytics'
    get 'analytics/realtime', to: 'analytics#realtime', as: 'analytics_realtime'
    get 'analytics/posts', to: 'analytics#posts', as: 'analytics_posts'
    get 'analytics/pages', to: 'analytics#pages', as: 'analytics_pages'
    get 'analytics/countries', to: 'analytics#countries', as: 'analytics_countries'
    get 'analytics/browsers', to: 'analytics#browsers', as: 'analytics_browsers'
    get 'analytics/referrers', to: 'analytics#referrers', as: 'analytics_referrers'
    get 'analytics/export', to: 'analytics#export', as: 'analytics_export'
    post 'analytics/purge', to: 'analytics#purge', as: 'analytics_purge'
    
    # Custom Fields (ACF-style)
    resources :field_groups do
      member do
        patch :toggle
        post :duplicate
      end
      collection do
        post :reorder
      end
    end
    
    # Page Templates
    resources :page_templates do
      member do
        patch :toggle
        post :duplicate
        get :customize
        get :theme_edit
      end
    end
    
    # Custom Fonts
    resources :fonts, controller: 'fonts' do
      member do
        patch :toggle
        get :preview
      end
      collection do
        get :google
        post :add_google
      end
    end
    
    # Application Logs
    get 'logs', to: 'logs#index', as: 'logs'
    get 'logs/stream', to: 'logs#stream'
    get 'logs/download', to: 'logs#download', as: 'download_logs'
    delete 'logs/clear', to: 'logs#clear', as: 'clear_logs'
    get 'logs/search', to: 'logs#search'
    
    # Email Logs
    resources :email_logs, only: [:index, :show, :destroy] do
      collection do
        delete 'destroy_all', to: 'email_logs#destroy_all', as: 'destroy_all'
      end
    end
    
    # Cache Management
    get 'cache', to: 'cache#index'
    post 'cache/enable', to: 'cache#enable'
    post 'cache/disable', to: 'cache#disable'
    post 'cache/clear', to: 'cache#clear'
    get 'cache/stats', to: 'cache#stats'
    
    # Update Management
    resources :updates, only: [:index] do
      collection do
        post :check
        get :release_notes
      end
    end
    
    # Shortcodes
    get 'shortcodes', to: 'shortcodes#index'
    post 'shortcodes/test', to: 'shortcodes#test'
    
    # Tools
    namespace :tools do
      get 'import', to: 'import#index', as: 'import'
      post 'import/upload', to: 'import#upload'
      post 'import/process', to: 'import#process'
      
      get 'export', to: 'export#index', as: 'export'
      post 'export/generate', to: 'export#generate'
      get 'export/download/:id', to: 'export#download', as: 'export_download'
      
      get 'site_health', to: 'site_health#index', as: 'site_health'
      post 'site_health/run_tests', to: 'site_health#run_tests'
      
      get 'export_personal_data', to: 'export_personal_data#index', as: 'export_personal_data'
      post 'export_personal_data/request', to: 'export_personal_data#request'
      get 'export_personal_data/download/:token', to: 'export_personal_data#download', as: 'download_personal_data'
      
      get 'erase_personal_data', to: 'erase_personal_data#index', as: 'erase_personal_data'
      post 'erase_personal_data/request', to: 'erase_personal_data#request'
      post 'erase_personal_data/confirm/:token', to: 'erase_personal_data#confirm', as: 'confirm_erase_personal_data'
      
      # Shortcuts Management
      resources :shortcuts do
        member do
          patch :toggle
        end
        collection do
          post :reorder
        end
      end
    end
    
    # Content Types Management
    resources :content_types
    
    # Template Customizer with GrapesJS
    get 'template_customizer', to: 'template_customizer#index', as: 'template_customizer'
    get 'template_customizer/:id/edit', to: 'template_customizer#edit', as: 'edit_template'
    patch 'template_customizer/:id', to: 'template_customizer#update', as: 'update_template'
    get 'template_customizer/:id/load', to: 'template_customizer#load_template', as: 'load_template'
    
    # Theme File Editor with Monaco
    resources :theme_editor, only: [:index, :edit, :update, :create, :destroy] do
      collection do
        post :rename
        get :search
      end
      member do
        get :download
        get :versions
        post :restore
      end
    end
    
    # AI Providers
    resources :ai_providers do
      member do
        patch :toggle
      end
    end
    
    # AI Agents
    resources :ai_agents do
      member do
        patch :toggle
        post :test
      end
    end
    
    # System Settings
    namespace :system do
      # Headless Mode
      get 'headless', to: 'headless#index', as: 'headless'
      patch 'headless', to: 'headless#update'
      post 'headless/test_cors', to: 'headless#test_cors', as: 'test_cors'
      
      # API Tokens
      resources :api_tokens do
        member do
          patch :toggle
          post :regenerate
        end
      end
    end
    
    # API Documentation
    resources :api_docs, only: [:index] do
      collection do
        get 'rest', to: 'api_docs#rest', as: 'rest'
        get 'graphql/playground', to: 'api_docs#graphql', as: 'graphql'
        get 'graphql/schema', to: 'api_docs#graphql_schema', as: 'graphql_schema'
        get 'plugins', to: 'api_docs#plugins', as: 'plugins'
        get 'themes', to: 'api_docs#themes', as: 'themes'
      end
    end
    
    # Plugin Admin Pages
    get 'plugins/:plugin_identifier/:page_slug', to: 'plugin_pages#show', as: 'plugin_page'
    patch 'plugins/:plugin_identifier/:page_slug', to: 'plugin_pages#update'
    post 'plugins/:plugin_identifier/:page_slug/:action_name', to: 'plugin_pages#action', as: 'plugin_page_action'
  end
  
  # Plugin Routes (dynamically loaded)
  # These are loaded after the app initializes via PluginSystem.load_plugin_routes!
  
  # Public routes
  root 'home#index'
  
  # Newsletter subscription (public)
  post 'subscribe', to: 'subscribers#create', as: 'subscribe'
  get 'unsubscribe/:token', to: 'subscribers#unsubscribe', as: 'unsubscribe'
  get 'confirm/:token', to: 'subscribers#confirm', as: 'confirm_subscription'
  
  # Analytics tracking (public)
  post 'analytics/track', to: 'analytics#track'
  post 'analytics/duration', to: 'analytics#duration'
  
  # RSS Feeds
  get 'feed', to: 'feeds#posts', defaults: { format: 'rss' }, as: 'feed'
  get 'feed/posts', to: 'feeds#posts', defaults: { format: 'rss' }, as: 'posts_feed'
  get 'feed/comments', to: 'feeds#comments', defaults: { format: 'rss' }, as: 'comments_feed'
  get 'feed/pages', to: 'feeds#pages', defaults: { format: 'rss' }, as: 'pages_feed'
  get 'feed/category/:slug', to: 'feeds#category', defaults: { format: 'rss' }, as: 'category_feed'
  get 'feed/tag/:slug', to: 'feeds#tag', defaults: { format: 'rss' }, as: 'tag_feed'
  get 'feed/author/:id', to: 'feeds#author', defaults: { format: 'rss' }, as: 'author_feed'
  
  # Atom feed alternative
  get 'feed.atom', to: 'feeds#posts', defaults: { format: 'atom' }
  
  # Blog routes
  get 'blog', to: 'posts#index', as: 'blog'
  get 'blog/:id', to: 'posts#show', as: 'blog_post'
  post 'blog/:id/verify_password', to: 'posts#verify_password', as: 'verify_password_blog_post'
  
  # Category and tag archives
  get 'category/:slug', to: 'posts#category', as: 'category'
  get 'tag/:slug', to: 'posts#tag', as: 'tag'
  
  # Archive routes
  get 'archive/:year(/:month)', to: 'posts#archive', as: 'archive'
  
  # Search
  get 'search', to: 'posts#search', as: 'search'
  
  # Theme Preview & Switching
  get 'themes/preview', to: 'themes#preview', as: 'theme_preview'
  post 'themes/switch', to: 'themes#switch', as: 'theme_switch'
  
    # Comments (public)
    resources :comments, only: [:create]
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # CSP violation reporting
  post "/csp-violation-report", to: "csp_reports#create"
  
  # Pages (catch-all for custom page URLs)
  # Page password verification
  post '*path/verify_password', to: 'pages#verify_password', as: 'verify_password_page'
  
  get '*path', to: 'pages#show', as: 'page', constraints: lambda { |req|
    # Only match if not starting with admin, assets, etc.
    !req.path.start_with?('/admin', '/assets', '/rails', '/auth', '/csp-violation-report')
  }
end
