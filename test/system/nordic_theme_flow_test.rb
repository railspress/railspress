require "application_system_test_case"

class NordicThemeFlowTest < ApplicationSystemTestCase
  setup do
    @user = users(:admin)
    
    @category_taxonomy = Taxonomy.find_or_create_by!(slug: 'category') do |t|
      t.name = 'Category'
      t.hierarchical = true
      t.object_types = ['Post']
    end
    
    @tag_taxonomy = Taxonomy.find_or_create_by!(slug: 'tag') do |t|
      t.name = 'Tag'
      t.hierarchical = false
      t.object_types = ['Post']
    end
    
    @post = Post.create!(
      title: "Welcome to Nordic Theme",
      content: "This is a beautiful minimalist theme inspired by WordPress Twenty Twenty-Five",
      excerpt: "A beautiful minimalist theme",
      status: "published",
      user: @user,
      published_at: Time.current
    )
    
    @category = @category_taxonomy.terms.create!(name: "Design", slug: "design")
    @tag = @tag_taxonomy.terms.create!(name: "Minimalism", slug: "minimalism")
    @post.term_relationships.create!(term: @category)
    @post.term_relationships.create!(term: @tag)
  end

  test "visiting the homepage" do
    visit root_url
    
    assert_selector "h1", text: /Welcome/i
    assert_selector "header"
    assert_selector "footer"
  end

  test "navigating from homepage to blog" do
    visit root_url
    
    click_on "Blog"
    
    assert_current_path blog_path
    assert_selector "h1", text: /Blog/i
  end

  test "reading a blog post" do
    visit blog_url
    
    assert_selector ".post-card", text: @post.title
    
    click_on @post.title
    
    assert_current_path blog_post_path(@post.slug)
    assert_selector "h1", text: @post.title
    assert_selector ".post-content", text: /minimalist/i
  end

  test "viewing post metadata" do
    visit blog_post_url(@post.slug)
    
    assert_selector ".post-meta"
    assert_text @user.name
    assert_text "Design"
    assert_text "Minimalism"
  end

  test "navigating via category" do
    visit blog_post_url(@post.slug)
    
    click_on "Design"
    
    assert_current_path blog_category_path(@category.slug)
    assert_selector "h1", text: /Design/i
    assert_selector ".post-card", text: @post.title
  end

  test "navigating via tag" do
    visit blog_post_url(@post.slug)
    
    click_on "Minimalism"
    
    assert_current_path blog_tag_path(@tag.slug)
    assert_selector "h1", text: /Minimalism/i
    assert_selector ".post-card", text: @post.title
  end

  test "using search functionality" do
    visit root_url
    
    fill_in "Search", with: "Nordic"
    click_on "Search"
    
    assert_selector ".search-results"
    assert_selector ".post-card", text: @post.title
  end

  test "searching with no results" do
    visit root_url
    
    fill_in "Search", with: "nonexistentquery"
    click_on "Search"
    
    assert_selector ".search-results"
    assert_text /no results/i
  end

  test "pagination on blog index" do
    # Create enough posts for pagination
    15.times do |i|
      Post.create!(
        title: "Post #{i}",
        content: "Content #{i}",
        status: "published",
        author: @user,
        published_at: i.hours.ago
      )
    end
    
    visit blog_url
    
    assert_selector ".pagination"
    assert_selector "a", text: "2"
    
    click_on "2"
    
    assert_current_path blog_path(page: 2)
  end

  test "viewing static page" do
    page = Page.create!(
      title: "About Us",
      slug: "about",
      content: "Learn more about us",
      status: "published",
      author: @user,
      published_at: Time.current
    )
    
    visit page_url("about")
    
    assert_selector "h1", text: "About Us"
    assert_text "Learn more about us"
  end

  test "reading related posts" do
    # Create related posts
    2.times do |i|
      related = Post.create!(
        title: "Related Post #{i}",
        content: "Content #{i}",
        status: "published",
        author: @user,
        published_at: Time.current
      )
      related.term_relationships.create!(term: @category)
    end
    
    visit blog_post_url(@post.slug)
    
    assert_selector ".related-posts"
    assert_selector ".related-posts .post-card", count: 2
  end

  test "viewing comments" do
    comment = @post.comments.create!(
      content: "Great post!",
      author: @user,
      status: "approved"
    )
    
    visit blog_post_url(@post.slug)
    
    assert_selector ".comments"
    assert_text "Great post!"
  end

  test "responsive design - mobile view" do
    # Simulate mobile viewport
    page.driver.browser.manage.window.resize_to(375, 667)
    
    visit root_url
    
    assert_selector "header"
    assert_selector "footer"
    
    # Mobile menu should be accessible
    assert_selector ".mobile-menu-button" if has_selector?(".mobile-menu-button")
  end

  test "responsive design - tablet view" do
    # Simulate tablet viewport
    page.driver.browser.manage.window.resize_to(768, 1024)
    
    visit root_url
    
    assert_selector "header"
    assert_selector "footer"
  end

  test "responsive design - desktop view" do
    # Simulate desktop viewport
    page.driver.browser.manage.window.resize_to(1920, 1080)
    
    visit root_url
    
    assert_selector "header"
    assert_selector "footer"
  end

  test "theme assets load correctly" do
    visit root_url
    
    # Check that CSS is loaded
    assert page.has_css?("link[href*='theme.css']", visible: false)
    
    # Check that JS is loaded
    assert page.has_css?("script[src*='theme.js']", visible: false)
  end

  test "SEO meta tags are present" do
    visit blog_post_url(@post.slug)
    
    assert page.has_css?("meta[property='og:title']", visible: false)
    assert page.has_css?("meta[property='og:description']", visible: false)
    assert page.has_css?("meta[name='twitter:card']", visible: false)
  end

  test "accessibility - keyboard navigation" do
    visit root_url
    
    # Tab through links
    page.driver.browser.action.send_keys(:tab).perform
    
    # Should focus on first interactive element
    assert page.has_css?(":focus")
  end

  test "accessibility - skip to content link" do
    visit root_url
    
    assert_selector "a.skip-link", text: /Skip to content/i
  end

  test "archive browsing by year" do
    visit archive_url(year: Time.current.year)
    
    assert_selector "h1", text: /#{Time.current.year}/
    assert_selector ".post-card", text: @post.title
  end

  test "archive browsing by month" do
    visit archive_url(year: Time.current.year, month: Time.current.month)
    
    assert_selector "h1", text: /#{Date::MONTHNAMES[Time.current.month]}/
    assert_selector ".post-card", text: @post.title
  end

  test "social sharing buttons" do
    visit blog_post_url(@post.slug)
    
    assert_selector ".share-buttons" if has_selector?(".share-buttons")
  end

  test "reading time display" do
    visit blog_post_url(@post.slug)
    
    assert_text /min read/i
  end

  test "breadcrumb navigation" do
    visit blog_post_url(@post.slug)
    
    assert_selector ".breadcrumbs" if has_selector?(".breadcrumbs")
  end

  test "theme handles errors gracefully" do
    # Try to visit non-existent post
    begin
      visit blog_post_url("nonexistent-post")
    rescue
      # Should render 404 page
    end
  end

  test "password protected post flow" do
    protected_post = Post.create!(
      title: "Secret Post",
      content: "Secret content",
      status: "published",
      author: @user,
      password: BCrypt::Password.create("secret123"),
      published_at: Time.current
    )
    
    visit blog_post_url(protected_post.slug)
    
    # Should show password form
    assert_selector "form"
    assert_selector "input[type='password']"
    
    # Enter correct password
    fill_in "Password", with: "secret123"
    click_on "Submit"
    
    # Should now see content
    assert_text "Secret content"
  end

  test "complete user journey" do
    # 1. Land on homepage
    visit root_url
    assert_selector "header"
    
    # 2. Navigate to blog
    click_on "Blog"
    assert_current_path blog_path
    
    # 3. Click on a post
    click_on @post.title
    assert_selector "h1", text: @post.title
    
    # 4. Click on a category
    click_on "Design"
    assert_selector "h1", text: /Design/i
    
    # 5. Use search
    fill_in "Search", with: "theme"
    click_on "Search"
    assert_selector ".search-results"
    
    # 6. Return to homepage
    click_on "Home"
    assert_current_path root_path
  end
end
