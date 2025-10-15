class BuilderTheme < ApplicationRecord
  # Associations
  belongs_to :tenant
  belongs_to :user
  belongs_to :parent_version, class_name: 'BuilderTheme', optional: true
  has_many :child_versions, class_name: 'BuilderTheme', foreign_key: 'parent_version_id', dependent: :nullify
  has_many :builder_theme_files, dependent: :destroy
  has_many :builder_theme_sections, -> { ordered }, dependent: :destroy
  has_many :builder_pages, -> { ordered }, dependent: :destroy
  has_many :builder_theme_snapshots, dependent: :destroy
  
  # Serialization
  serialize :settings_data, coder: JSON, type: Hash
  
  # Validations
  validates :theme_name, presence: true
  validates :label, presence: true
  validates :checksum, presence: true, uniqueness: true
  validates :user, presence: true
  
  # Scopes
  scope :published, -> { where(published: true) }
  scope :drafts, -> { where(published: false) }
  scope :for_theme, ->(theme_name) { where(theme_name: theme_name) }
  scope :latest, -> { order(created_at: :desc) }
  
  # Callbacks
  before_validation :generate_checksum, on: :create
  after_create :initialize_default_pages
  
  # Instance methods
  def theme
    @theme ||= Theme.where("LOWER(name) = ?", theme_name.downcase).first
  end
  
  def has_published_version?
    @has_published_version ||= PublishedThemeVersion.for_theme(theme).exists?
  end
  
  def published_version
    @published_version ||= PublishedThemeVersion.for_theme(theme).latest.first
  end
  
  def is_theme_active?
    # Check if the theme this BuilderTheme belongs to is active
    theme&.active?
  end
  
  # Class methods
  def self.create_version(theme_name, user, parent_version = nil, label = nil)
    label ||= "Version #{Time.current.strftime('%Y%m%d_%H%M%S')}"
    
    # Get the actual tenant object
    current_tenant = ActsAsTenant.current_tenant
    tenant = if current_tenant.is_a?(OpenStruct)
      Tenant.find(current_tenant.id)
    else
      current_tenant
    end
    
    create!(
      theme_name: theme_name,
      label: label,
      parent_version: parent_version,
      user: user,
      tenant: tenant,
      summary: "Created new version from #{parent_version&.label || 'base'}"
    )
  end
  
  def self.current_for_theme(theme_name)
    published.for_theme(theme_name).latest.first
  end
  
  def self.draft_for_theme(theme_name)
    drafts.for_theme(theme_name).latest.first
  end
  
  # Instance methods
  def publish!
    # Unpublish other versions of the same theme
    self.class.for_theme(theme_name).where.not(id: id).update_all(published: false)
    
    # Publish this version
    update!(published: true)
    
    # Create snapshot
    create_snapshot!
  end
  
  def create_snapshot!
    BuilderThemeSnapshot.create!(
      theme_name: theme_name,
      builder_theme: self,
      settings_data: settings_data.to_json,
      sections_data: sections_data.to_json,
      user: user,
      tenant: tenant, # tenant is already a proper Tenant object
      checksum: Digest::SHA256.hexdigest("#{settings_data}#{sections_data}#{created_at}")
    )
  end
  
  def sections_data
    @sections_data ||= build_sections_data
  end
  
  def sections_data=(data)
    @sections_data = data
  end

  def build_sections_data
    sections = {}
    builder_theme_sections.each do |section|
      sections[section.section_id] = {
        'type' => section.section_type,
        'settings' => section.settings
      }
    end
    sections
  end

  def section_order
    builder_theme_sections.pluck(:section_id)
  end

  def add_section(section_type, settings = {})
    BuilderThemeSection.create_section(self, section_type, settings)
  end

  def remove_section(section_id)
    section = builder_theme_sections.find_by(section_id: section_id)
    section&.destroy!
    
    # Reorder remaining sections
    reorder_sections
  end

  def reorder_sections
    builder_theme_sections.ordered.each_with_index do |section, index|
      section.update!(position: index)
    end
  end

  def update_section_order(section_ids)
    BuilderThemeSection.reorder_sections(self, section_ids)
  end

  def get_section(section_id)
    builder_theme_sections.find_by(section_id: section_id)
  end

  # Update section settings in PublishedThemeFile
  def update_section_settings(section_id, settings, template_name = 'index')
    published_version = ensure_published_version!
    
    # Get the template file
    template_file = published_version.published_theme_files.find_by(file_path: "templates/#{template_name}.json")
    return false unless template_file
    
    # Parse the template content
    template_content = JSON.parse(template_file.content)
    
    # Update the section settings
    if template_content['sections'] && template_content['sections'][section_id]
      template_content['sections'][section_id]['settings'] = settings
      
      # Update the PublishedThemeFile content
      template_file.update!(
        content: JSON.pretty_generate(template_content),
        checksum: Digest::MD5.hexdigest(template_file.content)
      )
      
      true
    else
      false
    end
  end

  # Update template file with new sections order
  def update_template_sections(template_name, sections_hash, section_order)
    published_version = ensure_published_version!
    
    # Get or create the template file
    template_file = published_version.published_theme_files.find_or_initialize_by(file_path: "templates/#{template_name}.json")
    
    # Create the template content
    template_content = {
      'name' => template_name.humanize,
      'sections' => sections_hash,
      'order' => section_order
    }
    
    # Update the PublishedThemeFile content
    template_file.assign_attributes(
      file_type: 'template',
      content: JSON.pretty_generate(template_content),
      checksum: Digest::MD5.hexdigest(template_file.content)
    )
    
    template_file.save!
  end

  # Get rendered file - creates PublishedThemeVersion if none exists, then works with PublishedThemeFile
  def get_rendered_file(template_name = 'index')
    # Ensure we have a PublishedThemeVersion to work with
    published_version = ensure_published_version!
    
    # Get layout file from PublishedThemeFile
    layout_file = published_version.published_theme_files.find_by(file_path: 'layout/theme.liquid')
    layout_content = layout_file&.content || default_layout
    
    # Get template JSON from PublishedThemeFile
    template_file = published_version.published_theme_files.find_by(file_path: "templates/#{template_name}.json")
    template_content = template_file ? JSON.parse(template_file.content) : {}
    
    # Return rendered data with PublishedThemeFile content
    {
      template_name: template_name,
      template_content: template_content,
      layout_content: layout_content,
      theme_settings: {},
      published_version: published_version
    }
  end

  # Publish the builder theme as a PublishedThemeVersion
  def publish!(publisher = nil)
    # Find or create the latest PublishedThemeVersion
    published_version = PublishedThemeVersion.where(theme: theme).latest.first
    
    if published_version
      # Update existing version
      published_version.update!(published_at: Time.current, published_by: publisher || user)
    else
      # Create new version
      published_version = PublishedThemeVersion.create!(
        theme: theme,
        version_number: next_version_number,
        published_at: Time.current,
        published_by: publisher || user,
        tenant: tenant
      )
    end

    # Copy all files from ThemesManager (database)
    manager = ThemesManager.new
    active_theme_version = manager.active_theme_version
    
    # Copy all theme files
    active_theme_version.theme_files.each do |theme_file|
      # Get the original content from ThemesManager
      content = manager.get_file(theme_file.file_path)
      next unless content
      
      # Create or update the published file
      published_file = PublishedThemeFile.find_or_initialize_by(
        published_theme_version: published_version,
        file_path: theme_file.file_path
      )
      
      published_file.assign_attributes(
        file_type: theme_file.file_type,
        content: content,
        checksum: Digest::MD5.hexdigest(content)
      )
      
      published_file.save!
    end

    # Mark as published
    update!(published: true, published_at: Time.current)
    
    published_version
  end


  def ensure_published_version!
    # Check if we have a PublishedThemeVersion for this theme
    published_version = PublishedThemeVersion.where(theme: theme).latest.first
    
    unless published_version
      Rails.logger.info "No PublishedThemeVersion found for #{theme.name}, creating initial version..."
      
      # Create initial PublishedThemeVersion
      published_version = PublishedThemeVersion.create!(
        theme: theme,
        version_number: 1,
        published_at: Time.current,
        published_by: user,
        tenant: tenant
      )
      
      # Copy all files from ThemesManager to PublishedThemeFile
      manager = ThemesManager.new
      active_theme_version = manager.active_theme_version
      
      if active_theme_version
        active_theme_version.theme_files.each do |theme_file|
          content = manager.get_file(theme_file.file_path)
          next unless content
          
          # Convert absolute path to relative path
          relative_path = theme_file.file_path.gsub(/^.*\/themes\/[^\/]+\//, '')
          
          PublishedThemeFile.create!(
            published_theme_version: published_version,
            file_path: relative_path,
            file_type: theme_file.file_type,
            content: content,
            checksum: Digest::MD5.hexdigest(content)
          )
        end
        
        Rails.logger.info "Created initial PublishedThemeVersion #{published_version.id} with #{published_version.published_theme_files.count} files"
      end
    end
    
    published_version
  end

  private

  def next_version_number
    # Get the next version number for this theme
    last_version = PublishedThemeVersion.where(theme: theme).maximum(:version_number) || 0
    last_version + 1
  end

  # Sync sections from template JSON file to database
  def sync_page_sections_from_template(page, template_name)
    manager = ThemesManager.new
    template_data = manager.get_parsed_file("templates/#{template_name}.json")
    
    return unless template_data && template_data['sections']
    
    # Clear existing sections
    page.builder_page_sections.destroy_all
    
    # Handle different section formats
    if template_data['sections'].is_a?(Array)
      # Array format: [["id", {type, settings}], ...]
      template_data['sections'].each_with_index do |section_data, index|
        # Handle both array format [id, {type, settings}] and hash format {id, type, settings}
        if section_data.is_a?(Array) && section_data.length == 2
          section_id = section_data[0]
          section_config = section_data[1]
          section_type = section_config['type']
          section_settings = section_config['settings'] || {}
        elsif section_data.is_a?(Hash)
          section_id = section_data['id'] || "#{section_data['type']}_#{Time.current.to_i}"
          section_type = section_data['type']
          section_settings = section_data['settings'] || {}
        else
          next # Skip invalid section data
        end
        
        # Create the section
        page.builder_page_sections.create!(
          tenant: tenant,
          section_id: section_id,
          section_type: section_type,
          settings: section_settings,
          position: index
        )
      end
    elsif template_data['sections'].is_a?(Hash) && template_data['order']
      # Object format with order array: {sections: {id: {type, settings}}, order: ["id1", "id2"]}
      template_data['order'].each_with_index do |section_id, index|
        section_config = template_data['sections'][section_id]
        next unless section_config
        
        section_type = section_config['type']
        section_settings = section_config['settings'] || {}
        
        # Create the section
        page.builder_page_sections.create!(
          tenant: tenant,
          section_id: section_id,
          section_type: section_type,
          settings: section_settings,
          position: index
        )
      end
    end
    
    Rails.logger.info "Synced #{page.builder_page_sections.count} sections for #{template_name} template"
  end

  # Get all builder files for this theme
  def builder_files
    BuilderFile.where(tenant: tenant)
  end
  
  def settings_data
    @settings_data ||= load_settings_data
  end
  
  def settings_data=(data)
    @settings_data = data
  end
  
  def get_file(path)
    builder_theme_files.find_by(path: path)
  end

  def get_template(template_name)
    # Get the template JSON file (e.g., 'home.json', 'blog.json', etc.)
    template_file = get_file("templates/#{template_name}.json")
    return nil unless template_file

    begin
      JSON.parse(template_file.content)
    rescue JSON::ParserError
      nil
    end
  end

  def get_section_content(section_type)
    # Get the section Liquid file
    section_file = get_file("sections/#{section_type}.liquid")
    section_file&.content || ''
  end

  def get_layout_content
    # Get the layout Liquid file
    layout_file = get_file("layout/theme.liquid")
    layout_file&.content || ''
  end
  
  def update_file(path, content)
    file = builder_theme_files.find_or_initialize_by(path: path)
    file.content = content
    file.checksum = Digest::SHA256.hexdigest(content)
    file.file_size = content.bytesize
    
    # Ensure we have a proper tenant object
    if tenant.is_a?(OpenStruct)
      file.tenant = Tenant.find(tenant.tenant_id)
    else
      file.tenant = tenant
    end
    
    file.save!
    file
  end
  
  def file_tree
    @file_tree ||= build_file_tree
  end
  
  def can_be_published?
    builder_theme_files.any? && !published?
  end
  
  def version_number
    return 1 unless parent_version
    
    parent_version.version_number + 1
  end
  
  private
  
  def generate_checksum
    return if checksum.present?
    
    content = "#{theme_name}#{label}#{parent_version_id}#{Time.current.to_i}"
    self.checksum = Digest::SHA256.hexdigest(content)
  end
  
  def create_initial_files
    return unless parent_version.nil? # Only for root versions
    
    # Copy files from the actual theme directory
    theme_path = Rails.root.join('app', 'themes', theme_name)
    return unless Dir.exist?(theme_path)
    
    copy_theme_files(theme_path)
  end
  
  def copy_theme_files(theme_path, relative_path = '')
    Dir.entries(theme_path).each do |entry|
      next if entry.start_with?('.')
      
      entry_path = File.join(theme_path, entry)
      file_relative_path = relative_path.present? ? "#{relative_path}/#{entry}" : entry
      
      if File.directory?(entry_path)
        copy_theme_files(entry_path, file_relative_path)
      else
        content = File.read(entry_path)
        update_file(file_relative_path, content)
      end
    end
  end
  
  def load_sections_data
    # Load from template JSON files
    sections = {}
    
    builder_theme_files.where("path LIKE 'templates/%.json'").each do |file|
      begin
        template_data = JSON.parse(file.content)
        sections.merge!(template_data['sections'] || {})
      rescue JSON::ParserError
        Rails.logger.warn "Invalid JSON in template file: #{file.path}"
      end
    end
    
    sections
  end
  
  def load_settings_data
    # Load from settings schema
    settings = {}
    
    settings_file = builder_theme_files.find_by(path: 'config/settings_schema.json')
    return settings unless settings_file
    
    begin
      schema = JSON.parse(settings_file.content)
      schema.each do |group|
        group['settings']&.each do |setting|
          settings[setting['id']] = setting['default']
        end
      end
    rescue JSON::ParserError
      Rails.logger.warn "Invalid JSON in settings schema: #{settings_file.path}"
    end
    
    settings
  end
  
  def build_file_tree
    tree = {}
    
    builder_theme_files.each do |file|
      path_parts = file.path.split('/')
      current = tree
      
      path_parts[0..-2].each do |part|
        current[part] ||= { type: 'directory', children: {} }
        current = current[part][:children]
      end
      
      current[path_parts.last] = {
        type: 'file',
        path: file.path,
        size: file.file_size,
        checksum: file.checksum
      }
    end
    
    tree
  end

  def initialize_default_pages
    # Define default pages based on common templates
    default_page_templates = {
      'index' => 'Home Page',
      'blog' => 'Blog Page',
      'post' => 'Post Page',
      'page' => 'Generic Page',
      'search' => 'Search Results',
      '404' => '404 Not Found',
      'login' => 'Login Page',
      'register' => 'Register Page',
      'contact' => 'Contact Page',
      'error' => 'Error Page',
      'email' => 'Email Template',
      'maintenance' => 'Maintenance Page'
    }

    default_page_templates.each do |template_name, page_title|
      builder_pages.find_or_create_by!(template_name: template_name) do |page|
        page.page_title = page_title
        page.settings = {} # Initial empty settings
        page.sections = {} # Initial empty sections (will be managed by BuilderPageSection)
        page.published = true if template_name == 'index' # Publish home page by default
        page.tenant = tenant
      end
    end
  end

  def default_layout
    <<~LIQUID
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{{ page_title | default: site.title }}</title>
        {{ content_for_header }}
      </head>
      <body>
        {{ content_for_layout }}
        {{ content_for_footer }}
      </body>
      </html>
    LIQUID
  end
end
