class Term < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  belongs_to :taxonomy
  belongs_to :parent, class_name: 'Term', optional: true
  
  # Associations
  has_many :children, class_name: 'Term', foreign_key: 'parent_id', dependent: :destroy
  has_many :term_relationships, dependent: :destroy
  
  # Serialization
  serialize :metadata, coder: JSON, type: Hash
  
  # Friendly ID for slugs
  extend FriendlyId
  friendly_id :name, use: [:slugged, :scoped], scope: :taxonomy
  
  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :taxonomy_id }
  validates :taxonomy, presence: true
  
  # Scopes
  scope :root_terms, -> { where(parent_id: nil) }
  scope :ordered, -> { order(name: :asc) }
  scope :popular, -> { order(count: :desc) }
  scope :for_taxonomy, ->(taxonomy_slug) { joins(:taxonomy).where(taxonomies: { slug: taxonomy_slug }) }
  
  # Callbacks
  after_initialize :set_defaults, if: :new_record?
  after_save :update_count
  
  # Methods
  def should_generate_new_friendly_id?
    name_changed? || slug.blank?
  end
  
  def hierarchical?
    taxonomy&.hierarchical?
  end
  
  def update_count
    self.count = term_relationships.count
    save if count_changed?
  end
  
  def breadcrumbs
    result = [self]
    current = self
    while current.parent.present?
      result.unshift(current.parent)
      current = current.parent
    end
    result
  end
  
  # Get all objects (posts/pages) with this term
  def objects
    term_relationships.includes(:object).map(&:object).compact
  end
  
  # Get objects of specific type
  def objects_of_type(type)
    term_relationships.where(object_type: type).includes(:object).map(&:object).compact
  end
  
  # Get posts associated with this term
  def posts
    Post.joins(:term_relationships).where(term_relationships: { term_id: id })
  end
  
  # Convert Term to Liquid-compatible hash
  def to_liquid
    {
      'id' => id,
      'name' => name,
      'slug' => slug,
      'description' => description,
      'count' => count,
      'taxonomy' => taxonomy&.name,
      'taxonomy_slug' => taxonomy&.slug,
      'parent_id' => parent_id,
      'children' => children.to_a, # Convert AssociationRelation to array
      'metadata' => metadata || {}
    }
  end
  
  # Generate URL for the term
  def url
    # This would need to be implemented based on your routing
    "/#{taxonomy&.slug}/#{slug}"
  end
  
  # Make methods public for Liquid access
  public :url, :to_liquid
  
  private
  
  def set_defaults
    self.count ||= 0
    self.metadata ||= {}
  end
end
