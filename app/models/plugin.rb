class Plugin < ApplicationRecord
  # Serialization
  serialize :settings, coder: JSON, type: Hash
  
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :version, presence: true
  validates :slug, presence: true, uniqueness: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  
  # Callbacks
  after_initialize :set_defaults, if: :new_record?
  before_validation :generate_slug, if: -> { slug.blank? }
  
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
  
  def generate_slug
    return if name.blank?
    self.slug = name.underscore.gsub(/\s+/, '_').gsub(/[^a-z0-9_]/, '')
  end
end
