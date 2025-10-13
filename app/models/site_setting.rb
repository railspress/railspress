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
    setting = find_by(key: key)
    setting ? setting.typed_value : default
  end
  
  def self.set(key, value, setting_type = 'string')
    setting = find_or_initialize_by(key: key)
    setting.value = value.to_s
    setting.setting_type = setting_type
    setting.save
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
