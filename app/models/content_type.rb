class ContentType < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant)
  
  # Associations
  has_many :posts, dependent: :nullify
  
  # Validations
  validates :ident, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_-]+\z/, message: "only allows lowercase letters, numbers, hyphens, and underscores" }
  validates :label, presence: true
  validates :singular, presence: true
  validates :plural, presence: true
  
  # JSON fields
  attribute :supports, :json, default: -> { ['title', 'editor', 'excerpt', 'thumbnail', 'comments'] }
  attribute :capabilities, :json, default: -> { {} }
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :public_types, -> { where(public: true) }
  scope :ordered, -> { order(:menu_position, :label) }
  
  # Callbacks
  before_validation :set_defaults, on: :create
  before_validation :normalize_ident
  
  # Class methods
  def self.find_by_ident(ident)
    find_by(ident: ident.to_s.downcase.strip)
  end
  
  def self.default_type
    find_by_ident('post') || first
  end
  
  # Instance methods
  def to_param
    ident
  end
  
  def display_name
    label
  end
  
  def supports?(feature)
    supports.is_a?(Array) && supports.include?(feature.to_s)
  end
  
  def add_support(feature)
    self.supports ||= []
    self.supports << feature.to_s unless supports?(feature)
    self.supports = supports.uniq
  end
  
  def remove_support(feature)
    self.supports ||= []
    self.supports.delete(feature.to_s)
  end
  
  def can?(capability)
    capabilities.is_a?(Hash) && capabilities[capability.to_s]
  end
  
  def rest_endpoint
    rest_base.presence || ident.pluralize
  end
  
  private
  
  def set_defaults
    self.rest_base ||= ident&.pluralize
    self.singular ||= label
    self.plural ||= label&.pluralize
    self.icon ||= 'document-text'
    self.public = true if public.nil?
    self.active = true if active.nil?
    self.hierarchical = false if hierarchical.nil?
    self.has_archive = true if has_archive.nil?
  end
  
  def normalize_ident
    self.ident = ident.to_s.downcase.strip.gsub(/[^a-z0-9_-]/, '-') if ident.present?
  end
end
