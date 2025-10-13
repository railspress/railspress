class MenuItem < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  belongs_to :menu
  belongs_to :parent, class_name: 'MenuItem', optional: true
  
  # Hierarchical structure
  has_many :children, class_name: 'MenuItem', foreign_key: 'parent_id', dependent: :destroy
  
  # Validations
  validates :label, presence: true
  validates :url, presence: true
  validates :position, presence: true, numericality: { only_integer: true }
  
  # Scopes
  scope :ordered, -> { order(position: :asc) }
  scope :root_items, -> { where(parent_id: nil) }
  
  # Callbacks
  before_validation :set_position, on: :create
  
  private
  
  def set_position
    self.position ||= (menu.menu_items.maximum(:position) || 0) + 1
  end
end
