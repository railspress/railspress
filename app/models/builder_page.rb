class BuilderPage < ApplicationRecord
  # Associations
  belongs_to :tenant
  belongs_to :builder_theme
  has_many :builder_page_sections, -> { ordered }, dependent: :destroy
  
  # Serialization
  serialize :settings, coder: JSON, type: Hash
  serialize :sections, coder: JSON, type: Hash
  
  # Validations
  validates :template_name, presence: true, uniqueness: { scope: :builder_theme_id }
  validates :page_title, presence: true
  validates :tenant, presence: true
  validates :builder_theme, presence: true
  
  # Scopes
  scope :ordered, -> { order(:position) }
  scope :published, -> { where(published: true) }
  scope :by_template, ->(template) { where(template_name: template) }
  
  # Callbacks
  before_validation :set_defaults, on: :create
  
  # Class methods
  def self.create_page(builder_theme, template_name, page_title, settings = {}, sections = {})
    position = builder_theme.builder_pages.count
    
    create!(
      builder_theme: builder_theme,
      tenant: builder_theme.tenant,
      template_name: template_name,
      page_title: page_title,
      settings: settings,
      sections: sections,
      position: position
    )
  end
  
  def self.initialize_default_pages(builder_theme)
    default_pages = [
      { template: 'index', title: 'Home', sections: { 'header' => {}, 'hero' => {}, 'footer' => {} } },
      { template: 'blog', title: 'Blog', sections: { 'header' => {}, 'post-list' => {}, 'footer' => {} } },
      { template: 'post', title: 'Post', sections: { 'header' => {}, 'post-content' => {}, 'comments' => {}, 'footer' => {} } },
      { template: 'page', title: 'Page', sections: { 'header' => {}, 'rich-text' => {}, 'footer' => {} } },
      { template: 'search', title: 'Search', sections: { 'header' => {}, 'search-form' => {}, 'search-results' => {}, 'footer' => {} } }
    ]
    
    default_pages.each do |page_data|
      next if builder_theme.builder_pages.exists?(template_name: page_data[:template])
      
      create_page(
        builder_theme,
        page_data[:template],
        page_data[:title],
        {},
        page_data[:sections]
      )
    end
  end
  
  # Instance methods
  def display_name
    page_title
  end
  
  def description
    "#{template_name.humanize} page with #{sections.keys.size} sections"
  end
  
  def section_order
    sections.keys
  end
  
  def get_setting(key, default = nil)
    settings[key.to_s] || default
  end
  
  def set_setting(key, value)
    self.settings = settings.merge(key.to_s => value)
    save!
  end
  
  def get_section_settings(section_id)
    sections[section_id.to_s] || {}
  end
  
  def set_section_settings(section_id, section_settings)
    self.sections = sections.merge(section_id.to_s => section_settings)
    save!
  end
  
  def add_section(section_id, section_settings = {})
    self.sections = sections.merge(section_id.to_s => section_settings)
    save!
  end
  
  def remove_section(section_id)
    self.sections = sections.except(section_id.to_s)
    save!
  end
  
  def reorder_sections(section_ids)
    new_sections = {}
    section_ids.each do |section_id|
      new_sections[section_id] = sections[section_id] if sections.key?(section_id)
    end
    self.sections = new_sections
    save!
  end
  
  def sections_data
    sections.map do |section_id, section_settings|
      {
        'id' => section_id,
        'type' => section_id,
        'settings' => section_settings
      }
    end
  end
  
  def template_file_path
    "templates/#{template_name}.json"
  end
  
  def template_content
    # Get template content from filesystem
    theme_path = Rails.root.join('app', 'themes', builder_theme.theme_name.underscore)
    template_file = theme_path.join(template_file_path)
    
    if File.exist?(template_file)
      JSON.parse(File.read(template_file))
    else
      # Default template structure
      {
        'sections' => sections,
        'order' => section_order,
        'settings' => settings
      }
    end
  end
  
  def publish!
    update!(published: true)
  end
  
  def unpublish!
    update!(published: false)
  end
  
  private
  
  def set_defaults
    self.settings ||= {}
    self.sections ||= {}
    self.position ||= 0
    self.published ||= false
  end
end
