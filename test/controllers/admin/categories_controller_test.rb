require "test_helper"

class Admin::CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    sign_in @admin
    
    @taxonomy = Taxonomy.find_or_create_by!(slug: 'category') do |t|
      t.name = 'Category'
      t.singular_name = 'Category'
      t.plural_name = 'Categories'
      t.hierarchical = true
      t.object_types = ['Post']
    end
    
    @uncategorized = @taxonomy.terms.find_or_create_by!(slug: 'uncategorized') do |term|
      term.name = 'Uncategorized'
    end
    
    @technology = @taxonomy.terms.create!(name: 'Technology', slug: 'technology')
  end

  test "should get index" do
    get admin_categories_url
    assert_response :success
  end

  test "should get index as JSON" do
    get admin_categories_url(format: :json)
    assert_response :success
    
    json = JSON.parse(response.body)
    assert json.is_a?(Array)
    assert json.length > 0
  end

  test "should show category" do
    get admin_category_url(@technology)
    assert_response :success
  end

  test "should get new" do
    get new_admin_category_url
    assert_response :success
  end

  test "should create category" do
    assert_difference('@taxonomy.terms.count') do
      post admin_categories_url, params: { 
        term: { 
          name: "New Category",
          slug: "new-category",
          description: "Test category"
        } 
      }
    end

    assert_redirected_to admin_category_url(Term.last)
  end

  test "should get edit" do
    get edit_admin_category_url(@technology)
    assert_response :success
  end

  test "should update category" do
    patch admin_category_url(@technology), params: { 
      term: { 
        name: "Updated Technology",
        description: "Updated description"
      } 
    }

    assert_redirected_to admin_category_url(@technology)
    @technology.reload
    assert_equal "Updated Technology", @technology.name
  end

  test "should destroy category" do
    category = @taxonomy.terms.create!(name: "Delete Me", slug: "delete-me")
    
    assert_difference('@taxonomy.terms.count', -1) do
      delete admin_category_url(category)
    end

    assert_redirected_to admin_categories_url
  end

  test "should not delete uncategorized category" do
    assert_no_difference('@taxonomy.terms.count') do
      delete admin_category_url(@uncategorized)
    end

    assert_redirected_to admin_categories_url
    assert_match /cannot delete/i, flash[:alert]
  end

  test "should reassign posts when deleting category" do
    post = Post.create!(
      title: 'Test', 
      content: 'Content', 
      slug: 'test-cat', 
      user: @admin, 
      status: 'published'
    )
    post.term_relationships.create!(term: @technology)
    
    delete admin_category_url(@technology)
    
    # Post should be reassigned to uncategorized
    post.reload
    assert_includes post.terms, @uncategorized
  end

  test "should create hierarchical category with parent" do
    post admin_categories_url, params: { 
      term: { 
        name: "Ruby",
        slug: "ruby",
        parent_id: @technology.id
      } 
    }

    term = Term.last
    assert_equal @technology, term.parent
  end

  test "should show parent categories in new form" do
    get new_admin_category_url
    assert_response :success
    assert_select 'select', { name: 'term[parent_id]' }, true
  end

  test "index JSON includes parent information" do
    child = @taxonomy.terms.create!(name: 'Child', slug: 'child', parent: @technology)
    
    get admin_categories_url(format: :json)
    json = JSON.parse(response.body)
    
    child_data = json.find { |item| item['id'] == child.id }
    assert_equal @technology.id, child_data['parent_id']
    assert_equal @technology.name, child_data['parent_name']
  end

  test "should require authentication" do
    sign_out @admin
    
    get admin_categories_url
    assert_redirected_to new_user_session_url
  end

  test "should show posts count" do
    get admin_categories_url(format: :json)
    json = JSON.parse(response.body)
    
    json.each do |category|
      assert_not_nil category['posts_count']
      assert category['posts_count'].is_a?(Integer)
    end
  end
end


