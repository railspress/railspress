class Admin::McpSettingsController < Admin::BaseController
  before_action :authenticate_user!
  before_action :ensure_admin
  before_action :load_mcp_settings

  def show
    # Load MCP settings for display
  end

  def update
    if update_mcp_settings
      redirect_to admin_mcp_settings_path, notice: 'MCP settings updated successfully.'
    else
      render :show, status: :unprocessable_entity
    end
  end

  def test_connection
    begin
      # Test MCP API connection
      result = test_mcp_api_connection
      
      if result[:success]
        render json: { 
          success: true, 
          message: 'MCP API connection successful',
          details: result[:details]
        }
      else
        render json: { 
          success: false, 
          message: 'MCP API connection failed',
          error: result[:error]
        }, status: :unprocessable_entity
      end
    rescue => e
      render json: { 
        success: false, 
        message: 'MCP API connection test failed',
        error: e.message
      }, status: :internal_server_error
    end
  end

  def generate_api_key
    begin
      # Generate a new API key for MCP
      new_api_key = SecureRandom.hex(32)
      
      # Update the site setting
      SiteSetting.set('mcp_api_key', new_api_key)
      
      render json: { 
        success: true, 
        message: 'New API key generated successfully',
        api_key: new_api_key
      }
    rescue => e
      render json: { 
        success: false, 
        message: 'Failed to generate API key',
        error: e.message
      }, status: :internal_server_error
    end
  end

  private

  def load_mcp_settings
    @mcp_settings = {
      enabled: SiteSetting.get('mcp_enabled', false),
      api_key: SiteSetting.get('mcp_api_key', ''),
      max_requests_per_minute: SiteSetting.get('mcp_max_requests_per_minute', 100),
      max_requests_per_hour: SiteSetting.get('mcp_max_requests_per_hour', 1000),
      max_requests_per_day: SiteSetting.get('mcp_max_requests_per_day', 10000),
      allowed_tools: SiteSetting.get('mcp_allowed_tools', 'all'),
      allowed_resources: SiteSetting.get('mcp_allowed_resources', 'all'),
      allowed_prompts: SiteSetting.get('mcp_allowed_prompts', 'all'),
      require_authentication: SiteSetting.get('mcp_require_authentication', true),
      log_requests: SiteSetting.get('mcp_log_requests', true),
      log_responses: SiteSetting.get('mcp_log_responses', false),
      rate_limit_by_ip: SiteSetting.get('mcp_rate_limit_by_ip', true),
      rate_limit_by_user: SiteSetting.get('mcp_rate_limit_by_user', true),
      enable_streaming: SiteSetting.get('mcp_enable_streaming', true),
      max_stream_duration: SiteSetting.get('mcp_max_stream_duration', 300),
      enable_cors: SiteSetting.get('mcp_enable_cors', false),
      cors_origins: SiteSetting.get('mcp_cors_origins', ''),
      enable_webhooks: SiteSetting.get('mcp_enable_webhooks', false),
      webhook_url: SiteSetting.get('mcp_webhook_url', ''),
      webhook_secret: SiteSetting.get('mcp_webhook_secret', ''),
      enable_analytics: SiteSetting.get('mcp_enable_analytics', true),
      analytics_retention_days: SiteSetting.get('mcp_analytics_retention_days', 30),
      enable_caching: SiteSetting.get('mcp_enable_caching', true),
      cache_ttl: SiteSetting.get('mcp_cache_ttl', 300),
      enable_compression: SiteSetting.get('mcp_enable_compression', true),
      max_request_size: SiteSetting.get('mcp_max_request_size', 1048576),
      timeout_seconds: SiteSetting.get('mcp_timeout_seconds', 30),
      enable_debug_mode: SiteSetting.get('mcp_enable_debug_mode', false),
      debug_log_level: SiteSetting.get('mcp_debug_log_level', 'info'),
      enable_metrics: SiteSetting.get('mcp_enable_metrics', true),
      metrics_endpoint: SiteSetting.get('mcp_metrics_endpoint', '/api/v1/mcp/metrics'),
      enable_health_check: SiteSetting.get('mcp_enable_health_check', true),
      health_check_endpoint: SiteSetting.get('mcp_health_check_endpoint', '/api/v1/mcp/health'),
      enable_versioning: SiteSetting.get('mcp_enable_versioning', true),
      supported_versions: SiteSetting.get('mcp_supported_versions', '2025-03-26'),
      enable_deprecation_warnings: SiteSetting.get('mcp_enable_deprecation_warnings', true),
      enable_feature_flags: SiteSetting.get('mcp_enable_feature_flags', false),
      feature_flags: SiteSetting.get('mcp_feature_flags', '{}'),
      enable_audit_log: SiteSetting.get('mcp_enable_audit_log', true),
      audit_log_retention_days: SiteSetting.get('mcp_audit_log_retention_days', 90),
      enable_security_headers: SiteSetting.get('mcp_enable_security_headers', true),
      enable_rate_limit_headers: SiteSetting.get('mcp_enable_rate_limit_headers', true),
      enable_error_tracking: SiteSetting.get('mcp_enable_error_tracking', true),
      error_tracking_endpoint: SiteSetting.get('mcp_error_tracking_endpoint', ''),
      enable_performance_monitoring: SiteSetting.get('mcp_enable_performance_monitoring', true),
      performance_threshold_ms: SiteSetting.get('mcp_performance_threshold_ms', 1000),
      enable_alerting: SiteSetting.get('mcp_enable_alerting', false),
      alert_webhook_url: SiteSetting.get('mcp_alert_webhook_url', ''),
      alert_threshold_errors: SiteSetting.get('mcp_alert_threshold_errors', 10),
      alert_threshold_response_time: SiteSetting.get('mcp_alert_threshold_response_time', 5000),
      enable_backup: SiteSetting.get('mcp_enable_backup', false),
      backup_frequency: SiteSetting.get('mcp_backup_frequency', 'daily'),
      backup_retention_days: SiteSetting.get('mcp_backup_retention_days', 30),
      enable_encryption: SiteSetting.get('mcp_enable_encryption', true),
      encryption_key: SiteSetting.get('mcp_encryption_key', ''),
      enable_ssl: SiteSetting.get('mcp_enable_ssl', true),
      ssl_cert_path: SiteSetting.get('mcp_ssl_cert_path', ''),
      ssl_key_path: SiteSetting.get('mcp_ssl_key_path', ''),
      enable_oauth: SiteSetting.get('mcp_enable_oauth', false),
      oauth_provider: SiteSetting.get('mcp_oauth_provider', ''),
      oauth_client_id: SiteSetting.get('mcp_oauth_client_id', ''),
      oauth_client_secret: SiteSetting.get('mcp_oauth_client_secret', ''),
      oauth_redirect_uri: SiteSetting.get('mcp_oauth_redirect_uri', ''),
      enable_jwt: SiteSetting.get('mcp_enable_jwt', false),
      jwt_secret: SiteSetting.get('mcp_jwt_secret', ''),
      jwt_expiration_hours: SiteSetting.get('mcp_jwt_expiration_hours', 24),
      enable_api_versioning: SiteSetting.get('mcp_enable_api_versioning', true),
      default_api_version: SiteSetting.get('mcp_default_api_version', 'v1'),
      enable_documentation: SiteSetting.get('mcp_enable_documentation', true),
      documentation_url: SiteSetting.get('mcp_documentation_url', '/api/v1/mcp/docs'),
      enable_sandbox: SiteSetting.get('mcp_enable_sandbox', false),
      sandbox_timeout_seconds: SiteSetting.get('mcp_sandbox_timeout_seconds', 60),
      enable_playground: SiteSetting.get('mcp_enable_playground', false),
      playground_url: SiteSetting.get('mcp_playground_url', '/api/v1/mcp/playground')
    }
  end

  def update_mcp_settings
    success = true
    
    # Update each setting
    params['mcp_settings']&.each do |key, value|
      case key.to_s
      when 'enabled'
        SiteSetting.set('mcp_enabled', value == '1')
      when 'api_key'
        SiteSetting.set('mcp_api_key', value) unless value.blank?
      when 'max_requests_per_minute'
        SiteSetting.set('mcp_max_requests_per_minute', value.to_i)
      when 'max_requests_per_hour'
        SiteSetting.set('mcp_max_requests_per_hour', value.to_i)
      when 'max_requests_per_day'
        SiteSetting.set('mcp_max_requests_per_day', value.to_i)
      when 'allowed_tools'
        SiteSetting.set('mcp_allowed_tools', value)
      when 'allowed_resources'
        SiteSetting.set('mcp_allowed_resources', value)
      when 'allowed_prompts'
        SiteSetting.set('mcp_allowed_prompts', value)
      when 'require_authentication'
        SiteSetting.set('mcp_require_authentication', value == '1')
      when 'log_requests'
        SiteSetting.set('mcp_log_requests', value == '1')
      when 'log_responses'
        SiteSetting.set('mcp_log_responses', value == '1')
      when 'rate_limit_by_ip'
        SiteSetting.set('mcp_rate_limit_by_ip', value == '1')
      when 'rate_limit_by_user'
        SiteSetting.set('mcp_rate_limit_by_user', value == '1')
      when 'enable_streaming'
        SiteSetting.set('mcp_enable_streaming', value == '1')
      when 'max_stream_duration'
        SiteSetting.set('mcp_max_stream_duration', value.to_i)
      when 'enable_cors'
        SiteSetting.set('mcp_enable_cors', value == '1')
      when 'cors_origins'
        SiteSetting.set('mcp_cors_origins', value)
      when 'enable_webhooks'
        SiteSetting.set('mcp_enable_webhooks', value == '1')
      when 'webhook_url'
        SiteSetting.set('mcp_webhook_url', value)
      when 'webhook_secret'
        SiteSetting.set('mcp_webhook_secret', value)
      when 'enable_analytics'
        SiteSetting.set('mcp_enable_analytics', value == '1')
      when 'analytics_retention_days'
        SiteSetting.set('mcp_analytics_retention_days', value.to_i)
      when 'enable_caching'
        SiteSetting.set('mcp_enable_caching', value == '1')
      when 'cache_ttl'
        SiteSetting.set('mcp_cache_ttl', value.to_i)
      when 'enable_compression'
        SiteSetting.set('mcp_enable_compression', value == '1')
      when 'max_request_size'
        SiteSetting.set('mcp_max_request_size', value.to_i)
      when 'timeout_seconds'
        SiteSetting.set('mcp_timeout_seconds', value.to_i)
      when 'enable_debug_mode'
        SiteSetting.set('mcp_enable_debug_mode', value == '1')
      when 'debug_log_level'
        SiteSetting.set('mcp_debug_log_level', value)
      when 'enable_metrics'
        SiteSetting.set('mcp_enable_metrics', value == '1')
      when 'metrics_endpoint'
        SiteSetting.set('mcp_metrics_endpoint', value)
      when 'enable_health_check'
        SiteSetting.set('mcp_enable_health_check', value == '1')
      when 'health_check_endpoint'
        SiteSetting.set('mcp_health_check_endpoint', value)
      when 'enable_versioning'
        SiteSetting.set('mcp_enable_versioning', value == '1')
      when 'supported_versions'
        SiteSetting.set('mcp_supported_versions', value)
      when 'enable_deprecation_warnings'
        SiteSetting.set('mcp_enable_deprecation_warnings', value == '1')
      when 'enable_feature_flags'
        SiteSetting.set('mcp_enable_feature_flags', value == '1')
      when 'feature_flags'
        SiteSetting.set('mcp_feature_flags', value)
      when 'enable_audit_log'
        SiteSetting.set('mcp_enable_audit_log', value == '1')
      when 'audit_log_retention_days'
        SiteSetting.set('mcp_audit_log_retention_days', value.to_i)
      when 'enable_security_headers'
        SiteSetting.set('mcp_enable_security_headers', value == '1')
      when 'enable_rate_limit_headers'
        SiteSetting.set('mcp_enable_rate_limit_headers', value == '1')
      when 'enable_error_tracking'
        SiteSetting.set('mcp_enable_error_tracking', value == '1')
      when 'error_tracking_endpoint'
        SiteSetting.set('mcp_error_tracking_endpoint', value)
      when 'enable_performance_monitoring'
        SiteSetting.set('mcp_enable_performance_monitoring', value == '1')
      when 'performance_threshold_ms'
        SiteSetting.set('mcp_performance_threshold_ms', value.to_i)
      when 'enable_alerting'
        SiteSetting.set('mcp_enable_alerting', value == '1')
      when 'alert_webhook_url'
        SiteSetting.set('mcp_alert_webhook_url', value)
      when 'alert_threshold_errors'
        SiteSetting.set('mcp_alert_threshold_errors', value.to_i)
      when 'alert_threshold_response_time'
        SiteSetting.set('mcp_alert_threshold_response_time', value.to_i)
      when 'enable_backup'
        SiteSetting.set('mcp_enable_backup', value == '1')
      when 'backup_frequency'
        SiteSetting.set('mcp_backup_frequency', value)
      when 'backup_retention_days'
        SiteSetting.set('mcp_backup_retention_days', value.to_i)
      when 'enable_encryption'
        SiteSetting.set('mcp_enable_encryption', value == '1')
      when 'encryption_key'
        SiteSetting.set('mcp_encryption_key', value) unless value.blank?
      when 'enable_ssl'
        SiteSetting.set('mcp_enable_ssl', value == '1')
      when 'ssl_cert_path'
        SiteSetting.set('mcp_ssl_cert_path', value)
      when 'ssl_key_path'
        SiteSetting.set('mcp_ssl_key_path', value)
      when 'enable_oauth'
        SiteSetting.set('mcp_enable_oauth', value == '1')
      when 'oauth_provider'
        SiteSetting.set('mcp_oauth_provider', value)
      when 'oauth_client_id'
        SiteSetting.set('mcp_oauth_client_id', value)
      when 'oauth_client_secret'
        SiteSetting.set('mcp_oauth_client_secret', value)
      when 'oauth_redirect_uri'
        SiteSetting.set('mcp_oauth_redirect_uri', value)
      when 'enable_jwt'
        SiteSetting.set('mcp_enable_jwt', value == '1')
      when 'jwt_secret'
        SiteSetting.set('mcp_jwt_secret', value) unless value.blank?
      when 'jwt_expiration_hours'
        SiteSetting.set('mcp_jwt_expiration_hours', value.to_i)
      when 'enable_api_versioning'
        SiteSetting.set('mcp_enable_api_versioning', value == '1')
      when 'default_api_version'
        SiteSetting.set('mcp_default_api_version', value)
      when 'enable_documentation'
        SiteSetting.set('mcp_enable_documentation', value == '1')
      when 'documentation_url'
        SiteSetting.set('mcp_documentation_url', value)
      when 'enable_sandbox'
        SiteSetting.set('mcp_enable_sandbox', value == '1')
      when 'sandbox_timeout_seconds'
        SiteSetting.set('mcp_sandbox_timeout_seconds', value.to_i)
      when 'enable_playground'
        SiteSetting.set('mcp_enable_playground', value == '1')
      when 'playground_url'
        SiteSetting.set('mcp_playground_url', value)
      end
    end
    
    success
  rescue => e
    Rails.logger.error "Failed to update MCP settings: #{e.message}"
    false
  end

  def test_mcp_api_connection
    # Test the MCP API by making a handshake request
    begin
      uri = URI("#{request.base_url}/api/v1/mcp/session/handshake")
      http = Net::HTTP.new(uri.host, uri.port)
      
      request_obj = Net::HTTP::Post.new(uri)
      request_obj['Content-Type'] = 'application/json'
      request_obj['Accept'] = 'application/json'
      
      payload = {
        jsonrpc: '2.0',
        method: 'session/handshake',
        params: {
          protocolVersion: '2025-03-26',
          clientInfo: {
            name: 'admin-test',
            version: '1.0.0'
          }
        },
        id: 1
      }
      
      request_obj.body = payload.to_json
      response = http.request(request_obj)
      
      if response.code == '200'
        response_data = JSON.parse(response.body)
        if response_data['jsonrpc'] == '2.0' && response_data['result']
          {
            success: true,
            details: {
              status_code: response.code,
              protocol_version: response_data['result']['protocolVersion'],
              capabilities: response_data['result']['capabilities'],
              server_info: response_data['result']['serverInfo']
            }
          }
        else
          {
            success: false,
            error: "Invalid response format: #{response_data}"
          }
        end
      else
        {
          success: false,
          error: "HTTP #{response.code}: #{response.body}"
        }
      end
    rescue => e
      {
        success: false,
        error: e.message
      }
    end
  end
end
