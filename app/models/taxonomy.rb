class Taxonomy < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant)
  
  # Associations
  has_many :terms, dependent: :destroy
  
  # Serialization
  serialize :object_types, coder: JSON, type: Array
  serialize :settings, coder: JSON, type: Hash
  
  # Friendly ID for slugs
  extend FriendlyId
  friendly_id :name, use: :slugged
  
  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  
  # Scopes
  scope :hierarchical, -> { where(hierarchical: true) }
  scope :flat, -> { where(hierarchical: false) }
  scope :for_posts, -> { where("object_types LIKE ?", "%Post%") }
  scope :for_pages, -> { where("object_types LIKE ?", "%Page%") }
  
  # Callbacks
  after_initialize :set_defaults, if: :new_record?
  
  # Methods
  def should_generate_new_friendly_id?
    name_changed? || slug.blank?
  end
  
  def root_terms
    terms.where(parent_id: nil).order(name: :asc)
  end
  
  def term_count
    terms.count
  end
  
  def applies_to?(object_type)
    object_types.include?(object_type.to_s)
  end
  
  # Built-in taxonomies
  def self.categories
    find_or_create_by!(slug: 'category') do |t|
      t.name = 'Categories'
      t.description = 'Post categories'
      t.hierarchical = true
      t.object_types = ['Post']
    end
  end
  
  def self.tags
    find_or_create_by!(slug: 'post_tag') do |t|
      t.name = 'Tags'
      t.description = 'Post tags'
      t.hierarchical = false
      t.object_types = ['Post']
    end
  end
  
  private
  
  def set_defaults
    self.hierarchical = false if hierarchical.nil?
    self.object_types ||= []
    self.settings ||= {}
  end
end
