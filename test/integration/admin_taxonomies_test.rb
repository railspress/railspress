require 'test_helper'

class AdminTaxonomiesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:admin)
    sign_in @user
    ActsAsTenant.current_tenant = Tenant.first
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "should get taxonomies index" do
    get admin_taxonomies_path
    assert_response :success
    assert_select "h1", text: /Custom Taxonomies/
    assert_select ".bg-\\[#1a1a1a\\]", minimum: 1 # Stats cards
    assert_select "a[href='#{new_admin_taxonomy_path}']", text: /New Taxonomy/
  end

  test "should display taxonomy stats correctly" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check stats cards are present
    assert_select ".bg-\\[#1a1a1a\\].border.border-\\[#2a2a2a\\].rounded-xl.p-6", minimum: 4
    
    # Check specific stats
    assert_select "p", text: /Total Taxonomies/
    assert_select "p", text: /Total Terms/
    assert_select "p", text: /Hierarchical/
    assert_select "p", text: /Flat/
  end

  test "should get new taxonomy form" do
    get new_admin_taxonomy_path
    assert_response :success
    assert_select "h1", text: /Create New Taxonomy/
    assert_select "form[action='#{admin_taxonomies_path}']"
    assert_select "input[name='taxonomy[name]']"
    assert_select "input[name='taxonomy[slug]']"
    assert_select "textarea[name='taxonomy[description]']"
    assert_select "input[name='taxonomy[hierarchical]']"
    assert_select "input[name='taxonomy[object_types][]']", minimum: 2
  end

  test "should create taxonomy with valid attributes" do
    assert_difference('Taxonomy.count') do
      post admin_taxonomies_path, params: {
        taxonomy: {
          name: 'Test Taxonomy',
          slug: 'test-taxonomy',
          description: 'A test taxonomy',
          hierarchical: true,
          object_types: ['Post']
        }
      }
    end
    
    assert_redirected_to admin_taxonomies_path
    follow_redirect!
    assert_select ".alert", text: /successfully created/
    
    taxonomy = Taxonomy.find_by(slug: 'test-taxonomy')
    assert_not_nil taxonomy
    assert_equal 'Test Taxonomy', taxonomy.name
    assert_equal 'A test taxonomy', taxonomy.description
    assert taxonomy.hierarchical?
    assert_includes taxonomy.object_types, 'Post'
  end

  test "should not create taxonomy with invalid attributes" do
    assert_no_difference('Taxonomy.count') do
      post admin_taxonomies_path, params: {
        taxonomy: {
          name: '', # Invalid: empty name
          slug: 'test-taxonomy',
          description: 'A test taxonomy',
          hierarchical: true,
          object_types: ['Post']
        }
      }
    end
    
    assert_response :unprocessable_entity
    assert_select ".alert", text: /error/
  end

  test "should show taxonomy" do
    taxonomy = taxonomies(:category)
    get admin_taxonomy_path(taxonomy)
    assert_response :success
    assert_select "h1", text: /#{taxonomy.name}/
  end

  test "should get edit taxonomy form" do
    taxonomy = taxonomies(:category)
    get edit_admin_taxonomy_path(taxonomy)
    assert_response :success
    assert_select "h1", text: /Edit/
    assert_select "form[action='#{admin_taxonomy_path(taxonomy)}']"
    assert_select "input[name='taxonomy[name]'][value='#{taxonomy.name}']"
  end

  test "should update taxonomy" do
    taxonomy = taxonomies(:category)
    patch admin_taxonomy_path(taxonomy), params: {
      taxonomy: { name: 'Updated Name' }
    }
    assert_redirected_to admin_taxonomy_path(taxonomy)
    taxonomy.reload
    assert_equal 'Updated Name', taxonomy.name
  end

  test "should destroy taxonomy" do
    taxonomy = taxonomies(:category)
    assert_difference('Taxonomy.count', -1) do
      delete admin_taxonomy_path(taxonomy)
    end
    assert_redirected_to admin_taxonomies_path
  end

  test "should get taxonomy terms" do
    taxonomy = taxonomies(:category)
    get admin_taxonomy_terms_path(taxonomy)
    assert_response :success
    assert_select "h1", text: /Manage #{taxonomy.name}/
    assert_select "form[action='#{admin_taxonomy_terms_path(taxonomy)}']"
  end

  test "should create term" do
    taxonomy = taxonomies(:category)
    assert_difference('Term.count') do
      post admin_taxonomy_terms_path(taxonomy), params: {
        term: {
          name: 'Test Term',
          slug: 'test-term',
          description: 'A test term'
        }
      }
    end
    
    assert_redirected_to admin_taxonomy_terms_path(taxonomy)
    follow_redirect!
    assert_select ".alert", text: /successfully created/
  end

  test "should update term" do
    taxonomy = taxonomies(:category)
    term = taxonomy.terms.first
    patch admin_taxonomy_term_path(taxonomy, term), params: {
      term: { name: 'Updated Term Name' }
    }
    assert_redirected_to admin_taxonomy_terms_path(taxonomy)
    term.reload
    assert_equal 'Updated Term Name', term.name
  end

  test "should destroy term" do
    taxonomy = taxonomies(:category)
    term = taxonomy.terms.first
    assert_difference('Term.count', -1) do
      delete admin_taxonomy_term_path(taxonomy, term)
    end
    assert_redirected_to admin_taxonomy_terms_path(taxonomy)
  end

  test "should require authentication" do
    sign_out @user
    get admin_taxonomies_path
    assert_redirected_to new_user_session_path
  end

  test "should require admin access" do
    sign_out @user
    @regular_user = users(:regular)
    sign_in @regular_user
    
    get admin_taxonomies_path
    assert_redirected_to root_path
    assert_match /permission/, flash[:alert]
  end

  test "should display hierarchical taxonomy correctly" do
    taxonomy = taxonomies(:category)
    get admin_taxonomies_path
    assert_response :success
    
    # Check hierarchical badge
    assert_select "span", text: /Hierarchical/
  end

  test "should display flat taxonomy correctly" do
    taxonomy = taxonomies(:post_tag)
    get admin_taxonomies_path
    assert_response :success
    
    # Check flat badge
    assert_select "span", text: /Flat/
  end

  test "should show empty state when no taxonomies" do
    Taxonomy.destroy_all
    get admin_taxonomies_path
    assert_response :success
    assert_select "h3", text: /No Custom Taxonomies/
    assert_select "a[href='#{new_admin_taxonomy_path}']", text: /Create Your First Taxonomy/
  end

  test "should handle hierarchical terms correctly" do
    taxonomy = taxonomies(:category)
    parent_term = taxonomy.terms.create!(name: 'Parent Term', slug: 'parent-term')
    child_term = taxonomy.terms.create!(name: 'Child Term', slug: 'child-term', parent: parent_term)
    
    get admin_taxonomy_terms_path(taxonomy)
    assert_response :success
    
    # Check parent selection in form
    assert_select "select[name='term[parent_id]'] option[value='#{parent_term.id}']"
  end

  test "should handle flat taxonomy terms correctly" do
    taxonomy = taxonomies(:post_tag)
    get admin_taxonomy_terms_path(taxonomy)
    assert_response :success
    
    # Should not have parent selection for flat taxonomies
    assert_select "select[name='term[parent_id]']", count: 0
  end

  test "should display term count correctly" do
    taxonomy = taxonomies(:category)
    get admin_taxonomies_path
    assert_response :success
    
    # Check term count is displayed
    assert_select "span", text: /#{taxonomy.term_count} terms/
  end

  test "should display object types correctly" do
    taxonomy = taxonomies(:category)
    get admin_taxonomies_path
    assert_response :success
    
    # Check object types are displayed
    assert_select "span", text: /#{taxonomy.object_types.join(', ')}/
  end

  test "should handle CSRF protection" do
    # Test that forms include CSRF token
    get new_admin_taxonomy_path
    assert_response :success
    assert_select "input[name='authenticity_token']"
  end

  test "should handle pagination if many taxonomies" do
    # Create many taxonomies to test pagination
    25.times do |i|
      Taxonomy.create!(
        name: "Taxonomy #{i}",
        slug: "taxonomy-#{i}",
        description: "Description #{i}",
        hierarchical: i.even?,
        object_types: ['Post']
      )
    end
    
    get admin_taxonomies_path
    assert_response :success
    # Should display taxonomies in grid format
    assert_select ".grid.grid-cols-1.md\\:grid-cols-2.lg\\:grid-cols-3"
  end

  test "should handle search functionality" do
    get admin_taxonomy_terms_path(taxonomies(:category))
    assert_response :success
    
    # Check search input is present
    assert_select "input[id='search-terms']"
  end

  test "should handle JavaScript table functionality" do
    get admin_taxonomy_terms_path(taxonomies(:category))
    assert_response :success
    
    # Check Tabulator table container
    assert_select "div[id='terms-table']"
    
    # Check JavaScript is loaded
    assert_select "script", text: /Tabulator/
  end

  test "should handle responsive design" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check responsive classes
    assert_select ".grid.grid-cols-1.md\\:grid-cols-2.lg\\:grid-cols-3"
    assert_select ".max-w-7xl.mx-auto"
  end

  test "should handle dark theme correctly" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check dark theme classes
    assert_select ".bg-\\[#1a1a1a\\]"
    assert_select ".text-white"
    assert_select ".border-\\[#2a2a2a\\]"
  end

  test "should handle form validation errors" do
    post admin_taxonomies_path, params: {
      taxonomy: {
        name: '', # Invalid
        slug: 'test',
        description: 'Test',
        hierarchical: true,
        object_types: ['Post']
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".alert", text: /error/
  end

  test "should handle term form validation errors" do
    taxonomy = taxonomies(:category)
    post admin_taxonomy_terms_path(taxonomy), params: {
      term: {
        name: '', # Invalid
        slug: 'test',
        description: 'Test'
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".alert", text: /error/
  end

  test "should handle friendly URLs" do
    taxonomy = taxonomies(:category)
    get admin_taxonomy_path(taxonomy.slug)
    assert_response :success
  end

  test "should handle term friendly URLs" do
    taxonomy = taxonomies(:category)
    term = taxonomy.terms.first
    get edit_admin_taxonomy_term_path(taxonomy, term.slug)
    assert_response :success
  end
end
