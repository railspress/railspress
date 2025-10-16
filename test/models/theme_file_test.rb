require 'test_helper'

class ThemeFileTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.first || Tenant.create!(name: 'Test Tenant', subdomain: 'test')
    @theme = Theme.create!(
      name: 'Test Theme',
      slug: 'test-theme',
      description: 'A test theme',
      version: '1.0.0',
      active: false,
      tenant: @tenant
    )
    
    @theme_version = ThemeVersion.create!(
      theme_name: @theme.name,
      version: @theme.version,
      user: User.first,
      is_live: true,
      change_summary: "Test version"
    )
    
    @theme_file = ThemeFile.create!(
      theme_name: @theme.name,
      file_path: 'templates/index.json',
      file_type: 'template',
      theme_version: @theme_version,
      current_checksum: 'test-checksum'
    )
  end

  test "should be valid" do
    assert @theme_file.valid?
  end

  test "should require theme_name" do
    @theme_file.theme_name = nil
    assert_not @theme_file.valid?
    assert_includes @theme_file.errors[:theme_name], "can't be blank"
  end

  test "should require file_path" do
    @theme_file.file_path = nil
    assert_not @theme_file.valid?
    assert_includes @theme_file.errors[:file_path], "can't be blank"
  end

  test "should require file_type" do
    @theme_file.file_type = nil
    assert_not @theme_file.valid?
    assert_includes @theme_file.errors[:file_type], "can't be blank"
  end

  test "should require current_checksum" do
    @theme_file.current_checksum = nil
    assert_not @theme_file.valid?
    assert_includes @theme_file.errors[:current_checksum], "can't be blank"
  end

  test "should require unique file_path per theme and version" do
    duplicate_file = @theme_file.dup
    assert_not duplicate_file.valid?
    assert_includes duplicate_file.errors[:file_path], "has already been taken"
  end

  test "should allow same file_path in different versions" do
    other_version = ThemeVersion.create!(
      theme_name: @theme.name,
      version: '2.0.0',
      user: User.first,
      is_live: false,
      change_summary: "Test version 2"
    )
    
    duplicate_file = @theme_file.dup
    duplicate_file.theme_version = other_version
    assert duplicate_file.valid?
  end

  test "should have many theme_file_versions" do
    # Create file versions
    version1 = ThemeFileVersion.create!(
      theme_file: @theme_file,
      content: 'content 1',
      file_size: 10,
      file_checksum: 'checksum1',
      user: User.first,
      change_summary: "Version 1",
      version_number: 1,
      theme_version: @theme_version
    )
    
    version2 = ThemeFileVersion.create!(
      theme_file: @theme_file,
      content: 'content 2',
      file_size: 10,
      file_checksum: 'checksum2',
      user: User.first,
      change_summary: "Version 2",
      version_number: 2,
      theme_version: @theme_version
    )
    
    assert_equal 2, @theme_file.theme_file_versions.count
    assert_includes @theme_file.theme_file_versions, version1
    assert_includes @theme_file.theme_file_versions, version2
  end

  test "should get current content" do
    ThemeFileVersion.create!(
      theme_file: @theme_file,
      content: 'current content',
      file_size: 15,
      file_checksum: 'current-checksum',
      user: User.first,
      change_summary: "Current version",
      version_number: 1,
      theme_version: @theme_version
    )
    
    @theme_file.update!(current_version: 1)
    
    assert_equal 'current content', @theme_file.current_content
  end

  test "should get parsed content for JSON files" do
    ThemeFileVersion.create!(
      theme_file: @theme_file,
      content: '{"title": "Test"}',
      file_size: 20,
      file_checksum: 'json-checksum',
      user: User.first,
      change_summary: "JSON version",
      version_number: 1,
      theme_version: @theme_version
    )
    
    @theme_file.update!(current_version: 1)
    
    parsed = @theme_file.parsed_content
    assert_equal 'Test', parsed['title']
  end

  test "should handle invalid JSON gracefully" do
    @theme_file.update!(file_path: 'templates/invalid.json')
    
    ThemeFileVersion.create!(
      theme_file: @theme_file,
      content: 'invalid json {',
      file_size: 15,
      file_checksum: 'invalid-checksum',
      user: User.first,
      change_summary: "Invalid JSON version",
      version_number: 1,
      theme_version: @theme_version
    )
    
    @theme_file.update!(current_version: 1)
    
    parsed = @theme_file.parsed_content
    assert_nil parsed
  end

  test "should scope by file type" do
    template_file = @theme_file
    section_file = ThemeFile.create!(
      theme_name: @theme.name,
      file_path: 'sections/header.liquid',
      file_type: 'section',
      theme_version: @theme_version,
      current_checksum: 'section-checksum'
    )
    
    templates = ThemeFile.templates
    sections = ThemeFile.sections
    
    assert_includes templates, template_file
    assert_includes sections, section_file
    assert_not_includes templates, section_file
    assert_not_includes sections, template_file
  end

  test "should scope by theme" do
    other_theme = Theme.create!(
      name: 'Other Theme',
      slug: 'other-theme',
      description: 'Another theme',
      version: '1.0.0',
      tenant: @tenant
    )
    
    other_version = ThemeVersion.create!(
      theme_name: other_theme.name,
      version: other_theme.version,
      user: User.first,
      is_live: true,
      change_summary: "Other theme version"
    )
    
    other_file = ThemeFile.create!(
      theme_name: other_theme.name,
      file_path: 'templates/index.json',
      file_type: 'template',
      theme_version: other_version,
      current_checksum: 'other-checksum'
    )
    
    theme_files = ThemeFile.for_theme(@theme.name)
    
    assert_includes theme_files, @theme_file
    assert_not_includes theme_files, other_file
  end
end



