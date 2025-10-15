class Page < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  # Trash functionality
  include Trashable
  
  # Soft deletes
  include Discard::Model
  self.discard_column = :deleted_at
  
  # Versioning
  has_paper_trail
  
  # Search - Database agnostic
  def self.search_full_text(query)
    return none if query.blank?
    
    # Simple LIKE search that works with all databases
    query_pattern = "%#{query}%"
    where(
      "title LIKE ? OR meta_description LIKE ? OR content LIKE ?",
      query_pattern, query_pattern, query_pattern
    )
  end
  
  # Custom Taxonomies
  include HasTaxonomies
  
  # Meta fields for plugin extensibility
  has_many :meta_fields, as: :metable, dependent: :destroy
  include Metable
  
  # SEO
  include SeoOptimizable
  
  belongs_to :user
  belongs_to :parent, class_name: 'Page', optional: true
  belongs_to :page_template, optional: true
  
  # Rich text content
  has_rich_text :content
  
  # Hierarchical structure
  has_many :children, class_name: 'Page', foreign_key: 'parent_id', dependent: :destroy
  
  # Comments
  has_many :comments, as: :commentable, dependent: :destroy
  
  # Status enum
  enum status: {
    draft: 0,
    published: 1,
    scheduled: 2,
    pending_review: 3,
    private_page: 4,
    trash: 5
  }, _suffix: true
  
  # Status scopes
  scope :visible_to_public, -> { 
    kept.where(status: [:published, :scheduled])
      .where('published_at IS NULL OR published_at <= ?', Time.current)
  }
  scope :not_trashed, -> { where.not(status: :trash) }
  scope :trashed, -> { where(status: :trash) }
  scope :awaiting_review, -> { where(status: :pending_review) }
  scope :scheduled_future, -> { 
    where(status: :scheduled)
      .where('published_at > ?', Time.current)
  }
  scope :scheduled_past, -> {
    where(status: :scheduled)
      .where('published_at <= ?', Time.current)
  }
  
  # Check if page should be visible to public (without password check)
  def visible_to_public?
    return false if trash_status?
    return false if draft_status?
    return false if pending_review_status?
    return false if private_page_status? # Only for logged-in users
    
    if scheduled_status?
      published_at.present? && published_at <= Time.current
    else
      published_status?
    end
  end
  
  # Check if page is password protected
  def password_protected?
    password.present?
  end
  
  # Check if provided password is correct
  def password_matches?(input_password)
    return true unless password_protected?
    password == input_password
  end
  
  # Auto-publish scheduled pages
  def check_scheduled_publish
    if scheduled_status? && published_at.present? && published_at <= Time.current
      update(status: :published)
    end
  end
  
  # Friendly ID for slugs
  extend FriendlyId
  friendly_id :title, use: :slugged
  
  # Validations
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :status, presence: true
  validates :password, length: { minimum: 4 }, allow_blank: true
  
  # Scopes
  scope :published, -> { where(status: 'published').where('published_at <= ?', Time.current) }
  scope :root_pages, -> { where(parent_id: nil) }
  scope :ordered, -> { order(order: :asc, title: :asc) }
  
  # Callbacks
  before_validation :set_published_at, if: :published_status?
  after_create :trigger_page_created_hook
  after_update :trigger_page_updated_hook, if: :saved_change_to_status?
  
  # Methods
  def should_generate_new_friendly_id?
    title_changed? || slug.blank?
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
  
  private
  
  def set_published_at
    self.published_at ||= Time.current
  end
  
  def trigger_page_created_hook
    Railspress::PluginSystem.do_action('page_created', self)
  end
  
  def trigger_page_updated_hook
    if published_status?
      Railspress::PluginSystem.do_action('page_published', self)
    end
    Railspress::PluginSystem.do_action('page_updated', self)
  end
  
  # SEO URL override
  def seo_default_url
    Rails.application.routes.url_helpers.page_url(slug)
  rescue
    "#"
  end
  
  # Custom Fields (ACF-style)
  has_many :custom_field_values, dependent: :destroy
  
  # Get field value by name
  def get_field(field_name)
    value = custom_field_values.by_key(field_name.to_s).first
    value&.typed_value
  end
  
  # Set field value by name
  def set_field(field_name, field_value)
    field = CustomField.joins(:field_group)
                      .where('custom_fields.name = ?', field_name.to_s)
                      .where('field_groups.active = ?', true)
                      .first
    
    return false unless field
    
    value_record = custom_field_values.find_or_initialize_by(
      custom_field: field,
      meta_key: field_name.to_s
    )
    
    value_record.typed_value = field_value
    value_record.save
  end
  
  # Get all fields as hash
  def get_fields
    custom_field_values.includes(:custom_field).each_with_object({}) do |cfv, hash|
      hash[cfv.meta_key] = cfv.typed_value
    end
  end
  
  # Update multiple fields at once
  def update_fields(fields_hash)
    fields_hash.each do |key, value|
      set_field(key, value)
    end
  end
  
  # Get field groups that should be shown for this page
  def applicable_field_groups
    FieldGroup.active.ordered.select { |fg| fg.matches_location?(self) }
  end
  
  # Template methods
  def template
    page_template || default_template
  end
  
  def default_template
    PageTemplate.active.by_type('default').first
  end
  
  def render_with_template
    template&.render_content(self) || content.to_s
  end
end
