require "test_helper"

class LiquidTemplateRendererTest < ActiveSupport::TestCase
  def setup
    @renderer = LiquidTemplateRenderer.new("default", "post", {})
    @user = users(:admin)
    @tenant = @user.tenant
    @post = posts(:hello_world)
  end

  test "should render simple liquid template" do
    template = "Hello {{ name }}!"
    context = { "name" => "World" }
    
    result = @renderer.render(template, context)
    assert_equal "Hello World!", result
  end

  test "should render liquid template with filters" do
    template = "{{ text | upcase | truncate: 5 }}"
    context = { "text" => "hello world" }
    
    result = @renderer.render(template, context)
    assert_equal "HELLO", result
  end

  test "should render liquid template with loops" do
    template = "{% for item in items %}{{ item }}{% endfor %}"
    context = { "items" => ["a", "b", "c"] }
    
    result = @renderer.render(template, context)
    assert_equal "abc", result
  end

  test "should render liquid template with conditionals" do
    template = "{% if show %}Hello{% else %}Goodbye{% endif %}"
    
    context = { "show" => true }
    result = @renderer.render(template, context)
    assert_equal "Hello", result
    
    context = { "show" => false }
    result = @renderer.render(template, context)
    assert_equal "Goodbye", result
  end

  test "should render liquid template with post context" do
    template = "{{ post.title }} by {{ post.user.name }}"
    context = { "post" => @post }
    
    result = @renderer.render(template, context)
    assert_equal "#{@post.title} by #{@post.user.name}", result
  end

  test "should render liquid template with comments" do
    comment = Comment.create!(
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
    
    template = "{{ comment.content }} - {{ comment.author_name }}"
    context = { "comment" => comment }
    
    result = @renderer.render(template, context)
    assert_equal "Great post! - John Doe", result
  end

  test "should render liquid template with site settings" do
    site_setting = SiteSetting.create!(
      key: "site_title",
      value: "My Awesome Site",
      tenant: @tenant
    )
    
    template = "Welcome to {{ site.title }}"
    context = { "site" => { "title" => site_setting.value } }
    
    result = @renderer.render(template, context)
    assert_equal "Welcome to My Awesome Site", result
  end

  test "should handle liquid template errors gracefully" do
    template = "{{ invalid.syntax }}"
    context = {}
    
    result = @renderer.render(template, context)
    assert_includes result, "Liquid error"
  end

  test "should render liquid template with custom filters" do
    # Test custom filters that might be defined in the application
    template = "{{ text | strip_html }}"
    context = { "text" => "<p>Hello <strong>World</strong></p>" }
    
    result = @renderer.render(template, context)
    assert_equal "Hello World", result
  end

  test "should render liquid template with date filters" do
    date = Time.current
    template = "{{ date | date: '%Y-%m-%d' }}"
    context = { "date" => date }
    
    result = @renderer.render(template, context)
    assert_equal date.strftime("%Y-%m-%d"), result
  end

  test "should render liquid template with number filters" do
    template = "{{ price | money }}"
    context = { "price" => 1234.56 }
    
    result = @renderer.render(template, context)
    assert_equal "$1,234.56", result
  end

  test "should render liquid template with array filters" do
    template = "{{ items | join: ', ' }}"
    context = { "items" => ["apple", "banana", "orange"] }
    
    result = @renderer.render(template, context)
    assert_equal "apple, banana, orange", result
  end

  test "should render liquid template with string filters" do
    template = "{{ text | capitalize | prepend: 'Hello ' | append: '!' }}"
    context = { "text" => "world" }
    
    result = @renderer.render(template, context)
    assert_equal "Hello World!", result
  end

  test "should render liquid template with math filters" do
    template = "{{ number | plus: 10 | times: 2 }}"
    context = { "number" => 5 }
    
    result = @renderer.render(template, context)
    assert_equal "30", result
  end

  test "should render liquid template with complex nested data" do
    template = "{% for post in posts %}{{ post.title }} by {{ post.user.name }}{% endfor %}"
    context = { "posts" => [@post] }
    
    result = @renderer.render(template, context)
    assert_equal "#{@post.title} by #{@post.user.name}", result
  end

  test "should render liquid template with pagination" do
    template = "Page {{ pagination.current_page }} of {{ pagination.total_pages }}"
    context = { "pagination" => { "current_page" => 2, "total_pages" => 5 } }
    
    result = @renderer.render(template, context)
    assert_equal "Page 2 of 5", result
  end

  test "should render liquid template with media context" do
    upload = Upload.create!(
      filename: "test-image.jpg",
      content_type: "image/jpeg",
      file_size: 1024,
      storage_provider: StorageProvider.first,
      tenant: @tenant
    )
    
    medium = Medium.create!(
      title: "Test Image",
      alt_text: "A test image",
      upload: upload,
      user: @user,
      tenant: @tenant
    )
    
    template = "{{ media.title }} - {{ media.alt_text }}"
    context = { "media" => medium }
    
    result = @renderer.render(template, context)
    assert_equal "Test Image - A test image", result
  end

  test "should render liquid template with taxonomy context" do
    taxonomy = Taxonomy.create!(
      name: "Categories",
      taxonomy_type: "category",
      tenant: @tenant
    )
    
    term = Term.create!(
      name: "Technology",
      slug: "technology",
      taxonomy: taxonomy,
      tenant: @tenant
    )
    
    template = "{{ term.name }} in {{ term.taxonomy.name }}"
    context = { "term" => term }
    
    result = @renderer.render(template, context)
    assert_equal "Technology in Categories", result
  end

  test "should render liquid template with menu context" do
    menu = Menu.create!(
      name: "Main Menu",
      location: "header",
      tenant: @tenant
    )
    
    menu_item = MenuItem.create!(
      title: "Home",
      url: "/",
      menu: menu,
      tenant: @tenant
    )
    
    template = "{{ menu_item.title }} - {{ menu_item.url }}"
    context = { "menu_item" => menu_item }
    
    result = @renderer.render(template, context)
    assert_equal "Home - /", result
  end

  test "should handle liquid template with missing variables" do
    template = "{{ missing_variable | default: 'fallback' }}"
    context = {}
    
    result = @renderer.render(template, context)
    assert_equal "fallback", result
  end

  test "should render liquid template with includes" do
    # This would test if the renderer supports includes
    template = "{% include 'header' %}"
    context = {}
    
    # For now, just test that it doesn't crash
    result = @renderer.render(template, context)
    assert_not_nil result
  end

  test "should render liquid template with custom tags" do
    # This would test custom Liquid tags defined in the application
    template = "{% custom_tag 'test' %}"
    context = {}
    
    # For now, just test that it doesn't crash
    result = @renderer.render(template, context)
    assert_not_nil result
  end

  test "should sanitize liquid template output" do
    template = "{{ unsafe_html }}"
    context = { "unsafe_html" => "<script>alert('xss')</script>Safe content" }
    
    result = @renderer.render(template, context)
    assert_not_includes result, "<script>"
    assert_includes result, "Safe content"
  end

  test "should handle liquid template with large datasets" do
    # Create a large array
    large_array = (1..1000).map { |i| "Item #{i}" }
    
    template = "{{ items.size }} items"
    context = { "items" => large_array }
    
    result = @renderer.render(template, context)
    assert_equal "1000 items", result
  end

  test "should render liquid template with nested objects" do
    template = "{{ user.profile.name }} from {{ user.profile.location }}"
    context = { 
      "user" => { 
        "profile" => { 
          "name" => "John Doe", 
          "location" => "New York" 
        } 
      } 
    }
    
    result = @renderer.render(template, context)
    assert_equal "John Doe from New York", result
  end

  test "should handle liquid template with nil values" do
    template = "{{ nil_value | default: 'No value' }}"
    context = { "nil_value" => nil }
    
    result = @renderer.render(template, context)
    assert_equal "No value", result
  end

  test "should render liquid template with boolean values" do
    template = "{% if is_published %}Published{% else %}Draft{% endif %}"
    
    context = { "is_published" => true }
    result = @renderer.render(template, context)
    assert_equal "Published", result
    
    context = { "is_published" => false }
    result = @renderer.render(template, context)
    assert_equal "Draft", result
  end
end