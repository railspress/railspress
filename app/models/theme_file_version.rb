class ThemeFileVersion < ApplicationRecord
  belongs_to :user
  belongs_to :theme_file, optional: true
  belongs_to :theme_version, optional: true
  
  # Validations
  validates :version_number, presence: true, uniqueness: { scope: :theme_file_id }
  validates :file_checksum, presence: true
  
  # Scopes
  scope :latest, -> { order(version_number: :desc) }
  
  # Callbacks
  before_create :set_version_number
  after_create :update_theme_file_version
  
  # Methods
  def self.create_version(theme_file, content, user, theme_version = nil)
    create!(
      theme_file: theme_file,
      content: content,
      file_size: content.bytesize,
      user: user,
      theme_version: theme_version,
      change_summary: "Version #{version_number}"
    )
  end
  
  private
  
  def set_version_number
    latest = self.class.where(theme_file: theme_file).latest.first
    self.version_number = latest ? latest.version_number + 1 : 1
  end
  
  def update_theme_file_version
    theme_file.update!(current_version: version_number)
  end
  
  def determine_file_type(file_path)
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
