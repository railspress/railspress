require 'test_helper'

class ThemeTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.first || Tenant.create!(name: 'Test Tenant', subdomain: 'test')
    @theme = Theme.create!(
      name: 'Test Theme',
      slug: 'test-theme',
      description: 'A test theme',
      version: '1.0.0',
      active: false,
      tenant: @tenant,
      config: { 'test' => true }
    )
  end

  test "should be valid" do
    assert @theme.valid?
  end

  test "should require name" do
    @theme.name = nil
    assert_not @theme.valid?
    assert_includes @theme.errors[:name], "can't be blank"
  end

  test "should require slug" do
    @theme.slug = nil
    assert_not @theme.valid?
    assert_includes @theme.errors[:slug], "can't be blank"
  end

  test "should require unique slug" do
    duplicate_theme = @theme.dup
    duplicate_theme.name = 'Different Name'
    assert_not duplicate_theme.valid?
    assert_includes duplicate_theme.errors[:slug], "has already been taken"
  end

  test "should require tenant" do
    @theme.tenant = nil
    assert_not @theme.valid?
    assert_includes @theme.errors[:tenant], "must exist"
  end

  test "should activate theme" do
    # Create another theme
    other_theme = Theme.create!(
      name: 'Other Theme',
      slug: 'other-theme',
      description: 'Another theme',
      version: '1.0.0',
      active: true,
      tenant: @tenant
    )
    
    assert other_theme.active?
    assert_not @theme.active?
    
    # Activate current theme
    assert @theme.activate!
    
    # Check that only current theme is active
    assert @theme.active?
    assert_not other_theme.reload.active?
  end

  test "should get file content" do
    # Create theme version and file
    theme_version = ThemeVersion.create!(
      theme_name: @theme.name,
      version: @theme.version,
      user: User.first,
      is_live: true,
      change_summary: "Test version"
    )
    
    theme_file = ThemeFile.create!(
      theme_name: @theme.name,
      file_path: 'templates/index.json',
      file_type: 'template',
      theme_version: theme_version,
      current_checksum: 'test-checksum'
    )
    
    ThemeFileVersion.create!(
      theme_file: theme_file,
      content: '{"title": "Test"}',
      file_size: 20,
      file_checksum: 'test-checksum',
      user: User.first,
      change_summary: "Test version",
      version_number: 1,
      theme_version: theme_version
    )
    
    content = @theme.get_file('templates/index.json')
    assert_equal '{"title": "Test"}', content
  end

  test "should get parsed file content" do
    # Create theme version and file
    theme_version = ThemeVersion.create!(
      theme_name: @theme.name,
      version: @theme.version,
      user: User.first,
      is_live: true,
      change_summary: "Test version"
    )
    
    theme_file = ThemeFile.create!(
      theme_name: @theme.name,
      file_path: 'templates/index.json',
      file_type: 'template',
      theme_version: theme_version,
      current_checksum: 'test-checksum'
    )
    
    ThemeFileVersion.create!(
      theme_file: theme_file,
      content: '{"title": "Test"}',
      file_size: 20,
      file_checksum: 'test-checksum',
      user: User.first,
      change_summary: "Test version",
      version_number: 1,
      theme_version: theme_version
    )
    
    data = @theme.get_parsed_file('templates/index.json')
    assert_equal 'Test', data['title']
  end

  test "should handle invalid JSON gracefully" do
    # Create theme version and file with invalid JSON
    theme_version = ThemeVersion.create!(
      theme_name: @theme.name,
      version: @theme.version,
      user: User.first,
      is_live: true,
      change_summary: "Test version"
    )
    
    theme_file = ThemeFile.create!(
      theme_name: @theme.name,
      file_path: 'templates/invalid.json',
      file_type: 'template',
      theme_version: theme_version,
      current_checksum: 'test-checksum'
    )
    
    ThemeFileVersion.create!(
      theme_file: theme_file,
      content: 'invalid json {',
      file_size: 15,
      file_checksum: 'test-checksum',
      user: User.first,
      change_summary: "Test version",
      version_number: 1,
      theme_version: theme_version
    )
    
    data = @theme.get_parsed_file('templates/invalid.json')
    assert_nil data
  end

  test "should get live version" do
    # Create theme version
    theme_version = ThemeVersion.create!(
      theme_name: @theme.name,
      version: @theme.version,
      user: User.first,
      is_live: true,
      change_summary: "Test version"
    )
    
    live_version = @theme.live_version
    assert_equal theme_version, live_version
  end

  test "should check for updates" do
    # Mock ThemesManager
    manager = mock('ThemesManager')
    manager.expects(:check_for_updates).with(@theme).returns(true)
    ThemesManager.expects(:new).returns(manager)
    
    assert @theme.has_update_available?
  end

  test "should set slug from name" do
    theme = Theme.new(
      name: 'My Awesome Theme',
      description: 'Test theme',
      version: '1.0.0',
      tenant: @tenant
    )
    
    theme.save!
    assert_equal 'my-awesome-theme', theme.slug
  end

  test "should not override existing slug" do
    theme = Theme.new(
      name: 'My Awesome Theme',
      slug: 'custom-slug',
      description: 'Test theme',
      version: '1.0.0',
      tenant: @tenant
    )
    
    theme.save!
    assert_equal 'custom-slug', theme.slug
  end
end



