class Admin::CacheController < Admin::BaseController
  def index
    # Load Redis settings from system configuration
    @cache_enabled = SiteSetting.get('redis_enabled', Rails.cache.is_a?(ActiveSupport::Cache::RedisCacheStore))
    @redis_url = SiteSetting.get('redis_url', ENV['REDIS_URL'] || 'redis://localhost:6379/0')
    @cache_url = SiteSetting.get('redis_cache_url', ENV['REDIS_CACHE_URL'] || ENV['REDIS_URL'] || 'redis://localhost:6379/1')
    @session_url = SiteSetting.get('redis_session_url', ENV['REDIS_SESSION_URL'] || ENV['REDIS_URL'] || 'redis://localhost:6379/2')
    @timeout = SiteSetting.get('redis_timeout', 5)
    @connect_timeout = SiteSetting.get('redis_connect_timeout', 5)
    @reconnect_attempts = SiteSetting.get('redis_reconnect_attempts', 3)
    @reconnect_delay = SiteSetting.get('redis_reconnect_delay', 0.5)
    @reconnect_delay_max = SiteSetting.get('redis_reconnect_delay_max', 2.0)
    @cache_expires_in = (SiteSetting.get('redis_cache_expires_in', 1.hour.to_i) / 1.hour.to_i)
    @session_expires_in = (SiteSetting.get('redis_session_expires_in', 24.hours.to_i) / 1.hour.to_i)
    
    @redis_configured = defined?(Redis)
    
    # Get Redis connection info if available
    begin
      redis_url = @redis_url
      if defined?(Redis) && redis_url.present?
        redis = Redis.new(url: redis_url)
        @redis_info = redis.info
        @redis_connected = true
        @redis_configured = true
        
        # Get additional stats
        @redis_stats = {
          db_size: redis.dbsize,
          memory_usage: @redis_info['used_memory_human'],
          connected_clients: @redis_info['connected_clients'],
          version: @redis_info['redis_version'],
          uptime: @redis_info['uptime_in_seconds']
        }
        
        # Calculate hit rate if available
        if @redis_info['keyspace_hits'] && @redis_info['keyspace_misses']
          total_requests = @redis_info['keyspace_hits'].to_f + @redis_info['keyspace_misses'].to_f
          @redis_stats[:hit_rate] = total_requests > 0 ? (@redis_info['keyspace_hits'].to_f / total_requests) : 0
        else
          @redis_stats[:hit_rate] = 0
        end
        
        redis.quit
      else
        @redis_connected = false
        @redis_configured = false
        @redis_info = {}
        @redis_stats = {}
      end
    rescue => e
      @redis_connected = false
      @redis_configured = false
      @redis_info = {}
      @redis_stats = {}
      @redis_error = e.message
    end
  end
  
  def update
    redis_params = params.permit(
      :enabled, :url, :cache_url, :session_url, :timeout, :connect_timeout,
      :reconnect_attempts, :reconnect_delay, :reconnect_delay_max,
      :cache_expires_in, :session_expires_in
    )
    
    begin
      # Convert enabled checkbox to boolean
      enabled = redis_params[:enabled] == '1'
      
      # Save Redis settings to SiteSetting
      SiteSetting.set('redis_enabled', enabled, 'general')
      SiteSetting.set('redis_url', redis_params[:url], 'general')
      SiteSetting.set('redis_cache_url', redis_params[:cache_url], 'general')
      SiteSetting.set('redis_session_url', redis_params[:session_url], 'general')
      SiteSetting.set('redis_timeout', redis_params[:timeout].to_i, 'general')
      SiteSetting.set('redis_connect_timeout', redis_params[:connect_timeout].to_i, 'general')
      SiteSetting.set('redis_reconnect_attempts', redis_params[:reconnect_attempts].to_i, 'general')
      SiteSetting.set('redis_reconnect_delay', redis_params[:reconnect_delay].to_f, 'general')
      SiteSetting.set('redis_reconnect_delay_max', redis_params[:reconnect_delay_max].to_f, 'general')
      SiteSetting.set('redis_cache_expires_in', redis_params[:cache_expires_in].to_i.hours.to_i, 'general')
      SiteSetting.set('redis_session_expires_in', redis_params[:session_expires_in].to_i.hours.to_i, 'general')
      
      # Test the connection with new settings
      if enabled && redis_params[:url].present?
        begin
          redis = Redis.new(url: redis_params[:url])
          redis.ping
          redis.quit
          message = "Redis settings updated and connection tested successfully! Note: Some changes may require application restart."
        rescue => e
          message = "Redis settings saved but connection test failed: #{e.message}"
        end
      else
        message = "Redis settings updated successfully!"
      end
      
      if request.xhr?
        render json: { success: true, message: message }
      else
        flash[:notice] = message
        redirect_to admin_cache_path
      end
    rescue => e
      error_message = "Failed to update Redis settings: #{e.message}"
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
      redis_url = SiteSetting.get('redis_url', ENV['REDIS_URL'] || 'redis://localhost:6379/0')
      
      redis = Redis.new(url: redis_url)
      info = redis.info
      redis.quit
      
      message = "Redis connection test successful!"
      if request.xhr?
        render json: { success: true, message: message }
      else
        flash[:notice] = message
        redirect_to admin_cache_path
      end
    rescue => e
      error_message = "Redis connection test failed: #{e.message}"
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
      # Flush Rails cache
      Rails.cache.clear
      
      # Also flush Redis directly if available
      redis_url = SiteSetting.get('redis_url', ENV['REDIS_URL'])
      if defined?(Redis) && redis_url
        redis = Redis.new(url: redis_url)
        redis.flushdb
        redis.quit
      end
      
      message = "Cache flushed successfully!"
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
      if defined?(Redis) && ENV['REDIS_URL']
        redis = Redis.new(url: ENV['REDIS_URL'])
        info = redis.info
        
        # Get database size
        db_size = redis.dbsize
        
        # Calculate hit rate if available
        hit_rate = 0
        if info['keyspace_hits'] && info['keyspace_misses']
          total_requests = info['keyspace_hits'].to_f + info['keyspace_misses'].to_f
          hit_rate = total_requests > 0 ? (info['keyspace_hits'].to_f / total_requests) : 0
        end
        
        redis.quit
        
        render json: {
          success: true,
          stats: {
            total_keys: db_size,
            memory_usage: info['used_memory_human'],
            hit_rate: hit_rate,
            connected_clients: info['connected_clients'],
            uptime: info['uptime_in_seconds'],
            version: info['redis_version']
          }
        }
      else
        render json: {
          success: false,
          message: "Redis not available"
        }
      end
    rescue => e
      render json: {
        success: false,
        message: "Failed to get Redis stats: #{e.message}"
      }
    end
  end

  def enable
    begin
      SiteSetting.set('redis_enabled', true, 'general')
      flash[:notice] = "Cache enabled successfully!"
    rescue => e
      flash[:alert] = "Failed to enable cache: #{e.message}"
    end
    redirect_to admin_cache_path
  end

  def disable
    begin
      SiteSetting.set('redis_enabled', false, 'general')
      flash[:notice] = "Cache disabled successfully!"
    rescue => e
      flash[:alert] = "Failed to disable cache: #{e.message}"
    end
    redirect_to admin_cache_path
  end

  def clear
    begin
      # Clear Rails cache
      Rails.cache.clear
      
      # Also clear Redis directly if available
      if defined?(Redis) && ENV['REDIS_URL']
        redis = Redis.new(url: ENV['REDIS_URL'])
        redis.flushdb
        redis.quit
      end
      
      flash[:notice] = "Cache cleared successfully!"
    rescue => e
      flash[:alert] = "Failed to clear cache: #{e.message}"
    end
    redirect_to admin_cache_path
  end
end
