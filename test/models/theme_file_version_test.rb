require 'test_helper'

class ThemeFileVersionTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.first || Tenant.create!(name: 'Test Tenant', subdomain: 'test')
    @user = User.first || User.create!(email: 'test@example.com', password: 'password')
    
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
      user: @user,
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
    
    @theme_file_version = ThemeFileVersion.create!(
      theme_file: @theme_file,
      content: '{"title": "Test"}',
      file_size: 20,
      file_checksum: 'test-checksum',
      user: @user,
      change_summary: "Test version",
      version_number: 1,
      theme_version: @theme_version
    )
  end

  test "should be valid" do
    assert @theme_file_version.valid?
  end

  test "should require version_number" do
    @theme_file_version.version_number = nil
    assert_not @theme_file_version.valid?
    assert_includes @theme_file_version.errors[:version_number], "can't be blank"
  end

  test "should require file_checksum" do
    @theme_file_version.file_checksum = nil
    assert_not @theme_file_version.valid?
    assert_includes @theme_file_version.errors[:file_checksum], "can't be blank"
  end

  test "should require unique version_number per theme_file" do
    duplicate_version = @theme_file_version.dup
    duplicate_version.version_number = 1
    assert_not duplicate_version.valid?
    assert_includes duplicate_version.errors[:version_number], "has already been taken"
  end

  test "should allow same version_number for different theme_files" do
    other_file = ThemeFile.create!(
      theme_name: @theme.name,
      file_path: 'templates/about.json',
      file_type: 'template',
      theme_version: @theme_version,
      current_checksum: 'other-checksum'
    )
    
    other_version = ThemeFileVersion.new(
      theme_file: other_file,
      content: '{"title": "About"}',
      file_size: 20,
      file_checksum: 'other-checksum',
      user: @user,
      change_summary: "Other version",
      version_number: 1,
      theme_version: @theme_version
    )
    
    assert other_version.valid?
  end

  test "should belong to user" do
    assert_equal @user, @theme_file_version.user
  end

  test "should belong to theme_file" do
    assert_equal @theme_file, @theme_file_version.theme_file
  end

  test "should belong to theme_version" do
    assert_equal @theme_version, @theme_file_version.theme_version
  end

  test "should scope by latest" do
    # Create additional versions
    version2 = ThemeFileVersion.create!(
      theme_file: @theme_file,
      content: '{"title": "Test 2"}',
      file_size: 22,
      file_checksum: 'test-checksum-2',
      user: @user,
      change_summary: "Version 2",
      version_number: 2,
      theme_version: @theme_version
    )
    
    version3 = ThemeFileVersion.create!(
      theme_file: @theme_file,
      content: '{"title": "Test 3"}',
      file_size: 22,
      file_checksum: 'test-checksum-3',
      user: @user,
      change_summary: "Version 3",
      version_number: 3,
      theme_version: @theme_version
    )
    
    latest = ThemeFileVersion.latest
    assert_equal version3, latest.first
  end

  test "should set version number automatically" do
    # Create new version without specifying version_number
    new_version = ThemeFileVersion.new(
      theme_file: @theme_file,
      content: '{"title": "New"}',
      file_size: 20,
      file_checksum: 'new-checksum',
      user: @user,
      change_summary: "New version",
      theme_version: @theme_version
    )
    
    new_version.save!
    assert_equal 2, new_version.version_number
  end

  test "should update theme file current version after creation" do
    # Create new version
    new_version = ThemeFileVersion.create!(
      theme_file: @theme_file,
      content: '{"title": "Updated"}',
      file_size: 25,
      file_checksum: 'updated-checksum',
      user: @user,
      change_summary: "Updated version",
      version_number: 2,
      theme_version: @theme_version
    )
    
    # Theme file should be updated with new current version
    @theme_file.reload
    assert_equal 2, @theme_file.current_version
  end

  test "should create version with helper method" do
    content = '{"title": "Helper Created"}'
    version = ThemeFileVersion.create_version(
      @theme_file,
      content,
      @user,
      @theme_version
    )
    
    assert_not_nil version
    assert_equal content, version.content
    assert_equal @theme_file, version.theme_file
    assert_equal @user, version.user
    assert_equal @theme_version, version.theme_version
  end
end

