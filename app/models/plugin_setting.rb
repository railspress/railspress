class PluginSetting < ApplicationRecord
  # Validations
  validates :plugin_name, presence: true
  validates :key, presence: true, uniqueness: { scope: :plugin_name }
  validates :setting_type, inclusion: { in: %w[string boolean integer float array json text] }, allow_nil: true
  
  # Scopes
  scope :for_plugin, ->(plugin_name) { where(plugin_name: plugin_name) }
  scope :by_key, ->(key) { where(key: key) }
  
  # Callbacks
  before_save :set_default_type
  
  # Get typed value
  def typed_value
    case setting_type
    when 'boolean'
      value == 'true' || value == '1' || value == true
    when 'integer'
      value.to_i
    when 'float'
      value.to_f
    when 'array', 'json'
      JSON.parse(value) rescue []
    else
      value
    end
  end
  
  # Set typed value
  def typed_value=(new_value)
    case setting_type
    when 'boolean'
      self.value = new_value.to_s
    when 'integer', 'float'
      self.value = new_value.to_s
    when 'array', 'json'
      self.value = new_value.to_json
    else
      self.value = new_value.to_s
    end
  end
  
  # Class method to get setting
  def self.get(plugin_name, key, default = nil)
    setting = find_by(plugin_name: plugin_name, key: key)
    setting ? setting.typed_value : default
  end
  
  # Class method to set setting
  def self.set(plugin_name, key, value, type = 'string')
    setting = find_or_initialize_by(plugin_name: plugin_name, key: key)
    setting.setting_type = type
    setting.typed_value = value
    setting.save!
    setting
  end
  
  private
  
  def set_default_type
    self.setting_type ||= 'string'
  end
end
