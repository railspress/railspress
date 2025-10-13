class Menu < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  # Associations
  has_many :menu_items, dependent: :destroy
  
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :location, presence: true
  
  # Scopes
  scope :by_location, ->(location) { where(location: location) }
  
  # Methods
  def root_items
    menu_items.where(parent_id: nil).order(position: :asc)
  end
end
