class MetaField < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  belongs_to :metable, polymorphic: true
  
  # Validations
  validates :key, presence: true, length: { maximum: 255 }
  validates :key, uniqueness: { scope: [:metable_type, :metable_id], message: "must be unique per metable" }
  validates :immutable, inclusion: { in: [true, false] }
  
  # Scopes
  scope :immutable, -> { where(immutable: true) }
  scope :mutable, -> { where(immutable: false) }
  scope :by_key, ->(key) { where(key: key) }
  
  # Callbacks for cache invalidation
  after_save :invalidate_metable_cache
  after_destroy :invalidate_metable_cache
  
  # Class methods for easy access
  def self.get(metable, key)
    cache_key = "meta_field:#{metable.class.name}:#{metable.id}:#{key}"
    
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      find_by(metable: metable, key: key)&.value
    end
  end
  
  def self.set(metable, key, value, immutable: false)
    meta_field = find_or_initialize_by(metable: metable, key: key)
    
    if meta_field.persisted? && meta_field.immutable?
      raise ArgumentError, "Cannot modify immutable meta field: #{key}"
    end
    
    meta_field.assign_attributes(value: value, immutable: immutable)
    meta_field.save!
    
    # Update cache
    cache_key = "meta_field:#{metable.class.name}:#{metable.id}:#{key}"
    Rails.cache.write(cache_key, value, expires_in: 1.hour)
    
    meta_field
  end
  
  def self.delete(metable, key)
    meta_field = find_by(metable: metable, key: key)
    
    if meta_field&.immutable?
      raise ArgumentError, "Cannot delete immutable meta field: #{key}"
    end
    
    if meta_field&.destroy
      # Clear cache
      cache_key = "meta_field:#{metable.class.name}:#{metable.id}:#{key}"
      Rails.cache.delete(cache_key)
      
      # Clear metable's meta cache
      metable_cache_key = "meta_fields:#{metable.class.name}:#{metable.id}"
      Rails.cache.delete(metable_cache_key)
    end
    
    meta_field
  end
  
  def self.bulk_get(metable, keys)
    cache_keys = keys.map { |key| "meta_field:#{metable.class.name}:#{metable.id}:#{key}" }
    
    cached_values = Rails.cache.read_multi(*cache_keys)
    missing_keys = keys - cached_values.keys.map { |k| k.split(':').last }
    
    if missing_keys.any?
      # Fetch missing values from database
      missing_meta_fields = where(metable: metable, key: missing_keys)
      
      missing_meta_fields.each do |meta_field|
        cache_key = "meta_field:#{metable.class.name}:#{metable.id}:#{meta_field.key}"
        Rails.cache.write(cache_key, meta_field.value, expires_in: 1.hour)
        cached_values[meta_field.key] = meta_field.value
      end
    end
    
    # Return values in the same order as requested keys
    keys.map { |key| cached_values[key] }
  end
  
  def self.bulk_set(metable, hash, immutable: false)
    transaction do
      hash.each do |key, value|
        set(metable, key, value, immutable: immutable)
      end
    end
    
    # Clear metable's meta cache
    metable_cache_key = "meta_fields:#{metable.class.name}:#{metable.id}"
    Rails.cache.delete(metable_cache_key)
  end
  
  def self.all_for(metable)
    cache_key = "meta_fields:#{metable.class.name}:#{metable.id}"
    
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      where(metable: metable).pluck(:key, :value, :immutable).to_h do |key, value, immutable|
        [key, { value: value, immutable: immutable }]
      end
    end
  end
  
  # Instance methods
  def to_s
    value.to_s
  end
  
  def to_i
    value.to_i
  end
  
  def to_f
    value.to_f
  end
  
  def to_bool
    ActiveModel::Type::Boolean.new.cast(value)
  end
  
  def json_value
    JSON.parse(value) if value.present?
  rescue JSON::ParserError
    nil
  end
  
  private
  
  def invalidate_metable_cache
    # Clear individual field cache
    cache_key = "meta_field:#{metable.class.name}:#{metable.id}:#{key}"
    Rails.cache.delete(cache_key)
    
    # Clear metable's meta cache
    metable_cache_key = "meta_fields:#{metable.class.name}:#{metable.id}"
    Rails.cache.delete(metable_cache_key)
  end
end
