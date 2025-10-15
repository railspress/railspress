require "test_helper"

class Admin::TermsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @category_taxonomy = taxonomies(:category)
    @tag_taxonomy = taxonomies(:tag)
    @uncategorized = terms(:uncategorized)
    @technology = terms(:technology)
    sign_in @admin
  end

  test "should get index for taxonomy" do
    get admin_taxonomy_terms_url(@category_taxonomy)
    assert_response :success
    assert_select 'h1', /#{@category_taxonomy.plural_name}/i
  end

  test "should show term" do
    get admin_taxonomy_term_url(@category_taxonomy, @uncategorized)
    assert_response :success
    assert_select 'h1', @uncategorized.name
  end

  test "should get new" do
    get new_admin_taxonomy_term_url(@category_taxonomy)
    assert_response :success
    assert_select 'form'
  end

  test "should create term" do
    assert_difference('Term.count') do
      post admin_taxonomy_terms_url(@category_taxonomy), params: { 
        term: { 
          name: "New Category",
          slug: "new-category",
          description: "Test category"
        } 
      }
    end

    assert_redirected_to admin_taxonomy_term_url(@category_taxonomy, Term.last)
    assert_equal "New Category", Term.last.name
  end

  test "should auto-generate slug if not provided" do
    post admin_taxonomy_terms_url(@category_taxonomy), params: { 
      term: { 
        name: "Auto Slug Test"
      } 
    }

    assert_equal "auto-slug-test", Term.last.slug
  end

  test "should create hierarchical term with parent" do
    post admin_taxonomy_terms_url(@category_taxonomy), params: { 
      term: { 
        name: "Child Category",
        slug: "child-category",
        parent_id: @technology.id
      } 
    }

    term = Term.last
    assert_equal @technology, term.parent
  end

  test "should not create term with duplicate slug in same taxonomy" do
    assert_no_difference('Term.count') do
      post admin_taxonomy_terms_url(@category_taxonomy), params: { 
        term: { 
          name: "Duplicate",
          slug: @uncategorized.slug
        } 
      }
    end

    assert_response :unprocessable_entity
  end

  test "should allow same slug in different taxonomies" do
    # Create term in category taxonomy
    category_term = @category_taxonomy.terms.create!(
      name: "Featured",
      slug: "featured-unique-1"
    )

    # Create term with same slug in tag taxonomy
    assert_difference('Term.count') do
      post admin_taxonomy_terms_url(@tag_taxonomy), params: { 
        term: { 
          name: "Featured",
          slug: "featured-unique-2"
        } 
      }
    end

    assert_response :redirect
  end

  test "should get edit" do
    get edit_admin_taxonomy_term_url(@category_taxonomy, @uncategorized)
    assert_response :success
    assert_select 'form'
    assert_select "input[value=?]", @uncategorized.name
  end

  test "should update term" do
    patch admin_taxonomy_term_url(@category_taxonomy, @uncategorized), params: { 
      term: { 
        name: "Updated Name",
        description: "Updated description"
      } 
    }

    assert_redirected_to admin_taxonomy_term_url(@category_taxonomy, @uncategorized)
    @uncategorized.reload
    assert_equal "Updated Name", @uncategorized.name
  end

  test "should not update with invalid data" do
    patch admin_taxonomy_term_url(@category_taxonomy, @uncategorized), params: { 
      term: { 
        name: ""
      } 
    }

    assert_response :unprocessable_entity
  end

  test "should destroy term" do
    term = @category_taxonomy.terms.create!(name: "Delete Me", slug: "delete-me-term")
    
    assert_difference('Term.count', -1) do
      delete admin_taxonomy_term_url(@category_taxonomy, term)
    end

    assert_redirected_to admin_taxonomy_terms_url(@category_taxonomy)
  end

  test "should show parent select for hierarchical taxonomies" do
    get new_admin_taxonomy_term_url(@category_taxonomy)
    assert_response :success
    
    # Should show parent selector for hierarchical taxonomy
    assert_select 'select#term_parent_id'
  end

  test "should not show parent select for flat taxonomies" do
    get new_admin_taxonomy_term_url(@tag_taxonomy)
    assert_response :success
    
    # Should not show parent selector for flat taxonomy
    assert_select 'select#term_parent_id', count: 0
  end

  test "should update term count" do
    term = @category_taxonomy.terms.create!(name: "Test", slug: "test-count-update")
    
    patch admin_taxonomy_term_url(@category_taxonomy, term), params: { 
      term: { 
        count: 5
      } 
    }

    term.reload
    assert_equal 5, term.count
  end

  test "should show term usage in posts" do
    get admin_taxonomy_term_url(@category_taxonomy, @uncategorized)
    assert_response :success
    
    # Should show count of posts using this term
    assert_match /#{@uncategorized.count}/, response.body
  end

  test "should handle meta fields" do
    post admin_taxonomy_terms_url(@category_taxonomy), params: { 
      term: { 
        name: "Meta Test",
        slug: "meta-test",
        meta: { color: "blue", icon: "star" }
      } 
    }

    term = Term.last
    assert_equal "blue", term.meta["color"]
    assert_equal "star", term.meta["icon"]
  end

  test "should not allow non-admin to manage terms" do
    sign_out @admin
    editor = users(:editor)
    sign_in editor

    get admin_taxonomy_terms_url(@category_taxonomy)
    assert_response :redirect
  end

  test "should bulk delete terms" do
    term1 = @category_taxonomy.terms.create!(name: "Bulk 1", slug: "bulk-1")
    term2 = @category_taxonomy.terms.create!(name: "Bulk 2", slug: "bulk-2")
    
    assert_difference('Term.count', -2) do
      delete admin_taxonomy_bulk_delete_terms_url(@category_taxonomy), params: {
        term_ids: [term1.id, term2.id]
      }
    end
  end
end






