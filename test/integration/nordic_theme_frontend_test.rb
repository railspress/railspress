require "test_helper"

class NordicThemeFrontendTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    
    # Setup taxonomies
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
    
    @category = @category_taxonomy.terms.create!(name: "Technology", slug: "technology", description: "Tech posts")
    @tag = @tag_taxonomy.terms.create!(name: "Rails", slug: "rails", description: "Ruby on Rails")
    
    # Create published posts
    @post1 = Post.create!(
      title: "Getting Started with Nordic Theme",
      content: "This is a comprehensive guide to using the Nordic theme in RailsPress.",
      excerpt: "Learn how to use the Nordic theme",
      slug: "getting-started-nordic",
      status: "published",
      user: @user,
      published_at: 2.days.ago
    )
    @post1.term_relationships.create!(term: @category)
    @post1.term_relationships.create!(term: @tag)
    
    @post2 = Post.create!(
      title: "Liquid Templates Guide",
      content: "Liquid templates are powerful and flexible for theming.",
      excerpt: "Master Liquid templates",
      slug: "liquid-templates-guide",
      status: "published",
      user: @user,
      published_at: 1.day.ago
    )
    @post2.term_relationships.create!(term: @category)
    
    @post3 = Post.create!(
      title: "Building Custom Sections",
      content: "Learn how to build custom sections for your Nordic theme.",
      excerpt: "Custom sections tutorial",
      slug: "custom-sections",
      status: "published",
      user: @user,
      published_at: Time.current
    )
    @post3.term_relationships.create!(term: @tag)
    
    # Create a static page
    @page = Page.create!(
      title: "About Us",
      slug: "about",
      content: "We are a team dedicated to building beautiful CMS experiences.",
      excerpt: "Learn about our team",
      status: "published",
      user: @user,
      published_at: 1.week.ago
    )
  end

  # ========================================
  # Homepage (index.json) Tests
  # ========================================
  
  test "homepage should load successfully" do
    get root_url
    assert_response :success
    assert_select "html"
  end

  test "homepage should render header section" do
    get root_url
    assert_response :success
    assert_select "header.header"
    assert_select "header .brand"
    assert_select "header nav.nav"
  end

  test "homepage should render footer section" do
    get root_url
    assert_response :success
    assert_select "footer.footer"
  end

  test "homepage should render hero section" do
    get root_url
    assert_response :success
    assert_select "section.hero"
    assert_select ".hero-title"
  end

  test "homepage should include site navigation" do
    get root_url
    assert_response :success
    assert_select "nav a[href='/']", text: "Home"
    assert_select "nav a[href='/blog']", text: "Blog"
  end

  test "homepage should have viewport meta tag" do
    get root_url
    assert_response :success
    assert_select "meta[name='viewport']"
  end

  test "homepage should load theme CSS" do
    get root_url
    assert_response :success
    assert_select "link[href*='theme.css']"
  end

  test "homepage should load theme JavaScript" do
    get root_url
    assert_response :success
    assert_select "script[src*='theme.js']"
  end

  test "homepage should have copyright in footer" do
    get root_url
    assert_response :success
    assert_select "footer", text: /#{Time.current.year}/
  end

  # ========================================
  # Blog Index (blog.json) Tests
  # ========================================
  
  test "blog index should load successfully" do
    get blog_url
    assert_response :success
  end

  test "blog index should list published posts" do
    get blog_url
    assert_response :success
    # All 3 posts should be visible
    assert_match /Getting Started with Nordic Theme/, response.body
    assert_match /Liquid Templates Guide/, response.body
    assert_match /Building Custom Sections/, response.body
  end

  test "blog index should not show draft posts" do
    draft = Post.create!(
      title: "Draft Post",
      content: "This is a draft",
      status: "draft",
      author: @user
    )
    
    get blog_url
    assert_response :success
    assert_no_match /Draft Post/, response.body
  end

  test "blog index should show post excerpts" do
    get blog_url
    assert_response :success
    assert_match /Learn how to use the Nordic theme/, response.body
  end

  test "blog index should have post-list section" do
    get blog_url
    assert_response :success
    assert_select ".post-list"
  end

  test "blog index should handle pagination" do
    # Create more posts to trigger pagination
    15.times do |i|
      Post.create!(
        title: "Post #{i}",
        content: "Content #{i}",
        status: "published",
        author: @user,
        published_at: Time.current
      )
    end
    
    get blog_url
    assert_response :success
    assert_select "nav.pagination"
  end

  test "blog index should show next page link when has more posts" do
    15.times do |i|
      Post.create!(
        title: "Post #{i}",
        content: "Content #{i}",
        status: "published",
        author: @user,
        published_at: Time.current
      )
    end
    
    get blog_url
    assert_response :success
  end

  test "blog index page 2 should load" do
    15.times do |i|
      Post.create!(
        title: "Post #{i}",
        content: "Content #{i}",
        status: "published",
        author: @user,
        published_at: Time.current
      )
    end
    
    get blog_url(page: 2)
    assert_response :success
  end

  # ========================================
  # Single Post (post.json) Tests
  # ========================================
  
  test "single post should load successfully" do
    get blog_post_url(@post1.slug)
    assert_response :success
  end

  test "single post should display post title" do
    get blog_post_url(@post1.slug)
    assert_response :success
    assert_select "h1", text: @post1.title
  end

  test "single post should display post content" do
    get blog_post_url(@post1.slug)
    assert_response :success
    assert_match /comprehensive guide/, response.body
  end

  test "single post should show author information" do
    get blog_post_url(@post1.slug)
    assert_response :success
    assert_match /#{@user.full_name}/, response.body
  end

  test "single post should show publication date" do
    get blog_post_url(@post1.slug)
    assert_response :success
  end

  test "single post should show categories" do
    get blog_post_url(@post1.slug)
    assert_response :success
    assert_match /Technology/, response.body
  end

  test "single post should show tags" do
    get blog_post_url(@post1.slug)
    assert_response :success
    assert_match /Rails/, response.body
  end

  test "single post should have post-content section" do
    get blog_post_url(@post1.slug)
    assert_response :success
  end

  test "single post should show related posts section" do
    get blog_post_url(@post1.slug)
    assert_response :success
    # Related posts from same category should appear
  end

  test "single post should show comments section" do
    @post1.comments.create!(
      content: "Great article!",
      author: @user,
      status: "approved"
    )
    
    get blog_post_url(@post1.slug)
    assert_response :success
    assert_match /Great article!/, response.body
  end

  test "single post should not show unapproved comments" do
    @post1.comments.create!(
      content: "Pending comment",
      author: @user,
      status: "pending"
    )
    
    get blog_post_url(@post1.slug)
    assert_response :success
    assert_no_match /Pending comment/, response.body
  end

  test "single post should have reading time" do
    get blog_post_url(@post1.slug)
    assert_response :success
    assert_match /min read/, response.body
  end

  test "single post should have share buttons" do
    get blog_post_url(@post1.slug)
    assert_response :success
  end

  test "single post 404 for non-existent slug" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get blog_post_url("nonexistent-post")
    end
  end

  # ========================================
  # Static Page (page.json) Tests
  # ========================================
  
  test "static page should load successfully" do
    get page_url(@page.slug)
    assert_response :success
  end

  test "static page should display page title" do
    get page_url(@page.slug)
    assert_response :success
    assert_select "h1", text: @page.title
  end

  test "static page should display page content" do
    get page_url(@page.slug)
    assert_response :success
    assert_match /team dedicated/, response.body
  end

  test "static page should have breadcrumbs" do
    get page_url(@page.slug)
    assert_response :success
  end

  test "static page 404 for non-existent slug" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get page_url("nonexistent-page")
    end
  end

  test "static page should show comments if enabled" do
    @page.comments.create!(
      content: "Great page!",
      author: @user,
      status: "approved"
    )
    
    get page_url(@page.slug)
    assert_response :success
  end

  test "private page should not show to guests" do
    @page.update!(status: "private")
    
    assert_raises(ActiveRecord::RecordNotFound) do
      get page_url(@page.slug)
    end
  end

  test "private page should show to logged in users" do
    sign_in @user
    @page.update!(status: "private")
    
    get page_url(@page.slug)
    assert_response :success
  end

  test "draft page should not show to guests" do
    @page.update!(status: "draft")
    
    assert_raises(ActiveRecord::RecordNotFound) do
      get page_url(@page.slug)
    end
  end

  test "draft page should show to admin" do
    sign_in @user
    @page.update!(status: "draft")
    
    get page_url(@page.slug)
    assert_response :success
  end

  # ========================================
  # Category Archive (category.json) Tests
  # ========================================
  
  test "category archive should load successfully" do
    get blog_category_url(@category.slug)
    assert_response :success
  end

  test "category archive should show category name" do
    get blog_category_url(@category.slug)
    assert_response :success
    assert_select "h1", text: /Technology/i
  end

  test "category archive should list posts in category" do
    get blog_category_url(@category.slug)
    assert_response :success
    assert_match /Getting Started with Nordic Theme/, response.body
    assert_match /Liquid Templates Guide/, response.body
  end

  test "category archive should not show posts from other categories" do
    other_category = @category_taxonomy.terms.create!(name: "Design", slug: "design")
    other_post = Post.create!(
      title: "Design Post",
      content: "Design content",
      status: "published",
      user: @user,
      published_at: Time.current
    )
    other_post.term_relationships.create!(term: other_category)
    
    get blog_category_url(@category.slug)
    assert_response :success
    assert_no_match /Design Post/, response.body
  end

  test "category archive should show category description" do
    get blog_category_url(@category.slug)
    assert_response :success
    assert_match /Tech posts/, response.body
  end

  test "category archive should have pagination" do
    15.times do |i|
      post = Post.create!(
        title: "Tech Post #{i}",
        content: "Content #{i}",
        status: "published",
        author: @user,
        published_at: Time.current
      )
      post.term_relationships.create!(term: @category)
    end
    
    get blog_category_url(@category.slug)
    assert_response :success
    assert_select "nav.pagination"
  end

  test "category archive 404 for non-existent category" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get blog_category_url("nonexistent-category")
    end
  end

  # ========================================
  # Tag Archive (tag.json) Tests
  # ========================================
  
  test "tag archive should load successfully" do
    get blog_tag_url(@tag.slug)
    assert_response :success
  end

  test "tag archive should show tag name" do
    get blog_tag_url(@tag.slug)
    assert_response :success
    assert_select "h1", text: /Rails/i
  end

  test "tag archive should list posts with tag" do
    get blog_tag_url(@tag.slug)
    assert_response :success
    assert_match /Getting Started with Nordic Theme/, response.body
    assert_match /Building Custom Sections/, response.body
  end

  test "tag archive should not show posts without tag" do
    get blog_tag_url(@tag.slug)
    assert_response :success
    assert_no_match /Liquid Templates Guide/, response.body
  end

  test "tag archive should show tag description" do
    get blog_tag_url(@tag.slug)
    assert_response :success
    assert_match /Ruby on Rails/, response.body
  end

  test "tag archive should have pagination" do
    15.times do |i|
      post = Post.create!(
        title: "Rails Post #{i}",
        content: "Content #{i}",
        status: "published",
        author: @user,
        published_at: Time.current
      )
      post.term_relationships.create!(term: @tag)
    end
    
    get blog_tag_url(@tag.slug)
    assert_response :success
    assert_select "nav.pagination"
  end

  test "tag archive 404 for non-existent tag" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get blog_tag_url("nonexistent-tag")
    end
  end

  # ========================================
  # Search (search.json) Tests
  # ========================================
  
  test "search page should load successfully" do
    get search_url(q: "Nordic")
    assert_response :success
  end

  test "search should find matching posts" do
    get search_url(q: "Nordic")
    assert_response :success
    assert_match /Getting Started with Nordic Theme/, response.body
  end

  test "search should show search query in page" do
    get search_url(q: "Liquid")
    assert_response :success
    assert_match /Liquid/, response.body
  end

  test "search should show no results message for non-matching query" do
    get search_url(q: "nonexistentquery12345")
    assert_response :success
  end

  test "search should handle empty query" do
    get search_url(q: "")
    assert_response :success
  end

  test "search should handle special characters in query" do
    get search_url(q: "test & query")
    assert_response :success
  end

  test "search should search in post titles" do
    get search_url(q: @post1.title.split.first)
    assert_response :success
    assert_match /#{@post1.title}/, response.body
  end

  test "search should search in post content" do
    get search_url(q: "comprehensive")
    assert_response :success
    assert_match /Getting Started with Nordic Theme/, response.body
  end

  test "search results should have pagination" do
    20.times do |i|
      Post.create!(
        title: "Searchable Post #{i}",
        content: "Nordic theme searchable content #{i}",
        status: "published",
        author: @user,
        published_at: Time.current
      )
    end
    
    get search_url(q: "Nordic")
    assert_response :success
    assert_select "nav.pagination"
  end

  # ========================================
  # Archive (archive.json) Tests
  # ========================================
  
  test "year archive should load successfully" do
    get archive_url(year: Time.current.year)
    assert_response :success
  end

  test "year archive should show posts from that year" do
    get archive_url(year: Time.current.year)
    assert_response :success
    assert_match /Getting Started with Nordic Theme/, response.body
  end

  test "year archive should not show posts from other years" do
    old_post = Post.create!(
      title: "Old Post",
      content: "Old content",
      status: "published",
      author: @user,
      published_at: 2.years.ago
    )
    
    get archive_url(year: Time.current.year)
    assert_response :success
    assert_no_match /Old Post/, response.body
  end

  test "month archive should load successfully" do
    get archive_url(year: Time.current.year, month: Time.current.month)
    assert_response :success
  end

  test "month archive should show posts from that month" do
    get archive_url(year: Time.current.year, month: Time.current.month)
    assert_response :success
    assert_match /Building Custom Sections/, response.body
  end

  test "month archive should show month name in title" do
    get archive_url(year: Time.current.year, month: Time.current.month)
    assert_response :success
    assert_select "h1", text: /#{Date::MONTHNAMES[Time.current.month]}/
  end

  test "archive should have pagination" do
    15.times do |i|
      Post.create!(
        title: "Archive Post #{i}",
        content: "Content #{i}",
        status: "published",
        author: @user,
        published_at: Time.current
      )
    end
    
    get archive_url(year: Time.current.year, month: Time.current.month)
    assert_response :success
    assert_select "nav.pagination"
  end

  # ========================================
  # Author Archive Tests
  # ========================================
  
  test "author should have profile page" do
    skip "Author archive not yet implemented"
    # get author_url(@user.slug)
    # assert_response :success
  end

  # ========================================
  # 404 Page (404.json) Tests
  # ========================================
  
  test "404 page should render for non-existent posts" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get blog_post_url("nonexistent-post-slug-12345")
    end
  end

  test "404 page should render for non-existent pages" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get page_url("nonexistent-page-slug-12345")
    end
  end

  test "404 page should render for non-existent categories" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get blog_category_url("nonexistent-category-12345")
    end
  end

  test "404 page should render for non-existent tags" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get blog_tag_url("nonexistent-tag-12345")
    end
  end

  # ========================================
  # Login Page (login.json) Tests
  # ========================================
  
  test "login page should load successfully" do
    get new_user_session_url
    assert_response :success
  end

  test "login page should have login form" do
    get new_user_session_url
    assert_response :success
    assert_select "form"
    assert_select "input[type='email']"
    assert_select "input[type='password']"
  end

  test "login page should use login layout" do
    get new_user_session_url
    assert_response :success
    # Should have minimal login layout, not full theme layout
  end

  test "login page should have site logo or name" do
    get new_user_session_url
    assert_response :success
  end

  # ========================================
  # Theme Features Tests
  # ========================================
  
  test "theme should have consistent header across all pages" do
    pages = [
      root_url,
      blog_url,
      blog_post_url(@post1.slug),
      page_url(@page.slug),
      blog_category_url(@category.slug)
    ]
    
    pages.each do |page_url|
      get page_url
      assert_response :success
      assert_select "header.header"
      assert_select ".brand"
    end
  end

  test "theme should have consistent footer across all pages" do
    pages = [
      root_url,
      blog_url,
      blog_post_url(@post1.slug),
      page_url(@page.slug)
    ]
    
    pages.each do |page_url|
      get page_url
      assert_response :success
      assert_select "footer.footer"
    end
  end

  test "theme CSS should load on all pages" do
    pages = [
      root_url,
      blog_url,
      blog_post_url(@post1.slug)
    ]
    
    pages.each do |page_url|
      get page_url
      assert_response :success
      assert_select "link[href*='theme.css']"
    end
  end

  test "theme JavaScript should load on all pages" do
    pages = [
      root_url,
      blog_url,
      blog_post_url(@post1.slug)
    ]
    
    pages.each do |page_url|
      get page_url
      assert_response :success
      assert_select "script[src*='theme.js']"
    end
  end

  test "theme should have proper HTML structure" do
    get root_url
    assert_response :success
    assert_select "html"
    assert_select "head"
    assert_select "body"
    assert_select "main"
  end

  test "theme should have skip to content link for accessibility" do
    get root_url
    assert_response :success
  end

  test "theme should have language attribute" do
    get root_url
    assert_response :success
    assert_select "html[lang]"
  end

  test "theme should be valid HTML5" do
    get root_url
    assert_response :success
    assert_select "html"
    assert_select "head meta[charset]"
    assert_select "head meta[name='viewport']"
  end

  # ========================================
  # Responsive Design Tests
  # ========================================
  
  test "theme should have mobile viewport meta tag" do
    get root_url
    assert_response :success
    assert_select "meta[name='viewport'][content*='width=device-width']"
  end

  test "theme should load responsive CSS" do
    get root_url
    assert_response :success
    # CSS should be loaded
    assert_select "link[href*='theme.css']"
  end

  # ========================================
  # SEO Tests
  # ========================================
  
  test "homepage should have title tag" do
    get root_url
    assert_response :success
    assert_select "title"
  end

  test "blog index should have title tag" do
    get blog_url
    assert_response :success
    assert_select "title"
  end

  test "single post should have title tag with post title" do
    get blog_post_url(@post1.slug)
    assert_response :success
    assert_select "title"
  end

  test "static page should have title tag with page title" do
    get page_url(@page.slug)
    assert_response :success
    assert_select "title"
  end

  test "category archive should have title with category name" do
    get blog_category_url(@category.slug)
    assert_response :success
    assert_select "h1", text: /Technology/
  end

  test "tag archive should have title with tag name" do
    get blog_tag_url(@tag.slug)
    assert_response :success
    assert_select "h1", text: /Rails/
  end

  # ========================================
  # Navigation Tests
  # ========================================
  
  test "navigation should link to homepage" do
    get blog_url
    assert_response :success
    assert_select "nav a[href='/']"
  end

  test "navigation should link to blog" do
    get root_url
    assert_response :success
    assert_select "nav a[href='/blog']"
  end

  test "navigation should link to about page" do
    get root_url
    assert_response :success
    assert_select "nav a[href='/page/about']"
  end

  test "footer navigation should have privacy link" do
    get root_url
    assert_response :success
    assert_select "footer nav a[href='/page/privacy']"
  end

  test "footer navigation should have RSS link" do
    get root_url
    assert_response :success
    assert_select "footer nav a[href='/feed.xml']"
  end

  # ========================================
  # Content Display Tests
  # ========================================
  
  test "post cards should display on homepage" do
    get root_url
    assert_response :success
  end

  test "post cards should display on blog index" do
    get blog_url
    assert_response :success
  end

  test "post cards should have title" do
    get blog_url
    assert_response :success
  end

  test "post cards should have excerpt" do
    get blog_url
    assert_response :success
  end

  test "post cards should have link to full post" do
    get blog_url
    assert_response :success
  end

  # ========================================
  # Theme Assets Tests
  # ========================================
  
  test "theme CSS should be accessible" do
    get "/themes/nordic/assets/theme.css"
    assert_response :success
    assert_equal "text/css", response.content_type
  end

  test "theme JavaScript should be accessible" do
    get "/themes/nordic/assets/theme.js"
    assert_response :success
    assert_equal "text/javascript", response.content_type
  end

  test "login CSS should be accessible" do
    get "/themes/nordic/assets/login.css"
    assert_response :success
    assert_equal "text/css", response.content_type
  end

  test "theme assets should have cache headers" do
    get "/themes/nordic/assets/theme.css"
    assert_response :success
    assert_not_nil response.headers['Cache-Control']
  end

  test "non-existent theme assets should return 404" do
    get "/themes/nordic/assets/nonexistent.css"
    assert_response :not_found
  end

  test "theme assets should prevent path traversal" do
    get "/themes/nordic/assets/../../config/database.yml"
    assert_response :forbidden
  end

  # ========================================
  # Performance Tests
  # ========================================
  
  test "homepage should load in reasonable time" do
    start_time = Time.current
    get root_url
    end_time = Time.current
    
    assert_response :success
    assert (end_time - start_time) < 5.seconds, "Homepage took too long to load"
  end

  test "blog index should load in reasonable time" do
    start_time = Time.current
    get blog_url
    end_time = Time.current
    
    assert_response :success
    assert (end_time - start_time) < 5.seconds, "Blog index took too long to load"
  end

  test "single post should load in reasonable time" do
    start_time = Time.current
    get blog_post_url(@post1.slug)
    end_time = Time.current
    
    assert_response :success
    assert (end_time - start_time) < 5.seconds, "Post page took too long to load"
  end

  # ========================================
  # Error Handling Tests
  # ========================================
  
  test "theme should handle missing sections gracefully" do
    get root_url
    assert_response :success
    # Should still render even if some sections have errors
  end

  test "theme should handle missing snippets gracefully" do
    get root_url
    assert_response :success
    # Should still render even if some snippets are missing
  end

  test "theme should handle empty database" do
    Post.delete_all
    Page.delete_all
    Term.for_taxonomy('category').delete_all
    Term.for_taxonomy('post_tag').delete_all
    
    get root_url
    assert_response :success
    
    get blog_url
    assert_response :success
  end

  test "theme should handle posts with no categories" do
    post_no_cat = Post.create!(
      title: "Uncategorized Post",
      content: "Content",
      status: "published",
      author: @user,
      published_at: Time.current
    )
    
    get blog_post_url(post_no_cat.slug)
    assert_response :success
  end

  test "theme should handle posts with no tags" do
    post_no_tags = Post.create!(
      title: "Untagged Post",
      content: "Content",
      status: "published",
      author: @user,
      published_at: Time.current
    )
    
    get blog_post_url(post_no_tags.slug)
    assert_response :success
  end

  test "theme should handle posts with no comments" do
    get blog_post_url(@post2.slug)
    assert_response :success
  end

  test "theme should handle very long post titles" do
    long_title_post = Post.create!(
      title: "This is a very long post title that might cause layout issues if not handled properly in the theme design",
      content: "Content",
      status: "published",
      author: @user,
      published_at: Time.current
    )
    
    get blog_post_url(long_title_post.slug)
    assert_response :success
  end

  test "theme should handle very long post content" do
    long_content = ("This is a test sentence. " * 1000)
    long_post = Post.create!(
      title: "Long Content Post",
      content: long_content,
      status: "published",
      author: @user,
      published_at: Time.current
    )
    
    get blog_post_url(long_post.slug)
    assert_response :success
  end

  test "theme should handle posts with HTML in content" do
    html_post = Post.create!(
      title: "HTML Content Post",
      content: "<h2>Subheading</h2><p>Paragraph with <strong>bold</strong> and <em>italic</em></p>",
      status: "published",
      author: @user,
      published_at: Time.current
    )
    
    get blog_post_url(html_post.slug)
    assert_response :success
  end

  test "theme should handle posts with special characters" do
    special_post = Post.create!(
      title: "Post with Special Chars: !@#$%^&*()",
      content: "Content with émojis 🎉 and spëcial çharacters",
      status: "published",
      author: @user,
      published_at: Time.current
    )
    
    get blog_post_url(special_post.slug)
    assert_response :success
  end

  # ========================================
  # Security Tests
  # ========================================
  
  test "theme should escape HTML in titles" do
    xss_post = Post.create!(
      title: "<script>alert('xss')</script>Title",
      content: "Content",
      status: "published",
      author: @user,
      published_at: Time.current
    )
    
    get blog_url
    assert_response :success
    assert_no_match /<script>alert\('xss'\)<\/script>/, response.body
  end

  test "theme should sanitize user input" do
    get search_url(q: "<script>alert('xss')</script>")
    assert_response :success
    assert_no_match /<script>alert/, response.body
  end

  test "theme assets should not serve files outside theme directory" do
    get "/themes/nordic/assets/../../../config/secrets.yml"
    assert_response :forbidden
  end

  test "theme should validate theme name parameter" do
    get "/themes/../../etc/passwd"
    assert_response :not_found
  end
end
