class BuilderPageSection < ApplicationRecord
  # Associations
  belongs_to :tenant
  belongs_to :builder_page
  
  # Serialization
  serialize :settings, coder: JSON, type: Hash
  
  # Validations
  validates :section_id, presence: true, uniqueness: { scope: :builder_page_id }
  validates :section_type, presence: true
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :settings, presence: true
  validates :tenant, presence: true
  validates :builder_page, presence: true
  
  # Scopes
  scope :ordered, -> { order(:position) }
  scope :by_type, ->(type) { where(section_type: type) }
  
  # Callbacks
  before_validation :set_defaults, on: :create
  
  # Class methods
  def self.create_section(builder_page, section_type, settings = {})
    section_id = "#{section_type}_#{Time.current.to_i}"
    position = builder_page.builder_page_sections.count
    
    create!(
      builder_page: builder_page,
      tenant: builder_page.tenant,
      section_id: section_id,
      section_type: section_type,
      settings: settings,
      position: position
    )
  end
  
  def self.reorder_sections(builder_page, section_ids)
    section_ids.each_with_index do |section_id, index|
      section = builder_page.builder_page_sections.find_by(section_id: section_id)
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
  
  def section_content
    # Get section content from filesystem
    theme_path = Rails.root.join('app', 'themes', builder_page.builder_theme.theme_name.underscore)
    section_file = theme_path.join('sections', "#{section_type}.liquid")
    
    if File.exist?(section_file)
      File.read(section_file)
    else
      ''
    end
  end
  
  private
  
  def set_defaults
    self.settings ||= {}
    self.position ||= 0
  end
end

