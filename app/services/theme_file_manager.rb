class ThemeFileManager
  # Allowed file extensions for editing
  EDITABLE_EXTENSIONS = %w[
    .erb .html .htm .haml .slim
    .css .scss .sass
    .js .coffee
    .json .yml .yaml
    .rb
    .md .txt
  ].freeze
  
  # Binary/asset extensions (download only)
  BINARY_EXTENSIONS = %w[
    .png .jpg .jpeg .gif .svg .webp .ico
    .woff .woff2 .ttf .eot .otf
    .mp4 .webm .ogg
    .zip .tar .gz
    .pdf
  ].freeze
  
  attr_reader :theme_name, :theme_path, :errors
  
  def initialize(theme_name)
    @theme_name = theme_name
    @theme_path = Rails.root.join('app', 'themes', theme_name)
    @errors = []
    
    validate_theme_exists!
  end
  
  # List all files in theme directory
  def list_files(directory = '')
    return [] unless valid_directory?(directory)
    
    full_path = @theme_path.join(directory)
    entries = []
    
    Dir.entries(full_path).sort.each do |entry|
      next if entry.start_with?('.')
      
      entry_path = full_path.join(entry)
      relative_path = entry_path.relative_path_from(@theme_path).to_s
      
      entries << {
        name: entry,
        path: relative_path,
        type: File.directory?(entry_path) ? 'directory' : 'file',
        editable: editable_file?(entry),
        extension: File.extname(entry),
        size: File.directory?(entry_path) ? nil : File.size(entry_path),
        modified_at: File.mtime(entry_path)
      }
    end
    
    entries
  end
  
  # Get file tree structure
  def file_tree
    build_tree(@theme_path)
  end
  
  # Read file content
  def read_file(file_path)
    return nil unless valid_file_path?(file_path)
    
    full_path = @theme_path.join(file_path)
    
    unless File.exist?(full_path)
      @errors << "File not found: #{file_path}"
      return nil
    end
    
    unless editable_file?(file_path)
      @errors << "File type not editable: #{file_path}"
      return nil
    end
    
    File.read(full_path)
  end
  
  # Write file content
  def write_file(file_path, content)
    return false unless valid_file_path?(file_path)
    
    full_path = @theme_path.join(file_path)
    
    unless editable_file?(file_path)
      @errors << "File type not editable: #{file_path}"
      return false
    end
    
    # Create backup before writing
    create_backup(full_path) if File.exist?(full_path)
    
    # Ensure directory exists
    FileUtils.mkdir_p(File.dirname(full_path))
    
    # Write file
    File.write(full_path, content)
    
    # Create version record
    create_version_record(file_path, content)
    
    true
  rescue => e
    @errors << "Failed to write file: #{e.message}"
    false
  end
  
  # Create new file
  def create_file(file_path, content = '')
    return false unless valid_file_path?(file_path)
    
    full_path = @theme_path.join(file_path)
    
    if File.exist?(full_path)
      @errors << "File already exists: #{file_path}"
      return false
    end
    
    write_file(file_path, content)
  end
  
  # Delete file
  def delete_file(file_path)
    return false unless valid_file_path?(file_path)
    
    full_path = @theme_path.join(file_path)
    
    unless File.exist?(full_path)
      @errors << "File not found: #{file_path}"
      return false
    end
    
    # Create backup before deleting
    create_backup(full_path)
    
    File.delete(full_path)
    true
  rescue => e
    @errors << "Failed to delete file: #{e.message}"
    false
  end
  
  # Rename file
  def rename_file(old_path, new_path)
    return false unless valid_file_path?(old_path) && valid_file_path?(new_path)
    
    old_full_path = @theme_path.join(old_path)
    new_full_path = @theme_path.join(new_path)
    
    unless File.exist?(old_full_path)
      @errors << "File not found: #{old_path}"
      return false
    end
    
    if File.exist?(new_full_path)
      @errors << "File already exists: #{new_path}"
      return false
    end
    
    FileUtils.mv(old_full_path, new_full_path)
    true
  rescue => e
    @errors << "Failed to rename file: #{e.message}"
    false
  end
  
  # Search in files
  def search(query)
    return [] if query.blank?
    
    results = []
    
    Dir.glob(@theme_path.join('**', '*')).each do |file_path|
      next unless File.file?(file_path)
      next unless editable_file?(file_path)
      
      begin
        content = File.read(file_path)
        relative_path = Pathname.new(file_path).relative_path_from(@theme_path).to_s
        
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
  
  # Get file versions
  def file_versions(file_path)
    ThemeFileVersion.where(
      theme_name: @theme_name,
      file_path: file_path
    ).order(created_at: :desc).limit(20)
  end
  
  # Restore file from version
  def restore_version(version_id)
    version = ThemeFileVersion.find(version_id)
    
    return false unless version.theme_name == @theme_name
    
    write_file(version.file_path, version.content)
  end
  
  private
  
  def validate_theme_exists!
    unless File.directory?(@theme_path)
      raise ArgumentError, "Theme not found: #{@theme_name}"
    end
  end
  
  def valid_directory?(directory)
    # Prevent directory traversal
    return false if directory.include?('..')
    return false if directory.start_with?('/')
    
    true
  end
  
  def valid_file_path?(file_path)
    # Prevent path traversal attacks
    return false if file_path.include?('..')
    return false if file_path.start_with?('/')
    
    # Must be within theme directory
    full_path = @theme_path.join(file_path)
    return false unless full_path.to_s.start_with?(@theme_path.to_s)
    
    true
  end
  
  def editable_file?(file_path)
    ext = File.extname(file_path).downcase
    EDITABLE_EXTENSIONS.include?(ext)
  end
  
  def build_tree(directory, prefix = '')
    entries = []
    
    Dir.entries(directory).sort.each do |entry|
      next if entry.start_with?('.')
      
      entry_path = File.join(directory, entry)
      relative_path = Pathname.new(entry_path).relative_path_from(@theme_path).to_s
      
      if File.directory?(entry_path)
        entries << {
          name: entry,
          path: relative_path,
          type: 'directory',
          children: build_tree(entry_path, "#{prefix}#{entry}/")
        }
      else
        entries << {
          name: entry,
          path: relative_path,
          type: 'file',
          editable: editable_file?(entry),
          extension: File.extname(entry),
          size: File.size(entry_path)
        }
      end
    end
    
    entries
  end
  
  def create_backup(file_path)
    backup_dir = Rails.root.join('tmp', 'theme_backups', @theme_name)
    FileUtils.mkdir_p(backup_dir)
    
    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    backup_file = backup_dir.join("#{File.basename(file_path)}.#{timestamp}.bak")
    
    FileUtils.cp(file_path, backup_file)
  end
  
  def create_version_record(file_path, content)
    ThemeFileVersion.create!(
      theme_name: @theme_name,
      file_path: file_path,
      content: content,
      file_size: content.bytesize,
      user_id: Current.user&.id
    )
  rescue => e
    Rails.logger.error "Failed to create version record: #{e.message}"
  end
end






