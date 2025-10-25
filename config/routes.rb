Rails.application.routes.draw do
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
  # Mount ActionCable for WebSocket connections
  mount ActionCable.server => '/cable'
  
  # Theme assets
  get '/themes/:theme/assets/*path', to: 'theme_assets#show', constraints: { theme: /[a-zA-Z0-9_-]+/ }, format: false
  
  
  # Devise routes for frontend
  devise_for :users, path: 'auth', controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    omniauth_callbacks: 'omniauth_callbacks'
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
    
    # OAuth routes for admin
    get '/admin/auth/:provider/callback', to: 'omniauth_callbacks#create'
    post '/admin/auth/:provider/callback', to: 'omniauth_callbacks#create'
  end
  
  # GraphQL API
  post "/graphql", to: "graphql#execute"


  constraints lambda { |req| 
    req.session["admin_logged_in"] == true || 
    (req.session["warden.user.user.key"] && User.find_by(id: req.session["warden.user.user.key"][0])&.administrator?)
  } do
    mount Logster::Web => "/logs"
  end
  
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
      
      # OpenAI-compatible endpoints
      post 'chat/completions', to: 'openai#chat_completions'
      get 'models', to: 'openai#models'
      get 'models/:id', to: 'openai#model'
      
      # Content Types
      resources :content_types, only: [:index, :show], param: :id
      resources :uploads, only: [:index, :show, :create, :update, :destroy] do
        member do
          post :approve
          post :reject
        end
      end
    resources :media, only: [:index, :show, :create, :update, :destroy] do
      member do
        post :approve
        post :reject
      end
      collection do
        get :bulk_optimization
        post :bulk_optimize
        get :bulk_optimize_status
        post :regenerate_variants
        delete :clear_variants
        get :optimization_report
      end
    end
    
    # Image Optimization API
    resources :image_optimization, only: [] do
      collection do
        get :analytics
        get :report
        get :failed
        get :top_savings
        get :user_stats
        get :compression_levels
        get :performance
        post :bulk_optimize
        post :regenerate_variants
        delete :clear_logs
        get :export
      end
    end
    
    # Content Channels API
    resources :channels, only: [:index, :show, :create, :update, :destroy]
      
      # Meta Fields API - Must be before other resources to avoid route conflicts
      constraints metable_type: /(posts|pages|users|ai_agents)/ do
        scope '/:metable_type/:metable_id' do
          resources :meta_fields, param: :key, only: [:index, :show, :create, :update, :destroy] do
            collection do
              post :bulk_create, as: :bulk_create
              patch :bulk_update, as: :bulk_update
            end
          end
        end
      end
      
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
      
        # Simple test route
        get 'simple', to: 'simple#index'
      
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
      resources :themes, only: [:index, :show] do
        member do
          get :screenshot
        end
      end
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
      
      # GDPR Compliance API
      namespace :gdpr do
        get 'data-export/:user_id', to: 'gdpr#export_data', as: :export_data
        get 'data-export/download/:token', to: 'gdpr#download_export', as: :download_export
        post 'data-erasure/:user_id', to: 'gdpr#request_erasure', as: :request_erasure
        post 'data-erasure/confirm/:token', to: 'gdpr#confirm_erasure', as: :confirm_erasure
        get 'data-portability/:user_id', to: 'gdpr#data_portability', as: :data_portability
        get 'requests', to: 'gdpr#requests'
        get 'status/:user_id', to: 'gdpr#status'
        post 'consent/:user_id', to: 'gdpr#record_consent'
        delete 'consent/:user_id', to: 'gdpr#withdraw_consent'
        get 'audit-log', to: 'gdpr#audit_log'
      end
      
      # Consent Management API
      namespace :consent do
        get 'configuration', to: 'consent#configuration'
        get 'region', to: 'consent#region'
        post '', to: 'consent#create'
        patch '', to: 'consent#update'
        delete ':consent_type', to: 'consent#withdraw'
        get 'status', to: 'consent#status'
        get 'pixels', to: 'consent#pixels'
      end
      
      # Analytics API
      namespace :analytics do
        get 'posts', to: 'analytics#posts_analytics'
        get 'posts/:id', to: 'analytics#post_analytics'
        get 'pages', to: 'analytics#pages_analytics'
        get 'pages/:id', to: 'analytics#page_analytics'
        get 'overview', to: 'analytics#overview'
        get 'realtime', to: 'analytics#realtime'
      end
      
      # MCP (Model Context Protocol) API
      post 'mcp/session/handshake', to: 'mcp#handshake'
      get 'mcp/tools/list', to: 'mcp#tools_list'
      post 'mcp/tools/call', to: 'mcp#tools_call'
      get 'mcp/tools/stream', to: 'mcp#tools_stream'
      get 'mcp/resources/list', to: 'mcp#resources_list'
      get 'mcp/prompts/list', to: 'mcp#prompts_list'
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
  get '/admin', to: 'admin/dashboard#index'
  
  namespace :admin do
    root 'dashboard#index'
    get 'dashboard', to: 'dashboard#index'
    
    # AI Demo
    get 'ai_demo', to: 'ai_demo#index'
    
    # AI Chat
    post 'ai_chat/stream', to: 'ai_chat#stream'
    post 'ai_chat/feedback', to: 'ai_chat#feedback'
    post 'ai_chat/close_session', to: 'ai_chat#close_session'
    post 'ai_chat/upload_attachment', to: 'ai_chat#upload_attachment'
    get 'ai_chat/session', to: 'ai_chat#session'
    get 'ai_chat/agent_info', to: 'ai_chat#agent_info'
    
    resources :posts do
      collection do
        post :bulk_action
        get :write, action: :new  # Redirects to new which creates auto-draft and redirects to edit
      end
      member do
        patch :publish
        patch :unpublish
        patch :restore
        get :write  # Fullscreen editor for existing post
        get :versions  # View post versions
        post :restore_version  # Restore to specific version
      end
    end
    
    # User preferences
    get 'user_preferences', to: 'user_preferences#show'
    patch 'user_preferences', to: 'user_preferences#update'
    
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
      collection do
        post :bulk_action
      end
    end
    
    resources :media, except: [:show] do
      collection do
        post :bulk_upload
        post :upload              # EditorJS image upload endpoint
        get :bulk_optimization
        post :bulk_optimize
        get :bulk_optimize_status
        post :regenerate_variants
        delete :clear_variants
        get :optimization_report
      end
    end
    
    # Image Optimization Analytics
    resources :image_optimization_analytics, path: 'media/optimization_analytics', only: [:index] do
      collection do
        get :report
        get :failed
        get :top_savings
        get :user_stats
        get :tenant_stats
        get :compression_levels
        get :performance
        delete :clear_logs
        get :export
      end
    end
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
        patch :update_monaco_theme
      end
      member do
        post :regenerate_token
        post :regenerate_api_key
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
      patch :editor_preference
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
        post :sync
      end
      member do
        patch :activate
        get :screenshot
        get :load_customizer
        get :load_preview
      end
      resources :templates
    end
    
    # Theme Builder
    resources :builder, only: [:index, :show], path: 'builder' do
      member do
        post :create_version
        patch :save_draft
        patch :autosave
        patch :publish
        post :rollback
        get :preview
        get :render_preview
        get 'sections/:template', action: :sections, as: :sections
        get :available_sections
        get :section_data
        get :versions
        get :snapshots
        get 'file/:file_path', action: :get_file, as: :file
        patch 'file/:file_path', action: :update_file
        
        # Section management
        post :add_section
        delete 'remove_section/:section_id', action: :remove_section, as: :remove_section
        patch 'update_section/:section_id', action: :update_section, as: :update_section
        patch :reorder_sections
        
        # Block management
        post :add_block
        delete 'remove_block/:block_id', action: :remove_block, as: :remove_block
        patch 'update_block/:block_id', action: :update_block, as: :update_block
        
        # Theme settings management
        patch :update_theme_settings
      end
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
        get :test
        post :test
        patch :toggle_active
      end
      collection do
        post :bulk_action
      end
    end
    
    # Settings sections
    get 'settings', to: 'settings#index', as: 'settings'
    get 'settings/general', to: 'settings#general', as: 'general_settings'
    get 'settings/writing', to: 'settings#writing', as: 'writing_settings'
    get 'settings/reading', to: 'settings#reading', as: 'reading_settings'
    get 'settings/discussion', to: 'settings#discussion', as: 'discussion_settings'
    get 'settings/media', to: 'settings#media', as: 'media_settings'
    get 'settings/permalinks', to: 'settings#permalinks', as: 'permalinks_settings'
    get 'settings/privacy', to: 'settings#privacy', as: 'privacy_settings'
    get 'settings/email', to: 'settings#email', as: 'email_settings'
    get 'settings/post_by_email', to: 'settings#post_by_email', as: 'post_by_email_settings'
    
    patch 'settings/general', to: 'settings#update_general'
    patch 'settings/writing', to: 'settings#update_writing'
    patch 'settings/reading', to: 'settings#update_reading'
    patch 'settings/discussion', to: 'settings#update_discussion'
    patch 'settings/media', to: 'settings#update_media'
    patch 'settings/permalinks', to: 'settings#update_permalinks'
    patch 'settings/privacy', to: 'settings#update_privacy'
    patch 'settings/email', to: 'settings#update_email'
    post 'settings/test_email', to: 'settings#test_email'
    patch 'settings/post_by_email', to: 'settings#update_post_by_email'
    post 'settings/test_post_by_email', to: 'settings#test_post_by_email', as: 'test_post_by_email'
    get 'settings/shortcuts', to: 'settings#shortcuts', as: 'shortcuts_settings'
    get 'settings/shortcuts.json', to: 'settings#shortcuts_json'
    patch 'settings/shortcuts', to: 'settings#update_shortcuts'
    
    get 'settings/white_label', to: 'settings#white_label'
    patch 'settings/white_label', to: 'settings#update_white_label'
    
    get 'settings/appearance', to: 'settings#appearance'
    patch 'settings/appearance', to: 'settings#update_appearance'
    
    # Storage settings
    get 'settings/storage', to: 'settings#storage', as: 'storage_settings'
    patch 'settings/storage', to: 'settings#update_storage'
    resources :storage_providers, path: 'settings/storage_providers'
    
    # MCP Settings
    get 'settings/mcp', to: 'mcp_settings#show', as: 'mcp_settings'
    patch 'settings/mcp', to: 'mcp_settings#update'
    post 'settings/mcp/test_connection', to: 'mcp_settings#test_connection', as: 'test_mcp_connection'
    post 'settings/mcp/generate_api_key', to: 'mcp_settings#generate_api_key', as: 'generate_mcp_api_key'
    
    # OAuth settings
    get 'settings/oauth', to: 'oauth#index', as: 'oauth_settings'
    patch 'settings/oauth', to: 'oauth#update'
    post 'settings/oauth/test_connection', to: 'oauth#test_connection', as: 'oauth_test_connection'
    
    # Upload security settings
    namespace :settings do
      get 'upload_security', to: 'upload_security#show', as: 'upload_security'
      patch 'upload_security', to: 'upload_security#update'
    end

    # Geolocation Settings
    get 'settings/geolocation', to: 'geolocation_settings#show', as: 'geolocation_settings'
    patch 'settings/geolocation', to: 'geolocation_settings#update'
    post 'settings/geolocation/test_lookup', to: 'geolocation_settings#test_lookup'
    post 'settings/geolocation/update_maxmind', to: 'geolocation_settings#update_maxmind'
    post 'settings/geolocation/test_connection', to: 'geolocation_settings#test_connection'
    post 'settings/geolocation/schedule_auto_update', to: 'geolocation_settings#schedule_auto_update'
    delete 'settings/geolocation/disable_auto_update', to: 'geolocation_settings#disable_auto_update'
    get 'settings/geolocation/schedule_status', to: 'geolocation_settings#schedule_status'
    
    # Trash management
    get 'trash', to: 'trash#index', as: 'trash_index'
    patch 'trash/restore/:type/:id', to: 'trash#restore', as: 'restore_trash'
    delete 'trash/permanent/:type/:id', to: 'trash#destroy_permanently', as: 'destroy_permanently_trash'
    delete 'trash/empty', to: 'trash#empty_trash', as: 'empty_trash'
    
    # Trash settings
    get 'trash/settings', to: 'trash_settings#show', as: 'trash_settings'
    patch 'trash/settings', to: 'trash_settings#update'
    get 'trash/settings/test', to: 'trash_settings#test_cleanup', as: 'test_cleanup_trash'
    post 'trash/settings/cleanup', to: 'trash_settings#run_cleanup', as: 'run_cleanup_trash'
    
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
    get 'analytics/insights', to: 'analytics#insights', as: 'analytics_insights'
    get 'analytics/posts', to: 'analytics#posts', as: 'analytics_posts'
    get 'analytics/pages', to: 'analytics#pages', as: 'analytics_pages'
    get 'analytics/countries', to: 'analytics#countries', as: 'analytics_countries'
    get 'analytics/browsers', to: 'analytics#browsers', as: 'analytics_browsers'
    get 'analytics/referrers', to: 'analytics#referrers', as: 'analytics_referrers'
    get 'analytics/export', to: 'analytics#export', as: 'analytics_export'
    post 'analytics/purge', to: 'analytics#purge', as: 'analytics_purge'
    
    # Content Analytics (Medium-like)
    get 'analytics/posts/:id', to: 'content_analytics#post', as: 'content_analytics_post'
    get 'analytics/pages/:id', to: 'content_analytics#page', as: 'content_analytics_page'
    get 'analytics/content/performance', to: 'content_analytics#performance', as: 'content_analytics_performance'
    get 'analytics/content/engagement', to: 'content_analytics#engagement', as: 'content_analytics_engagement'
    get 'analytics/content/export', to: 'content_analytics#export', as: 'content_analytics_export'
    
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
    delete 'logs/clear/:file', to: 'logs#clear', as: 'clear_logs_file'
    get 'logs/search', to: 'logs#search'
    
    # Email Logs
    resources :email_logs, only: [:index, :show, :destroy] do
      collection do
        delete 'destroy_all', to: 'email_logs#destroy_all', as: 'destroy_all'
      end
    end
    
    # Cache Management
    get 'cache', to: 'cache#index'
    patch 'cache', to: 'cache#update'
    post 'cache/enable', to: 'cache#enable'
    post 'cache/disable', to: 'cache#disable'
    post 'cache/clear', to: 'cache#clear'
    post 'cache/test_connection', to: 'cache#test_connection'
    post 'cache/flush', to: 'cache#flush_cache'
    get 'cache/stats', to: 'cache#stats'
    
    # Update Management
    resources :updates, only: [:index] do
      collection do
        get :check
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
      post 'import/process', to: 'import#process_import'
      
      get 'export', to: 'export#index', as: 'export'
      post 'export/generate', to: 'export#generate'
      get 'export/download/:id', to: 'export#download', as: 'export_download'
      
      get 'site_health', to: 'site_health#index', as: 'site_health'
      post 'site_health/run_tests', to: 'site_health#run_tests'
      
      get 'export_personal_data', to: 'export_personal_data#index', as: 'export_personal_data'
      post 'export_personal_data/request', to: 'export_personal_data#create_request'
      get 'export_personal_data/download/:token', to: 'export_personal_data#download', as: 'download_personal_data'
      
      get 'erase_personal_data', to: 'erase_personal_data#index', as: 'erase_personal_data'
      post 'erase_personal_data/request', to: 'erase_personal_data#create_request'
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
    get 'template_customizer/customize', to: 'template_customizer#customize', as: 'template_customizer_customize'
    get 'template_customizer/test_data', to: 'template_customizer#test_data', as: 'template_customizer_test_data'
    post 'template_customizer/save', to: 'template_customizer#save_customization', as: 'save_template_customization'
    post 'template_customizer/publish', to: 'template_customizer#publish_customization', as: 'publish_template_customization'
    get 'template_customizer/load_content', to: 'template_customizer#load_template_content', as: 'load_template_content'
    get 'template_customizer/section_schema', to: 'template_customizer#load_section_schema', as: 'load_section_schema'
    
    # Theme File Editor with Monaco
    resources :theme_editor, only: [:index, :edit, :update, :create, :destroy] do
      collection do
        post :rename
        get :search
        get :file, to: 'theme_editor#open_file'
        get :test
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
      collection do
        get :usage
      end
    end
    
    # System Settings
    namespace :system do
      # Headless Mode
      get 'headless', to: 'headless#index', as: 'headless'
      patch 'headless', to: 'headless#update'
      post 'headless/test_cors', to: 'headless#test_cors', as: 'test_cors'
      
      # Content Channels
      resources :channels do
        resources :channel_overrides do
          collection do
            post :copy_from_channel
            get :export
            post :import
          end
        end
      end
      
      # API Tokens
      resources :api_tokens do
        member do
          patch :toggle
          post :regenerate
        end
      end
    end
    
    # GDPR Compliance Management
    namespace :gdpr do
      root 'gdpr#index'
      get 'index', to: 'gdpr#index'
      
      # User management
      get 'users', to: 'gdpr#users'
      get 'users/:id', to: 'gdpr#user_data', as: 'user_data'
      post 'users/:id/export', to: 'gdpr#export_user_data', as: 'export_user_data'
      post 'users/:id/erase', to: 'gdpr#erase_user_data', as: 'erase_user_data'
      
      # Consent management
      get 'users/:id/consent', to: 'gdpr#user_consent_history', as: 'user_consent_history'
      post 'users/:id/consent', to: 'gdpr#record_consent'
      delete 'users/:id/consent/:consent_type', to: 'gdpr#withdraw_consent', as: 'withdraw_consent'
      
      # Request management
      get 'requests', to: 'gdpr#requests'
      get 'exports/:id/download', to: 'gdpr#download_export', as: 'download_export'
      post 'erasures/:id/confirm', to: 'gdpr#confirm_erasure', as: 'confirm_erasure'
      
      # Audit and compliance
      get 'audit', to: 'gdpr#audit'
      get 'compliance', to: 'gdpr#compliance'
      
      # Settings
      get 'settings', to: 'gdpr#settings'
      patch 'settings', to: 'gdpr#update_settings'
      
      # Bulk operations
      post 'bulk_export', to: 'gdpr#bulk_export'
      
        # Export template
        get 'export_template', to: 'gdpr#export_template'
      end
      
      # Consent Management (Admin)
      namespace :consent do
        root 'consent#index'
        get 'index', to: 'consent#index'
        
        # Configuration management
        resources :consent_configurations, path: 'configurations' do
          member do
            get 'preview'
            get 'test_banner', to: 'consent#test_banner'
          end
        end
        
        # Pixel consent management
        get 'pixels', to: 'consent#pixels'
        get 'pixels/:id/consent_settings', to: 'consent#pixel_consent_settings', as: 'pixel_consent_settings'
        patch 'pixels/:id/update_consent_mapping', to: 'consent#update_pixel_consent_mapping', as: 'update_pixel_consent_mapping'
        
        # User consent management
        get 'users', to: 'consent#users'
        get 'users/:id', to: 'consent#user_consents', as: 'user_consents'
        post 'users/:id/export_data', to: 'consent#export_user_data', as: 'export_user_data'
        delete 'users/:id/consent/:consent_type', to: 'consent#withdraw_user_consent', as: 'withdraw_user_consent'
        
        # Analytics and compliance
        get 'analytics', to: 'consent#analytics'
        get 'compliance', to: 'consent#compliance'
        
        # Settings
        get 'settings', to: 'consent#settings'
        patch 'settings', to: 'consent#update_settings'
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
    
    # Plugin Proxy (for plugin handlers)
    post 'plugins/:plugin_id/:action_name', to: 'plugin_proxy#proxy', as: 'plugin_proxy'
    get 'plugins/:plugin_id/:action_name/*path', to: 'plugin_proxy#proxy'
    
    # Command Palette API
    resource :search, only: [] do
      get :autocomplete, on: :collection
    end
    
    namespace :api do
      resources :shortcuts, only: [:index]
    end
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
  post 'analytics/reading', to: 'analytics#reading'
  post 'analytics/events', to: 'admin/analytics#track_event'
  
  # Analytics API documentation
  get 'analytics/api-docs', to: 'analytics#api_docs', as: :analytics_api_docs
  
  # Analytics API examples
  get 'analytics/examples', to: 'analytics#examples', as: :analytics_examples
  
  # GDPR Compliance routes
  get 'gdpr/privacy-policy', to: 'gdpr#privacy_policy', as: :gdpr_privacy_policy
  post 'gdpr/consent', to: 'gdpr#update_consent', as: :gdpr_update_consent
  post 'gdpr/data-access', to: 'gdpr#data_access', as: :gdpr_data_access
  post 'gdpr/data-deletion', to: 'gdpr#data_deletion', as: :gdpr_data_deletion
  post 'gdpr/data-portability', to: 'gdpr#data_portability', as: :gdpr_data_portability
  get 'gdpr/download/:session_id', to: 'gdpr#download_data', as: :gdpr_download
  post 'gdpr/contact-dpo', to: 'gdpr#contact_dpo', as: :gdpr_contact_dpo
  get 'gdpr/consent-status', to: 'gdpr#consent_status', as: :gdpr_consent_status
  
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
  
  # Frontend preview route
  get 'preview/:template_name', to: 'preview#show', as: 'frontend_preview'
  get 'preview', to: 'preview#show', defaults: { template_name: 'index' }
  
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
    !req.path.start_with?('/admin', '/assets', '/rails', '/auth', '/api', '/csp-violation-report')
  }
end
