module Metable
  extend ActiveSupport::Concern

  included do
    # This will be added by the has_many :meta_fields association
  end

  # Convenience methods for meta fields
  def get_meta(key)
    MetaField.get(self, key)
  end

  def set_meta(key, value, immutable: false)
    MetaField.set(self, key, value, immutable: immutable)
  end

  def delete_meta(key)
    MetaField.delete(self, key)
  end

  def bulk_get_meta(keys)
    MetaField.bulk_get(self, keys)
  end

  def bulk_set_meta(hash, immutable: false)
    MetaField.bulk_set(self, hash, immutable: immutable)
  end

  def all_meta
    MetaField.all_for(self)
  end

  def has_meta?(key)
    get_meta(key).present?
  end

  def meta_keys
    meta_fields.pluck(:key)
  end

  def immutable_meta_keys
    meta_fields.immutable.pluck(:key)
  end

  def mutable_meta_keys
    meta_fields.mutable.pluck(:key)
  end

  # Plugin helpers for common use cases
  def get_meta_as_string(key, default = "")
    value = get_meta(key)
    value.present? ? value.to_s : default
  end

  def get_meta_as_integer(key, default = 0)
    value = get_meta(key)
    value.present? ? value.to_i : default
  end

  def get_meta_as_float(key, default = 0.0)
    value = get_meta(key)
    value.present? ? value.to_f : default
  end

  def get_meta_as_boolean(key, default = false)
    value = get_meta(key)
    return default if value.blank?
    
    case value.to_s.downcase
    when 'true', '1', 'yes', 'on'
      true
    when 'false', '0', 'no', 'off'
      false
    else
      default
    end
  end

  def get_meta_as_json(key, default = {})
    value = get_meta(key)
    return default if value.blank?
    
    begin
      JSON.parse(value)
    rescue JSON::ParserError
      default
    end
  end

  def set_meta_json(key, value, immutable: false)
    set_meta(key, value.to_json, immutable: immutable)
  end

  # Clear all meta fields (useful for cleanup)
  def clear_all_meta!
    meta_fields.mutable.destroy_all
  end

  # Plugin namespace helpers
  def get_plugin_meta(plugin_name, key)
    get_meta("#{plugin_name}:#{key}")
  end

  def set_plugin_meta(plugin_name, key, value, immutable: false)
    set_meta("#{plugin_name}:#{key}", value, immutable: immutable)
  end

  def delete_plugin_meta(plugin_name, key)
    delete_meta("#{plugin_name}:#{key}")
  end

  def bulk_get_plugin_meta(plugin_name, keys)
    prefixed_keys = keys.map { |key| "#{plugin_name}:#{key}" }
    values = bulk_get_meta(prefixed_keys)
    keys.zip(values).to_h
  end

  def bulk_set_plugin_meta(plugin_name, hash, immutable: false)
    prefixed_hash = hash.transform_keys { |key| "#{plugin_name}:#{key}" }
    bulk_set_meta(prefixed_hash, immutable: immutable)
  end

  def get_all_plugin_meta(plugin_name)
    all_meta.select { |key, _| key.start_with?("#{plugin_name}:") }
           .transform_keys { |key| key.sub("#{plugin_name}:", "") }
           .transform_values { |meta_data| meta_data.is_a?(Hash) ? meta_data[:value] : meta_data }
  end

  def delete_all_plugin_meta(plugin_name)
    meta_fields.where("key LIKE ?", "#{plugin_name}:%").destroy_all
  end
end
