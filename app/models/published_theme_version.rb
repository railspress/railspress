class PublishedThemeVersion < ApplicationRecord
  belongs_to :published_by, polymorphic: true
  belongs_to :tenant
  belongs_to :theme
  has_many :published_theme_files, dependent: :destroy
  
  # Scopes
  scope :for_theme, ->(theme_or_name) { 
    if theme_or_name.is_a?(Theme)
      where(theme: theme_or_name)
    else
      joins(:theme).where("LOWER(themes.name) = ?", theme_or_name.to_s.downcase)
    end
  }
  scope :latest, -> { order(version_number: :desc) }
  
  # Get file content
  def file_content(file_path)
    file = published_theme_files.find_by(file_path: file_path)
    file&.content
  end
  
  # Get parsed JSON file
  def parsed_file(file_path)
    content = file_content(file_path)
    return nil unless content
    
    JSON.parse(content)
  rescue JSON::ParserError
    nil
  end
  
  # Liquid file system compatibility methods
  def read_template_file(template_path)
    Rails.logger.info "PublishedVersion: Looking for template: #{template_path}"
    
    # Try to find the file directly
    file = published_theme_files.find_by(file_path: template_path)
    if file
      Rails.logger.info "PublishedVersion: Found template file: #{template_path}"
      return file.content
    end
    
    # Try with .liquid extension
    file = published_theme_files.find_by(file_path: "#{template_path}.liquid")
    if file
      Rails.logger.info "PublishedVersion: Found template file with .liquid: #{template_path}.liquid"
      return file.content
    end
    
    # Try snippets directory
    file = published_theme_files.find_by(file_path: "snippets/#{template_path}.liquid")
    if file
      Rails.logger.info "PublishedVersion: Found snippet file: snippets/#{template_path}.liquid"
      return file.content
    end
    
    Rails.logger.warn "PublishedVersion: Template file not found: #{template_path}"
    # Fallback to empty string
    ""
  end
end
