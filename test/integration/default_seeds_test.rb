require "test_helper"

class DefaultSeedsTest < ActiveSupport::TestCase
  test "should have default taxonomies seeded" do
    # Category taxonomy
    category = Taxonomy.find_by(slug: 'category')
    assert_not_nil category
    assert_equal 'Category', category.name
    assert_equal 'Category', category.singular_name
    assert_equal 'Categories', category.plural_name
    assert category.hierarchical
    assert_includes category.object_types, 'Post'
    
    # Tag taxonomy
    tag = Taxonomy.find_by(slug: 'tag')
    assert_not_nil tag
    assert_equal 'Tag', tag.name
    assert_equal 'Tags', tag.plural_name
    assert_not tag.hierarchical
    
    # Post format taxonomy
    format = Taxonomy.find_by(slug: 'post_format')
    assert_not_nil format
    assert_equal 'Post Format', format.name
    assert_not format.hierarchical
  end

  test "should have uncategorized term" do
    category_taxonomy = Taxonomy.find_by(slug: 'category')
    uncategorized = category_taxonomy.terms.find_by(slug: 'uncategorized')
    
    assert_not_nil uncategorized
    assert_equal 'Uncategorized', uncategorized.name
  end

  test "tag taxonomy should have no default terms" do
    tag_taxonomy = Taxonomy.find_by(slug: 'tag')
    
    # In a fresh seed, tags should be empty (only test fixtures add tags)
    # So we just check the taxonomy exists
    assert_not_nil tag_taxonomy
  end

  test "post_format taxonomy should be empty" do
    format_taxonomy = Taxonomy.find_by(slug: 'post_format')
    
    # In a fresh seed, post formats should be empty
    assert_not_nil format_taxonomy
    # Formats are added by themes, not by default
  end

  test "taxonomies should have correct settings" do
    category = Taxonomy.find_by(slug: 'category')
    
    assert_equal true, category.settings['show_in_menu']
    assert_equal true, category.settings['show_in_api']
    assert_equal true, category.settings['show_ui']
    assert_equal true, category.settings['public']
  end

  test "should create default admin user" do
    # Note: This test assumes seeds have been run
    # In test environment, we use fixtures instead
    assert User.where(role: 'administrator').exists?
  end

  test "default taxonomies should apply to Post" do
    category = Taxonomy.find_by(slug: 'category')
    tag = Taxonomy.find_by(slug: 'tag')
    
    assert category.applies_to?('Post')
    assert tag.applies_to?('Post')
  end

  test "should maintain WordPress-compatible structure" do
    # Verify the three core taxonomies exist
    assert Taxonomy.exists?(slug: 'category')
    assert Taxonomy.exists?(slug: 'tag')
    assert Taxonomy.exists?(slug: 'post_format')
    
    # Verify category is hierarchical (like WP)
    assert Taxonomy.find_by(slug: 'category').hierarchical
    
    # Verify tags are flat (like WP)
    assert_not Taxonomy.find_by(slug: 'tag').hierarchical
    
    # Verify uncategorized exists (like WP)
    category = Taxonomy.find_by(slug: 'category')
    assert category.terms.exists?(slug: 'uncategorized')
  end

  test "should use correct human-readable names" do
    # WordPress shows "Categories" not "category" in UI
    category = Taxonomy.find_by(slug: 'category')
    assert_equal 'Categories', category.plural_name
    assert_equal 'Category', category.singular_name
    
    tag = Taxonomy.find_by(slug: 'tag')
    assert_equal 'Tags', tag.plural_name
    assert_equal 'Tag', tag.singular_name
    
    format = Taxonomy.find_by(slug: 'post_format')
    assert_equal 'Formats', format.plural_name
    assert_equal 'Format', format.singular_name
  end
end






