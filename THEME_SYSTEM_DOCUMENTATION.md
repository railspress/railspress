# RailsPress Theme System Documentation

This document explains how the RailsPress theme system works, covering three key workflows:

1. **File Retrieval Flow**: Filesystem → ThemesManager → getFile → getPublishedVersion → getFile
2. **Builder Update Flow**: Filesystem → ThemesManager → BuilderTheme → BuilderThemeFiles → PublishedVersion → Update File
3. **Frontend Renderer Flow**: How FrontendRendererService works

---

## 1. File Retrieval Flow
**Filesystem → ThemesManager → getFile → getPublishedVersion → getFile**

This flow is used when the frontend needs to retrieve theme files for rendering.

### Step-by-Step Process:

#### 1.1 Filesystem Scan (`ThemesManager#scan_themes`)
```ruby
# Location: app/services/themes_manager.rb:11-46
def scan_themes
  themes = []
  Dir.glob(File.join(@themes_path, '*')).each do |theme_dir|
    theme_name = File.basename(theme_dir)
    theme_json_file = File.join(theme_dir, 'config', 'theme.json')
    
    if File.exist?(theme_json_file)
      theme_data = JSON.parse(File.read(theme_json_file))
      # Extract theme metadata (name, version, description)
    end
  end
end
```

**What it does:**
- Scans `app/themes/` directory
- Reads `config/theme.json` from each theme folder
- Extracts theme metadata (name, version, description, config)

#### 1.2 Theme Sync (`ThemesManager#sync_theme`)
```ruby
# Location: app/services/themes_manager.rb:49-101
def sync_theme(theme_slug)
  # 1. Read theme.json from filesystem
  theme_data = JSON.parse(File.read(theme_json_file))
  
  # 2. Find or create Theme record in database
  theme = Theme.find_or_create_by(name: theme_config[:name])
  
  # 3. Sync theme files
  sync_theme_files(theme)
end
```

**What it does:**
- Reads theme metadata from filesystem
- Creates/updates Theme record in database
- Calls `sync_theme_files` to process individual files

#### 1.3 File Sync (`ThemesManager#sync_theme_files`)
```ruby
# Location: app/services/themes_manager.rb:222-271
def sync_theme_files(theme)
  files = find_theme_files(theme_path)
  
  files.each do |file_path|
    content = File.read(file_path)
    file_checksum = Digest::SHA256.hexdigest(content)
    
    # Find or create ThemeFile
    theme_file = ThemeFile.find_or_create_by(
      theme_name: theme.name,
      file_path: file_path,
      theme_version_id: theme_version.id
    )
    
    # Check if file changed (different checksum)
    if theme_file.current_checksum != file_checksum
      # Create new ThemeFileVersion
      create_file_version_if_needed(theme_file, content, file_checksum)
      
      # Update PublishedThemeFile if theme is active
      if theme.active?
        update_published_files_if_needed(theme, relative_path, content)
      end
    end
  end
end
```

**What it does:**
- Scans all files in theme directory
- Calculates SHA256 checksum for each file
- Creates `ThemeFile` record (metadata about file)
- Creates `ThemeFileVersion` record (actual file content + checksum)
- If theme is active, updates `PublishedThemeFile` record

#### 1.4 Get File (`ThemesManager#get_file`)
```ruby
# Location: app/services/themes_manager.rb:287-311
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
```

**What it does:**
- Gets theme version (specific theme or active theme)
- Builds full filesystem path using lowercase theme name
- Finds ThemeFile by full path first, then by path ending (legacy support)
- Returns latest ThemeFileVersion content

#### 1.5 Get Published Version (`Theme#get_file`)
```ruby
# Location: app/models/theme.rb:44-47
def get_file(file_path)
  live_version = theme_versions.live.first
  live_version&.file_content(file_path)
end
```

**What it does:**
- Gets live theme version
- Calls `file_content` on the version

#### 1.6 Get Theme Version File (`ThemeVersion#file_content`)
```ruby
# Location: app/models/theme_version.rb:58-68
def file_content(file_path)
  # Try exact match first (for full paths)
  theme_file = theme_files.find_by(file_path: file_path)
  return theme_file.theme_file_versions.latest.first&.content if theme_file
  
  # Try to find by matching the end of the path (for legacy relative paths)
  theme_file = theme_files.find { |file| file.file_path.end_with?("/#{file_path}") }
  return nil unless theme_file
  
  theme_file.theme_file_versions.latest.first&.content
end
```

**What it does:**
- Finds ThemeFile by exact path first, then by path ending (legacy support)
- Returns latest ThemeFileVersion content

---

## 2. Builder Update Flow
**Filesystem → ThemesManager → BuilderTheme → BuilderThemeFiles → PublishedVersion → Update File**

This flow is used when files are edited through the builder interface (not Monaco editor).

### Step-by-Step Process:

#### 2.1 Builder Theme Files
```ruby
# BuilderThemeFiles store user customizations
# These override the default theme files when rendering
builder_theme.builder_theme_files.each do |file|
  # File contains user's custom content from builder interface
  # This takes precedence over filesystem files
end
```

**What it does:**
- `BuilderThemeFiles` store user customizations made through the builder
- These files override the default theme files when rendering
- Builder interface saves changes directly to `BuilderThemeFiles`

#### 2.2 Builder Theme Integration
```ruby
# Location: app/services/themes_manager.rb:314-323
def get_builder_file(builder_theme, file_path)
  # Check if builder has an override for this file
  builder_files = builder_theme.settings_data['builder_files'] || {}
  if builder_files[file_path]
    return builder_files[file_path]['content']
  end
  
  # Fall back to regular theme file
  get_file(file_path)
end
```

**What it does:**
- Checks if builder has custom overrides
- Falls back to regular theme files if no overrides

#### 2.3 Published Version Update
```ruby
# Location: app/services/themes_manager.rb:402-430
def update_published_files_if_needed(theme, relative_path, content)
  published_version = theme.published_version
  return false unless published_version
  
  published_file = published_version.published_theme_files.find_or_create_by(
    file_path: relative_path
  )
  
  # Check if content has changed
  new_checksum = Digest::MD5.hexdigest(content)
  if published_file.checksum != new_checksum
    published_file.update!(
      content: content,
      checksum: new_checksum
    )
  end
end
```

**What it does:**
- Updates PublishedThemeFile with new content
- Updates checksum to track changes
- This is what the frontend actually serves

---

## 3. Frontend Renderer Flow
**How FrontendRendererService Works**

The FrontendRendererService is responsible for rendering the final HTML that users see.

### Step-by-Step Process:

#### 3.1 Initialization
```ruby
# Location: app/services/frontend_renderer_service.rb:4-12
def initialize(published_version, builder_theme_id = nil)
  @published_version = published_version
  @builder_theme_id = builder_theme_id
  @builder_theme = create_mock_builder_theme
  @builder_renderer = BuilderLiquidRenderer.new(@builder_theme)
end
```

**What it does:**
- Takes PublishedThemeVersion as input
- Creates mock BuilderTheme object
- Initializes BuilderLiquidRenderer

#### 3.2 Mock Builder Theme Creation
```ruby
# Location: app/services/frontend_renderer_service.rb:66-134
def create_mock_builder_theme
  mock_theme = Object.new
  
  def mock_theme.get_rendered_file(template_name)
    # Get template data from PublishedThemeFile
    template_file = @published_version.published_theme_files.find_by(
      file_path: "templates/#{template_name}.json"
    )
    
    # Get layout file
    layout_file = @published_version.published_theme_files.find_by(
      file_path: 'layout/theme.liquid'
    )
    
    # Build page sections from template data
    page_sections = []
    template_content['order']&.each_with_index do |section_id, index|
      section_config = template_content['sections'][section_id]
      # Create mock section objects
    end
  end
end
```

**What it does:**
- Creates a mock object that mimics BuilderTheme interface
- Reads template data from PublishedThemeFiles
- Builds section objects from template configuration

#### 3.3 Template Rendering
```ruby
# Location: app/services/frontend_renderer_service.rb:15-27
def render_template(template_name, context = {})
  # Use BuilderLiquidRenderer
  html = @builder_renderer.render_template(template_name, context)
  
  # Replace asset URLs with embedded content
  html = replace_asset_urls_with_content(html)
  
  html
end
```

**What it does:**
- Delegates to BuilderLiquidRenderer
- Replaces asset URLs with embedded content
- Returns final HTML

#### 3.4 BuilderLiquidRenderer Process
```ruby
# Location: app/services/builder_liquid_renderer.rb:13-30
def render_template(template_name, context = {})
  # Get rendered file data (template + layout + sections + settings)
  rendered_data = builder_theme.get_rendered_file(template_name)
  
  # Get layout content from filesystem
  layout_content = rendered_data[:layout_content]
  
  # Render sections based on file settings
  sections_html = render_sections_from_rendered_data(rendered_data, context)
  
  # Replace content_for_layout with rendered sections
  layout_content = layout_content.gsub('{{ content_for_layout }}', sections_html)
  
  # Render the layout with all sections and settings
  render_layout_with_sections(layout_content, context, rendered_data)
end
```

**What it does:**
- Gets template configuration from mock builder theme
- Renders each section using Liquid templates
- Combines sections into layout
- Returns complete HTML

#### 3.5 Section Rendering (`BuilderLiquidRenderer#render_sections_from_rendered_data`)
```ruby
# Location: app/services/builder_liquid_renderer.rb:287-305
def render_sections_from_rendered_data(rendered_data, context)
  sections_html = ''
  # Avoid double-rendering header/footer: layout already includes them
  page_sections = rendered_data[:page_sections].reject { |s| %w[header footer].include?(s.section_type) }

  page_sections.each do |section|
    # Get section content from filesystem
    section_content = get_section_content(section.section_type)
    next unless section_content
    
    # Render section with its settings
    sections_html += render_section_with_content(section, section_content, context)
  end
  
  sections_html
end
```

**What it does:**
- Filters out header/footer sections (already in layout)
- Gets section content using `get_section_content`
- Renders each section with its settings
- Combines all section HTML

#### 3.6 File Content Retrieval (`BuilderLiquidRenderer#get_file_content`)
```ruby
# Location: app/services/builder_liquid_renderer.rb:153-165
def get_file_content(file_path)
  # Check if we're using PublishedThemeFile (FrontendRendererService)
  if @builder_theme.respond_to?(:instance_variable_get) && 
     @builder_theme.instance_variable_get(:@published_version)
    
    published_version = @builder_theme.instance_variable_get(:@published_version)
    file = published_version.published_theme_files.find_by(file_path: file_path)
    return file&.content
  end
  
  # Otherwise use ThemesManager
  @themes_manager.get_file(file_path)
end
```

**What it does:**
- Checks if using FrontendRendererService (has PublishedThemeVersion)
- If yes, gets content from PublishedThemeFile
- If no, falls back to ThemesManager.get_file

#### 3.7 Liquid File System Setup (`BuilderLiquidRenderer#setup_liquid_file_system`)
```ruby
# Location: app/services/builder_liquid_renderer.rb:136-150
def setup_liquid_file_system
  # Create a custom file system that can resolve includes from PublishedThemeFile
  if @builder_theme.respond_to?(:instance_variable_get) && 
     @builder_theme.instance_variable_get(:@published_version)
    
    published_version = @builder_theme.instance_variable_get(:@published_version)
    
    # Use PublishedVersion directly as the file system
    Liquid::Template.file_system = published_version
    Rails.logger.info "Set up PublishedVersion as Liquid file system"
  else
    # Use default file system for regular themes
    Liquid::Template.file_system = Liquid::LocalFileSystem.new("/", "%s.liquid")
  end
end
```

**What it does:**
- Detects if using FrontendRendererService (has PublishedThemeVersion)
- If yes, sets PublishedThemeVersion as Liquid's file system
- If no, uses default LocalFileSystem
- This enables `{% render %}` and `{% include %}` tags to work

#### 3.8 Liquid File System Integration
```ruby
# Location: app/models/published_theme_version.rb:34-61
def read_template_file(template_path)
  # Try to find the file directly
  file = published_theme_files.find_by(file_path: template_path)
  if file
    return file.content
  end
  
  # Try with .liquid extension
  file = published_theme_files.find_by(file_path: "#{template_path}.liquid")
  if file
    return file.content
  end
  
  # Try snippets directory
  file = published_theme_files.find_by(file_path: "snippets/#{template_path}.liquid")
  if file
    return file.content
  end
end
```

**What it does:**
- Implements Liquid's file system interface
- Allows `{% render %}` and `{% include %}` tags to work
- Resolves template paths to PublishedThemeFile content

---

## Data Flow Summary

### File Storage Hierarchy:
1. **Filesystem** - Original theme files (`app/themes/theme_name/`)
2. **ThemeFile** - Metadata about files (path, type, checksum)
3. **ThemeFileVersion** - Versioned file content (content + checksum)
4. **PublishedThemeFile** - Live file content for frontend serving

### Key Models:
- **Theme** - Theme metadata and configuration
- **ThemeVersion** - Version of theme (live, preview, published)
- **ThemeFile** - File metadata within a theme version
- **ThemeFileVersion** - Versioned content of a file
- **PublishedThemeVersion** - Live version for frontend
- **PublishedThemeFile** - Live file content for frontend
- **BuilderTheme** - Builder theme configuration
- **BuilderThemeFiles** - User customizations from builder interface

### Services:
- **ThemesManager** - Handles filesystem ↔ database sync
- **FrontendRendererService** - Renders final HTML
- **BuilderLiquidRenderer** - Handles Liquid template rendering
- **ThemeFileManager** - Alternative file management (used by some controllers)

### Key Features:
- **Checksum-based change detection** - Only creates new versions when files change
- **Version-safe file serving** - Frontend always gets consistent file versions
- **Builder integration** - User customizations in BuilderThemeFiles override default files
- **Liquid compatibility** - Full support for `{% render %}`, `{% include %}`, etc.

This architecture ensures that:
1. Theme files are safely versioned and tracked
2. Frontend rendering is consistent and reliable
3. User customizations in the builder work seamlessly
4. File changes are detected and propagated correctly
5. Builder interface works with BuilderThemeFiles, not Monaco editor