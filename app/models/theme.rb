class Theme < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  # Associations
  has_many :templates, dependent: :destroy
  
  # Serialization
  serialize :settings, coder: JSON, type: Hash
  
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :version, presence: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  
  # Callbacks
  after_initialize :set_defaults, if: :new_record?
  before_save :deactivate_others, if: :active?
  after_create :create_default_templates
  
  # Methods
  def self.current
    active.first || first
  end
  
  def activate!
    Theme.where.not(id: id).update_all(active: false)
    update(active: true)
  end
  
  def get_template(template_type)
    templates.by_type(template_type).active.first
  end
  
  private
  
  def set_defaults
    self.active = false if active.nil?
    self.settings ||= {}
  end
  
  def deactivate_others
    Theme.where.not(id: id).update_all(active: false) if active_changed? && active?
  end
  
  def create_default_templates
    Template::TEMPLATE_TYPES.each do |type|
      templates.create!(
        name: type.titleize,
        template_type: type,
        description: "Default #{type} template"
      )
    end
  end
end
