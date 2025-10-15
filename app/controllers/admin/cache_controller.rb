class Admin::CacheController < Admin::BaseController
  before_action :ensure_admin

  def index
    @cache_enabled = SiteSetting.get('cache_enabled', false)
    @cache_store = Rails.cache.class.name
    @redis_configured = redis_available?
  end

  def enable
    if redis_available?
      SiteSetting.set('cache_enabled', 'true', 'boolean')
      configure_cache_store
      redirect_to admin_cache_path, notice: 'Cache enabled successfully'
    else
      redirect_to admin_cache_path, alert: 'Redis is not available. Please ensure Redis is running.'
    end
  end

  def disable
    SiteSetting.set('cache_enabled', 'false', 'boolean')
    redirect_to admin_cache_path, notice: 'Cache disabled'
  end

  def clear
    Rails.cache.clear
    redirect_to admin_cache_path, notice: 'Cache cleared successfully'
  end

  def stats
    if redis_available?
      redis = Redis.new
      info = redis.info
      
      render json: {
        connected: true,
        version: info['redis_version'],
        used_memory: info['used_memory_human'],
        connected_clients: info['connected_clients'],
        total_commands: info['total_commands_processed']
      }
    else
      render json: { connected: false, error: 'Redis not available' }
    end
  end

  private

  def redis_available?
    begin
      redis = Redis.new
      redis.ping == 'PONG'
    rescue
      false
    end
  end

  def configure_cache_store
    # This would typically require server restart
    # For now, we just store the setting
  end
end








