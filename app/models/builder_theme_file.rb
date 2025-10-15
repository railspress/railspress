class BuilderThemeFile < ApplicationRecord
  # Associations
  belongs_to :tenant
  belongs_to :builder_theme
  
  # Validations
  validates :path, presence: true, uniqueness: { scope: :builder_theme_id }
  validates :content, presence: true
  validates :checksum, presence: true
  validates :builder_theme, presence: true
  
  # Callbacks
  before_validation :generate_checksum, on: :create
  before_validation :calculate_file_size, on: :create
  
  # Scopes
  scope :liquid_files, -> { where("path LIKE '%.liquid'") }
  scope :json_files, -> { where("path LIKE '%.json'") }
  scope :css_files, -> { where("path LIKE '%.css'") }
  scope :js_files, -> { where("path LIKE '%.js'") }
  scope :sections, -> { where("path LIKE 'sections/%.liquid'") }
  scope :templates, -> { where("path LIKE 'templates/%.json'") }
  scope :snippets, -> { where("path LIKE 'snippets/%.liquid'") }
  scope :layouts, -> { where("path LIKE 'layout/%.liquid'") }
  
  # Class methods
  def self.editable_extensions
    %w[.liquid .json .css .js .html .md .yml .yaml]
  end
  
  def self.editable?(path)
    ext = File.extname(path).downcase
    editable_extensions.include?(ext)
  end
  
  # Instance methods
  def editable?
    self.class.editable?(path)
  end
  
  def file_type
    case File.extname(path).downcase
    when '.liquid'
      'liquid'
    when '.json'
      'json'
    when '.css'
      'css'
    when '.js'
      'javascript'
    when '.html'
      'html'
    when '.md'
      'markdown'
    when '.yml', '.yaml'
      'yaml'
    else
      'text'
    end
  end
  
  def section_name
    return nil unless path.start_with?('sections/')
    File.basename(path, '.liquid')
  end
  
  def template_name
    return nil unless path.start_with?('templates/')
    File.basename(path, '.json')
  end
  
  def snippet_name
    return nil unless path.start_with?('snippets/')
    File.basename(path, '.liquid')
  end
  
  def layout_name
    return nil unless path.start_with?('layout/')
    File.basename(path, '.liquid')
  end
  
  def schema_data
    return nil unless file_type == 'liquid' && content.include?('{% schema %}')
    
    # Extract schema from liquid file
    schema_match = content.match(/{% schema %}(.*?){% endschema %}/m)
    return nil unless schema_match
    
    begin
      JSON.parse(schema_match[1].strip)
    rescue JSON::ParserError
      nil
    end
  end
  
  def update_content!(new_content)
    self.content = new_content
    generate_checksum
    calculate_file_size
    save!
  end
  
  def content_changed?
    new_checksum = Digest::SHA256.hexdigest(content)
    checksum != new_checksum
  end
  
  private
  
  def generate_checksum
    return if content.blank?
    self.checksum = Digest::SHA256.hexdigest(content)
  end
  
  def calculate_file_size
    return if content.blank?
    self.file_size = content.bytesize
  end
end
