class BuilderThemeSection < ApplicationRecord
  # Associations
  belongs_to :tenant
  belongs_to :builder_theme
  
  # Serialization
  serialize :settings, coder: JSON, type: Hash
  
  # Validations
  validates :section_id, presence: true, uniqueness: { scope: :builder_theme_id }
  validates :section_type, presence: true
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :settings, presence: true
  validates :tenant, presence: true
  validates :builder_theme, presence: true
  
  # Scopes
  scope :ordered, -> { order(:position) }
  scope :by_type, ->(type) { where(section_type: type) }
  
  # Callbacks
  before_validation :set_defaults, on: :create
  
  # Class methods
  def self.create_section(builder_theme, section_type, settings = {})
    section_id = "#{section_type}_#{Time.current.to_i}"
    position = builder_theme.builder_theme_sections.count
    
    create!(
      builder_theme: builder_theme,
      tenant: builder_theme.tenant,
      section_id: section_id,
      section_type: section_type,
      settings: settings,
      position: position
    )
  end
  
  def self.reorder_sections(builder_theme, section_ids)
    section_ids.each_with_index do |section_id, index|
      section = builder_theme.builder_theme_sections.find_by(section_id: section_id)
      section&.update!(position: index)
    end
  end
  
  # Instance methods
  def update_settings!(new_settings)
    update!(settings: settings.merge(new_settings.stringify_keys))
  end
  
  def get_setting(key, default = nil)
    settings[key.to_s] || default
  end
  
  def set_setting(key, value)
    self.settings = settings.merge(key.to_s => value)
    save!
  end
  
  def display_name
    case section_type
    when 'hero'
      'Hero'
    when 'post-list'
      'Blog List'
    when 'rich-text'
      'Rich Text'
    when 'image'
      'Image'
    when 'gallery'
      'Image Gallery'
    when 'contact'
      'Contact Form'
    when 'header'
      'Header'
    when 'footer'
      'Footer'
    when 'menu'
      'Menu'
    when 'search-form'
      'Search Form'
    when 'comments'
      'Comments'
    when 'pagination'
      'Pagination'
    when 'taxonomy-list'
      'Category/Tag List'
    when 'seo-head'
      'SEO Head'
    when 'post-content'
      'Post Content'
    when 'related-posts'
      'Related Posts'
    else
      section_type.humanize
    end
  end
  
  def description
    case section_type
    when 'hero'
      get_setting('heading', 'Hero section')
    when 'post-list'
      "Blog list (#{get_setting('items_per_page', 6)} items)"
    when 'rich-text'
      get_setting('content', 'Rich text content')&.truncate(50)
    when 'image'
      get_setting('alt_text', 'Image section')
    when 'contact'
      get_setting('title', 'Contact form')
    else
      "#{display_name} section"
    end
  end
  
  private
  
  def set_defaults
    self.settings ||= {}
    self.position ||= 0
  end
end

