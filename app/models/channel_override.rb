class ChannelOverride < ApplicationRecord
  belongs_to :channel
  
  # Validations
  validates :resource_type, presence: true
  validates :kind, presence: true, inclusion: { in: %w[override exclude] }
  validates :path, presence: true
  validates :resource_id, presence: true, if: -> { resource_type.present? }
  
  # Scopes
  scope :overrides, -> { where(kind: 'override') }
  scope :exclusions, -> { where(kind: 'exclude') }
  scope :enabled, -> { where(enabled: true) }
  scope :for_resource, ->(resource_type, resource_id) { where(resource_type: resource_type, resource_id: resource_id) }
  scope :for_path, ->(path) { where(path: path) }
  
  # Methods
  def resource
    return nil unless resource_type.present? && resource_id.present?
    
    case resource_type
    when 'Post'
      Post.find_by(id: resource_id)
    when 'Page'
      Page.find_by(id: resource_id)
    when 'Medium'
      Medium.find_by(id: resource_id)
    when 'Setting'
      SiteSetting.find_by(id: resource_id)
    else
      resource_type.constantize.find_by(id: resource_id) rescue nil
    end
  end
  
  def resource_name
    resource&.title || resource&.name || "#{resource_type} ##{resource_id}"
  end
  
  def is_override?
    kind == 'override'
  end
  
  def is_exclusion?
    kind == 'exclude'
  end
  
  def apply_to_data(data)
    return data if !enabled? || !is_override?
    
    path_parts = path.split('.')
    current = data
    
    # Navigate to the parent of the target key
    path_parts[0..-2].each do |part|
      current = current[part] ||= {}
    end
    
    # Set the final value
    current[path_parts.last] = self.data
    
    data
  end
  
  def should_exclude_resource?
    enabled? && is_exclusion?
  end
end
