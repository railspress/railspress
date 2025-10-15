source "https://rubygems.org"

ruby "3.3.9"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.5", ">= 7.1.5.2"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 2.1", group: [:development, :test]

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Markdown processing for documentation
gem "redcarpet"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Liquid template engine for themes
gem "liquid", "~> 5.5", require: 'liquid'

# Ferrum for screenshot generation
gem "ferrum"

# Redis for caching
# Use Redis adapter to run Action Cable in production
gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
gem "kredis"

# Redis caching and session store
gem "redis-rails"

# Logster for log viewing
gem "logster"

# Use Redis adapter to run Action Cable in production


# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Soft deletes
gem "discard"

# Authentication
gem "devise"
gem "devise-two-factor"

# Authorization
gem "pundit"

# Tenancy / Settings
gem "acts_as_tenant"
gem "rails-settings-cached"

# Content
gem "friendly_id"
gem "paper_trail"
gem "mobility"

# Search
gem "pg_search"

# SEO
gem "meta-tags"

# Pagination
gem "kaminari"
gem "pagy"

# Slugs and permalinks
gem "stringex"

# Redis for caching (already defined above)

# Background jobs & scheduling
gem "sidekiq"
gem "sidekiq-cron"

# Feature flags
gem "flipper"
gem "flipper-active_record"
gem "flipper-ui"

# API
gem "jsonapi-serializer"
gem "rack-cors"
gem "graphql", "~> 2.1"
gem "graphiql-rails", group: :development

# AI Services
gem "openai"

# Security / hardening
gem "rack-attack"
gem "secure_headers"
gem "loofah", "~> 2.21"  # HTML sanitization

# Observability
gem "lograge"
gem "sentry-ruby"
gem "sentry-rails"

# Admin UI
gem "administrate"

# Email
gem "resend"
gem "letter_opener", group: :development

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]
  
  # Testing
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "capybara"
  
  # Security auditing
  gem "brakeman"
  gem "bundler-audit"
  
  # Code quality
  gem "rubocop", require: false
  gem "standard", require: false
end

group :test do
  # HTTP mocking
  gem "webmock"
  gem "vcr"
  
  # Test coverage
  gem "simplecov", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

