class FieldGroup < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant)
  
  # Versioning
  has_paper_trail
  
  # Associations
  has_many :custom_fields, dependent: :destroy
  accepts_nested_attributes_for :custom_fields, allow_destroy: true
  
  # Serialization
  serialize :location_rules, coder: JSON, type: Hash
  
  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :tenant_id }
  
  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? }
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc) }
  scope :for_posts, -> { where("location_rules LIKE '%post%'") }
  scope :for_pages, -> { where("location_rules LIKE '%page%'") }
  
  # ACF-style field types
  FIELD_TYPES = {
    # Basic
    'text' => 'Text',
    'textarea' => 'Text Area',
    'number' => 'Number',
    'email' => 'Email',
    'url' => 'URL',
    'password' => 'Password',
    
    # Content
    'wysiwyg' => 'WYSIWYG Editor',
    'oembed' => 'oEmbed',
    'image' => 'Image',
    'file' => 'File',
    'gallery' => 'Gallery',
    
    # Choice
    'select' => 'Select',
    'checkbox' => 'Checkbox',
    'radio' => 'Radio Button',
    'button_group' => 'Button Group',
    'true_false' => 'True / False',
    
    # Relational
    'link' => 'Link',
    'post_object' => 'Post Object',
    'page_link' => 'Page Link',
    'relationship' => 'Relationship',
    'taxonomy' => 'Taxonomy',
    'user' => 'User',
    
    # jQuery
    'date_picker' => 'Date Picker',
    'date_time_picker' => 'Date Time Picker',
    'time_picker' => 'Time Picker',
    'color_picker' => 'Color Picker',
    
    # Layout
    'message' => 'Message',
    'accordion' => 'Accordion',
    'tab' => 'Tab',
    'group' => 'Group',
    'repeater' => 'Repeater',
    'flexible_content' => 'Flexible Content'
  }.freeze
  
  # Location rules for where to show this field group
  def self.location_rule_operators
    {
      '==' => 'is equal to',
      '!=' => 'is not equal to',
      'contains' => 'contains',
      'not_contains' => 'does not contain'
    }
  end
  
  def self.location_rule_params
    {
      'post_type' => 'Post Type',
      'post_category' => 'Post Category',
      'post_status' => 'Post Status',
      'page_type' => 'Page Type',
      'page_parent' => 'Page Parent',
      'page_template' => 'Page Template',
      'current_user_role' => 'Current User Role'
    }
  end
  
  # Check if this field group should be shown for a given object
  def matches_location?(object)
    return true if location_rules.blank?
    
    rules = location_rules.is_a?(String) ? JSON.parse(location_rules) : location_rules
    return true if rules.blank?
    
    # All rules must match (AND logic)
    rules.all? do |rule|
      param = rule['param']
      operator = rule['operator']
      value = rule['value']
      
      check_location_rule(object, param, operator, value)
    end
  rescue
    true  # Show by default if rules are invalid
  end
  
  private
  
  def generate_slug
    self.slug = name.parameterize
  end
  
  def check_location_rule(object, param, operator, value)
    case param
    when 'post_type'
      return false unless object.is_a?(Post)
      compare_values(

'post', operator, value)
    when 'post_category'
      return false unless object.is_a?(Post)
      category_taxonomy = Taxonomy.find_by(slug: 'category')
      return false unless category_taxonomy
      categories = object.terms.where(taxonomy: category_taxonomy).pluck(:id).map(&:to_s)
      compare_values(categories, operator, value)
    when 'page_type'
      return false unless object.is_a?(Page)
      compare_values('page', operator, value)
    else
      true
    end
  end
  
  def compare_values(actual, operator, expected)
    case operator
    when '=='
      if actual.is_a?(Array)
        actual.include?(expected)
      else
        actual.to_s == expected.to_s
      end
    when '!='
      if actual.is_a?(Array)
        !actual.include?(expected)
      else
        actual.to_s != expected.to_s
      end
    when 'contains'
      actual.to_s.include?(expected.to_s)
    when 'not_contains'
      !actual.to_s.include?(expected.to_s)
    else
      true
    end
  end
end
