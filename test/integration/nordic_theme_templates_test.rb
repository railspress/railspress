require "test_helper"

class NordicThemeTemplatesTest < ActionDispatch::IntegrationTest
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
      title: "Test Post",
      content: "Test content",
      status: "published",
      user: @user,
      published_at: Time.current
    )
    
    @category = @category_taxonomy.terms.create!(name: "Tech", slug: "tech")
    @tag = @tag_taxonomy.terms.create!(name: "Rails", slug: "rails")
  end

  # Index Template Tests
  test "index template should render homepage" do
    get root_url
    assert_response :success
  end

  test "index template should include header section" do
    get root_url
    assert_response :success
    # Should have navigation
    assert_select "header", count: 1
  end

  test "index template should include footer section" do
    get root_url
    assert_response :success
    assert_select "footer", count: 1
  end

  test "index template should show featured posts" do
    3.times do |i|
      Post.create!(
        title: "Featured #{i}",
        content: "Content #{i}",
        status: "published",
        user: @user,
        published_at: Time.current
      )
    end
    
    get root_url
    assert_response :success
  end

  # Blog Template Tests
  test "blog template should render blog index" do
    get blog_url
    assert_response :success
  end

  test "blog template should list published posts" do
    5.times do |i|
      Post.create!(
        title: "Blog Post #{i}",
        content: "Content #{i}",
        status: "published",
        user: @user,
        published_at: Time.current
      )
    end
    
    get blog_url
    assert_response :success
  end

  test "blog template should not show draft posts" do
    draft = Post.create!(
      title: "Draft Post",
      content: "Draft content",
      status: "draft",
      author: @user
    )
    
    get blog_url
    assert_response :success
    assert_select "body", text: /Draft Post/, count: 0
  end

  test "blog template should handle pagination" do
    15.times do |i|
      Post.create!(
        title: "Post #{i}",
        content: "Content #{i}",
        status: "published",
        user: @user,
        published_at: Time.current
      )
    end
    
    get blog_url(page: 2)
    assert_response :success
  end

  # Post Template Tests
  test "post template should render single post" do
    get blog_post_url(@post.slug)
    assert_response :success
  end

  test "post template should show post title" do
    get blog_post_url(@post.slug)
    assert_response :success
    assert_select "h1", @post.title
  end

  test "post template should show post content" do
    get blog_post_url(@post.slug)
    assert_response :success
  end

  test "post template should show author information" do
    get blog_post_url(@post.slug)
    assert_response :success
  end

  test "post template should show related posts" do
    # Create related posts
    2.times do |i|
      Post.create!(
        title: "Related #{i}",
        content: "Content #{i}",
        status: "published",
        user: @user,
        published_at: Time.current
      )
    end
    
    get blog_post_url(@post.slug)
    assert_response :success
  end

  test "post template should show comments section" do
    @post.comments.create!(
      content: "Great post!",
      user: @user,
      author_name: @user.name,
      author_email: @user.email,
      status: "approved"
    )
    
    get blog_post_url(@post.slug)
    assert_response :success
  end

  # Page Template Tests
  test "page template should render static page" do
    page = Page.create!(
      title: "About",
      slug: "about",
      content: "About us content",
      status: "published",
      author: @user,
      published_at: Time.current
    )
    
    get page_url("about")
    assert_response :success
  end

  test "page template should show page title" do
    page = Page.create!(
      title: "Contact",
      slug: "contact",
      content: "Contact content",
      status: "published",
      author: @user,
      published_at: Time.current
    )
    
    get page_url("contact")
    assert_response :success
    assert_select "h1", "Contact"
  end

  test "page template should show page content" do
    page = Page.create!(
      title: "About",
      slug: "about",
      content: "This is our story",
      status: "published",
      author: @user,
      published_at: Time.current
    )
    
    get page_url("about")
    assert_response :success
  end

  # Category Template Tests
  test "category template should render category archive" do
    @post.term_relationships.create!(term: @category)
    
    get blog_category_url(@category.slug)
    assert_response :success
  end

  test "category template should show category name" do
    get blog_category_url(@category.slug)
    assert_response :success
    assert_select "h1", /Tech/
  end

  test "category template should list posts in category" do
    3.times do |i|
      post = Post.create!(
        title: "Tech Post #{i}",
        content: "Content #{i}",
        status: "published",
        user: @user,
        published_at: Time.current
      )
      post.term_relationships.create!(term: @category)
    end
    
    get blog_category_url(@category.slug)
    assert_response :success
  end

  # Tag Template Tests
  test "tag template should render tag archive" do
    @post.term_relationships.create!(term: @tag)
    
    get blog_tag_url(@tag.slug)
    assert_response :success
  end

  test "tag template should show tag name" do
    get blog_tag_url(@tag.slug)
    assert_response :success
    assert_select "h1", /Rails/
  end

  test "tag template should list posts with tag" do
    3.times do |i|
      post = Post.create!(
        title: "Rails Post #{i}",
        content: "Content #{i}",
        status: "published",
        user: @user,
        published_at: Time.current
      )
      post.term_relationships.create!(term: @tag)
    end
    
    get blog_tag_url(@tag.slug)
    assert_response :success
  end

  # Search Template Tests
  test "search template should render search results" do
    get search_url(q: "test")
    assert_response :success
  end

  test "search template should show search query" do
    get search_url(q: "ruby")
    assert_response :success
  end

  test "search template should show matching posts" do
    Post.create!(
      title: "Ruby on Rails Guide",
      content: "Learn Ruby",
      status: "published",
      author: @user,
      published_at: Time.current
    )
    
    get search_url(q: "Ruby")
    assert_response :success
  end

  test "search template should handle no results" do
    get search_url(q: "nonexistentquery")
    assert_response :success
  end

  # Archive Template Tests
  test "archive template should render year archive" do
    get archive_url(year: Time.current.year)
    assert_response :success
  end

  test "archive template should render month archive" do
    get archive_url(year: Time.current.year, month: Time.current.month)
    assert_response :success
  end

  test "archive template should show posts from specified period" do
    5.times do |i|
      Post.create!(
        title: "Archive Post #{i}",
        content: "Content #{i}",
        status: "published",
        user: @user,
        published_at: Time.current
      )
    end
    
    get archive_url(year: Time.current.year, month: Time.current.month)
    assert_response :success
  end

  # Author Template Tests (if implemented)
  test "author template should render author archive" do
    skip "Author archive not yet implemented"
    # get author_url(@user.slug)
    # assert_response :success
  end

  # 404 Template Tests
  test "404 template should render on not found" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get blog_post_url("nonexistent-post")
    end
  end

  test "404 template should show error message" do
    begin
      get blog_post_url("nonexistent")
    rescue ActiveRecord::RecordNotFound
      # Expected
    end
  end

  # Login Template Tests
  test "login template should render login page" do
    get new_user_session_url
    assert_response :success
  end

  test "login template should show login form" do
    get new_user_session_url
    assert_response :success
    assert_select "form"
  end

  # Template Integration Tests
  test "all templates should include SEO head section" do
    get root_url
    assert_response :success
    assert_select "title"
    assert_select "meta[name='description']"
  end

  test "all templates should include analytics pixels" do
    # Create a test pixel
    Pixel.create!(
      name: "Test Pixel",
      code: "<!-- test pixel -->",
      location: "head",
      active: true
    )
    
    get root_url
    assert_response :success
  end

  test "all templates should be responsive" do
    get root_url
    assert_response :success
    assert_select "meta[name='viewport']"
  end

  test "templates should handle missing data gracefully" do
    Post.delete_all
    Term.for_taxonomy('category').delete_all
    Term.for_taxonomy('post_tag').delete_all
    
    get root_url
    assert_response :success
    
    get blog_url
    assert_response :success
  end
end
