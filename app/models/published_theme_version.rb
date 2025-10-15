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
end
