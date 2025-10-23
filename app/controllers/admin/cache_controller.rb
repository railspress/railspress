class Admin::CacheController < Admin::BaseController
  def index
    @current_store_type = CacheConfigurationService.current_store_type
    @cache_stats = CacheConfigurationService.get_cache_stats
    
    # Load cache settings
    @cache_store_type = SiteSetting.get('cache_store_type', @current_store_type)
    # If stored type is null, ensure enabled is false regardless of stale cache
    stored_enabled = SiteSetting.get('cache_enabled', @current_store_type != 'null')
    @cache_enabled = (@cache_store_type != 'null') && stored_enabled
    @cache_expires_in = SiteSetting.get('cache_expires_in', 1.hour.to_i) / 1.hour.to_i
    @site_setting_cache_expires_in = SiteSetting.get('site_setting_cache_expires_in', 5) # in minutes
    
    # Redis-specific settings
    @redis_url = SiteSetting.get('redis_url', ENV['REDIS_URL'] || 'redis://localhost:6379/0')
    @redis_cache_url = SiteSetting.get('redis_cache_url', ENV['REDIS_CACHE_URL'] || ENV['REDIS_URL'] || 'redis://localhost:6379/1')
    @redis_timeout = SiteSetting.get('redis_timeout', 5)
    @redis_connect_timeout = SiteSetting.get('redis_connect_timeout', 5)
    @redis_namespace = SiteSetting.get('redis_namespace', 'railspress:cache')
    
    # File cache settings
    @file_cache_path = SiteSetting.get('file_cache_path', Rails.root.join('tmp', 'cache').to_s)
    
    # Memory cache settings
    @memory_cache_size = SiteSetting.get('memory_cache_size', 32) # in MB
    
    @redis_available = defined?(Redis)
  end
  
  def update
    cache_params = params.permit(
      :enabled, :store_type, :expires_in, :site_setting_cache_expires_in,
      :redis_url, :redis_cache_url, :redis_timeout, :redis_connect_timeout, :redis_namespace,
      :file_cache_path, :memory_cache_size,
      # Legacy fields from old Redis form
      :url, :cache_url, :session_url, :timeout, :connect_timeout,
      :reconnect_attempts,
      :cache_expires_in, :session_expires_in, :commit
    )

    # Normalize legacy params → new structure
    if cache_params[:url].present? || cache_params[:cache_url].present?
      cache_params[:redis_url] ||= cache_params[:url]
      cache_params[:redis_cache_url] ||= cache_params[:cache_url]
      cache_params[:redis_timeout] ||= cache_params[:timeout]
      cache_params[:redis_connect_timeout] ||= cache_params[:connect_timeout]
      cache_params[:expires_in] ||= cache_params[:cache_expires_in]
      cache_params[:store_type] ||= 'redis'
    end
    
    begin
      # Convert enabled checkbox to boolean
      enabled = cache_params[:enabled] == '1'
      store_type = cache_params[:store_type] || 'memory'
      
      # If disabled, use null store
      if !enabled
        store_type = 'null'
      end
      
      # Prepare options based on store type
      expires_in_hours = (cache_params[:expires_in] || cache_params[:cache_expires_in] || 1).to_i
      options = {
        expires_in: expires_in_hours.hours
      }
      
      case store_type
      when 'redis'
        options[:url] = cache_params[:redis_cache_url] || cache_params[:redis_url]
        options[:namespace] = cache_params[:redis_namespace]
        options[:redis_options] = {
          timeout: cache_params[:redis_timeout].to_i,
          connect_timeout: cache_params[:redis_connect_timeout].to_i
        }
      when 'file'
        options[:path] = cache_params[:file_cache_path]
      when 'memory'
        options[:size] = (cache_params[:memory_cache_size] || 32).to_i.megabytes
      end
      
      # For disabling (null store), skip testing to avoid false negatives
      tested = (store_type == 'null') ? true : CacheConfigurationService.test_cache_store(store_type, options)
      fell_back = false
      if !tested && store_type == 'redis'
        # Fallback to memory store when Redis is unavailable
        store_type = 'memory'
        options = {
          expires_in: expires_in_hours.hours,
          size: (cache_params[:memory_cache_size] || 32).to_i.megabytes
        }
        tested = CacheConfigurationService.test_cache_store(store_type, options)
        fell_back = tested
      end

      if tested
        # Configure the cache store
        if CacheConfigurationService.configure_cache_store(store_type, options)
          # Save settings
          SiteSetting.set('cache_enabled', enabled, 'boolean')
          SiteSetting.set('cache_store_type', store_type, 'string')
          SiteSetting.set('cache_expires_in', expires_in_hours.hours.to_i, 'integer')
          SiteSetting.set('site_setting_cache_expires_in', cache_params[:site_setting_cache_expires_in].to_i, 'integer')
          
          # Save store-specific settings
          if store_type == 'redis'
            SiteSetting.set('redis_url', cache_params[:redis_url], 'string')
            SiteSetting.set('redis_cache_url', cache_params[:redis_cache_url], 'string')
            SiteSetting.set('redis_timeout', cache_params[:redis_timeout].to_i, 'integer')
            SiteSetting.set('redis_connect_timeout', cache_params[:redis_connect_timeout].to_i, 'integer')
            SiteSetting.set('redis_namespace', cache_params[:redis_namespace], 'string')
          elsif store_type == 'file'
            SiteSetting.set('file_cache_path', cache_params[:file_cache_path], 'string')
          elsif store_type == 'memory'
            SiteSetting.set('memory_cache_size', cache_params[:memory_cache_size].to_i, 'integer')
          end
          
          message = if fell_back
            "Redis unavailable. Cache enabled using memory store."
          else
            "Cache configuration updated successfully! Cache is now #{enabled ? 'enabled' : 'disabled'} using #{store_type} store."
          end
        else
          message = "Failed to configure cache store. Please check your settings."
        end
      else
        message = "Cache configuration test failed. Please check your settings."
      end
      
      if request.xhr?
        render json: { success: true, message: message }
      else
        flash[:notice] = message
        redirect_to admin_cache_path
      end
    rescue => e
      error_message = "Failed to update cache configuration: #{e.message}"
      if request.xhr?
        render json: { success: false, message: error_message }
      else
        flash[:alert] = error_message
        redirect_to admin_cache_path
      end
    end
  end
  
  def test_connection
    begin
      # Test the current cache store instead of hardcoding Redis
      if CacheConfigurationService.current_store_type == 'redis'
        # Use Rails cache to test Redis connection instead of hardcoding Redis.new
        if Rails.cache.respond_to?(:redis)
          redis = Rails.cache.redis
          info = redis.info
          
          message = "Redis connection test successful!"
        else
          message = "Redis not available through Rails cache"
        end
      else
        # Test the current cache store
        test_key = "connection_test_#{Time.now.to_i}"
        test_value = "test_#{rand(1000)}"
        
        Rails.cache.write(test_key, test_value, expires_in: 1.minute)
        retrieved = Rails.cache.read(test_key)
        Rails.cache.delete(test_key)
        
        if retrieved == test_value
          message = "#{CacheConfigurationService.current_store_type.capitalize} cache connection test successful!"
        else
          message = "#{CacheConfigurationService.current_store_type.capitalize} cache connection test failed!"
        end
      end
      
      if request.xhr?
        render json: { success: true, message: message }
      else
        flash[:notice] = message
        redirect_to admin_cache_path
      end
    rescue => e
      error_message = "Cache connection test failed: #{e.message}"
      if request.xhr?
        render json: { success: false, message: error_message }
      else
        flash[:alert] = error_message
        redirect_to admin_cache_path
      end
    end
  end
  
  def flush_cache
    begin
      # Use the cache configuration service to clear cache
      if CacheConfigurationService.clear_cache
        message = "Cache flushed successfully!"
      else
        message = "Failed to flush cache."
      end
      
      if request.xhr?
        render json: { success: true, message: message }
      else
        flash[:notice] = message
        redirect_to admin_cache_path
      end
    rescue => e
      error_message = "Failed to flush cache: #{e.message}"
      if request.xhr?
        render json: { success: false, message: error_message }
      else
        flash[:alert] = error_message
        redirect_to admin_cache_path
      end
    end
  end
  
  def stats
    begin
      # Use the cache configuration service to get stats
      stats = CacheConfigurationService.get_cache_stats
      
      if stats[:error]
        render json: {
          success: false,
          message: "Failed to get cache stats: #{stats[:error]}"
        }
      else
        render json: {
          success: true,
          stats: stats
        }
      end
    rescue => e
      render json: {
        success: false,
        message: "Failed to get cache stats: #{e.message}"
      }
    end
  end

  def enable
    begin
      # Get current store type or default to memory
      store_type = SiteSetting.get('cache_store_type', 'memory')
      
      # Configure cache store
      if CacheConfigurationService.configure_cache_store(store_type)
        SiteSetting.set('cache_enabled', true, 'boolean')
        flash[:notice] = "Cache enabled successfully using #{store_type} store!"
      else
        flash[:alert] = "Failed to enable cache. Please check your configuration."
      end
    rescue => e
      flash[:alert] = "Failed to enable cache: #{e.message}"
    end
    redirect_to admin_cache_path
  end

  def disable
    begin
      # Configure null store to disable caching
      if CacheConfigurationService.configure_cache_store('null')
        SiteSetting.set('cache_enabled', false, 'boolean')
        flash[:notice] = "Cache disabled successfully!"
      else
        flash[:alert] = "Failed to disable cache."
      end
    rescue => e
      flash[:alert] = "Failed to disable cache: #{e.message}"
    end
    redirect_to admin_cache_path
  end

  def clear
    begin
      if CacheConfigurationService.clear_cache
        flash[:notice] = "Cache cleared successfully!"
      else
        flash[:alert] = "Failed to clear cache."
      end
    rescue => e
      flash[:alert] = "Failed to clear cache: #{e.message}"
    end
    redirect_to admin_cache_path
  end
end
