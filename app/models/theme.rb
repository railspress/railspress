class Theme < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant)
  
  # Associations
  has_many :templates, dependent: :destroy
  has_many :theme_versions, foreign_key: :theme_name, primary_key: :name, dependent: :destroy
  has_many :theme_files, foreign_key: :theme_name, primary_key: :name, dependent: :destroy
  
  # Serialization
  serialize :config, coder: JSON, type: Hash
  
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :version, presence: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  
  # Callbacks
  after_initialize :set_defaults, if: :new_record?
  before_save :deactivate_others, if: :active?
  before_save :set_slug_from_name
  
  # Methods
  def self.current
    active.first || first
  end
  
  def activate!
    Theme.where.not(id: id).update_all(active: false)
    success = update(active: true)
    
    if success
      # Create PublishedThemeVersion if it doesn't exist
      ensure_published_version_exists!
      true
    else
      false
    end
  end
  
  def get_file(file_path)
    live_version = theme_versions.live.first
    live_version&.file_content(file_path)
  end
  
  def get_parsed_file(file_path)
    content = get_file(file_path)
    return nil unless content
    
    if file_path.end_with?('.json')
      JSON.parse(content)
    else
      content
    end
  rescue JSON::ParserError
    nil
  end
  
  def file_tree
    ThemesManager.new.file_tree(name)
  end
  
  def live_version
    theme_versions.live.first
  end
  
  def has_update_available?
    ThemesManager.new.check_for_updates(self)
  end
  
  def get_template(template_type)
    templates.by_type(template_type).active.first
  end
  
  # Ensure a PublishedThemeVersion exists for this theme
  def ensure_published_version_exists!
    # Check if we already have a PublishedThemeVersion for this theme
    return if PublishedThemeVersion.where(theme: self).exists?
    
    Rails.logger.info "Creating initial PublishedThemeVersion for theme: #{name}"
    
    # Create initial PublishedThemeVersion
    published_version = PublishedThemeVersion.create!(
      theme: self,
      version_number: 1,
      published_at: Time.current,
      published_by: User.first, # TODO: Use current user if available
      tenant: tenant
    )
    
    # Copy all files from this theme's version to PublishedThemeFile
    manager = ThemesManager.new
    theme_version = theme_versions.live.first
    
    if theme_version
      theme_version.theme_files.each do |theme_file|
        # Convert absolute path to relative path
        relative_path = theme_file.file_path.gsub(/^.*\/themes\/[^\/]+\//, '')
        
        # Get content using relative path and theme name
        content = manager.get_file(relative_path, name)
        next unless content
        
        PublishedThemeFile.create!(
          published_theme_version: published_version,
          file_path: relative_path,
          file_type: theme_file.file_type,
          content: content,
          checksum: Digest::MD5.hexdigest(content)
        )
      end
      
      Rails.logger.info "Created initial PublishedThemeVersion #{published_version.id} with #{published_version.published_theme_files.count} files"
    else
      Rails.logger.warn "No theme version found for #{name}"
    end
    
    published_version
  end
  
  def published_version
    PublishedThemeVersion.where(theme: self).first
  end
  
  private
  
  def set_defaults
    self.active = false if active.nil?
    self.config ||= {}
  end
  
  def set_slug_from_name
    self.slug = name.parameterize if name.present? && slug.blank?
  end
  
  def deactivate_others
    Theme.where.not(id: id).update_all(active: false) if active_changed? && active?
  end
end
