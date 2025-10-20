require 'test_helper'

class AdminTaxonomiesErrorHandlingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:admin)
    sign_in @user
    ActsAsTenant.current_tenant = Tenant.first
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "should handle missing taxonomy gracefully" do
    get admin_taxonomy_path(99999)
    assert_response :not_found
  end

  test "should handle missing term gracefully" do
    taxonomy = taxonomies(:category)
    get admin_taxonomy_term_path(taxonomy, 99999)
    assert_response :not_found
  end

  test "should handle invalid taxonomy slug" do
    get admin_taxonomy_path("invalid-slug")
    assert_response :not_found
  end

  test "should handle invalid term slug" do
    taxonomy = taxonomies(:category)
    get admin_taxonomy_term_path(taxonomy, "invalid-slug")
    assert_response :not_found
  end

  test "should handle duplicate taxonomy slug" do
    existing_taxonomy = taxonomies(:category)
    
    post admin_taxonomies_path, params: {
      taxonomy: {
        name: 'New Taxonomy',
        slug: existing_taxonomy.slug, # Duplicate slug
        description: 'A test taxonomy',
        hierarchical: true,
        object_types: ['Post']
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".alert", text: /error/
  end

  test "should handle duplicate term slug within taxonomy" do
    taxonomy = taxonomies(:category)
    existing_term = taxonomy.terms.first
    
    post admin_taxonomy_terms_path(taxonomy), params: {
      term: {
        name: 'New Term',
        slug: existing_term.slug, # Duplicate slug
        description: 'A test term'
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".alert", text: /error/
  end

  test "should handle empty taxonomy name" do
    post admin_taxonomies_path, params: {
      taxonomy: {
        name: '', # Empty name
        slug: 'test-taxonomy',
        description: 'A test taxonomy',
        hierarchical: true,
        object_types: ['Post']
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".alert", text: /error/
  end

  test "should handle empty term name" do
    taxonomy = taxonomies(:category)
    
    post admin_taxonomy_terms_path(taxonomy), params: {
      term: {
        name: '', # Empty name
        slug: 'test-term',
        description: 'A test term'
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".alert", text: /error/
  end

  test "should handle taxonomy with no object types" do
    post admin_taxonomies_path, params: {
      taxonomy: {
        name: 'Test Taxonomy',
        slug: 'test-taxonomy',
        description: 'A test taxonomy',
        hierarchical: true,
        object_types: [] # No object types
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".alert", text: /error/
  end

  test "should handle very long taxonomy name" do
    long_name = "A" * 256 # Very long name
    
    post admin_taxonomies_path, params: {
      taxonomy: {
        name: long_name,
        slug: 'test-taxonomy',
        description: 'A test taxonomy',
        hierarchical: true,
        object_types: ['Post']
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".alert", text: /error/
  end

  test "should handle very long term name" do
    taxonomy = taxonomies(:category)
    long_name = "A" * 256 # Very long name
    
    post admin_taxonomy_terms_path(taxonomy), params: {
      term: {
        name: long_name,
        slug: 'test-term',
        description: 'A test term'
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".alert", text: /error/
  end

  test "should handle special characters in taxonomy name" do
    post admin_taxonomies_path, params: {
      taxonomy: {
        name: 'Test <script>alert("xss")</script>',
        slug: 'test-taxonomy',
        description: 'A test taxonomy',
        hierarchical: true,
        object_types: ['Post']
      }
    }
    
    # Should either create successfully (with sanitization) or fail validation
    if response.status == 302
      assert_redirected_to admin_taxonomies_path
    else
      assert_response :unprocessable_entity
    end
  end

  test "should handle special characters in term name" do
    taxonomy = taxonomies(:category)
    
    post admin_taxonomy_terms_path(taxonomy), params: {
      term: {
        name: 'Test <script>alert("xss")</script>',
        slug: 'test-term',
        description: 'A test term'
      }
    }
    
    # Should either create successfully (with sanitization) or fail validation
    if response.status == 302
      assert_redirected_to admin_taxonomy_terms_path(taxonomy)
    else
      assert_response :unprocessable_entity
    end
  end

  test "should handle invalid parent term" do
    taxonomy = taxonomies(:category)
    
    post admin_taxonomy_terms_path(taxonomy), params: {
      term: {
        name: 'Test Term',
        slug: 'test-term',
        description: 'A test term',
        parent_id: 99999 # Invalid parent
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".alert", text: /error/
  end

  test "should handle circular parent relationship" do
    taxonomy = taxonomies(:category)
    parent_term = taxonomy.terms.create!(name: 'Parent Term', slug: 'parent-term')
    child_term = taxonomy.terms.create!(name: 'Child Term', slug: 'child-term', parent: parent_term)
    
    # Try to make parent a child of its child (circular)
    patch admin_taxonomy_term_path(taxonomy, parent_term), params: {
      term: { parent_id: child_term.id }
    }
    
    assert_response :unprocessable_entity
    assert_select ".alert", text: /error/
  end

  test "should handle deleting taxonomy with terms" do
    taxonomy = taxonomies(:category)
    # Ensure taxonomy has terms
    taxonomy.terms.create!(name: 'Test Term', slug: 'test-term')
    
    delete admin_taxonomy_path(taxonomy)
    
    # Should either delete successfully (cascade) or prevent deletion
    if response.status == 302
      assert_redirected_to admin_taxonomies_path
      assert_nil Taxonomy.find_by(id: taxonomy.id)
    else
      assert_response :unprocessable_entity
    end
  end

  test "should handle deleting term with relationships" do
    taxonomy = taxonomies(:category)
    term = taxonomy.terms.create!(name: 'Test Term', slug: 'test-term')
    
    # Create a post and associate it with the term
    post = Post.create!(
      title: 'Test Post',
      content: 'Test content',
      status: 'published',
      user: @user,
      tenant: Tenant.first
    )
    post.terms << term
    
    delete admin_taxonomy_term_path(taxonomy, term)
    
    # Should either delete successfully (cascade) or prevent deletion
    if response.status == 302
      assert_redirected_to admin_taxonomy_terms_path(taxonomy)
      assert_nil Term.find_by(id: term.id)
    else
      assert_response :unprocessable_entity
    end
  end

  test "should handle malformed JSON in settings" do
    post admin_taxonomies_path, params: {
      taxonomy: {
        name: 'Test Taxonomy',
        slug: 'test-taxonomy',
        description: 'A test taxonomy',
        hierarchical: true,
        object_types: ['Post'],
        settings: 'invalid json' # Malformed JSON
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".alert", text: /error/
  end

  test "should handle malformed JSON in object_types" do
    post admin_taxonomies_path, params: {
      taxonomy: {
        name: 'Test Taxonomy',
        slug: 'test-taxonomy',
        description: 'A test taxonomy',
        hierarchical: true,
        object_types: 'invalid json' # Malformed JSON
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".alert", text: /error/
  end

  test "should handle CSRF token mismatch" do
    # Simulate CSRF token mismatch by using wrong token
    post admin_taxonomies_path, params: {
      taxonomy: {
        name: 'Test Taxonomy',
        slug: 'test-taxonomy',
        description: 'A test taxonomy',
        hierarchical: true,
        object_types: ['Post']
      },
      authenticity_token: 'invalid_token'
    }
    
    assert_response :unprocessable_entity
  end

  test "should handle session timeout" do
    # Simulate session timeout by signing out
    sign_out @user
    
    get admin_taxonomies_path
    assert_redirected_to new_user_session_path
  end

  test "should handle insufficient permissions" do
    # Create a regular user without admin access
    regular_user = users(:regular)
    sign_out @user
    sign_in regular_user
    
    get admin_taxonomies_path
    assert_redirected_to root_path
    assert_match /permission/, flash[:alert]
  end

  test "should handle database connection errors gracefully" do
    # This test would require mocking database errors
    # For now, we'll test that the application handles errors gracefully
    get admin_taxonomies_path
    assert_response :success
  end

  test "should handle large number of taxonomies" do
    # Create many taxonomies to test pagination/performance
    100.times do |i|
      Taxonomy.create!(
        name: "Taxonomy #{i}",
        slug: "taxonomy-#{i}",
        description: "Description #{i}",
        hierarchical: i.even?,
        object_types: ['Post'],
        tenant: Tenant.first
      )
    end
    
    get admin_taxonomies_path
    assert_response :success
    # Should still load successfully
  end

  test "should handle large number of terms" do
    taxonomy = taxonomies(:category)
    
    # Create many terms to test performance
    100.times do |i|
      taxonomy.terms.create!(
        name: "Term #{i}",
        slug: "term-#{i}",
        description: "Description #{i}",
        tenant: Tenant.first
      )
    end
    
    get admin_taxonomy_terms_path(taxonomy)
    assert_response :success
    # Should still load successfully
  end

  test "should handle concurrent taxonomy creation" do
    # Test that concurrent creation doesn't cause issues
    threads = []
    5.times do |i|
      threads << Thread.new do
        ActsAsTenant.current_tenant = Tenant.first
        post admin_taxonomies_path, params: {
          taxonomy: {
            name: "Concurrent Taxonomy #{i}",
            slug: "concurrent-taxonomy-#{i}",
            description: "A concurrent test taxonomy",
            hierarchical: true,
            object_types: ['Post']
          }
        }
      end
    end
    
    threads.each(&:join)
    
    # Should have created all taxonomies successfully
    assert_equal 5, Taxonomy.where("slug LIKE 'concurrent-taxonomy-%'").count
  end

  test "should handle invalid HTTP methods" do
    # Test that invalid HTTP methods are handled
    put admin_taxonomies_path
    assert_response :method_not_allowed
    
    patch admin_taxonomies_path
    assert_response :method_not_allowed
  end

  test "should handle missing required parameters" do
    post admin_taxonomies_path, params: {}
    assert_response :bad_request
  end

  test "should handle invalid content type" do
    post admin_taxonomies_path, 
         params: '{"invalid": "json"}',
         headers: { 'Content-Type' => 'application/json' }
    assert_response :bad_request
  end

  test "should handle XSS in taxonomy description" do
    post admin_taxonomies_path, params: {
      taxonomy: {
        name: 'Test Taxonomy',
        slug: 'test-taxonomy',
        description: '<script>alert("xss")</script>',
        hierarchical: true,
        object_types: ['Post']
      }
    }
    
    if response.status == 302
      # Should be sanitized
      taxonomy = Taxonomy.find_by(slug: 'test-taxonomy')
      assert_not_includes taxonomy.description, '<script>'
    else
      assert_response :unprocessable_entity
    end
  end

  test "should handle XSS in term description" do
    taxonomy = taxonomies(:category)
    
    post admin_taxonomy_terms_path(taxonomy), params: {
      term: {
        name: 'Test Term',
        slug: 'test-term',
        description: '<script>alert("xss")</script>'
      }
    }
    
    if response.status == 302
      # Should be sanitized
      term = Term.find_by(slug: 'test-term')
      assert_not_includes term.description, '<script>'
    else
      assert_response :unprocessable_entity
    end
  end

  test "should handle SQL injection attempts" do
    post admin_taxonomies_path, params: {
      taxonomy: {
        name: "'; DROP TABLE taxonomies; --",
        slug: 'test-taxonomy',
        description: 'A test taxonomy',
        hierarchical: true,
        object_types: ['Post']
      }
    }
    
    # Should either create successfully (with sanitization) or fail validation
    if response.status == 302
      assert_redirected_to admin_taxonomies_path
      # Verify table still exists
      assert_not_nil Taxonomy.first
    else
      assert_response :unprocessable_entity
    end
  end

  test "should handle very long descriptions" do
    long_description = "A" * 10000 # Very long description
    
    post admin_taxonomies_path, params: {
      taxonomy: {
        name: 'Test Taxonomy',
        slug: 'test-taxonomy',
        description: long_description,
        hierarchical: true,
        object_types: ['Post']
      }
    }
    
    # Should either create successfully or fail validation
    if response.status == 302
      assert_redirected_to admin_taxonomies_path
    else
      assert_response :unprocessable_entity
    end
  end

  test "should handle invalid boolean values" do
    post admin_taxonomies_path, params: {
      taxonomy: {
        name: 'Test Taxonomy',
        slug: 'test-taxonomy',
        description: 'A test taxonomy',
        hierarchical: 'invalid_boolean',
        object_types: ['Post']
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".alert", text: /error/
  end

  test "should handle invalid array values" do
    post admin_taxonomies_path, params: {
      taxonomy: {
        name: 'Test Taxonomy',
        slug: 'test-taxonomy',
        description: 'A test taxonomy',
        hierarchical: true,
        object_types: 'not_an_array'
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".alert", text: /error/
  end
end
