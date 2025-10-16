require "test_helper"

class FrontendRenderingTest < ActionDispatch::IntegrationTest
  def setup
    @tenant = Tenant.first
    @user = users(:admin)
    @post = posts(:hello_world)
  end

  test "should render home page" do
    get "/"
    assert_response :success
    assert_select "title"
    assert_select "body"
  end

  test "should render post page" do
    get "/posts/#{@post.slug}"
    assert_response :success
    assert_select "h1", text: @post.title
    assert_select ".post-content"
  end

  test "should render post with liquid template" do
    # Set up a theme with liquid templates
    theme = Theme.create!(
      name: "test_theme",
      active: true,
      tenant: @tenant
    )
    
    # Create a post template
    template_content = <<~LIQUID
      <!DOCTYPE html>
      <html>
        <head>
          <title>{{ post.title }}</title>
        </head>
        <body>
          <h1>{{ post.title }}</h1>
          <div class="content">{{ post.content }}</div>
          <div class="meta">
            Published by {{ post.user.name }} on {{ post.created_at | date: '%B %d, %Y' }}
          </div>
        </body>
      </html>
    LIQUID
    
    # Save template to theme
    template_path = Rails.root.join("app/themes/#{theme.name}/views/posts/show.html.liquid")
    FileUtils.mkdir_p(File.dirname(template_path))
    File.write(template_path, template_content)
    
    get "/posts/#{@post.slug}"
    assert_response :success
    assert_select "title", text: @post.title
    assert_select "h1", text: @post.title
    assert_select ".content"
    assert_select ".meta"
  end

  test "should render page with liquid template" do
    page = Page.create!(
      title: "About Us",
      content: "This is our about page.",
      slug: "about-us",
      status: "published",
      user: @user,
      tenant: @tenant
    )
    
    # Set up theme with page template
    theme = Theme.create!(
      name: "test_theme",
      active: true,
      tenant: @tenant
    )
    
    template_content = <<~LIQUID
      <!DOCTYPE html>
      <html>
        <head>
          <title>{{ page.title }}</title>
        </head>
        <body>
          <h1>{{ page.title }}</h1>
          <div class="content">{{ page.content }}</div>
        </body>
      </html>
    LIQUID
    
    template_path = Rails.root.join("app/themes/#{theme.name}/views/pages/show.html.liquid")
    FileUtils.mkdir_p(File.dirname(template_path))
    File.write(template_path, template_content)
    
    get "/pages/#{page.slug}"
    assert_response :success
    assert_select "title", text: page.title
    assert_select "h1", text: page.title
    assert_select ".content", text: page.content
  end

  test "should render category archive page" do
    taxonomy = Taxonomy.create!(
      name: "Categories",
      taxonomy_type: "category",
      tenant: @tenant
    )
    
    category = Term.create!(
      name: "Technology",
      slug: "technology",
      taxonomy: taxonomy,
      tenant: @tenant
    )
    
    # Assign post to category
    @post.terms << category
    
    # Set up theme with category template
    theme = Theme.create!(
      name: "test_theme",
      active: true,
      tenant: @tenant
    )
    
    template_content = <<~LIQUID
      <!DOCTYPE html>
      <html>
        <head>
          <title>{{ category.name }} - Category</title>
        </head>
        <body>
          <h1>{{ category.name }}</h1>
          {% for post in posts %}
            <article>
              <h2><a href="/posts/{{ post.slug }}">{{ post.title }}</a></h2>
              <div class="excerpt">{{ post.excerpt }}</div>
            </article>
          {% endfor %}
        </body>
      </html>
    LIQUID
    
    template_path = Rails.root.join("app/themes/#{theme.name}/views/taxonomies/show.html.liquid")
    FileUtils.mkdir_p(File.dirname(template_path))
    File.write(template_path, template_content)
    
    get "/categories/#{category.slug}"
    assert_response :success
    assert_select "title", text: "#{category.name} - Category"
    assert_select "h1", text: category.name
    assert_select "article"
  end

  test "should render tag archive page" do
    taxonomy = Taxonomy.create!(
      name: "Tags",
      taxonomy_type: "tag",
      tenant: @tenant
    )
    
    tag = Term.create!(
      name: "ruby",
      slug: "ruby",
      taxonomy: taxonomy,
      tenant: @tenant
    )
    
    # Assign post to tag
    @post.terms << tag
    
    get "/tags/#{tag.slug}"
    assert_response :success
    assert_select "h1", text: tag.name
  end

  test "should render search results page" do
    get "/search", params: { q: "hello" }
    assert_response :success
    assert_select "h1", text: /Search/
  end

  test "should render 404 page for non-existent post" do
    get "/posts/non-existent-post"
    assert_response :not_found
  end

  test "should render 404 page for non-existent page" do
    get "/pages/non-existent-page"
    assert_response :not_found
  end

  test "should render RSS feed" do
    get "/feed.rss"
    assert_response :success
    assert_equal "application/rss+xml", response.content_type
    assert_select "rss"
    assert_select "channel"
  end

  test "should render sitemap" do
    get "/sitemap.xml"
    assert_response :success
    assert_equal "application/xml", response.content_type
    assert_select "urlset"
  end

  test "should render theme assets" do
    theme = Theme.create!(
      name: "test_theme",
      active: true,
      tenant: @tenant
    )
    
    # Create a CSS file
    css_content = "body { background: red; }"
    css_path = Rails.root.join("app/themes/#{theme.name}/assets/stylesheets/style.css")
    FileUtils.mkdir_p(File.dirname(css_path))
    File.write(css_path, css_content)
    
    get "/themes/#{theme.name}/assets/stylesheets/style.css"
    assert_response :success
    assert_equal "text/css", response.content_type
    assert_includes response.body, "background: red"
  end

  test "should render JavaScript assets" do
    theme = Theme.create!(
      name: "test_theme",
      active: true,
      tenant: @tenant
    )
    
    # Create a JS file
    js_content = "console.log('Hello from theme!');"
    js_path = Rails.root.join("app/themes/#{theme.name}/assets/javascripts/main.js")
    FileUtils.mkdir_p(File.dirname(js_path))
    File.write(js_path, js_content)
    
    get "/themes/#{theme.name}/assets/javascripts/main.js"
    assert_response :success
    assert_equal "application/javascript", response.content_type
    assert_includes response.body, "Hello from theme!"
  end

  test "should render image assets" do
    theme = Theme.create!(
      name: "test_theme",
      active: true,
      tenant: @tenant
    )
    
    # Create a test image file
    image_path = Rails.root.join("app/themes/#{theme.name}/assets/images/logo.png")
    FileUtils.mkdir_p(File.dirname(image_path))
    File.write(image_path, "fake image data")
    
    get "/themes/#{theme.name}/assets/images/logo.png"
    assert_response :success
    assert_equal "image/png", response.content_type
  end

  test "should render post with comments" do
    # Create comments for the post
    comment1 = Comment.create!(
      content: "Great post!",
      author_name: "John Doe",
      author_email: "john@example.com",
      commentable: @post,
      user: @user,
      status: "approved",
      comment_type: "comment",
      comment_approved: "1",
      tenant: @tenant
    )
    
    comment2 = Comment.create!(
      content: "Thanks for sharing!",
      author_name: "Jane Smith",
      author_email: "jane@example.com",
      commentable: @post,
      user: @user,
      status: "approved",
      comment_type: "comment",
      comment_approved: "1",
      tenant: @tenant
    )
    
    # Set up theme with comments template
    theme = Theme.create!(
      name: "test_theme",
      active: true,
      tenant: @tenant
    )
    
    template_content = <<~LIQUID
      <!DOCTYPE html>
      <html>
        <head>
          <title>{{ post.title }}</title>
        </head>
        <body>
          <h1>{{ post.title }}</h1>
          <div class="content">{{ post.content }}</div>
          
          <div class="comments">
            <h3>Comments</h3>
            {% for comment in post.comments %}
              <div class="comment">
                <strong>{{ comment.author_name }}</strong>
                <p>{{ comment.content }}</p>
              </div>
            {% endfor %}
          </div>
        </body>
      </html>
    LIQUID
    
    template_path = Rails.root.join("app/themes/#{theme.name}/views/posts/show.html.liquid")
    FileUtils.mkdir_p(File.dirname(template_path))
    File.write(template_path, template_content)
    
    get "/posts/#{@post.slug}"
    assert_response :success
    assert_select ".comments h3", text: "Comments"
    assert_select ".comment", count: 2
    assert_select ".comment strong", text: "John Doe"
    assert_select ".comment strong", text: "Jane Smith"
  end

  test "should render post with custom fields" do
    # Create custom fields for the post
    custom_field = CustomField.create!(
      name: "featured_image",
      field_type: "text",
      tenant: @tenant
    )
    
    custom_field_value = CustomFieldValue.create!(
      custom_field: custom_field,
      value: "https://example.com/image.jpg",
      custom_fieldable: @post,
      tenant: @tenant
    )
    
    # Set up theme with custom fields template
    theme = Theme.create!(
      name: "test_theme",
      active: true,
      tenant: @tenant
    )
    
    template_content = <<~LIQUID
      <!DOCTYPE html>
      <html>
        <head>
          <title>{{ post.title }}</title>
        </head>
        <body>
          <h1>{{ post.title }}</h1>
          {% if post.custom_fields.featured_image %}
            <img src="{{ post.custom_fields.featured_image }}" alt="{{ post.title }}">
          {% endif %}
          <div class="content">{{ post.content }}</div>
        </body>
      </html>
    LIQUID
    
    template_path = Rails.root.join("app/themes/#{theme.name}/views/posts/show.html.liquid")
    FileUtils.mkdir_p(File.dirname(template_path))
    File.write(template_path, template_content)
    
    get "/posts/#{@post.slug}"
    assert_response :success
    assert_select "img[src='https://example.com/image.jpg']"
  end

  test "should render post with related posts" do
    # Create related posts
    related_post1 = Post.create!(
      title: "Related Post 1",
      content: "This is a related post.",
      slug: "related-post-1",
      status: "published",
      user: @user,
      tenant: @tenant
    )
    
    related_post2 = Post.create!(
      title: "Related Post 2",
      content: "This is another related post.",
      slug: "related-post-2",
      status: "published",
      user: @user,
      tenant: @tenant
    )
    
    # Set up theme with related posts template
    theme = Theme.create!(
      name: "test_theme",
      active: true,
      tenant: @tenant
    )
    
    template_content = <<~LIQUID
      <!DOCTYPE html>
      <html>
        <head>
          <title>{{ post.title }}</title>
        </head>
        <body>
          <h1>{{ post.title }}</h1>
          <div class="content">{{ post.content }}</div>
          
          <div class="related-posts">
            <h3>Related Posts</h3>
            {% for related_post in post.related_posts %}
              <div class="related-post">
                <h4><a href="/posts/{{ related_post.slug }}">{{ related_post.title }}</a></h4>
              </div>
            {% endfor %}
          </div>
        </body>
      </html>
    LIQUID
    
    template_path = Rails.root.join("app/themes/#{theme.name}/views/posts/show.html.liquid")
    FileUtils.mkdir_p(File.dirname(template_path))
    File.write(template_path, template_content)
    
    get "/posts/#{@post.slug}"
    assert_response :success
    assert_select ".related-posts h3", text: "Related Posts"
  end

  test "should handle theme switching" do
    # Create two themes
    theme1 = Theme.create!(
      name: "theme1",
      active: true,
      tenant: @tenant
    )
    
    theme2 = Theme.create!(
      name: "theme2",
      active: false,
      tenant: @tenant
    )
    
    # Create templates for both themes
    template1_content = "<h1>Theme 1</h1>"
    template2_content = "<h1>Theme 2</h1>"
    
    template1_path = Rails.root.join("app/themes/theme1/views/posts/show.html.liquid")
    template2_path = Rails.root.join("app/themes/theme2/views/posts/show.html.liquid")
    
    FileUtils.mkdir_p(File.dirname(template1_path))
    FileUtils.mkdir_p(File.dirname(template2_path))
    
    File.write(template1_path, template1_content)
    File.write(template2_path, template2_content)
    
    # Test theme1
    get "/posts/#{@post.slug}"
    assert_response :success
    assert_select "h1", text: "Theme 1"
    
    # Switch to theme2
    theme1.update!(active: false)
    theme2.update!(active: true)
    
    get "/posts/#{@post.slug}"
    assert_response :success
    assert_select "h1", text: "Theme 2"
  end

  test "should handle liquid template errors gracefully" do
    # Set up theme with broken template
    theme = Theme.create!(
      name: "broken_theme",
      active: true,
      tenant: @tenant
    )
    
    template_content = "{{ broken.syntax }}"
    template_path = Rails.root.join("app/themes/broken_theme/views/posts/show.html.liquid")
    FileUtils.mkdir_p(File.dirname(template_path))
    File.write(template_path, template_content)
    
    get "/posts/#{@post.slug}"
    assert_response :success
    # Should render error message or fallback content
  end

  test "should render pagination" do
    # Create multiple posts
    15.times do |i|
      Post.create!(
        title: "Post #{i + 1}",
        content: "Content for post #{i + 1}",
        slug: "post-#{i + 1}",
        status: "published",
        user: @user,
        tenant: @tenant
      )
    end
    
    # Set up theme with pagination template
    theme = Theme.create!(
      name: "pagination_theme",
      active: true,
      tenant: @tenant
    )
    
    template_content = <<~LIQUID
      <!DOCTYPE html>
      <html>
        <head>
          <title>Posts</title>
        </head>
        <body>
          {% for post in posts %}
            <article>
              <h2>{{ post.title }}</h2>
            </article>
          {% endfor %}
          
          {% if pagination.total_pages > 1 %}
            <div class="pagination">
              {% if pagination.previous_page %}
                <a href="?page={{ pagination.previous_page }}">Previous</a>
              {% endif %}
              <span>Page {{ pagination.current_page }} of {{ pagination.total_pages }}</span>
              {% if pagination.next_page %}
                <a href="?page={{ pagination.next_page }}">Next</a>
              {% endif %}
            </div>
          {% endif %}
        </body>
      </html>
    LIQUID
    
    template_path = Rails.root.join("app/themes/pagination_theme/views/posts/index.html.liquid")
    FileUtils.mkdir_p(File.dirname(template_path))
    File.write(template_path, template_content)
    
    get "/posts"
    assert_response :success
    assert_select ".pagination"
  end
end




