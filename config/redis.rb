# Redis Configuration
# This file configures Redis for caching, sessions, and background jobs

class RedisConfig
    def self.connection_url
      ENV['REDIS_URL'] || 'redis://localhost:6379/0'
    end
  
    def self.cache_url
      ENV['REDIS_CACHE_URL'] || ENV['REDIS_URL'] || 'redis://localhost:6379/1'
    end
  
    def self.session_url
      ENV['REDIS_SESSION_URL'] || ENV['REDIS_URL'] || 'redis://localhost:6379/2'
    end
  
    def self.connection_options
      {
        url: connection_url,
        timeout: 5,
        connect_timeout: 5,
        reconnect_attempts: 3,
        reconnect_delay: 0.5,
        reconnect_delay_max: 2.0
      }
    end
  
    def self.cache_options
      {
        url: cache_url,
        timeout: 5,
        connect_timeout: 5,
        reconnect_attempts: 3,
        reconnect_delay: 0.5,
        reconnect_delay_max: 2.0,
        expires_in: 1.hour,
        namespace: 'railspress:cache'
      }
    end
  
    def self.session_options
      {
        url: session_url,
        timeout: 5,
        connect_timeout: 5,
        reconnect_attempts: 3,
        reconnect_delay: 0.5,
        reconnect_delay_max: 2.0,
        namespace: 'railspress:sessions'
      }
    end
  
    def self.test_connection
      Redis.new(connection_options).ping
    rescue => e
      Rails.logger.error "Redis connection failed: #{e.message}"
      false
    end
  
    def self.flush_all
      Redis.new(connection_options).flushall
    rescue => e
      Rails.logger.error "Redis flush failed: #{e.message}"
      false
    end
  
    def self.info
      redis = Redis.new(connection_options)
      {
        connected: redis.ping == 'PONG',
        version: redis.info['redis_version'],
        memory_used: redis.info['used_memory_human'],
        connected_clients: redis.info['connected_clients'],
        uptime: redis.info['uptime_in_seconds']
      }
    rescue => e
      Rails.logger.error "Redis info failed: #{e.message}"
      { connected: false, error: e.message }
    end
  end
  
  