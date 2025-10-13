class Plugin < ApplicationRecord
  # Serialization
  serialize :settings, coder: JSON, type: Hash
  
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :version, presence: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  
  # Callbacks
  after_initialize :set_defaults, if: :new_record?
  
  # Methods
  def activate!
    update(active: true)
  end
  
  def deactivate!
    update(active: false)
  end
  
  private
  
  def set_defaults
    self.active = false if active.nil?
    self.settings ||= {}
  end
end
