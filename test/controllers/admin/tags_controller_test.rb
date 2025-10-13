require "test_helper"

class Admin::TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    sign_in @admin
    
    @taxonomy = Taxonomy.find_or_create_by!(slug: 'tag') do |t|
      t.name = 'Tag'
      t.singular_name = 'Tag'
      t.plural_name = 'Tags'
      t.hierarchical = false
      t.object_types = ['Post']
    end
    
    @ruby_tag = @taxonomy.terms.create!(name: 'ruby', slug: 'ruby')
  end

  test "should get index" do
    get admin_tags_url
    assert_response :success
  end

  test "should get index as JSON" do
    get admin_tags_url(format: :json)
    assert_response :success
    
    json = JSON.parse(response.body)
    assert json.is_a?(Array)
  end

  test "should show tag" do
    get admin_tag_url(@ruby_tag)
    assert_response :success
  end

  test "should get new" do
    get new_admin_tag_url
    assert_response :success
  end

  test "should create tag" do
    assert_difference('@taxonomy.terms.count') do
      post admin_tags_url, params: { 
        term: { 
          name: "rails",
          slug: "rails",
          description: "Ruby on Rails"
        } 
      }
    end

    assert_redirected_to admin_tag_url(Term.last)
  end

  test "should get edit" do
    get edit_admin_tag_url(@ruby_tag)
    assert_response :success
  end

  test "should update tag" do
    patch admin_tag_url(@ruby_tag), params: { 
      term: { 
        name: "Ruby Language",
        description: "Ruby programming language"
      } 
    }

    assert_redirected_to admin_tag_url(@ruby_tag)
    @ruby_tag.reload
    assert_equal "Ruby Language", @ruby_tag.name
  end

  test "should destroy tag" do
    tag = @taxonomy.terms.create!(name: "Delete Me", slug: "delete-me-tag")
    
    assert_difference('@taxonomy.terms.count', -1) do
      delete admin_tag_url(tag)
    end

    assert_redirected_to admin_tags_url
  end

  test "should not show parent selector in form (flat taxonomy)" do
    get new_admin_tag_url
    assert_response :success
    
    # Tags are flat, should not have parent selector
    assert_select 'select[name="term[parent_id]"]', count: 0
  end

  test "index JSON includes posts count" do
    post = Post.create!(
      title: 'Ruby Post',
      content: 'Content',
      slug: 'ruby-post',
      user: @admin,
      status: 'published'
    )
    post.term_relationships.create!(term: @ruby_tag)
    
    get admin_tags_url(format: :json)
    json = JSON.parse(response.body)
    
    ruby_data = json.find { |item| item['id'] == @ruby_tag.id }
    assert_equal 1, ruby_data['posts_count']
  end

  test "should require authentication" do
    sign_out @admin
    
    get admin_tags_url
    assert_redirected_to new_user_session_url
  end

  test "should handle tag without description" do
    post admin_tags_url, params: { 
      term: { 
        name: "minimalist",
        slug: "minimalist"
      } 
    }

    assert_response :redirect
    assert_nil Term.last.description
  end

  test "should auto-generate slug if not provided" do
    post admin_tags_url, params: { 
      term: { 
        name: "Auto Generated Slug"
      } 
    }

    term = Term.last
    assert_match /auto.*generated.*slug/i, term.slug
  end

  test "should show tag with associated posts" do
    post = Post.create!(
      title: 'Tagged Post',
      content: 'Content',
      slug: 'tagged-post',
      user: @admin,
      status: 'published'
    )
    post.term_relationships.create!(term: @ruby_tag)
    
    get admin_tag_url(@ruby_tag)
    assert_response :success
    
    # Should show the associated post
    assert_match /Tagged Post/i, response.body
  end
end



