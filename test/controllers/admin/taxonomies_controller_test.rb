require "test_helper"

class Admin::TaxonomiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @category_taxonomy = taxonomies(:category)
    @tag_taxonomy = taxonomies(:tag)
    sign_in @admin
  end

  test "should get index" do
    get admin_taxonomies_url
    assert_response :success
    assert_select 'h1', /Taxonomies/i
  end

  test "should show taxonomy details" do
    get admin_taxonomy_url(@category_taxonomy)
    assert_response :success
    assert_select 'h1', @category_taxonomy.name
  end

  test "should get new" do
    get new_admin_taxonomy_url
    assert_response :success
    assert_select 'form'
  end

  test "should create taxonomy" do
    assert_difference('Taxonomy.count') do
      post admin_taxonomies_url, params: { 
        taxonomy: { 
          name: "New Taxonomy",
          slug: "new-taxonomy",
          description: "Test description",
          hierarchical: false,
          object_types: ["Post"]
        } 
      }
    end

    assert_redirected_to admin_taxonomy_url(Taxonomy.last)
    assert_equal "New Taxonomy", Taxonomy.last.name
  end

  test "should not create invalid taxonomy" do
    assert_no_difference('Taxonomy.count') do
      post admin_taxonomies_url, params: { 
        taxonomy: { 
          name: "",
          slug: ""
        } 
      }
    end

    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_admin_taxonomy_url(@category_taxonomy)
    assert_response :success
    assert_select 'form'
    assert_select "input[value=?]", @category_taxonomy.name
  end

  test "should update taxonomy" do
    patch admin_taxonomy_url(@category_taxonomy), params: { 
      taxonomy: { 
        name: "Updated Name",
        description: "Updated description"
      } 
    }

    assert_redirected_to admin_taxonomy_url(@category_taxonomy)
    @category_taxonomy.reload
    assert_equal "Updated Name", @category_taxonomy.name
  end

  test "should not update with invalid data" do
    patch admin_taxonomy_url(@category_taxonomy), params: { 
      taxonomy: { 
        name: "",
        slug: ""
      } 
    }

    assert_response :unprocessable_entity
    @category_taxonomy.reload
    assert_not_equal "", @category_taxonomy.name
  end

  test "should destroy taxonomy" do
    taxonomy = Taxonomy.create!(name: "Delete Me", slug: "delete-me")
    
    assert_difference('Taxonomy.count', -1) do
      delete admin_taxonomy_url(taxonomy)
    end

    assert_redirected_to admin_taxonomies_url
  end

  test "should not allow non-admin to access" do
    sign_out @admin
    editor = users(:editor)
    sign_in editor

    get admin_taxonomies_url
    assert_response :redirect
  end

  test "should list taxonomy terms" do
    get admin_taxonomy_url(@category_taxonomy)
    assert_response :success
    
    @category_taxonomy.terms.each do |term|
      assert_select 'td', term.name
    end
  end

  test "should show hierarchical structure for categories" do
    parent = @category_taxonomy.terms.create!(name: "Parent", slug: "parent-test")
    child = @category_taxonomy.terms.create!(name: "Child", slug: "child-test", parent: parent)
    
    get admin_taxonomy_url(@category_taxonomy)
    assert_response :success
    
    # Should show both parent and child
    assert_match /Parent/, response.body
    assert_match /Child/, response.body
  end

  test "should filter taxonomies by object type" do
    get admin_taxonomies_url, params: { object_type: 'Post' }
    assert_response :success
    
    # Should show Post taxonomies
    assert_match /Category/, response.body
    assert_match /Tag/, response.body
  end

  test "should show taxonomy usage count" do
    get admin_taxonomy_url(@category_taxonomy)
    assert_response :success
    
    # Should show number of terms
    assert_match /#{@category_taxonomy.terms.count}/, response.body
  end
end






