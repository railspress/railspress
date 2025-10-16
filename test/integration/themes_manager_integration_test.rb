require 'test_helper'

class ThemesManagerIntegrationTest < ActiveSupport::TestCase
  def setup
    # Use the actual themes directory for integration testing
    @themes_path = Rails.root.join('app', 'themes')
    @manager = ThemesManager.new
    
    # Clear existing data
    ThemeFileVersion.delete_all
    ThemeFile.delete_all
    ThemeVersion.delete_all
    Theme.delete_all
  end

  test "should scan real themes from filesystem" do
    themes = @manager.scan_themes
    
    # Should find the actual themes in app/themes
    assert themes.length > 0
    
    theme_names = themes.map { |t| t[:name] }
    assert_includes theme_names, "Elegance"
    assert_includes theme_names, "Nordic"
    assert_includes theme_names, "Twenty Twenty Five"
  end

  test "should sync real themes to database" do
    synced_count = @manager.sync_themes
    
    assert synced_count > 0
    assert Theme.count > 0
    assert ThemeVersion.count > 0
    
    # Check that themes were created with proper names
    theme_names = Theme.pluck(:name)
    assert_includes theme_names, "Elegance"
    assert_includes theme_names, "Nordic"
    assert_includes theme_names, "Twenty Twenty Five"
  end

  test "should create theme files and versions for real themes" do
    @manager.sync_themes
    
    # Should have theme files
    assert ThemeFile.count > 0
    assert ThemeFileVersion.count > 0
    
    # Each theme file should have at least one version
    ThemeFile.all.each do |file|
      assert file.theme_file_versions.count > 0, "ThemeFile #{file.file_path} should have versions"
    end
    
    # Should have files for each theme
    Theme.all.each do |theme|
      theme_files = ThemeFile.where(theme_name: theme.name)
      assert theme_files.count > 0, "Theme #{theme.name} should have files"
    end
  end

  test "should get file content from real themes" do
    @manager.sync_themes
    
    theme = Theme.find_by(name: 'Nordic')
    theme.activate!
    
    content = @manager.get_file('templates/index.json')
    assert_not_nil content
    assert content.length > 0
  end

  test "should detect file changes in real themes" do
    @manager.sync_themes
    
    initial_version_count = ThemeFileVersion.count
    
    # Find a real file to modify
    theme = Theme.find_by(name: 'Nordic')
    theme_file = ThemeFile.where(theme_name: theme.name).first
    
    # Modify the actual file
    original_content = File.read(File.join(@themes_path, theme.name, theme_file.file_path))
    File.write(File.join(@themes_path, theme.name, theme_file.file_path), original_content + "\n// Modified")
    
    # Sync again
    result = @manager.send(:sync_theme_files, theme)
    
    assert result[:versions_created] > 0
    assert ThemeFileVersion.count > initial_version_count
    
    # Restore original content
    File.write(File.join(@themes_path, theme.name, theme_file.file_path), original_content)
  end

  test "should check for updates in real themes" do
    @manager.sync_themes
    
    theme = Theme.find_by(name: 'Nordic')
    
    # No update initially
    assert_not @manager.check_for_updates(theme)
    
    # Modify theme.json version
    theme_json_path = File.join(@themes_path, theme.name, 'config', 'theme.json')
    original_content = File.read(theme_json_path)
    
    theme_data = JSON.parse(original_content)
    theme_data.first['version'] = '2.0.0'
    File.write(theme_json_path, JSON.pretty_generate(theme_data))
    
    # Should detect update
    assert @manager.check_for_updates(theme)
    
    # Restore original content
    File.write(theme_json_path, original_content)
  end

  test "should build file tree for real themes" do
    @manager.sync_themes
    
    tree = @manager.file_tree('nordic')
    
    assert_instance_of Hash, tree
    assert tree.key?('templates')
    assert tree['templates'].key?('index.json')
    assert_equal 'file', tree['templates']['index.json'][:type]
  end
end



