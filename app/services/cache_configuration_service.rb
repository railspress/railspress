class CacheConfigurationService
  CACHE_STORES = {
    'null' => :null_store,
    'memory' => :memory_store,
    'file' => :file_store,
    'redis' => :redis_cache_store
  }.freeze

  def self.current_store_type
    store = Rails.cache
    case store
    when ActiveSupport::Cache::NullStore
      'null'
    when ActiveSupport::Cache::MemoryStore
      'memory'
    when ActiveSupport::Cache::FileStore
      'file'
    when ActiveSupport::Cache::RedisCacheStore
      'redis'
    else
      'unknown'
    end
  end

  def self.configure_cache_store(store_type, options = {})
    case store_type
    when 'null'
      Rails.cache = ActiveSupport::Cache::NullStore.new
    when 'memory'
      Rails.cache = ActiveSupport::Cache::MemoryStore.new(
        size: options[:size] || 32.megabytes,
        expires_in: options[:expires_in] || 1.hour
      )
    when 'file'
      Rails.cache = ActiveSupport::Cache::FileStore.new(
        options[:path] || Rails.root.join('tmp', 'cache'),
        expires_in: options[:expires_in] || 1.hour
      )
    when 'redis'
      redis_options = {
        url: options[:url] || RedisConfig.cache_url,
        expires_in: options[:expires_in] || 1.hour,
        namespace: options[:namespace] || 'railspress:cache'
      }

      # Map provided Redis-specific options to proper RedisCacheStore keys
      provided = options[:redis_options] || {}
      # Support legacy keys
      connect_timeout = provided[:connect_timeout] || options[:connect_timeout]
      timeout = provided[:timeout] || options[:timeout]

      if connect_timeout
        redis_options[:connect_timeout] = connect_timeout
      end
      if timeout
        redis_options[:read_timeout] = timeout
        redis_options[:write_timeout] = timeout
      end

      Rails.cache = ActiveSupport::Cache::RedisCacheStore.new(redis_options)
    else
      raise ArgumentError, "Unknown cache store type: #{store_type}"
    end

    # Update Rails configuration
    Rails.application.config.cache_store = Rails.cache.class.name.underscore.to_sym
    
    Rails.logger.info "Cache store configured: #{store_type}"
    true
  rescue => e
    Rails.logger.error "Failed to configure cache store: #{e.message}"
    false
  end

  def self.test_cache_store(store_type, options = {})
    begin
      # Test the cache store
      test_key = "cache_test_#{Time.now.to_i}"
      test_value = "test_value_#{rand(1000)}"
      
      # Configure temporarily
      old_cache = Rails.cache
      configure_cache_store(store_type, options)
      
      # Test write
      Rails.cache.write(test_key, test_value, expires_in: 1.minute)
      
      # Test read
      retrieved_value = Rails.cache.read(test_key)
      
      # Test delete
      Rails.cache.delete(test_key)
      
      # Restore original cache
      Rails.cache = old_cache
      
      retrieved_value == test_value
    rescue => e
      Rails.logger.error "Cache store test failed: #{e.message}"
      false
    end
  end

  def self.get_cache_stats
    case current_store_type
    when 'redis'
      begin
        # Prefer direct Redis client with short timeouts for reliability
        url = begin
          SiteSetting.get('redis_cache_url') || SiteSetting.get('redis_url')
        rescue
          nil
        end
        url ||= ENV['REDIS_CACHE_URL'] || ENV['REDIS_URL'] || RedisConfig.cache_url

        redis = Redis.new(url: url, connect_timeout: 1.0, read_timeout: 1.0, write_timeout: 1.0)
        # Quick connectivity check
        pong = redis.ping rescue nil
        raise 'Redis not reachable' unless pong == 'PONG'

        info = redis.info
        {
          store_type: 'redis',
          total_keys: redis.dbsize,
          memory_usage: info['used_memory_human'],
          connected_clients: info['connected_clients'],
          version: info['redis_version'],
          uptime: info['uptime_in_seconds'],
          hit_rate: calculate_hit_rate(info)
        }
      rescue => e
        { store_type: 'redis', error: e.message }
      end
    when 'memory'
      {
        store_type: 'memory',
        size_limit: Rails.cache.instance_variable_get(:@max_size),
        current_size: Rails.cache.instance_variable_get(:@cache)&.size || 0
      }
    when 'file'
      cache_path = Rails.cache.instance_variable_get(:@cache_path)
      {
        store_type: 'file',
        cache_path: cache_path,
        directory_size: File.directory?(cache_path) ? Dir.glob("#{cache_path}/**/*").size : 0
      }
    else
      { store_type: current_store_type }
    end
  end

  def self.clear_cache
    Rails.cache.clear
    Rails.logger.info "Cache cleared successfully"
    true
  rescue => e
    Rails.logger.error "Failed to clear cache: #{e.message}"
    false
  end

  private

  def self.calculate_hit_rate(info)
    return 0 unless info['keyspace_hits'] && info['keyspace_misses']
    
    hits = info['keyspace_hits'].to_f
    misses = info['keyspace_misses'].to_f
    total = hits + misses
    
    total > 0 ? (hits / total) : 0
  end
end
