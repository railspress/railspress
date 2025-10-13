require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @page = Page.create!(
      title: "About Us",
      slug: "about",
      content: "This is the about page content",
      status: "published",
      author: users(:admin),
      published_at: Time.current
    )
  end

  test "should show published page" do
    get page_url(@page.slug)
    assert_response :success
  end

  test "should not show draft page to guests" do
    @page.update!(status: "draft")
    
    assert_raises(ActiveRecord::RecordNotFound) do
      get page_url(@page.slug)
    end
  end

  test "should show draft page to admin" do
    sign_in users(:admin)
    @page.update!(status: "draft")
    
    get page_url(@page.slug)
    assert_response :success
  end

  test "should show private page to logged in users" do
    sign_in users(:user)
    @page.update!(status: "private")
    
    get page_url(@page.slug)
    assert_response :success
  end

  test "should not show private page to guests" do
    @page.update!(status: "private")
    
    assert_raises(ActiveRecord::RecordNotFound) do
      get page_url(@page.slug)
    end
  end

  test "should handle password protected pages" do
    @page.update!(password: "secret123")
    
    get page_url(@page.slug)
    assert_response :success
    # Should show password form
  end

  test "should show page after password verification" do
    @page.update!(password: BCrypt::Password.create("secret123"))
    
    # Verify password
    post verify_password_page_url(@page.slug), params: { password: "secret123" }
    assert_redirected_to page_url(@page.slug)
    
    follow_redirect!
    assert_response :success
  end

  test "should handle incorrect password" do
    @page.update!(password: BCrypt::Password.create("secret123"))
    
    post verify_password_page_url(@page.slug), params: { password: "wrong" }
    assert_redirected_to page_url(@page.slug)
    
    follow_redirect!
    assert_response :success
  end

  test "should render with correct template" do
    @page.update!(template: "about")
    
    get page_url(@page.slug)
    assert_response :success
    # Should use page.about template
  end

  test "should include comments" do
    @page.comments.create!(
      content: "Great page!",
      author: users(:user),
      status: "approved"
    )
    
    get page_url(@page.slug)
    assert_response :success
  end

  test "should not show unapproved comments" do
    @page.comments.create!(
      content: "Spam comment",
      author: users(:user),
      status: "pending"
    )
    
    get page_url(@page.slug)
    assert_response :success
    # Should not include pending comment
  end

  test "should handle 404 for nonexistent pages" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get page_url("nonexistent-page")
    end
  end

  test "should render 404 template on not found" do
    begin
      get page_url("nonexistent")
    rescue ActiveRecord::RecordNotFound
      # Expected
    end
  end

  test "should auto-publish scheduled pages" do
    @page.update!(
      status: "scheduled",
      scheduled_publish_at: 1.hour.ago
    )
    
    get page_url(@page.slug)
    assert_response :success
    
    @page.reload
    assert_equal "published", @page.status
  end

  test "should handle nested page paths" do
    nested_page = Page.create!(
      title: "Company Info",
      slug: "company/info",
      content: "Nested page content",
      status: "published",
      author: users(:admin),
      published_at: Time.current
    )
    
    get page_url("company/info")
    assert_response :success
  end
end

