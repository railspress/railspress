# CORS configuration for API access
# Be sure to restart your server when you modify this file.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In development, allow from localhost
    if Rails.env.development?
      origins 'localhost:3000', '127.0.0.1:3000', /\Ahttp:\/\/localhost:\d+\z/, /\Ahttp:\/\/127\.0\.0\.1:\d+\z/
    else
      origins ENV.fetch('ALLOWED_ORIGINS', 'https://yourdomain.com').split(',')
    end

    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      expose: ['X-RateLimit-Limit', 'X-RateLimit-Remaining', 'X-RateLimit-Reset']
  end
end

