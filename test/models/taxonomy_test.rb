require "test_helper"

class TaxonomyTest < ActiveSupport::TestCase
  def setup
    @category_taxonomy = taxonomies(:category)
    @tag_taxonomy = taxonomies(:tag)
    @format_taxonomy = taxonomies(:post_format)
  end

  test "should be valid with valid attributes" do
    taxonomy = Taxonomy.new(
      name: "Test Taxonomy",
      slug: "test-taxonomy",
      hierarchical: false,
      object_types: ['Post']
    )
    assert taxonomy.valid?
  end

  test "should require name" do
    taxonomy = Taxonomy.new(slug: "test")
    assert_not taxonomy.valid?
    assert_includes taxonomy.errors[:name], "can't be blank"
  end

  test "should require slug" do
    taxonomy = Taxonomy.new(name: "Test")
    taxonomy.slug = nil
    assert_not taxonomy.valid?
    assert_includes taxonomy.errors[:slug], "can't be blank"
  end

  test "should require unique slug" do
    taxonomy = Taxonomy.new(
      name: "Duplicate",
      slug: @category_taxonomy.slug
    )
    assert_not taxonomy.valid?
    assert_includes taxonomy.errors[:slug], "has already been taken"
  end

  test "should have default values" do
    taxonomy = Taxonomy.new(name: "Test", slug: "test")
    assert_equal false, taxonomy.hierarchical
    assert_equal [], taxonomy.object_types
    assert_equal({}, taxonomy.settings)
  end

  test "should generate slug from name" do
    taxonomy = Taxonomy.create!(name: "My Custom Taxonomy")
    assert_equal "my-custom-taxonomy", taxonomy.slug
  end

  test "should have many terms" do
    assert_respond_to @category_taxonomy, :terms
    assert_equal 1, @category_taxonomy.terms.count
  end

  test "should delete terms when destroyed" do
    taxonomy = Taxonomy.create!(name: "Test", slug: "test-delete")
    term = taxonomy.terms.create!(name: "Test Term", slug: "test-term")
    
    assert_difference 'Term.count', -1 do
      taxonomy.destroy
    end
  end

  test "should return root terms" do
    parent = @category_taxonomy.terms.create!(name: "Parent", slug: "parent")
    child = @category_taxonomy.terms.create!(name: "Child", slug: "child", parent: parent)
    
    assert_includes @category_taxonomy.root_terms, parent
    assert_not_includes @category_taxonomy.root_terms, child
  end

  test "should count terms" do
    taxonomy = Taxonomy.create!(name: "Test", slug: "test-count")
    taxonomy.terms.create!(name: "Term 1", slug: "term-1")
    taxonomy.terms.create!(name: "Term 2", slug: "term-2")
    
    assert_equal 2, taxonomy.term_count
  end

  test "should check if applies to object type" do
    taxonomy = Taxonomy.create!(
      name: "Test",
      slug: "test-applies",
      object_types: ['Post', 'Page']
    )
    
    assert taxonomy.applies_to?('Post')
    assert taxonomy.applies_to?(:Page)
    assert_not taxonomy.applies_to?('User')
  end

  test "should find or create categories taxonomy" do
    taxonomy = Taxonomy.categories
    assert_equal 'category', taxonomy.slug
    assert taxonomy.hierarchical
    assert_includes taxonomy.object_types, 'Post'
  end

  test "should find or create tags taxonomy" do
    taxonomy = Taxonomy.tags
    assert_equal 'tag', taxonomy.slug
    assert_not taxonomy.hierarchical
    assert_includes taxonomy.object_types, 'Post'
  end

  test "should scope hierarchical taxonomies" do
    hierarchical = Taxonomy.hierarchical.pluck(:slug)
    assert_includes hierarchical, 'category'
    assert_not_includes hierarchical, 'tag'
  end

  test "should scope flat taxonomies" do
    flat = Taxonomy.flat.pluck(:slug)
    assert_includes flat, 'tag'
    assert_includes flat, 'post_format'
  end

  test "should scope for posts" do
    post_taxonomies = Taxonomy.for_posts.pluck(:slug)
    assert_includes post_taxonomies, 'category'
    assert_includes post_taxonomies, 'tag'
  end

  test "should have singular and plural names" do
    assert_equal 'Category', @category_taxonomy.singular_name
    assert_equal 'Categories', @category_taxonomy.plural_name
  end

  test "should serialize settings as JSON" do
    taxonomy = Taxonomy.create!(
      name: "Test",
      slug: "test-settings",
      settings: { 'show_in_menu' => true, 'color' => 'blue' }
    )
    
    taxonomy.reload
    assert_equal true, taxonomy.settings['show_in_menu']
    assert_equal 'blue', taxonomy.settings['color']
  end

  test "should serialize object_types as JSON array" do
    taxonomy = Taxonomy.create!(
      name: "Test",
      slug: "test-types",
      object_types: ['Post', 'Page', 'CustomPost']
    )
    
    taxonomy.reload
    assert_equal ['Post', 'Page', 'CustomPost'], taxonomy.object_types
  end
end




