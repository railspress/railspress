class CustomField < ApplicationRecord
  # Associations
  belongs_to :field_group
  has_many :custom_field_values, dependent: :destroy
  
  # Serialization
  serialize :choices, coder: JSON, type: Hash
  serialize :conditional_logic, coder: JSON, type: Hash
  serialize :settings, coder: JSON, type: Hash
  
  # Validations
  validates :name, presence: true
  validates :label, presence: true
  validates :field_type, presence: true, inclusion: { in: FieldGroup::FIELD_TYPES.keys }
  
  # Callbacks
  before_validation :normalize_name
  
  # Scopes
  scope :ordered, -> { order(position: :asc) }
  scope :required_fields, -> { where(required: true) }
  scope :by_type, ->(type) { where(field_type: type) }
  
  # Get formatted choices for select/radio/checkbox fields
  def formatted_choices
    return [] if choices.blank?
    
    if choices.is_a?(Hash)
      choices.map { |k, v| [v, k] }
    elsif choices.is_a?(Array)
      choices.map { |c| [c, c] }
    else
      []
    end
  end
  
  # Check if field should be shown based on conditional logic
  def should_show?(values = {})
    return true if conditional_logic.blank?
    
    logic = conditional_logic.is_a?(String) ? JSON.parse(conditional_logic) : conditional_logic
    return true if logic.blank? || logic['rules'].blank?
    
    operator = logic['operator'] || 'and'  # 'and' or 'or'
    rules = logic['rules']
    
    results = rules.map do |rule|
      field_name = rule['field']
      condition = rule['operator']  # '==', '!=', 'contains', etc.
      expected_value = rule['value']
      
      actual_value = values[field_name].to_s
      
      case condition
      when '=='
        actual_value == expected_value.to_s
      when '!='
        actual_value != expected_value.to_s
      when 'contains'
        actual_value.include?(expected_value.to_s)
      when 'not_contains'
        !actual_value.include?(expected_value.to_s)
      when 'empty'
        actual_value.blank?
      when 'not_empty'
        actual_value.present?
      else
        true
      end
    end
    
    if operator == 'and'
      results.all?
    else  # 'or'
      results.any?
    end
  rescue
    true  # Show by default if logic is invalid
  end
  
  # Get setting value
  def get_setting(key, default = nil)
    return default if settings.blank?
    settings[key.to_s] || default
  end
  
  # Field type helpers
  def text_field?
    %w[text email url password].include?(field_type)
  end
  
  def textarea_field?
    field_type == 'textarea'
  end
  
  def number_field?
    field_type == 'number'
  end
  
  def wysiwyg_field?
    field_type == 'wysiwyg'
  end
  
  def select_field?
    %w[select checkbox radio button_group].include?(field_type)
  end
  
  def boolean_field?
    field_type == 'true_false'
  end
  
  def date_field?
    %w[date_picker date_time_picker time_picker].include?(field_type)
  end
  
  def image_field?
    %w[image file gallery].include?(field_type)
  end
  
  def relational_field?
    %w[post_object page_link relationship taxonomy user].include?(field_type)
  end
  
  def repeater_field?
    %w[repeater flexible_content group].include?(field_type)
  end
  
  private
  
  def normalize_name
    return if name.blank?
    self.name = name.parameterize(separator: '_')
  end
end
