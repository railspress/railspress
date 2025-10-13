class Widget < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  # Serialization
  serialize :settings, coder: JSON, type: Hash
  
  # Validations
  validates :title, presence: true
  validates :widget_type, presence: true
  validates :sidebar_location, presence: true
  validates :position, presence: true, numericality: { only_integer: true }
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_location, ->(location) { where(sidebar_location: location) }
  scope :ordered, -> { order(position: :asc) }
  
  # Callbacks
  after_initialize :set_defaults, if: :new_record?
  
  # Widget types
  WIDGET_TYPES = %w[
    text
    recent_posts
    categories
    tags
    search
    custom_html
    recent_comments
    archives
  ].freeze
  
  validates :widget_type, inclusion: { in: WIDGET_TYPES }
  
  private
  
  def set_defaults
    self.active = true if active.nil?
    self.settings ||= {}
    self.position ||= (Widget.where(sidebar_location: sidebar_location).maximum(:position) || 0) + 1
  end
end
