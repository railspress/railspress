class ThemeVersion < ApplicationRecord
  belongs_to :user
  has_many :theme_file_versions, dependent: :nullify
  has_many :theme_files, dependent: :destroy
  
  # Validations
  validates :theme_name, presence: true
  validates :version, presence: true
  validates :user_id, presence: true
  
  # Scopes
  scope :live, -> { where(is_live: true) }
  scope :preview, -> { where(is_preview: true) }
  scope :published, -> { where.not(published_at: nil) }
  scope :for_theme, ->(theme_name) { where(theme_name: theme_name) }
  
  # Callbacks
  before_create :generate_version_number
  after_create :snapshot_theme_files
  
  # Methods
  def self.create_preview(theme_name, user, changes = {})
    create!(
      theme_name: theme_name,
      user: user,
      is_preview: true,
      is_live: false,
      change_summary: changes[:summary] || "Preview version"
    )
  end
  
  def self.create_live_version(theme_name, user, changes = {})
    # Deactivate current live version
    live.for_theme(theme_name).update_all(is_live: false)
    
    create!(
      theme_name: theme_name,
      user: user,
      is_preview: false,
      is_live: true,
      published_at: Time.current,
      change_summary: changes[:summary] || "Published version"
    )
  end
  
  def publish!
    # Deactivate current live version
    self.class.live.for_theme(theme_name).update_all(is_live: false)
    
    # Make this version live
    update!(
      is_live: true,
      is_preview: false,
      published_at: Time.current
    )
  end
  
  def file_content(file_path)
    # Try exact match first (for full paths)
    theme_file = theme_files.find_by(file_path: file_path)
    return theme_file.theme_file_versions.latest.first&.content if theme_file
    
    # Try to find by matching the end of the path (for legacy relative paths)
    theme_file = theme_files.find { |file| file.file_path.end_with?("/#{file_path}") }
    return nil unless theme_file
    
    theme_file.theme_file_versions.latest.first&.content
  end
  
  def template_data(template_type)
    # Build full path for template file - use lowercase theme name for filesystem
    theme_path = Rails.root.join('app', 'themes', theme_name.downcase)
    full_path = File.join(theme_path, "templates/#{template_type}.json")
    
    content = file_content(full_path)
    content ? JSON.parse(content) : {}
  rescue JSON::ParserError
    {}
  end
  
  def section_content(section_type)
    # Build full path for section file - use lowercase theme name for filesystem
    theme_path = Rails.root.join('app', 'themes', theme_name.downcase)
    full_path = File.join(theme_path, "sections/#{section_type}.liquid")
    
    file_content(full_path) || ''
  end
  
  def layout_content
    # Build full path for layout file - use lowercase theme name for filesystem
    theme_path = Rails.root.join('app', 'themes', theme_name.downcase)
    full_path = File.join(theme_path, "layout/theme.liquid")
    
    file_content(full_path) || ''
  end
  
  def assets
    # Build full paths for asset files - use lowercase theme name for filesystem
    theme_path = Rails.root.join('app', 'themes', theme_name.downcase)
    
    {
      css: file_content(File.join(theme_path, "assets/theme.css")) || '',
      js: file_content(File.join(theme_path, "assets/theme.js")) || ''
    }
  end
  
  def theme_files
    ThemeFile.where(theme_version: self)
  end
  
  def templates
    theme_file_versions.joins(:theme_file).merge(ThemeFile.templates)
  end
  
  def sections
    theme_file_versions.joins(:theme_file).merge(ThemeFile.sections)
  end
  
  def layouts
    theme_file_versions.joins(:theme_file).merge(ThemeFile.layouts)
  end
  
  def assets_files
    theme_file_versions.joins(:theme_file).merge(ThemeFile.assets)
  end
  
  private
  
  def generate_version_number
    last_version = self.class.for_theme(theme_name).order(:created_at).last
    if last_version
      version_parts = last_version.version.split('.')
      version_parts[2] = (version_parts[2].to_i + 1).to_s
      self.version = version_parts.join('.')
    else
      self.version = "1.0.0"
    end
  end
  
  def snapshot_theme_files
    ThemeVersionService.new(self).snapshot_theme_files
  end
end
