class ThemeFile < ApplicationRecord
  belongs_to :theme_version, optional: true
  has_many :theme_file_versions, dependent: :destroy
  
  # Validations
  validates :theme_name, presence: true
  validates :file_path, presence: true, uniqueness: { scope: [:theme_name, :theme_version_id] }
  validates :file_type, presence: true
  validates :current_checksum, presence: true
  
  # Scopes
  scope :for_theme, ->(theme_name) { where(theme_name: theme_name) }
  scope :templates, -> { where(file_type: 'template') }
  scope :sections, -> { where(file_type: 'section') }
  scope :layouts, -> { where(file_type: 'layout') }
  scope :assets, -> { where(file_type: 'asset') }
  scope :configs, -> { where(file_type: 'config') }
  
  # Methods
  def current_content
    latest_version&.content
  end
  
  def latest_version
    theme_file_versions.latest.first
  end
  
  def version_at(version_number)
    theme_file_versions.find_by(version_number: version_number)
  end
  
  def create_new_version(content, user, theme_version = nil)
    ThemeFileVersion.create_version(theme_name, file_path, content, user, theme_version)
  end
  
  def liquid_content?
    file_path.end_with?('.liquid')
  end
  
  def json_content?
    file_path.end_with?('.json')
  end
  
  def css_content?
    file_path.end_with?('.css')
  end
  
  def js_content?
    file_path.end_with?('.js')
  end
  
  def parsed_content
    return nil unless current_content
    
    if json_content?
      JSON.parse(current_content)
    elsif liquid_content?
      current_content
    else
      current_content
    end
  rescue JSON::ParserError
    nil
  end
  
  def parsed_schema
    return nil unless liquid_content? && current_content
    
    schema_match = current_content.match(/\{%\s*schema\s*%\}(.*?)\{%\s*endschema\s*%\}/m)
    return nil unless schema_match
    
    JSON.parse(schema_match[1])
  rescue JSON::ParserError
    nil
  end
  
  def self.find_or_create_from_path(theme_name, file_path)
    find_or_create_by(theme_name: theme_name, file_path: file_path) do |file|
      file.file_type = determine_file_type(file_path)
    end
  end
  
  private
  
  def self.determine_file_type(file_path)
    if file_path.start_with?('templates/')
      'template'
    elsif file_path.start_with?('sections/')
      'section'
    elsif file_path.start_with?('layout/')
      'layout'
    elsif file_path.start_with?('assets/')
      'asset'
    elsif file_path.start_with?('config/')
      'config'
    else
      'other'
    end
  end
end
