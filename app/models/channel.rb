class Channel < ApplicationRecord
  # Multi-tenancy
  # acts_as_tenant(:tenant, optional: true) # Temporarily disabled for testing
  
  # Associations
  has_and_belongs_to_many :posts
  has_and_belongs_to_many :pages
  has_and_belongs_to_many :media, class_name: 'Medium'
  has_many :channel_overrides, dependent: :destroy
  
  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :locale, presence: true
  
  # Scopes
  scope :active, -> { where(enabled: true) }
  scope :by_domain, ->(domain) { where(domain: domain) }
  scope :by_locale, ->(locale) { where(locale: locale) }
  
  # Callbacks
  before_validation :set_default_locale
  before_validation :generate_slug_from_name, if: -> { slug.blank? }
  
  # Methods
  def self.find_by_domain(domain)
    find_by(domain: domain)
  end
  
  def self.find_by_slug(slug)
    find_by(slug: slug)
  end
  
  def override_for(resource_type, resource_id, path)
    channel_overrides.find_by(
      resource_type: resource_type,
      resource_id: resource_id,
      path: path,
      enabled: true
    )
  end
  
  def overrides_for(resource_type, resource_id)
    channel_overrides.where(
      resource_type: resource_type,
      resource_id: resource_id,
      kind: 'override',
      enabled: true
    )
  end
  
  def exclusions_for(resource_type, resource_id)
    channel_overrides.where(
      resource_type: resource_type,
      resource_id: resource_id,
      kind: 'exclude',
      enabled: true
    )
  end
  
  def excluded?(resource_type, resource_id)
    exclusions_for(resource_type, resource_id).exists?
  end
  
  def apply_overrides_to_data(data, resource_type, resource_id, include_provenance = false)
    overrides = overrides_for(resource_type, resource_id)
    return data, {} if overrides.empty?
    
    result = data.deep_dup
    provenance = {}
    
    overrides.each do |override|
      path_parts = override.path.split('.')
      current = result
      
      # Navigate to the parent of the target key
      path_parts[0..-2].each do |part|
        current = current[part] ||= {}
      end
      
      # Set the final value
      current[path_parts.last] = override.data
      
      # Track provenance if requested
      if include_provenance
        provenance[override.path] = 'channel_override'
      end
    end
    
    if include_provenance
      return result, provenance
    else
      return result
    end
  end
  
  def to_liquid
    {
      'id' => id,
      'name' => name,
      'slug' => slug,
      'domain' => domain,
      'locale' => locale,
      'metadata' => metadata,
      'settings' => settings
    }
  end
  
  private
  
  def set_default_locale
    self.locale ||= 'en'
  end
  
  def generate_slug_from_name
    self.slug = name.parameterize if name.present?
  end
end
