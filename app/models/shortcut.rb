class Shortcut < ApplicationRecord
  # Make tenant optional since shortcuts can be global
  belongs_to :tenant, optional: true
  
  CATEGORIES = %w[navigation content tools settings].freeze
  ACTION_TYPES = %w[navigate execute modal].freeze
  
  validates :name, presence: true
  validates :action_type, presence: true, inclusion: { in: ACTION_TYPES }
  validates :category, inclusion: { in: CATEGORIES }, allow_nil: true
  
  scope :active, -> { where(active: true) }
  scope :by_category, ->(category) { where(category: category) }
  scope :ordered, -> { order(:category, :position, :name) }
  
  after_initialize :set_defaults, if: :new_record?
  
  def execute(context = {})
    case action_type
    when 'navigate'
      # Return URL to navigate to
      action_value
    when 'execute'
      # Return JavaScript to execute
      action_value
    when 'modal'
      # Return modal to open
      action_value
    end
  end
  
  private
  
  def set_defaults
    self.active = true if active.nil?
    self.position ||= 0
    self.category ||= 'navigation'
  end
end
