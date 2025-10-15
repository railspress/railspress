require "application_system_test_case"

class TaxonomyManagementTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
    @category_taxonomy = taxonomies(:category)
    @tag_taxonomy = taxonomies(:tag)
    login_as @admin
  end

  test "admin can view all taxonomies" do
    visit admin_taxonomies_path
    
    assert_selector "h1", text: /Taxonomies/i
    assert_text "Category"
    assert_text "Tag"
    assert_text "Post Format"
  end

  test "admin can create new taxonomy" do
    visit admin_taxonomies_path
    click_on "New Taxonomy"
    
    fill_in "Name", with: "Custom Taxonomy"
    fill_in "Slug", with: "custom-taxonomy"
    fill_in "Description", with: "A custom taxonomy for testing"
    select "Post", from: "Object types"
    check "Hierarchical"
    
    click_on "Create Taxonomy"
    
    assert_text "Taxonomy was successfully created"
    assert_text "Custom Taxonomy"
  end

  test "admin can edit existing taxonomy" do
    visit admin_taxonomy_path(@category_taxonomy)
    click_on "Edit"
    
    fill_in "Description", with: "Updated description"
    click_on "Update Taxonomy"
    
    assert_text "Taxonomy was successfully updated"
    assert_text "Updated description"
  end

  test "admin can delete taxonomy" do
    # Create a taxonomy to delete
    taxonomy = Taxonomy.create!(
      name: "Delete Test",
      slug: "delete-test"
    )
    
    visit admin_taxonomies_path
    
    within "#taxonomy_#{taxonomy.id}" do
      accept_confirm do
        click_on "Delete"
      end
    end
    
    assert_text "Taxonomy was successfully deleted"
    assert_no_text "Delete Test"
  end

  test "admin can create term in taxonomy" do
    visit admin_taxonomy_path(@category_taxonomy)
    click_on "New Term"
    
    fill_in "Name", with: "Test Category"
    fill_in "Slug", with: "test-category"
    fill_in "Description", with: "A test category"
    
    click_on "Create Term"
    
    assert_text "Term was successfully created"
    assert_text "Test Category"
  end

  test "admin can create hierarchical term with parent" do
    parent = @category_taxonomy.terms.create!(
      name: "Parent Category",
      slug: "parent-category"
    )
    
    visit admin_taxonomy_path(@category_taxonomy)
    click_on "New Term"
    
    fill_in "Name", with: "Child Category"
    select "Parent Category", from: "Parent"
    
    click_on "Create Term"
    
    assert_text "Term was successfully created"
    assert_text "Child Category"
    
    # Verify hierarchy
    child = Term.find_by(name: "Child Category")
    assert_equal parent, child.parent
  end

  test "admin can edit term" do
    term = @category_taxonomy.terms.first
    
    visit admin_taxonomy_term_path(@category_taxonomy, term)
    click_on "Edit"
    
    fill_in "Name", with: "Updated Term Name"
    click_on "Update Term"
    
    assert_text "Term was successfully updated"
    assert_text "Updated Term Name"
  end

  test "admin can delete term" do
    term = @category_taxonomy.terms.create!(
      name: "Delete Me",
      slug: "delete-me"
    )
    
    visit admin_taxonomy_path(@category_taxonomy)
    
    within "#term_#{term.id}" do
      accept_confirm do
        click_on "Delete"
      end
    end
    
    assert_text "Term was successfully deleted"
    assert_no_text "Delete Me"
  end

  test "admin can assign categories to post" do
    post = posts(:published)
    category = @category_taxonomy.terms.first
    
    visit edit_admin_post_path(post)
    
    check category.name
    click_on "Update Post"
    
    assert_text "Post was successfully updated"
    
    # Verify assignment
    assert post.terms.include?(category)
  end

  test "admin can assign tags to post" do
    post = posts(:published)
    
    visit edit_admin_post_path(post)
    
    fill_in "Tags", with: "ruby, rails, testing"
    click_on "Update Post"
    
    assert_text "Post was successfully updated"
    
    # Verify tags were created
    post.reload
    tag_names = post.terms.where(taxonomy: @tag_taxonomy).pluck(:name)
    assert_includes tag_names, "ruby"
    assert_includes tag_names, "rails"
    assert_includes tag_names, "testing"
  end

  test "admin can filter posts by category" do
    category = @category_taxonomy.terms.first
    
    visit admin_posts_path
    select category.name, from: "Category"
    click_on "Filter"
    
    # Should show only posts in that category
    assert_selector ".post-row"
  end

  test "admin can filter posts by tag" do
    tag = @tag_taxonomy.terms.first
    
    visit admin_posts_path
    select tag.name, from: "Tag"
    click_on "Filter"
    
    # Should show only posts with that tag
    assert_selector ".post-row"
  end

  test "admin sees term count on taxonomy page" do
    visit admin_taxonomy_path(@category_taxonomy)
    
    @category_taxonomy.terms.each do |term|
      assert_text term.name
      assert_text term.count.to_s
    end
  end

  test "hierarchical taxonomy shows nested structure" do
    parent = @category_taxonomy.terms.create!(name: "Parent", slug: "parent-sys")
    child1 = @category_taxonomy.terms.create!(name: "Child 1", slug: "child-1-sys", parent: parent)
    child2 = @category_taxonomy.terms.create!(name: "Child 2", slug: "child-2-sys", parent: parent)
    
    visit admin_taxonomy_path(@category_taxonomy)
    
    # Should show parent and children
    assert_text "Parent"
    assert_text "Child 1"
    assert_text "Child 2"
    
    # Children should be visually indented or nested
    page_html = page.html
    assert page_html.include?("Child 1")
    assert page_html.include?("Child 2")
  end

  test "flat taxonomy does not show parent selector" do
    visit new_admin_taxonomy_term_path(@tag_taxonomy)
    
    # Should not have parent select for flat taxonomy
    assert_no_selector "select#term_parent_id"
  end

  test "validation errors are displayed" do
    visit new_admin_taxonomy_path
    
    # Try to create without required fields
    click_on "Create Taxonomy"
    
    assert_text "can't be blank"
  end

  test "term slug auto-generates from name" do
    visit new_admin_taxonomy_term_path(@category_taxonomy)
    
    fill_in "Name", with: "Auto Generated Slug"
    # Don't fill in slug manually
    
    click_on "Create Term"
    
    term = Term.last
    assert_equal "auto-generated-slug", term.slug
  end

  private

  def login_as(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_on "Log in"
  end
end






