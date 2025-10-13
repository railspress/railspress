require "application_system_test_case"

class AdminDashboardTest < ApplicationSystemTestCase
  setup do
    @user = users(:admin)
    sign_in @user
  end

  test "visiting the dashboard" do
    visit admin_dashboard_url
    
    assert_selector "h1", text: "Dashboard"
    assert_selector ".dashboard-stats"
    assert_selector ".recent-posts"
    assert_selector ".recent-comments"
  end

  test "dashboard shows correct statistics" do
    # Create test data
    Post.create!(title: "Test Post", content: "Content", author: @user, status: "published")
    Comment.create!(content: "Test comment", status: "approved")
    User.create!(email: "test@example.com", password: "password123", password_confirmation: "password123")
    
    visit admin_dashboard_url
    
    assert_selector ".stat-card", text: "1" # Posts
    assert_selector ".stat-card", text: "1" # Comments
    assert_selector ".stat-card", text: "2" # Users (including admin)
  end

  test "dashboard shows recent posts" do
    post = Post.create!(
      title: "Recent Post",
      content: "Recent content",
      author: @user,
      status: "published",
      created_at: 1.hour.ago
    )
    
    visit admin_dashboard_url
    
    assert_selector ".recent-posts"
    assert_selector ".post-item", text: post.title
  end

  test "dashboard shows recent comments" do
    post = Post.create!(title: "Test Post", content: "Content", author: @user, status: "published")
    comment = Comment.create!(
      content: "Recent comment",
      post: post,
      author: @user,
      status: "approved",
      created_at: 1.hour.ago
    )
    
    visit admin_dashboard_url
    
    assert_selector ".recent-comments"
    assert_selector ".comment-item", text: comment.content
  end

  test "dashboard navigation works" do
    visit admin_dashboard_url
    
    # Test sidebar navigation
    click_on "Posts"
    assert_current_path admin_posts_url
    
    click_on "Dashboard"
    assert_current_path admin_dashboard_url
    
    click_on "Users"
    assert_current_path admin_users_url
  end

  test "dashboard responsive design" do
    visit admin_dashboard_url
    
    # Test mobile view
    page.driver.browser.manage.window.resize_to(375, 667)
    
    assert_selector ".mobile-menu-button"
    assert_selector ".sidebar", visible: false
    
    # Open mobile menu
    click_on "Menu"
    assert_selector ".sidebar", visible: true
    
    # Close mobile menu
    click_on "Close"
    assert_selector ".sidebar", visible: false
  end

  test "dashboard command palette" do
    visit admin_dashboard_url
    
    # Open command palette with CMD+K
    page.driver.browser.action.send_keys(:command, :k).perform
    
    assert_selector ".command-palette", visible: true
    assert_selector ".command-palette input[placeholder='Search commands...']"
    
    # Type search query
    fill_in "Search commands...", with: "post"
    
    assert_selector ".command-item", text: "Create New Post"
    
    # Select command
    click_on "Create New Post"
    assert_current_path new_admin_post_url
  end

  test "dashboard quick actions" do
    visit admin_dashboard_url
    
    # Test quick action buttons
    click_on "New Post"
    assert_current_path new_admin_post_url
    
    visit admin_dashboard_url
    click_on "New Page"
    assert_current_path new_admin_page_url
    
    visit admin_dashboard_url
    click_on "New User"
    assert_current_path new_admin_user_url
  end

  test "dashboard real-time updates" do
    visit admin_dashboard_url
    
    # Create new post via AJAX
    page.execute_script("
      fetch('/admin/posts', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name=\"csrf-token\"]').content
        },
        body: JSON.stringify({
          post: {
            title: 'AJAX Post',
            content: 'AJAX content',
            status: 'published'
          }
        })
      });
    ")
    
    # Wait for update
    assert_selector ".recent-posts .post-item", text: "AJAX Post", wait: 5
  end

  test "dashboard error handling" do
    # Mock API failure
    ApplicationController.any_instance.stubs(:dashboard_stats).raises(StandardError.new("API Error"))
    
    visit admin_dashboard_url
    
    assert_selector ".error-message", text: "Unable to load dashboard statistics"
    assert_selector ".retry-button"
    
    # Retry
    ApplicationController.any_instance.unstub(:dashboard_stats)
    click_on "Retry"
    
    assert_selector ".dashboard-stats"
  end

  test "dashboard accessibility" do
    visit admin_dashboard_url
    
    # Test keyboard navigation
    page.driver.browser.action.send_keys(:tab).perform
    assert_selector ":focus", visible: true
    
    # Test ARIA labels
    assert_selector "[aria-label='Dashboard statistics']"
    assert_selector "[aria-label='Recent posts']"
    assert_selector "[aria-label='Recent comments']"
    
    # Test screen reader content
    assert_selector "[role='main']"
    assert_selector "[role='navigation']"
  end

  test "dashboard performance metrics" do
    visit admin_dashboard_url
    
    # Check for performance indicators
    assert_selector ".performance-metrics"
    assert_selector ".load-time"
    assert_selector ".memory-usage"
    
    # Test performance monitoring
    page.execute_script("
      window.performance.mark('dashboard-load-end');
      const loadTime = window.performance.now();
      document.querySelector('.load-time').textContent = loadTime + 'ms';
    ")
    
    assert_selector ".load-time", text: /\d+ms/
  end

  test "dashboard theme switching" do
    visit admin_dashboard_url
    
    # Test dark mode toggle
    click_on "Dark Mode"
    
    assert_selector "body.dark-theme"
    assert_selector ".theme-toggle .dark-icon"
    
    # Test light mode toggle
    click_on "Light Mode"
    
    assert_selector "body.light-theme"
    assert_selector ".theme-toggle .light-icon"
  end

  test "dashboard notifications" do
    visit admin_dashboard_url
    
    # Create notification
    page.execute_script("
      window.notifications.show('Test notification', 'info');
    ")
    
    assert_selector ".notification", text: "Test notification"
    
    # Dismiss notification
    click_on "Dismiss"
    assert_no_selector ".notification"
  end

  test "dashboard search functionality" do
    visit admin_dashboard_url
    
    # Test global search
    fill_in "Global search", with: "test"
    
    assert_selector ".search-results"
    assert_selector ".search-result-item"
    
    # Select result
    click_on "Test Post"
    assert_current_path admin_post_url(Post.find_by(title: "Test Post"))
  end

  test "dashboard user profile dropdown" do
    visit admin_dashboard_url
    
    # Open user dropdown
    click_on @user.full_name
    
    assert_selector ".user-dropdown", visible: true
    assert_selector ".dropdown-item", text: "Profile"
    assert_selector ".dropdown-item", text: "Settings"
    assert_selector ".dropdown-item", text: "Logout"
    
    # Close dropdown
    click_on "Profile"
    assert_current_path admin_user_url(@user)
  end

  test "dashboard breadcrumb navigation" do
    visit admin_dashboard_url
    
    assert_selector ".breadcrumb", text: "Dashboard"
    
    click_on "Posts"
    assert_selector ".breadcrumb", text: "Dashboard > Posts"
    
    click_on "New Post"
    assert_selector ".breadcrumb", text: "Dashboard > Posts > New Post"
  end

  test "dashboard keyboard shortcuts" do
    visit admin_dashboard_url
    
    # Test keyboard shortcuts
    page.driver.browser.action.send_keys(:command, :k).perform
    assert_selector ".command-palette", visible: true
    
    page.driver.browser.action.send_keys(:escape).perform
    assert_no_selector ".command-palette"
    
    # Test navigation shortcuts
    page.driver.browser.action.send_keys(:command, :digit1).perform
    assert_current_path admin_posts_url
    
    page.driver.browser.action.send_keys(:command, :digit0).perform
    assert_current_path admin_dashboard_url
  end

  test "dashboard data export" do
    visit admin_dashboard_url
    
    # Test export functionality
    click_on "Export Data"
    
    assert_selector ".export-modal", visible: true
    assert_selector ".export-option", text: "Posts"
    assert_selector ".export-option", text: "Comments"
    assert_selector ".export-option", text: "Users"
    
    # Select export options
    check "Posts"
    check "Comments"
    
    click_on "Export"
    
    # Verify download started
    assert_selector ".export-success", text: "Export started"
  end

  test "dashboard backup and restore" do
    visit admin_dashboard_url
    
    # Test backup functionality
    click_on "Backup"
    
    assert_selector ".backup-modal", visible: true
    assert_selector ".backup-option", text: "Full Backup"
    assert_selector ".backup-option", text: "Database Only"
    assert_selector ".backup-option", text: "Files Only"
    
    # Create backup
    choose "Full Backup"
    click_on "Create Backup"
    
    assert_selector ".backup-success", text: "Backup created successfully"
  end

  test "dashboard system status" do
    visit admin_dashboard_url
    
    # Check system status indicators
    assert_selector ".system-status"
    assert_selector ".status-indicator.online", text: "Database"
    assert_selector ".status-indicator.online", text: "Redis"
    assert_selector ".status-indicator.online", text: "Storage"
    
    # Test status updates
    page.execute_script("
      document.querySelector('.status-indicator.online').classList.remove('online');
      document.querySelector('.status-indicator.online').classList.add('offline');
    ")
    
    assert_selector ".status-indicator.offline"
  end
end



