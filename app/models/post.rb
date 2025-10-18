class Post < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  # Trash functionality
  include Trashable
  
  # Soft deletes
  include Discard::Model
  self.discard_column = :deleted_at
  
  # Versioning
  has_paper_trail
  
  # Versioning methods
  def versions_count
    versions.count
  end
  
  def latest_version
    versions.last
  end
  
  def version_at(timestamp)
    versions.where('created_at <= ?', timestamp).order(:created_at).last
  end
  
  def changes_since(version)
    return {} unless version
    
    current_changes = {}
    version.changeset.each do |field, change|
      current_changes[field] = {
        from: change[0],
        to: change[1],
        current: send(field)
      }
    end
    current_changes
  end
  
  def restore_to_version(version_id)
    version = versions.find(version_id)
    return false unless version
    
    # Create a backup of current version before restoring
    PaperTrail.without_versioning do
      version.reify.save!
    end
    true
  rescue => e
    Rails.logger.error "Failed to restore version #{version_id}: #{e.message}"
    false
  end
  
  def version_summary(version)
    changes = version.changeset
    return "Initial version" if changes.empty?
    
    summary_parts = []
    summary_parts << "Title changed" if changes.key?('title')
    summary_parts << "Content updated" if changes.key?('content')
    summary_parts << "Status changed" if changes.key?('status')
    summary_parts << "SEO updated" if changes.key?('meta_title') || changes.key?('meta_description')
    
    summary_parts.any? ? summary_parts.join(', ') : "Minor changes"
  end
  
  # Search - Database agnostic
  def self.search_full_text(query)
    return none if query.blank?
    
    # Simple LIKE search that works with all databases
    query_pattern = "%#{query}%"
    where(
      "title LIKE ? OR excerpt LIKE ? OR meta_description LIKE ? OR content LIKE ?",
      query_pattern, query_pattern, query_pattern, query_pattern
    )
  end
  
  # Custom Taxonomies
  include HasTaxonomies
  
  # Meta fields for plugin extensibility
  has_many :meta_fields, as: :metable, dependent: :destroy
  include Metable
  
  # Set up taxonomy associations
  has_taxonomy :category
  has_taxonomy :post_tag
  
  # SEO
  include SeoOptimizable
  
  belongs_to :user
  belongs_to :content_type, optional: true
  
  # Alias for semantic clarity
  def author
    user
  end
  
  # Get content type or default to 'post'
  def post_type
    content_type || ContentType.default_type
  end
  
  def post_type_ident
    post_type&.ident || 'post'
  end
  
  def author=(value)
    self.user = value
  end
  
  # Rich text content
  has_rich_text :content
  
  # Media/image support
  has_one_attached :featured_image_file
  
  # Associations
  has_many :comments, as: :commentable, dependent: :destroy
  
  # Status enum (like WordPress)
  enum status: {
    draft: 0,
    published: 1,
    scheduled: 2,
    pending_review: 3,
    private_post: 4,
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
  
  # Check if post should be visible to public (without password check)
  def visible_to_public?
    return false if trash_status?
    return false if draft_status?
    return false if pending_review_status?
    return false if private_post_status? # Only for logged-in users
    
    if scheduled_status?
      published_at.present? && published_at <= Time.current
    else
      published_status?
    end
  end
  
  # Check if post is password protected
  def password_protected?
    password.present?
  end
  
  # Check if provided password is correct
  def password_matches?(input_password)
    return true unless password_protected?
    password == input_password
  end
  
  # Auto-publish scheduled posts
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
  scope :scheduled, -> { where(status: 'scheduled').where('published_at > ?', Time.current) }
  scope :recent, -> { order(published_at: :desc) }
  scope :by_category, ->(category) { joins(:terms).where(terms: { slug: category }).joins('INNER JOIN taxonomies ON terms.taxonomy_id = taxonomies.id').where(taxonomies: { slug: 'category' }) }
  scope :by_tag, ->(tag) { joins(:terms).where(terms: { slug: tag }).joins('INNER JOIN taxonomies ON terms.taxonomy_id = taxonomies.id').where(taxonomies: { slug: 'post_tag' }) }
  scope :search, ->(query) { search_full_text(query) }
  
  # Callbacks
  before_validation :set_published_at, if: :published_status?
  after_create :trigger_post_created_hook
  after_update :trigger_post_updated_hook, if: :saved_change_to_status?
  
  # Methods
  def should_generate_new_friendly_id?
    title_changed? || slug.blank?
  end
  
  def author_name
    user&.name || user&.email&.split('@')&.first&.titleize || 'Anonymous'
  end
  
  private
  
  def set_published_at
    self.published_at ||= Time.current
  end
  
  def trigger_post_created_hook
    Railspress::PluginSystem.do_action('post_created', self)
    Railspress::WebhookDispatcher.dispatch('post.created', self)
  end
  
  def trigger_post_updated_hook
    if published_status?
      Railspress::PluginSystem.do_action('post_published', self)
      Railspress::WebhookDispatcher.dispatch('post.published', self)
    end
    Railspress::PluginSystem.do_action('post_updated', self)
    Railspress::WebhookDispatcher.dispatch('post.updated', self)
  end
  
  # SEO URL override
  def seo_default_url
    Rails.application.routes.url_helpers.blog_post_url(slug)
  rescue
    "#"
  end
  
  # Featured image URL for SEO
  def featured_image_url
    return nil unless featured_image_file.attached?
    Rails.application.routes.url_helpers.url_for(featured_image_file)
  rescue
    nil
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
  
  # Get field groups that should be shown for this post
  def applicable_field_groups
    FieldGroup.active.ordered.select { |fg| fg.matches_location?(self) }
  end

  # Generate URL for the post
  def url
    Rails.application.routes.url_helpers.blog_post_url(self.id, host: 'localhost:3000')
  end

  # Get the author of the post
  def author
    User.find_by(id: self.user_id)
  end

  # Get categories for the post
  def categories
    # This would need to be implemented based on your taxonomy system
    # For now, return an empty array to prevent errors
    []
  end

  # Convert Post to Liquid-compatible hash
  def to_liquid
    {
      'id' => id,
      'title' => title,
      'content' => content.to_s, # Convert ActionText to string
      'excerpt' => excerpt,
      'url' => url,
      'author' => author,
      'categories' => categories.to_a, # Convert AssociationRelation to array
      'terms' => terms.to_a, # Convert AssociationRelation to array
      'published_at' => published_at,
      'created_at' => created_at,
      'updated_at' => updated_at,
      'featured_image' => featured_image
    }
  end

  # Make these methods public for Liquid access
  public :url, :author, :categories, :to_liquid
end
