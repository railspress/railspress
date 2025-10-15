class ThemeVersionService
  def initialize(theme_version)
    @theme_version = theme_version
    @theme_name = theme_version.theme_name
    @theme_path = Rails.root.join('app', 'themes', @theme_name)
  end

  def snapshot_theme_files
    return false unless Dir.exist?(@theme_path)
    
    # Create file versions for all theme files
    snapshot_directory_recursive(@theme_path.to_s, '')
    true
  rescue => e
    Rails.logger.error "Error snapshotting theme files: #{e.message}"
    false
  end

  def update_file(file_path, content)
    # Create or find the theme file
    theme_file = ThemeFile.find_or_create_from_path(@theme_name, file_path)
    
    # Create a new version linked to this theme version
    ThemeFileVersion.create_version(@theme_name, file_path, content, @theme_version.user, @theme_version)
  end

  def update_template(template_type, template_data)
    file_path = "templates/#{template_type}.json"
    content = JSON.pretty_generate(template_data)
    update_file(file_path, content)
  end

  def update_section(section_type, content)
    file_path = "sections/#{section_type}.liquid"
    update_file(file_path, content)
  end

  def update_layout(content)
    file_path = "layout/theme.liquid"
    update_file(file_path, content)
  end

  def update_asset(asset_type, content)
    file_path = "assets/#{asset_type}"
    update_file(file_path, content)
  end

  def get_file_content(file_path)
    @theme_version.theme_file_versions.find_by(file_path: file_path)&.content
  end

  def get_template_data(template_type)
    content = get_file_content("templates/#{template_type}.json")
    content ? JSON.parse(content) : {}
  rescue JSON::ParserError
    {}
  end

  def get_section_content(section_type)
    get_file_content("sections/#{section_type}.liquid") || ''
  end

  def get_layout_content
    get_file_content("layout/theme.liquid") || ''
  end

  def get_assets
    {
      css: get_file_content("assets/theme.css") || '',
      js: get_file_content("assets/theme.js") || ''
    }
  end

  def render_preview(template_type)
    renderer = LiquidTemplateVersionRenderer.new(@theme_version, template_type)
    renderer.render
  end

  private

  def snapshot_directory_recursive(source_dir, relative_path)
    Dir.entries(source_dir).each do |entry|
      next if entry.start_with?('.')
      next if entry == 'node_modules'
      
      source_path = File.join(source_dir, entry)
      relative_file_path = relative_path.blank? ? entry : File.join(relative_path, entry)
      
      if File.directory?(source_path)
        snapshot_directory_recursive(source_path, relative_file_path)
      else
        snapshot_file(source_path, relative_file_path)
      end
    end
  end

  def snapshot_file(source_path, relative_path)
    return unless should_snapshot_file?(relative_path)
    
    content = File.read(source_path)
    
    # Create or find the theme file
    theme_file = ThemeFile.find_or_create_from_path(@theme_name, relative_path)
    
    # Create a new version linked to this theme version
    ThemeFileVersion.create_version(@theme_name, relative_path, content, @theme_version.user, @theme_version)
  rescue => e
    Rails.logger.error "Error snapshotting file #{relative_path}: #{e.message}"
  end

  def should_snapshot_file?(file_path)
    # Only snapshot theme-related files
    extensions = %w[.liquid .json .css .js .yml .yaml .md .txt]
    extensions.any? { |ext| file_path.end_with?(ext) }
  end
end
