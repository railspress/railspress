class CustomFieldValue < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  # Associations
  belongs_to :custom_field
  belongs_to :post, optional: true
  belongs_to :page, optional: true
  
  # Validations
  validates :meta_key, presence: true
  validate :must_belong_to_post_or_page
  
  # Scopes
  scope :for_post, ->(post_id) { where(post_id: post_id) }
  scope :for_page, ->(page_id) { where(page_id: page_id) }
  scope :by_key, ->(key) { where(meta_key: key) }
  
  # Get typed value based on field type
  def typed_value
    return nil if value.blank?
    
    case custom_field&.field_type
    when 'number'
      value.to_f
    when 'true_false'
      value.to_s == '1' || value.to_s.downcase == 'true'
    when 'checkbox'
      value.is_a?(String) ? JSON.parse(value) : value
    when 'repeater', 'flexible_content', 'group'
      value.is_a?(String) ? JSON.parse(value) : value
    when 'gallery'
      value.is_a?(String) ? JSON.parse(value) : value
    else
      value
    end
  rescue JSON::ParserError
    value
  end
  
  # Set value with automatic serialization
  def typed_value=(val)
    case custom_field&.field_type
    when 'checkbox', 'repeater', 'flexible_content', 'group', 'gallery'
      self.value = val.is_a?(String) ? val : val.to_json
    when 'true_false'
      self.value = val.to_s == '1' || val.to_s.downcase == 'true' ? '1' : '0'
    else
      self.value = val.to_s
    end
  end
  
  private
  
  def must_belong_to_post_or_page
    if post_id.blank? && page_id.blank?
      errors.add(:base, 'Must belong to either a post or a page')
    end
    
    if post_id.present? && page_id.present?
      errors.add(:base, 'Cannot belong to both a post and a page')
    end
  end
end
