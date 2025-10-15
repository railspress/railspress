require 'test_helper'

class Admin::ThemesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @tenant = Tenant.first || Tenant.create!(name: 'Test Tenant', subdomain: 'test')
    @user = User.first || User.create!(email: 'admin@example.com', password: 'password', role: 'admin')
    @theme = Theme.create!(
      name: 'Test Theme',
      slug: 'test-theme',
      description: 'A test theme',
      version: '1.0.0',
      active: false,
      tenant: @tenant
    )
    
    sign_in @user
  end

  test "should get index" do
    get admin_themes_url
    assert_response :success
    assert_select 'h1', text: /Themes/
  end

  test "should sync themes" do
    # Mock ThemesManager
    manager = mock('ThemesManager')
    manager.expects(:sync_themes).returns(2)
    ThemesManager.expects(:new).returns(manager)
    
    post sync_admin_themes_url
    assert_redirected_to admin_themes_url
    assert_equal '✓ 2 themes synced successfully!', flash[:notice]
  end

  test "should activate theme" do
    patch activate_admin_theme_url(@theme)
    
    assert_redirected_to admin_themes_url
    assert_equal "✓ Theme '#{@theme.name}' activated successfully! View your frontend to see the changes.", flash[:notice]
    
    @theme.reload
    assert @theme.active?
  end

  test "should not activate non-existent theme" do
    patch activate_admin_theme_url(id: 'non-existent')
    
    assert_redirected_to admin_themes_url
    assert_equal '✗ Theme not found.', flash[:alert]
  end

  test "should show preview" do
    get preview_admin_themes_url, params: { theme: @theme.slug }
    assert_response :success
  end

  test "should require admin for activate" do
    @user.update!(role: 'user')
    
    patch activate_admin_theme_url(@theme)
    assert_response :forbidden
  end

  test "should require admin for sync" do
    @user.update!(role: 'user')
    
    post sync_admin_themes_url
    assert_response :forbidden
  end

  test "should handle theme activation failure" do
    # Mock theme to fail activation
    @theme.expects(:activate!).returns(false)
    Theme.expects(:find_by).with(id: @theme.id.to_s).returns(@theme)
    
    patch activate_admin_theme_url(@theme)
    
    assert_redirected_to admin_themes_url
    assert_equal "✗ Failed to activate theme '#{@theme.name}'. Please check the theme files.", flash[:alert]
  end
end
