class SiteSetting < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  # Validations
  validates :key, presence: true
  validates :key, uniqueness: { scope: :tenant_id }
  validates :setting_type, presence: true
  
  # Setting types
  SETTING_TYPES = %w[string integer boolean text].freeze
  validates :setting_type, inclusion: { in: SETTING_TYPES }
  
  # Class methods for easy access
  def self.get(key, default = nil)
    # Use Rails cache to avoid repeated database calls
    tenant = ActsAsTenant.current_tenant
    tenant_id = tenant.is_a?(Tenant) ? tenant.id : 'global'
    cache_key = "site_setting:#{tenant_id}:#{key}"
    
    # Get cache expiration from settings or use default
    cache_expires_in = get_cache_expiration
    
    Rails.cache.fetch(cache_key, expires_in: cache_expires_in) do
      if tenant.is_a?(Tenant)
        setting = where(tenant: tenant).find_by(key: key)
      else
        setting = find_by(key: key)
      end
      setting ? setting.typed_value : default
    end
  rescue ActiveRecord::ConnectionTimeoutError => e
    Rails.logger.error("SiteSetting.get connection timeout for key '#{key}': #{e.message}")
    default
  rescue => e
    Rails.logger.error("SiteSetting.get error for key '#{key}': #{e.message}")
    default
  end
  
  def self.set(key, value, setting_type = 'string')
    tenant = ActsAsTenant.current_tenant
    setting = if tenant.is_a?(Tenant)
      where(tenant: tenant).find_or_initialize_by(key: key)
    else
      find_or_initialize_by(key: key)
    end
    setting.value = value.to_s
    setting.setting_type = setting_type
    setting.tenant = tenant if tenant.is_a?(Tenant)
    
    if setting.save
      # Clear cache when setting is updated
      clear_cache_for_key(key)
      true
    else
      false
    end
  end

  # Clear cache for a specific key
  def self.clear_cache_for_key(key)
    tenant = ActsAsTenant.current_tenant
    tenant_id = tenant.is_a?(Tenant) ? tenant.id : 'global'
    cache_key = "site_setting:#{tenant_id}:#{key}"
    Rails.cache.delete(cache_key)
  end

  # Clear all site setting caches for current tenant
  def self.clear_all_caches
    tenant = ActsAsTenant.current_tenant
    tenant_id = tenant.is_a?(Tenant) ? tenant.id : 'global'
    # This is a simple approach - in production you might want to use cache versioning
    Rails.cache.delete_matched("site_setting:#{tenant_id}:*")
  end

  # Get cache expiration time from settings
  def self.get_cache_expiration
    # Try to get from settings first, but avoid infinite recursion
    begin
      # Use a shorter cache for this specific setting to avoid recursion
      cache_key = "site_setting_cache_expiration"
      Rails.cache.fetch(cache_key, expires_in: 1.minute) do
        # Get from database without using our cached get method to avoid recursion
        tenant = ActsAsTenant.current_tenant
        setting = if tenant.is_a?(Tenant)
          where(tenant: tenant).find_by(key: 'site_setting_cache_expires_in')
        else
          find_by(key: 'site_setting_cache_expires_in')
        end
        
        if setting
          setting.typed_value.minutes
        else
          # Default to 5 minutes if not set
          5.minutes
        end
      end
    rescue => e
      Rails.logger.error("Error getting cache expiration: #{e.message}")
      # Fallback to default
      5.minutes
    end
  end
  
  # Instance methods
  def typed_value
    case setting_type
    when 'integer'
      value.to_i
    when 'boolean'
      value == 'true' || value == '1'
    when 'text', 'string'
      value
    else
      value
    end
  end
end
