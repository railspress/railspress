require 'test_helper'

class Admin::ThemeEditorControllerTest < ActionDispatch::IntegrationTest
  def setup
    @tenant = Tenant.first || Tenant.create!(name: 'Test Tenant', subdomain: 'test')
    @user = User.first || User.create!(email: 'admin@example.com', password: 'password', role: 'admin')
    
    @theme = Theme.create!(
      name: 'Test Theme',
      slug: 'test-theme',
      description: 'A test theme',
      version: '1.0.0',
      active: true,
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
    
    ThemeFileVersion.create!(
      theme_file: @theme_file,
      content: '{"title": "Test"}',
      file_size: 20,
      file_checksum: 'test-checksum',
      user: @user,
      change_summary: "Test version",
      version_number: 1,
      theme_version: @theme_version
    )
    
    sign_in @user
  end

  test "should get index" do
    get admin_theme_editor_index_url
    assert_response :success
  end

  test "should get edit file" do
    get edit_admin_theme_editor_url(@theme_file.file_path)
    assert_response :success
  end

  test "should update file" do
    new_content = '{"title": "Updated"}'
    
    patch admin_theme_editor_url(@theme_file.file_path), params: {
      file: {
        content: new_content
      }
    }
    
    assert_redirected_to admin_theme_editor_index_url(file: @theme_file.file_path)
    assert_equal '✓ File saved successfully!', flash[:notice]
    
    # Check that new version was created
    assert_equal 2, @theme_file.theme_file_versions.count
    
    latest_version = @theme_file.theme_file_versions.latest.first
    assert_equal new_content, latest_version.content
  end

  test "should handle file update failure" do
    # Mock ThemesManager to raise error
    manager = mock('ThemesManager')
    manager.expects(:create_file_version).raises(StandardError.new('Save failed'))
    ThemesManager.expects(:new).returns(manager)
    
    patch admin_theme_editor_url(@theme_file.file_path), params: {
      file: {
        content: 'new content'
      }
    }
    
    assert_redirected_to admin_theme_editor_index_url
    assert_equal '✗ Failed to save file: Save failed', flash[:alert]
  end

  test "should get file versions" do
    get versions_admin_theme_editor_url(@theme_file.file_path)
    assert_response :success
  end

  test "should restore file version" do
    # Create another version
    version2 = ThemeFileVersion.create!(
      theme_file: @theme_file,
      content: '{"title": "Version 2"}',
      file_size: 25,
      file_checksum: 'version2-checksum',
      user: @user,
      change_summary: "Version 2",
      version_number: 2,
      theme_version: @theme_version
    )
    
    patch restore_admin_theme_editor_url(@theme_file.file_path), params: {
      version_number: 1
    }
    
    assert_redirected_to admin_theme_editor_index_url(file: @theme_file.file_path)
    assert_equal '✓ File restored to version 1', flash[:notice]
    
    # Check that restoration created new version
    assert_equal 3, @theme_file.theme_file_versions.count
  end

  test "should download file" do
    get download_admin_theme_editor_url(@theme_file.file_path)
    assert_response :success
    assert_equal 'application/json', response.content_type
  end

  test "should redirect when no active theme" do
    @theme.update!(active: false)
    
    get admin_theme_editor_index_url
    assert_redirected_to admin_themes_url
    assert_equal 'No active theme found. Please activate a theme first.', flash[:alert]
  end

  test "should redirect when file not found" do
    get edit_admin_theme_editor_url('non-existent-file.json')
    assert_redirected_to admin_theme_editor_index_url
    assert_equal 'File not found or could not be read.', flash[:alert]
  end

  test "should require authentication" do
    sign_out @user
    
    get admin_theme_editor_index_url
    assert_redirected_to new_user_session_url
  end
end



