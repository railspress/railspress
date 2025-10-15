class ThemesManager
  include ActiveModel::Model
  
  attr_accessor :themes_path
  
  def initialize
    @themes_path = Rails.root.join('app', 'themes')
  end
  
  # Get all themes from filesystem
  def scan_themes
    themes = []
    
    return themes unless Dir.exist?(@themes_path)
    
    Dir.glob(File.join(@themes_path, '*')).each do |theme_dir|
      next unless File.directory?(theme_dir)
      
      theme_name = File.basename(theme_dir)
      theme_json_file = File.join(theme_dir, 'config', 'theme.json')
      
      if File.exist?(theme_json_file)
        theme_data = JSON.parse(File.read(theme_json_file))
        # Handle both array and hash formats
        theme_info = theme_data.is_a?(Array) ? theme_data.first : theme_data
        
        themes << {
          name: theme_info['name'] || theme_name,
          slug: theme_name.parameterize,
          description: theme_info['description'] || "Theme: #{theme_name}",
          version: theme_info['version'] || '1.0.0',
          config: theme_info
        }
      else
        themes << {
          name: theme_name,
          slug: theme_name.parameterize,
          description: "Theme: #{theme_name}",
          version: '1.0.0',
          config: {}
        }
      end
    end
    
    themes
  end
  
  # Sync a specific theme from filesystem to database
  def sync_theme(theme_slug)
    theme_dir = File.join(@themes_path, theme_slug)
    
    return false unless Dir.exist?(theme_dir)
    
    theme_json_file = File.join(theme_dir, 'config', 'theme.json')
    
    if File.exist?(theme_json_file)
      theme_data = JSON.parse(File.read(theme_json_file))
      # Handle both array and hash formats
      theme_info = theme_data.is_a?(Array) ? theme_data.first : theme_data
      
      theme_config = {
        name: theme_info['name'] || theme_slug.titleize,
        slug: theme_slug,
        description: theme_info['description'] || "Theme: #{theme_slug.titleize}",
        version: theme_info['version'] || '1.0.0',
        config: theme_info
      }
    else
      theme_config = {
        name: theme_slug.titleize,
        slug: theme_slug,
        description: "Theme: #{theme_slug.titleize}",
        version: '1.0.0',
        config: {}
      }
    end
    
    # Find or create theme
    theme = Theme.find_or_create_by(name: theme_config[:name]) do |t|
      t.slug = theme_config[:slug]
      t.description = theme_config[:description]
      t.version = theme_config[:version]
      t.config = theme_config[:config]
      t.active = false
      # Use ActsAsTenant.current_tenant or fallback to first tenant
      t.tenant = ActsAsTenant.current_tenant || Tenant.first
    end
    
    # Update if changed
    theme.update!(
      slug: theme_config[:slug],
      description: theme_config[:description],
      version: theme_config[:version],
      config: theme_config[:config]
    )
    
    # Sync theme files for this theme
    sync_theme_files(theme)
    
    theme
  end

  # Sync themes from filesystem to database
  def sync_themes
    themes = scan_themes
    synced_count = 0
    
    themes.each do |theme_data|
      theme = Theme.find_or_create_by(slug: theme_data[:slug]) do |t|
        t.name = theme_data[:name]
        t.description = theme_data[:description]
        t.version = theme_data[:version]
        t.config = theme_data[:config]
        t.active = false
        # Use ActsAsTenant.current_tenant or fallback to first tenant
        # Ensure we get a proper Tenant model instance, not OpenStruct
        current_tenant = ActsAsTenant.current_tenant
        if current_tenant.is_a?(OpenStruct)
          t.tenant = Tenant.find(current_tenant.id)
        else
          t.tenant = current_tenant || Tenant.first
        end
      end
      
      # Update if changed
      if theme.changed?
        theme.update!(theme_data)
        synced_count += 1
      end
      
      # Create initial version if none exists
      create_initial_version_if_needed(theme)
      
      # Sync files and detect changes
      sync_theme_files(theme)
    end
    
    synced_count
  end
  
  # Create initial theme version if none exists
  def create_initial_version_if_needed(theme)
    return if ThemeVersion.for_theme(theme.name).exists?
    
    # Create initial version
    theme_version = ThemeVersion.create!(
      theme_name: theme.name,
      version: theme.version || '1.0.0',
      user: User.first,
      is_live: true,
      is_preview: false,
      published_at: Time.current,
      change_summary: "Initial version from filesystem"
    )
    
    # Create theme files for this version
    create_theme_files_for_version(theme_version)
    
    # If this is an active theme, also create PublishedThemeVersion
    if theme.active?
      theme.ensure_published_version_exists!
    end
  end
  
  # Create theme files for a specific version
  def create_theme_files_for_version(theme_version)
    # Use the theme's slug for the directory path, not the name
    theme = Theme.find_by(name: theme_version.theme_name)
    theme_slug = theme&.slug || theme_version.theme_name.parameterize
    theme_path = File.join(@themes_path, theme_slug)
    return unless Dir.exist?(theme_path)
    
    files = find_theme_files(theme_path)
    
    files.each do |file_path|
      relative_path = file_path.gsub("#{theme_path}/", '')
      content = File.read(file_path)
      file_checksum = Digest::SHA256.hexdigest(content)
      
      # Create theme file for this version - store FULL PATH
      theme_file = ThemeFile.find_or_create_by(
        theme_name: theme_version.theme_name,
        file_path: file_path, # Store full path, not relative
        theme_version_id: theme_version.id
      ) do |tf|
        tf.file_type = determine_file_type(relative_path)
        tf.current_checksum = file_checksum
      end
      
      # Update checksum if file exists but checksum differs
      if theme_file.persisted? && theme_file.current_checksum != file_checksum
        theme_file.update!(current_checksum: file_checksum)
      end
      
      # Create initial file version if none exists
      create_file_version_if_needed(theme_file, content, file_checksum)
    end
  end
  
  # Create file version if needed (checksum-based)
  def create_file_version_if_needed(theme_file, content, file_checksum)
    # Check if we already have a version with this checksum
    existing_version = theme_file.theme_file_versions.find_by(file_checksum: file_checksum)
    return existing_version if existing_version
    
    # Create new version
    version_number = (theme_file.theme_file_versions.maximum(:version_number) || 0) + 1
    
    ThemeFileVersion.create!(
      theme_file: theme_file,
      content: content,
      file_size: content.bytesize,
      file_checksum: file_checksum,
      user: User.first,
      change_summary: "Synced from filesystem",
      version_number: version_number,
      theme_version_id: theme_file.theme_version_id
    )
  end
  
  # Sync theme files and detect changes
  def sync_theme_files(theme)
    theme_version = theme.theme_versions.live.first
    return unless theme_version
    
    # Use theme slug for directory path, not name
    theme_slug = theme.slug || theme.name.parameterize
    theme_path = File.join(@themes_path, theme_slug)
    return unless Dir.exist?(theme_path)
    
    files = find_theme_files(theme_path)
    files_processed = 0
    versions_created = 0
    published_files_updated = 0
    
    files.each do |file_path|
      relative_path = file_path.gsub("#{theme_path}/", '')
      content = File.read(file_path)
      file_checksum = Digest::SHA256.hexdigest(content)
      
      # Find or create theme file (use full path for consistency)
      theme_file = ThemeFile.find_or_create_by(
        theme_name: theme.name,
        file_path: file_path, # Store full path
        theme_version_id: theme_version.id
      ) do |tf|
        tf.file_type = determine_file_type(relative_path)
        tf.current_checksum = file_checksum
      end
      
      files_processed += 1
      
      # Check if file has changed (different checksum)
      if theme_file.current_checksum != file_checksum
        # Update checksum
        theme_file.update!(current_checksum: file_checksum)
        
        # Create new version
        version = create_file_version_if_needed(theme_file, content, file_checksum)
        versions_created += 1 if version
        
        # Update published files if theme is active
        if theme.active?
          updated = update_published_files_if_needed(theme, relative_path, content)
          published_files_updated += 1 if updated
        end
      end
    end
    
    { files_processed: files_processed, versions_created: versions_created, published_files_updated: published_files_updated }
  end
  
  # Get active theme
  def active_theme
    Theme.active.first
  end
  
  # Get active theme version for active theme
  def active_theme_version
    theme = active_theme
    return nil unless theme
    
    ThemeVersion.for_theme(theme.name).live.first
  end
  
  # Get file content for active theme or specific theme
  def get_file(file_path, theme_name = nil)
    if theme_name
      # Get file from specific theme
      theme_version = ThemeVersion.for_theme(theme_name).live.first
    else
      # Get file from active theme
      theme_version = active_theme_version
    end
    
    return nil unless theme_version
    
    # Build full path for lookup - use lowercase theme name for filesystem
    theme_path = File.join(@themes_path, (theme_name || active_theme.name).downcase)
    full_path = File.join(theme_path, file_path)
    
    # Try to find by full path
    theme_file = theme_version.theme_files.find_by(file_path: full_path)
    return theme_file.theme_file_versions.latest.first&.content if theme_file
    
    # If not found, try to find by matching the end of the path (for legacy data)
    theme_file = theme_version.theme_files.find { |file| file.file_path.end_with?("/#{file_path}") }
    return nil unless theme_file
    
    theme_file.theme_file_versions.latest.first&.content
  end

  # Get file content for builder theme (with overrides)
  def get_builder_file(builder_theme, file_path)
    # Check if builder has an override for this file
    builder_files = builder_theme.settings_data['builder_files'] || {}
    if builder_files[file_path]
      return builder_files[file_path]['content']
    end
    
    # Fall back to regular theme file
    get_file(file_path)
  end
  
  # Get parsed file content (for JSON files)
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
  
  # Create new file version (for Monaco editor saves)
  def create_file_version(theme_file, content, user = nil)
    file_checksum = Digest::SHA256.hexdigest(content)
    theme_version = theme_file.theme_version
    
    # Create new version
    version = ThemeFileVersion.create!(
      theme_file: theme_file,
      content: content,
      file_size: content.bytesize,
      file_checksum: file_checksum,
      user: user || User.first,
      change_summary: "Edited via Monaco Editor",
      version_number: (theme_file.theme_file_versions.maximum(:version_number) || 0) + 1,
      theme_version_id: theme_version.id
    )
    
    # Update theme file checksum and current version
    theme_file.update!(
      current_checksum: file_checksum,
      current_version: version.version_number
    )
    
    version
  end
  
  # Get all files for a theme
  def theme_files(theme_name)
    theme_version = ThemeVersion.for_theme(theme_name).live.first
    return [] unless theme_version
    
    theme_version.theme_files
  end
  
  # Get file tree structure
  def file_tree(theme_name)
    files = theme_files(theme_name)
    tree_hash = build_file_tree(files)
    # Convert hash tree to array format expected by the view
    convert_tree_to_array(tree_hash)
  end
  
  # Check for theme updates
  def check_for_updates(theme)
    return false unless theme
    
    # Compare filesystem version with database version
    theme_path = File.join(@themes_path, theme.name)
    theme_json_file = File.join(theme_path, 'config', 'theme.json')
    
    if File.exist?(theme_json_file)
      theme_data = JSON.parse(File.read(theme_json_file))
      theme_info = theme_data.is_a?(Array) ? theme_data.first : theme_data
      filesystem_version = theme_info['version'] || '1.0.0'
      database_version = theme.version || '1.0.0'
      
      filesystem_version != database_version
    else
      false
    end
  end
  
  # Update published theme files when files change
  def update_published_files_if_needed(theme, relative_path, content)
    published_version = theme.published_version
    return false unless published_version
    
    # Find or create published theme file
    published_file = published_version.published_theme_files.find_or_create_by(
      file_path: relative_path
    ) do |pf|
      pf.file_type = determine_file_type(relative_path)
      pf.content = content
      pf.checksum = Digest::MD5.hexdigest(content)
    end
    
    # Check if content has changed
    new_checksum = Digest::MD5.hexdigest(content)
    if published_file.checksum != new_checksum
      published_file.update!(
        content: content,
        checksum: new_checksum
      )
      Rails.logger.info "Updated published file: #{relative_path} for theme: #{theme.name}"
      return true
    end
    
    false
  rescue => e
    Rails.logger.error "Failed to update published file #{relative_path}: #{e.message}"
    false
  end
  
  private
  
  # Convert tree hash to array format for the view
  def convert_tree_to_array(tree_hash, path = '')
    result = []
    
    tree_hash.each do |name, content|
      current_path = path.empty? ? name : "#{path}/#{name}"
      
      if content.is_a?(Hash) && content[:type] == 'file'
        # This is a file
        result << {
          name: name,
          path: current_path,
          type: 'file',
          editable: content[:editable] || false,
          extension: File.extname(name),
          size: content[:size]
        }
      elsif content.is_a?(Hash) && content[:type] == 'directory'
        # This is a directory
        children = convert_tree_to_array(content[:children] || {}, current_path)
        result << {
          name: name,
          path: current_path,
          type: 'directory',
          children: children
        }
      elsif content.is_a?(Hash) && content[:children]
        # This is a directory (has children)
        children = convert_tree_to_array(content[:children], current_path)
        result << {
          name: name,
          path: current_path,
          type: 'directory',
          children: children
        }
      else
        # This might be a nested directory (no explicit type)
        children = convert_tree_to_array(content, current_path)
        if children.any? { |child| child[:type] == 'directory' }
          # Has subdirectories, treat as directory
          result << {
            name: name,
            path: current_path,
            type: 'directory',
            children: children
          }
        else
          # All files, add them directly
          result.concat(children)
        end
      end
    end
    
    result
  end
  
  def find_theme_files(theme_path)
    files = []
    
    Dir.glob(File.join(theme_path, '**', '*')).each do |file|
      next if File.directory?(file)
      files << file
    end
    
    files
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
  
  def build_file_tree(files)
    tree = {}
    
    files.each do |file|
      # Extract the theme directory name from the absolute path
      # Path format: /path/to/app/themes/theme_name/...
      path_parts = file.file_path.split('/')
      theme_index = path_parts.index('themes')
      
      if theme_index && theme_index + 1 < path_parts.length
        # Get the relative path after the theme directory
        theme_dir = path_parts[theme_index + 1]
        relative_parts = path_parts[(theme_index + 2)..-1]
        relative_path = relative_parts.join('/')
        
        path_parts = relative_path.split('/')
        current = tree
        
        path_parts.each_with_index do |part, index|
          if index == path_parts.length - 1
            # This is a file
            current[part] = {
              type: 'file',
              path: relative_path,
              theme_file: file,
              editable: editable_file?(relative_path)
            }
          else
            # This is a directory
            current[part] ||= {
              type: 'directory',
              children: {}
            }
            current = current[part][:children]
          end
        end
      end
    end
    
    tree
  end
  
  def editable_file?(file_path)
    editable_extensions = %w[.liquid .json .css .js .scss .html .erb]
    editable_extensions.any? { |ext| file_path.end_with?(ext) }
  end
  
  # Additional methods for ThemeEditorController compatibility
  
  def create_file(file_path, content = '')
    return false unless valid_file_path?(file_path)
    
    full_path = File.join(@themes_path, active_theme.name, file_path)
    
    # Create directory if it doesn't exist
    FileUtils.mkdir_p(File.dirname(full_path))
    
    File.write(full_path, content)
    
    # Create theme file and version
    theme_version = active_theme_version
    return false unless theme_version
    
    theme_file = ThemeFile.create!(
      theme_name: active_theme.name,
      file_path: file_path,
      file_type: determine_file_type(file_path),
      theme_version: theme_version,
      current_checksum: Digest::SHA256.hexdigest(content)
    )
    
    ThemeFileVersion.create!(
      theme_file: theme_file,
      content: content,
      file_size: content.bytesize,
      file_checksum: Digest::SHA256.hexdigest(content),
      user: User.first,
      change_summary: "File created",
      version_number: 1,
      theme_version: theme_version
    )
    
    true
  rescue => e
    Rails.logger.error "Failed to create file: #{e.message}"
    false
  end
  
  def delete_file(file_path)
    return false unless valid_file_path?(file_path)
    
    full_path = File.join(@themes_path, active_theme.name, file_path)
    
    if File.exist?(full_path)
      File.delete(full_path)
      
      # Remove theme file and versions
      theme_file = ThemeFile.find_by(theme_name: active_theme.name, file_path: file_path)
      theme_file&.destroy
      
      true
    else
      false
    end
  rescue => e
    Rails.logger.error "Failed to delete file: #{e.message}"
    false
  end
  
  def rename_file(old_path, new_path)
    return false unless valid_file_path?(old_path) && valid_file_path?(new_path)
    
    old_full_path = File.join(@themes_path, active_theme.name, old_path)
    new_full_path = File.join(@themes_path, active_theme.name, new_path)
    
    if File.exist?(old_full_path)
      FileUtils.mkdir_p(File.dirname(new_full_path))
      File.rename(old_full_path, new_full_path)
      
      # Update theme file path
      theme_file = ThemeFile.find_by(theme_name: active_theme.name, file_path: old_path)
      if theme_file
        theme_file.update!(file_path: new_path)
      end
      
      true
    else
      false
    end
  rescue => e
    Rails.logger.error "Failed to rename file: #{e.message}"
    false
  end
  
  def search(query)
    return [] if query.blank?
    
    results = []
    theme_path = File.join(@themes_path, active_theme.name)
    
    Dir.glob(File.join(theme_path, '**', '*')).each do |file_path|
      next unless File.file?(file_path)
      next unless editable_file?(File.basename(file_path))
      
      begin
        content = File.read(file_path)
        relative_path = file_path.gsub("#{theme_path}/", '')
        
        content.each_line.with_index do |line, line_number|
          if line.include?(query)
            results << {
              file: relative_path,
              line: line_number + 1,
              content: line.strip,
              match: line.index(query)
            }
          end
        end
      rescue => e
        # Skip files that can't be read
      end
    end
    
    results
  end
  
  def file_versions(file_path)
    theme_file = ThemeFile.find_by(theme_name: active_theme.name, file_path: file_path)
    return [] unless theme_file
    
    theme_file.theme_file_versions.order(version_number: :desc)
  end
  
  def restore_version(version_id)
    version = ThemeFileVersion.find(version_id)
    
    # Write to filesystem
    theme_path = File.join(@themes_path, active_theme.name, version.theme_file.file_path)
    File.write(theme_path, version.content)
    
    # Create new version
    theme_file = version.theme_file
    new_version = ThemeFileVersion.create!(
      theme_file: theme_file,
      content: version.content,
      file_size: version.content.bytesize,
      file_checksum: Digest::SHA256.hexdigest(version.content),
      user: User.first,
      change_summary: "Restored from version #{version.version_number}",
      version_number: (theme_file.theme_file_versions.maximum(:version_number) || 0) + 1,
      theme_version: theme_file.theme_version
    )
    
    # Update theme file checksum
    theme_file.update!(current_checksum: new_version.file_checksum)
    
    true
  rescue => e
    Rails.logger.error "Failed to restore version: #{e.message}"
    false
  end
  
  def read_file(file_path)
    get_file(file_path)
  end
  
  def errors
    @errors ||= []
  end
  
  private
  
  def valid_file_path?(file_path)
    # Prevent path traversal attacks
    return false if file_path.include?('..')
    return false if file_path.start_with?('/')
    
    true
  end
end