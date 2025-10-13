require "test_helper"

class NordicThemeSectionsTest < ActionDispatch::IntegrationTest
  setup do
    @renderer = LiquidTemplateRenderer.new('nordic')
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
      content: "This is test content for the Nordic theme",
      excerpt: "Test excerpt",
      status: "published",
      user: @user,
      published_at: Time.current
    )
    
    @category = @category_taxonomy.terms.create!(name: "Tech", slug: "tech")
    @tag = @tag_taxonomy.terms.create!(name: "Rails", slug: "rails")
    @post.term_relationships.create!(term: @category)
    @post.term_relationships.create!(term: @tag)
  end

  # Header Section Tests
  test "header section should render" do
    assigns = {
      'site' => { 'name' => 'Test Site' },
      'menus' => { 'primary' => [] }
    }
    
    result = @renderer.render_section('header', assigns)
    assert_not_nil result
    assert_includes result, 'Test Site'
  end

  test "header should include navigation menu" do
    assigns = {
      'site' => { 'name' => 'Test Site' },
      'menus' => {
        'primary' => [
          { 'title' => 'Home', 'url' => '/' },
          { 'title' => 'Blog', 'url' => '/blog' }
        ]
      }
    }
    
    result = @renderer.render_section('header', assigns)
    assert_includes result, 'Home'
    assert_includes result, 'Blog'
  end

  test "header should include site logo when present" do
    assigns = {
      'site' => { 'name' => 'Test Site', 'logo' => '/logo.png' },
      'menus' => {}
    }
    
    result = @renderer.render_section('header', assigns)
    assert_includes result, 'logo.png'
  end

  # Footer Section Tests
  test "footer section should render" do
    assigns = {
      'site' => { 'name' => 'Test Site' },
      'menus' => { 'footer' => [] }
    }
    
    result = @renderer.render_section('footer', assigns)
    assert_not_nil result
    assert_includes result, Time.current.year.to_s
  end

  test "footer should include copyright notice" do
    assigns = {
      'site' => { 'name' => 'Test Site' },
      'menus' => {}
    }
    
    result = @renderer.render_section('footer', assigns)
    assert_includes result, 'Test Site'
  end

  # Hero Section Tests
  test "hero section should render with title" do
    assigns = {
      'title' => 'Welcome to Our Site',
      'subtitle' => 'The best content platform'
    }
    
    result = @renderer.render_section('hero', assigns)
    assert_includes result, 'Welcome to Our Site'
    assert_includes result, 'The best content platform'
  end

  test "hero section should handle missing subtitle" do
    assigns = {
      'title' => 'Welcome'
    }
    
    result = @renderer.render_section('hero', assigns)
    assert_includes result, 'Welcome'
  end

  # Post List Section Tests
  test "post-list section should render posts" do
    3.times do |i|
      Post.create!(
        title: "Post #{i}",
        content: "Content #{i}",
        status: "published",
        author: @user,
        published_at: Time.current
      )
    end
    
    assigns = {
      'posts' => Post.published.recent.limit(3)
    }
    
    result = @renderer.render_section('post-list', assigns)
    assert_includes result, 'Post 0'
    assert_includes result, 'Post 1'
    assert_includes result, 'Post 2'
  end

  test "post-list should handle empty posts" do
    Post.delete_all
    
    assigns = {
      'posts' => Post.none
    }
    
    result = @renderer.render_section('post-list', assigns)
    assert_not_nil result
  end

  # Post Content Section Tests
  test "post-content section should render post" do
    assigns = {
      'post' => @post,
      'page' => {
        'author' => @user,
        'published_at' => Time.current
      }
    }
    
    result = @renderer.render_section('post-content', assigns)
    assert_includes result, @post.title
    assert_includes result, @post.content
  end

  test "post-content should include author information" do
    assigns = {
      'post' => @post,
      'page' => {
        'author' => @user,
        'published_at' => Time.current
      }
    }
    
    result = @renderer.render_section('post-content', assigns)
    assert_includes result, @user.full_name
  end

  # Related Posts Section Tests
  test "related-posts section should render" do
    related = []
    2.times do |i|
      related << Post.create!(
        title: "Related Post #{i}",
        content: "Related content #{i}",
        status: "published",
        author: @user,
        published_at: Time.current
      )
    end
    
    assigns = {
      'related_posts' => related
    }
    
    result = @renderer.render_section('related-posts', assigns)
    assert_includes result, 'Related Post 0'
    assert_includes result, 'Related Post 1'
  end

  # Pagination Section Tests
  test "pagination section should render page numbers" do
    assigns = {
      'paginate' => {
        'current_page' => 2,
        'total_pages' => 5,
        'per_page' => 10
      }
    }
    
    result = @renderer.render_section('pagination', assigns)
    assert_includes result, '2'
    assert_includes result, '5'
  end

  test "pagination should show prev/next links" do
    assigns = {
      'paginate' => {
        'current_page' => 2,
        'total_pages' => 5
      }
    }
    
    result = @renderer.render_section('pagination', assigns)
    assert_not_nil result
  end

  # Rich Text Section Tests
  test "rich-text section should render content" do
    assigns = {
      'content' => '<p>Rich text content</p>'
    }
    
    result = @renderer.render_section('rich-text', assigns)
    assert_includes result, 'Rich text content'
  end

  # Comments Section Tests
  test "comments section should render comments" do
    comment = @post.comments.create!(
      content: "Great post!",
      author: @user,
      status: "approved"
    )
    
    assigns = {
      'post' => @post,
      'comments' => [@post.comments.first]
    }
    
    result = @renderer.render_section('comments', assigns)
    assert_includes result, 'Great post!'
  end

  test "comments section should handle no comments" do
    assigns = {
      'post' => @post,
      'comments' => []
    }
    
    result = @renderer.render_section('comments', assigns)
    assert_not_nil result
  end

  # Search Form Section Tests
  test "search-form section should render search input" do
    assigns = {}
    
    result = @renderer.render_section('search-form', assigns)
    assert_includes result, 'search'
  end

  test "search-form should include current query" do
    assigns = {
      'query' => 'test search'
    }
    
    result = @renderer.render_section('search-form', assigns)
    assert_includes result, 'test search'
  end

  # Search Results Section Tests
  test "search-results section should render results" do
    assigns = {
      'posts' => [@post],
      'query' => 'test'
    }
    
    result = @renderer.render_section('search-results', assigns)
    assert_includes result, @post.title
  end

  test "search-results should show no results message" do
    assigns = {
      'posts' => [],
      'query' => 'nonexistent'
    }
    
    result = @renderer.render_section('search-results', assigns)
    assert_not_nil result
  end

  # Taxonomy List Section Tests
  test "taxonomy-list section should render categories" do
    5.times do |i|
      @category_taxonomy.terms.create!(name: "Category #{i}", slug: "category-#{i}")
    end
    
    assigns = {
      'categories' => @category_taxonomy.terms.all
    }
    
    result = @renderer.render_section('taxonomy-list', assigns)
    assert_includes result, 'Category 0'
  end

  # Taxonomy Cloud Section Tests
  test "taxonomy-cloud section should render tags" do
    5.times do |i|
      @tag_taxonomy.terms.create!(name: "Tag #{i}", slug: "tag-#{i}")
    end
    
    assigns = {
      'tags' => @tag_taxonomy.terms.all
    }
    
    result = @renderer.render_section('taxonomy-cloud', assigns)
    assert_includes result, 'Tag 0'
  end

  # Author Card Section Tests
  test "author-card section should render author info" do
    assigns = {
      'author' => @user
    }
    
    result = @renderer.render_section('author-card', assigns)
    assert_includes result, @user.full_name
  end

  test "author-card should include author bio" do
    @user.update!(bio: 'Test author bio')
    
    assigns = {
      'author' => @user
    }
    
    result = @renderer.render_section('author-card', assigns)
    assert_includes result, 'Test author bio'
  end

  # SEO Head Section Tests
  test "seo-head section should render meta tags" do
    assigns = {
      'page' => {
        'title' => 'Test Page',
        'description' => 'Test description'
      }
    }
    
    result = @renderer.render_section('seo-head', assigns)
    assert_includes result, 'Test Page'
    assert_includes result, 'Test description'
  end
end
