class Admin::Tools::SiteHealthController < Admin::BaseController
  # GET /admin/tools/site_health
  def index
    @health_checks = run_health_checks
  end
  
  # POST /admin/tools/site_health/run_tests
  def run_tests
    @health_checks = run_health_checks
    
    render json: {
      status: overall_status(@health_checks),
      checks: @health_checks,
      timestamp: Time.current
    }
  end
  
  private
  
  def run_health_checks
    checks = []
    
    # Database Connection
    checks << check_database
    
    # Redis Connection
    checks << check_redis
    
    # File Permissions
    checks << check_file_permissions
    
    # Disk Space
    checks << check_disk_space
    
    # Ruby Version
    checks << check_ruby_version
    
    # Rails Version
    checks << check_rails_version
    
    # Required Gems
    checks << check_required_gems
    
    # ActiveStorage
    checks << check_active_storage
    
    # Mail Configuration
    checks << check_mail_config
    
    # Background Jobs
    checks << check_sidekiq
    
    # SSL/HTTPS
    checks << check_ssl
    
    # Performance
    checks << check_caching
    
    checks
  end
  
  def check_database
    {
      name: 'Database Connection',
      category: 'critical',
      status: ActiveRecord::Base.connection.active? ? 'pass' : 'fail',
      message: ActiveRecord::Base.connection.active? ? 
        "Connected to #{ActiveRecord::Base.connection.adapter_name}" : 
        'Database connection failed',
      details: {
        adapter: ActiveRecord::Base.connection.adapter_name,
        database: ActiveRecord::Base.connection.current_database
      }
    }
  rescue => e
    { name: 'Database Connection', category: 'critical', status: 'fail', message: e.message }
  end
  
  def check_redis
    begin
      # Use Rails cache to check Redis instead of hardcoding Redis.new
      if Rails.cache.respond_to?(:redis)
        redis = Rails.cache.redis
        ping_result = redis.ping
        
        {
          name: 'Redis Connection',
          category: 'recommended',
          status: ping_result == 'PONG' ? 'pass' : 'fail',
          message: ping_result == 'PONG' ? 'Redis is running' : 'Redis connection failed',
          details: { url: ENV['REDIS_URL'] || 'redis://localhost:6379' }
        }
      else
        {
          name: 'Redis Connection',
          category: 'recommended',
          status: 'warning',
          message: 'Redis not configured or not available through Rails cache'
        }
      end
    rescue => e
      { name: 'Redis Connection', category: 'recommended', status: 'warning', message: "Redis not available: #{e.message}" }
    end
  end
  
  def check_file_permissions
    writable_paths = ['tmp', 'log', 'storage', 'public/uploads']
    failed_paths = writable_paths.reject { |path| File.writable?(Rails.root.join(path)) }
    
    {
      name: 'File Permissions',
      category: 'critical',
      status: failed_paths.empty? ? 'pass' : 'fail',
      message: failed_paths.empty? ? 
        'All required directories are writable' : 
        "Not writable: #{failed_paths.join(', ')}",
      details: { checked_paths: writable_paths }
    }
  end
  
  def check_disk_space
    stat = Sys::Filesystem.stat(Rails.root.to_s)
    free_gb = (stat.bytes_available / 1024.0 / 1024.0 / 1024.0).round(2)
    
    {
      name: 'Disk Space',
      category: 'recommended',
      status: free_gb > 1 ? 'pass' : 'warning',
      message: "#{free_gb} GB available",
      details: { free_gb: free_gb }
    }
  rescue => e
    { name: 'Disk Space', category: 'recommended', status: 'info', message: 'Could not check disk space' }
  end
  
  def check_ruby_version
    required_version = Gem::Version.new('3.0.0')
    current_version = Gem::Version.new(RUBY_VERSION)
    
    {
      name: 'Ruby Version',
      category: 'critical',
      status: current_version >= required_version ? 'pass' : 'fail',
      message: "Ruby #{RUBY_VERSION}",
      details: { required: '3.0.0+', current: RUBY_VERSION }
    }
  end
  
  def check_rails_version
    {
      name: 'Rails Version',
      category: 'info',
      status: 'pass',
      message: "Rails #{Rails.version}",
      details: { version: Rails.version }
    }
  end
  
  def check_required_gems
    required_gems = %w[devise pundit acts_as_tenant sidekiq flipper]
    missing = required_gems.reject { |gem| Gem.loaded_specs.key?(gem) }
    
    {
      name: 'Required Gems',
      category: 'critical',
      status: missing.empty? ? 'pass' : 'fail',
      message: missing.empty? ? 
        'All required gems are installed' : 
        "Missing: #{missing.join(', ')}",
      details: { required: required_gems, missing: missing }
    }
  end
  
  def check_active_storage
    configured = Rails.application.config.active_storage.service.present?
    
    {
      name: 'ActiveStorage',
      category: 'recommended',
      status: configured ? 'pass' : 'warning',
      message: configured ? 
        "Service: #{Rails.application.config.active_storage.service}" : 
        'ActiveStorage not fully configured',
      details: { service: Rails.application.config.active_storage.service }
    }
  end
  
  def check_mail_config
    configured = ActionMailer::Base.smtp_settings.present? || 
                 ActionMailer::Base.delivery_method != :smtp
    
    {
      name: 'Email Configuration',
      category: 'recommended',
      status: configured ? 'pass' : 'warning',
      message: configured ? 
        "Delivery method: #{ActionMailer::Base.delivery_method}" : 
        'Email not configured',
      details: { delivery_method: ActionMailer::Base.delivery_method }
    }
  end
  
  def check_sidekiq
    stats = Sidekiq::Stats.new
    
    {
      name: 'Background Jobs (Sidekiq)',
      category: 'recommended',
      status: 'pass',
      message: "#{stats.workers_size} workers, #{stats.enqueued} jobs queued",
      details: {
        workers: stats.workers_size,
        enqueued: stats.enqueued,
        processed: stats.processed,
        failed: stats.failed
      }
    }
  rescue => e
    { name: 'Background Jobs (Sidekiq)', category: 'recommended', status: 'warning', message: 'Sidekiq not running' }
  end
  
  def check_ssl
    {
      name: 'HTTPS/SSL',
      category: 'recommended',
      status: request.ssl? ? 'pass' : 'warning',
      message: request.ssl? ? 'HTTPS enabled' : 'Not using HTTPS',
      details: { protocol: request.protocol }
    }
  end
  
  def check_caching
    enabled = Rails.application.config.action_controller.perform_caching
    
    {
      name: 'Caching',
      category: 'performance',
      status: enabled ? 'pass' : 'info',
      message: enabled ? 'Caching enabled' : 'Caching disabled',
      details: { 
        enabled: enabled,
        store: Rails.cache.class.name
      }
    }
  end
  
  def overall_status(checks)
    return 'fail' if checks.any? { |c| c[:category] == 'critical' && c[:status] == 'fail' }
    return 'warning' if checks.any? { |c| c[:status] == 'warning' }
    'pass'
  end
end








