class BuilderThemeService
  attr_reader :builder_theme

  def initialize(builder_theme)
    @builder_theme = builder_theme
  end

  # Apply theme snapshot to the frontend
  def apply_snapshot_to_frontend
    return false unless builder_theme.published?

    snapshot = builder_theme.builder_theme_snapshots.last
    return false unless snapshot

    # Update the active theme to use this snapshot
    update_active_theme_settings(snapshot)
    
    # Clear any relevant caches
    clear_theme_caches
    
    # Trigger frontend update notification
    notify_frontend_update
    
    true
  end

  # Create a new version from an existing theme
  def create_version_from_theme(theme_name, user, label = nil)
    # Get the current published version or create from base theme
    base_version = BuilderTheme.current_for_theme(theme_name)
    
    new_version = BuilderTheme.create_version(
      theme_name,
      user,
      base_version,
      label
    )

    # Copy files from base version or theme directory
    if base_version
      copy_files_from_version(base_version, new_version)
    else
      copy_files_from_theme_directory(theme_name, new_version)
    end

    new_version
  end

  # Export theme as a downloadable package
  def export_theme_package
    return nil unless builder_theme.published?

    # Create a temporary directory for the export
    temp_dir = Rails.root.join('tmp', 'theme_exports', "theme_#{builder_theme.id}_#{Time.current.to_i}")
    FileUtils.mkdir_p(temp_dir)

    begin
      # Copy all theme files
      builder_theme.builder_theme_files.each do |file|
        file_path = temp_dir.join(file.path)
        FileUtils.mkdir_p(file_path.dirname)
        File.write(file_path, file.content)
      end

      # Create theme.json with metadata
      theme_json = {
        name: builder_theme.theme_name,
        version: builder_theme.version_number.to_s,
        description: "Exported from RailsPress Theme Builder",
        author: builder_theme.user.email,
        created_at: builder_theme.created_at.iso8601,
        files: builder_theme.builder_theme_files.pluck(:path)
      }
      
      File.write(temp_dir.join('theme.json'), JSON.pretty_generate(theme_json))

      # Create zip file
      zip_path = temp_dir.parent.join("#{builder_theme.theme_name}_v#{builder_theme.version_number}.zip")
      system("cd #{temp_dir} && zip -r #{zip_path} .")

      zip_path if File.exist?(zip_path)
    ensure
      # Clean up temporary directory
      FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
    end
  end

  # Import theme from uploaded package
  def self.import_theme_package(zip_file, user, theme_name = nil)
    temp_dir = Rails.root.join('tmp', 'theme_imports', "import_#{Time.current.to_i}")
    FileUtils.mkdir_p(temp_dir)

    begin
      # Extract zip file
      system("unzip -q #{zip_file.path} -d #{temp_dir}")
      
      # Read theme metadata
      theme_json_path = temp_dir.join('theme.json')
      if File.exist?(theme_json_path)
        theme_data = JSON.parse(File.read(theme_json_path))
        theme_name ||= theme_data['name']
      end

      # Create new builder theme version
      builder_theme = BuilderTheme.create_version(theme_name, user, nil, "Imported theme")
      
      # Copy files to builder theme
      copy_files_from_directory(temp_dir, builder_theme)
      
      builder_theme
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
    end
  end

  # Validate theme structure
  def validate_theme_structure
    errors = []
    
    # Check for required files
    required_files = ['templates/index.json', 'layout/theme.liquid']
    required_files.each do |file|
      unless builder_theme.get_file(file)
        errors << "Missing required file: #{file}"
      end
    end

    # Validate JSON files
    builder_theme.builder_theme_files.json_files.each do |file|
      begin
        JSON.parse(file.content)
      rescue JSON::ParserError => e
        errors << "Invalid JSON in #{file.path}: #{e.message}"
      end
    end

    # Validate Liquid files
    builder_theme.builder_theme_files.liquid_files.each do |file|
      # Basic Liquid syntax validation could be added here
      # For now, we'll just check that the file isn't empty
      if file.content.strip.empty?
        errors << "Empty Liquid file: #{file.path}"
      end
    end

    errors
  end

  private

  def update_active_theme_settings(snapshot)
    # Update the active theme's settings in the database
    active_theme = Theme.active.first
    return unless active_theme

    # Merge snapshot settings with existing theme settings
    current_settings = active_theme.settings || {}
    snapshot_settings = snapshot.settings
    
    # Update theme settings
    active_theme.update!(settings: current_settings.merge(snapshot_settings))
    
    # Store snapshot reference for rollback capability
    Rails.cache.write("active_theme_snapshot_#{active_theme.name}", snapshot.id, expires_in: 1.week)
  end

  def clear_theme_caches
    # Clear Rails view cache
    ActionView::LookupContext::DetailsKey.clear
    
    # Clear any custom theme caches
    Rails.cache.delete_matched("theme_*")
    
    # Clear asset cache if using asset pipeline
    Rails.application.config.assets.version = Time.current.to_i.to_s if Rails.application.config.respond_to?(:assets)
  end

  def notify_frontend_update
    # Broadcast to any connected frontend clients
    ActionCable.server.broadcast(
      'theme_updates',
      {
        type: 'theme_updated',
        theme_name: builder_theme.theme_name,
        timestamp: Time.current.to_i
      }
    )
  end

  def copy_files_from_version(source_version, target_version)
    source_version.builder_theme_files.each do |file|
      target_version.builder_theme_files.create!(
        path: file.path,
        content: file.content,
        checksum: file.checksum,
        file_size: file.file_size
      )
    end
  end

  def copy_files_from_theme_directory(theme_name, builder_theme)
    theme_path = Rails.root.join('app', 'themes', theme_name)
    return unless Dir.exist?(theme_path)

    copy_files_recursive(theme_path, builder_theme, '')
  end

  def copy_files_recursive(directory, builder_theme, relative_path)
    Dir.entries(directory).each do |entry|
      next if entry.start_with?('.')

      entry_path = File.join(directory, entry)
      file_relative_path = relative_path.present? ? "#{relative_path}/#{entry}" : entry

      if File.directory?(entry_path)
        copy_files_recursive(entry_path, builder_theme, file_relative_path)
      else
        content = File.read(entry_path)
        builder_theme.update_file(file_relative_path, content)
      end
    end
  end

  def self.copy_files_from_directory(directory, builder_theme)
    Dir.glob(File.join(directory, '**', '*')).each do |file_path|
      next if File.directory?(file_path)
      
      relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(directory)).to_s
      content = File.read(file_path)
      
      builder_theme.update_file(relative_path, content)
    end
  end
end

