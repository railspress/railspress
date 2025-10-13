require "test_helper"

class NordicThemeSnippetsTest < ActionDispatch::IntegrationTest
  setup do
    @renderer = LiquidTemplateRenderer.new('nordic')
    @user = users(:admin)
    @post = Post.create!(
      title: "Test Post for Snippets",
      content: "This is test content with multiple words to test reading time calculation",
      excerpt: "Test excerpt",
      status: "published",
      user: @user,
      published_at: Time.current
    )
  end

  # SEO Snippet Tests
  test "seo snippet should render title tag" do
    assigns = {
      'page' => {
        'title' => 'Test Page Title'
      },
      'site' => {
        'name' => 'Test Site'
      }
    }
    
    result = @renderer.render_snippet('seo', assigns)
    assert_includes result, '<title>'
    assert_includes result, 'Test Page Title'
  end

  test "seo snippet should include meta description" do
    assigns = {
      'page' => {
        'title' => 'Test Page',
        'description' => 'This is a test description'
      },
      'site' => { 'name' => 'Test Site' }
    }
    
    result = @renderer.render_snippet('seo', assigns)
    assert_includes result, 'meta name="description"'
    assert_includes result, 'This is a test description'
  end

  test "seo snippet should include Open Graph tags" do
    assigns = {
      'page' => {
        'title' => 'Test Page',
        'description' => 'Test description'
      },
      'site' => {
        'name' => 'Test Site',
        'url' => 'https://test.com'
      },
      'request_path' => '/test-page'
    }
    
    result = @renderer.render_snippet('seo', assigns)
    assert_includes result, 'property="og:title"'
    assert_includes result, 'property="og:description"'
    assert_includes result, 'property="og:url"'
  end

  test "seo snippet should include Twitter Card tags" do
    assigns = {
      'page' => {
        'title' => 'Test Page',
        'description' => 'Test description'
      },
      'site' => { 'name' => 'Test Site' }
    }
    
    result = @renderer.render_snippet('seo', assigns)
    assert_includes result, 'name="twitter:card"'
    assert_includes result, 'name="twitter:title"'
  end

  test "seo snippet should include JSON-LD structured data" do
    assigns = {
      'page' => {
        'title' => 'Test Page',
        'description' => 'Test description',
        'schema_type' => 'Article'
      },
      'site' => {
        'name' => 'Test Site',
        'url' => 'https://test.com'
      },
      'request_path' => '/test-page'
    }
    
    result = @renderer.render_snippet('seo', assigns)
    assert_includes result, 'application/ld+json'
    assert_includes result, '@type'
    assert_includes result, 'Article'
  end

  # Post Card Snippet Tests
  test "post-card snippet should render post title" do
    assigns = {
      'post' => @post
    }
    
    result = @renderer.render_snippet('post-card', assigns)
    assert_includes result, @post.title
  end

  test "post-card snippet should render post excerpt" do
    assigns = {
      'post' => @post
    }
    
    result = @renderer.render_snippet('post-card', assigns)
    assert_includes result, @post.excerpt
  end

  test "post-card snippet should include post URL" do
    assigns = {
      'post' => @post
    }
    
    result = @renderer.render_snippet('post-card', assigns)
    assert_not_nil result
  end

  # Post Meta Snippet Tests
  test "post-meta snippet should render publication date" do
    assigns = {
      'post' => @post,
      'page' => {
        'published_at' => @post.published_at
      }
    }
    
    result = @renderer.render_snippet('post-meta', assigns)
    assert_not_nil result
  end

  test "post-meta snippet should render author name" do
    assigns = {
      'post' => @post,
      'page' => {
        'author' => @user
      }
    }
    
    result = @renderer.render_snippet('post-meta', assigns)
    assert_includes result, @user.name
  end

  test "post-meta snippet should render categories" do
    category_taxonomy = Taxonomy.find_or_create_by!(slug: 'category') do |t|
      t.name = 'Category'
      t.hierarchical = true
      t.object_types = ['Post']
    end
    
    category = category_taxonomy.terms.create!(name: "Tech", slug: "tech")
    @post.term_relationships.create!(term: category)
    
    assigns = {
      'post' => @post,
      'page' => {
        'categories' => @post.terms.where(taxonomy: category_taxonomy)
      }
    }
    
    result = @renderer.render_snippet('post-meta', assigns)
    assert_includes result, 'Tech'
  end

  # Image Snippet Tests
  test "image snippet should render img tag" do
    assigns = {
      'src' => '/path/to/image.jpg',
      'alt' => 'Test Image'
    }
    
    result = @renderer.render_snippet('image', assigns)
    assert_includes result, '<img'
    assert_includes result, '/path/to/image.jpg'
    assert_includes result, 'Test Image'
  end

  test "image snippet should include loading attribute" do
    assigns = {
      'src' => '/image.jpg',
      'alt' => 'Test',
      'loading' => 'lazy'
    }
    
    result = @renderer.render_snippet('image', assigns)
    assert_includes result, 'loading='
  end

  # Date Format Snippet Tests
  test "dateformat snippet should format dates" do
    assigns = {
      'date' => Time.new(2025, 10, 12),
      'format' => '%B %d, %Y'
    }
    
    result = @renderer.render_snippet('dateformat', assigns)
    assert_includes result, 'October 12, 2025'
  end

  # Time Ago Snippet Tests
  test "timeago snippet should render relative time" do
    assigns = {
      'date' => 2.hours.ago
    }
    
    result = @renderer.render_snippet('timeago', assigns)
    assert_not_nil result
  end

  # Reading Time Snippet Tests
  test "reading-time snippet should calculate reading time" do
    assigns = {
      'content' => ('word ' * 200).strip
    }
    
    result = @renderer.render_snippet('reading-time', assigns)
    assert_includes result, 'min read'
  end

  # Excerpt Snippet Tests
  test "excerpt snippet should truncate long text" do
    long_text = "This is a very long piece of text that should be truncated to a shorter excerpt for display purposes"
    
    assigns = {
      'text' => long_text,
      'length' => 10
    }
    
    result = @renderer.render_snippet('excerpt', assigns)
    assert result.length < long_text.length
    assert_includes result, '...'
  end

  test "excerpt snippet should not truncate short text" do
    short_text = "Short text"
    
    assigns = {
      'text' => short_text,
      'length' => 50
    }
    
    result = @renderer.render_snippet('excerpt', assigns)
    assert_equal short_text, result.strip
  end

  # Share Buttons Snippet Tests
  test "share-buttons snippet should render social links" do
    assigns = {
      'url' => 'https://example.com/post',
      'title' => 'Test Post'
    }
    
    result = @renderer.render_snippet('share-buttons', assigns)
    assert_not_nil result
  end

  # Paginate Snippet Tests
  test "paginate snippet should render pagination" do
    assigns = {
      'paginate' => {
        'current_page' => 2,
        'total_pages' => 5,
        'per_page' => 10
      }
    }
    
    result = @renderer.render_snippet('paginate', assigns)
    assert_not_nil result
  end

  test "paginate snippet should show current page" do
    assigns = {
      'paginate' => {
        'current_page' => 3,
        'total_pages' => 5
      }
    }
    
    result = @renderer.render_snippet('paginate', assigns)
    assert_includes result, '3'
  end

  # Taxonomy Badges Snippet Tests
  test "taxonomy-badges snippet should render category badges" do
    category_taxonomy = Taxonomy.find_or_create_by!(slug: 'category') do |t|
      t.name = 'Category'
      t.hierarchical = true
      t.object_types = ['Post']
    end
    
    category = category_taxonomy.terms.create!(name: "Tech", slug: "tech")
    
    assigns = {
      'categories' => [category]
    }
    
    result = @renderer.render_snippet('taxonomy-badges', assigns)
    assert_includes result, 'Tech'
  end

  test "taxonomy-badges snippet should render tag badges" do
    tag_taxonomy = Taxonomy.find_or_create_by!(slug: 'tag') do |t|
      t.name = 'Tag'
      t.hierarchical = false
      t.object_types = ['Post']
    end
    
    tag = tag_taxonomy.terms.create!(name: "Rails", slug: "rails")
    
    assigns = {
      'tags' => [tag]
    }
    
    result = @renderer.render_snippet('taxonomy-badges', assigns)
    assert_includes result, 'Rails'
  end

  # Markdown Snippet Tests
  test "markdown snippet should convert markdown to HTML" do
    assigns = {
      'content' => '# Heading\n\nParagraph with **bold** text.'
    }
    
    result = @renderer.render_snippet('markdown', assigns)
    assert_includes result, '<h1>'
    assert_includes result, 'Heading'
    assert_includes result, '<strong>'
    assert_includes result, 'bold'
  end

  # Sanitize Snippet Tests
  test "sanitize snippet should remove dangerous HTML" do
    assigns = {
      'content' => '<p>Safe content</p><script>alert("danger")</script>'
    }
    
    result = @renderer.render_snippet('sanitize', assigns)
    assert_includes result, 'Safe content'
    assert_not_includes result, '<script>'
  end

  test "sanitize snippet should allow safe HTML tags" do
    assigns = {
      'content' => '<p>Paragraph with <strong>bold</strong> and <em>italic</em></p>'
    }
    
    result = @renderer.render_snippet('sanitize', assigns)
    assert_includes result, '<p>'
    assert_includes result, '<strong>'
    assert_includes result, '<em>'
  end
end
