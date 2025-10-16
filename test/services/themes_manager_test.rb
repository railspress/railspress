require 'test_helper'

class ThemesManagerTest < ActiveSupport::TestCase
  def setup
    @themes_path = Rails.root.join('test', 'fixtures', 'themes')
    @manager = ThemesManager.new
    @manager.themes_path = @themes_path
    
    # Clear existing data
    ThemeFileVersion.delete_all
    ThemeFile.delete_all
    ThemeVersion.delete_all
    Theme.delete_all
  end

  test "should scan themes from filesystem" do
    themes = @manager.scan_themes
    
    assert_equal 3, themes.length
    
    theme_names = themes.map { |t| t[:name] }
    assert_includes theme_names, "Test Theme 1"
    assert_includes theme_names, "Test Theme 2"
    assert_includes theme_names, "Test Theme 3"
  end

  test "should sync themes to database" do
    synced_count = @manager.sync_themes
    
    assert_equal 3, synced_count
    assert_equal 3, Theme.count
    assert_equal 3, ThemeVersion.count
    
    # Check theme names
    theme_names = Theme.pluck(:name)
    assert_includes theme_names, "Test Theme 1"
    assert_includes theme_names, "Test Theme 2"
    assert_includes theme_names, "Test Theme 3"
  end

  test "should create theme files and versions" do
    @manager.sync_themes
    
    # Should have theme files
    assert ThemeFile.count > 0
    assert ThemeFileVersion.count > 0
    
    # Each theme file should have at least one version
    ThemeFile.all.each do |file|
      assert file.theme_file_versions.count > 0
    end
  end

  test "should detect file changes and create new versions" do
    @manager.sync_themes
    
    initial_version_count = ThemeFileVersion.count
    
    # Modify a file
    test_file_path = File.join(@themes_path, 'test_theme_1', 'templates', 'index.json')
    File.write(test_file_path, '{"modified": true}')
    
    # Sync again
    theme = Theme.find_by(slug: 'test-theme-1')
    result = @manager.send(:sync_theme_files, theme)
    
    assert result[:versions_created] > 0
    assert ThemeFileVersion.count > initial_version_count
  end

  test "should get active theme" do
    @manager.sync_themes
    
    # No active theme initially
    assert_nil @manager.active_theme
    
    # Activate a theme
    theme = Theme.first
    theme.activate!
    
    assert_equal theme, @manager.active_theme
  end

  test "should get file content from active theme" do
    @manager.sync_themes
    
    theme = Theme.first
    theme.activate!
    
    content = @manager.get_file('templates/index.json')
    assert_not_nil content
    assert content.length > 0
  end

  test "should get parsed JSON file content" do
    @manager.sync_themes
    
    theme = Theme.first
    theme.activate!
    
    data = @manager.get_parsed_file('templates/index.json')
    assert_instance_of Hash, data
  end

  test "should create file version for Monaco editor" do
    @manager.sync_themes
    
    theme_file = ThemeFile.first
    new_content = '{"new": "content"}'
    
    version = @manager.create_file_version(theme_file, new_content)
    
    assert_not_nil version
    assert_equal new_content, version.content
    assert_equal 2, version.version_number
  end

  test "should check for theme updates" do
    @manager.sync_themes
    
    theme = Theme.first
    
    # No update initially
    assert_not @manager.check_for_updates(theme)
    
    # Modify theme.json version
    theme_json_path = File.join(@themes_path, theme.slug, 'config', 'theme.json')
    theme_data = JSON.parse(File.read(theme_json_path))
    theme_data.first['version'] = '2.0.0'
    File.write(theme_json_path, JSON.pretty_generate(theme_data))
    
    # Should detect update
    assert @manager.check_for_updates(theme)
  end

  test "should build file tree" do
    @manager.sync_themes
    
    tree = @manager.file_tree('test-theme-1')
    
    assert_instance_of Hash, tree
    assert tree.key?('templates')
    assert tree['templates'].key?('index.json')
    assert_equal 'file', tree['templates']['index.json'][:type]
  end

  test "should determine file types correctly" do
    assert_equal 'template', @manager.send(:determine_file_type, 'templates/index.json')
    assert_equal 'section', @manager.send(:determine_file_type, 'sections/header.liquid')
    assert_equal 'layout', @manager.send(:determine_file_type, 'layout/theme.liquid')
    assert_equal 'asset', @manager.send(:determine_file_type, 'assets/style.css')
    assert_equal 'config', @manager.send(:determine_file_type, 'config/settings.json')
    assert_equal 'other', @manager.send(:determine_file_type, 'README.md')
  end

  test "should identify editable files" do
    assert @manager.send(:editable_file?, 'templates/index.json')
    assert @manager.send(:editable_file?, 'sections/header.liquid')
    assert @manager.send(:editable_file?, 'assets/style.css')
    assert @manager.send(:editable_file?, 'assets/script.js')
    assert_not @manager.send(:editable_file?, 'README.md')
    assert_not @manager.send(:editable_file?, 'image.png')
  end

  private

  def create_test_themes
    # Create test theme directories and files
    themes = [
      {
        name: 'test_theme_1',
        display_name: 'Test Theme 1',
        version: '1.0.0'
      },
      {
        name: 'test_theme_2', 
        display_name: 'Test Theme 2',
        version: '1.0.0'
      },
      {
        name: 'test_theme_3',
        display_name: 'Test Theme 3', 
        version: '1.0.0'
      }
    ]

    themes.each do |theme_info|
      theme_dir = File.join(@themes_path, theme_info[:name])
      FileUtils.mkdir_p(theme_dir)
      
      # Create config directory
      config_dir = File.join(theme_dir, 'config')
      FileUtils.mkdir_p(config_dir)
      
      # Create theme.json
      theme_json = [{
        "name" => theme_info[:display_name],
        "version" => theme_info[:version]
      }]
      File.write(File.join(config_dir, 'theme.json'), JSON.pretty_generate(theme_json))
      
      # Create templates directory and file
      templates_dir = File.join(theme_dir, 'templates')
      FileUtils.mkdir_p(templates_dir)
      File.write(File.join(templates_dir, 'index.json'), '{"title": "Homepage"}')
      
      # Create sections directory and file
      sections_dir = File.join(theme_dir, 'sections')
      FileUtils.mkdir_p(sections_dir)
      File.write(File.join(sections_dir, 'header.liquid'), '<header>Header</header>')
    end
  end
end



