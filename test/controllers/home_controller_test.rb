require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
  end

  test "should load featured posts" do
    # Create published posts
    3.times do |i|
      Post.create!(
        title: "Featured Post #{i}",
        content: "Content #{i}",
        status: "published",
        user: users(:admin),
        published_at: i.days.ago
      )
    end
    
    get root_url
    assert_response :success
  end

  test "should load recent posts" do
    # Create recent posts
    6.times do |i|
      Post.create!(
        title: "Recent Post #{i}",
        content: "Content #{i}",
        status: "published",
        user: users(:admin),
        published_at: i.hours.ago
      )
    end
    
    get root_url
    assert_response :success
  end

  test "should load categories" do
    # Create category taxonomy and terms
    taxonomy = Taxonomy.find_or_create_by!(slug: 'category') do |t|
      t.name = 'Category'
      t.hierarchical = true
      t.object_types = ['Post']
    end
    
    10.times do |i|
      taxonomy.terms.create!(name: "Category #{i}", slug: "category-#{i}")
    end
    
    get root_url
    assert_response :success
  end

  test "should render with Liquid template" do
    get root_url
    assert_response :success
    
    # Should not have Rails default layout
    assert_select "html"
  end

  test "should include SEO meta tags" do
    get root_url
    assert_response :success
    
    assert_select "meta[name='description']"
    assert_select "meta[property='og:title']"
    assert_select "title"
  end

  test "should handle empty database" do
    Post.delete_all
    Term.delete_all
    
    get root_url
    assert_response :success
  end
end
