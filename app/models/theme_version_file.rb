class ThemeVersionFile < ApplicationRecord
  belongs_to :theme_version
  
  # Validations
  validates :file_path, presence: true
  validates :file_type, presence: true
  
  # Scopes
  scope :templates, -> { where(file_type: 'template') }
  scope :sections, -> { where(file_type: 'section') }
  scope :layouts, -> { where(file_type: 'layout') }
  scope :assets, -> { where(file_type: 'asset') }
  scope :configs, -> { where(file_type: 'config') }
  
  # Methods
  def self.create_from_file(theme_version, file_path, content)
    file_type = determine_file_type(file_path)
    
    create!(
      theme_version: theme_version,
      file_path: file_path,
      file_type: file_type,
      content: content,
      file_size: content.bytesize
    )
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
  
  def parsed_json
    return nil unless json_content?
    JSON.parse(content)
  rescue JSON::ParserError
    nil
  end
  
  def parsed_schema
    return nil unless liquid_content?
    
    # Extract schema from liquid content
    schema_match = content.match(/\{%\s*schema\s*%\}(.*?)\{%\s*endschema\s*%\}/m)
    return nil unless schema_match
    
    JSON.parse(schema_match[1])
  rescue JSON::ParserError
    nil
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
