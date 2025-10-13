require "test_helper"

class TermTest < ActiveSupport::TestCase
  def setup
    @category_taxonomy = taxonomies(:category)
    @tag_taxonomy = taxonomies(:tag)
    @uncategorized = terms(:uncategorized)
  end

  test "should be valid with valid attributes" do
    term = Term.new(
      taxonomy: @category_taxonomy,
      name: "Test Term",
      slug: "test-term"
    )
    assert term.valid?
  end

  test "should require name" do
    term = Term.new(taxonomy: @category_taxonomy, slug: "test")
    assert_not term.valid?
    assert_includes term.errors[:name], "can't be blank"
  end

  test "should require slug" do
    term = Term.new(taxonomy: @category_taxonomy, name: "Test")
    term.slug = nil
    assert_not term.valid?
    assert_includes term.errors[:slug], "can't be blank"
  end

  test "should require taxonomy" do
    term = Term.new(name: "Test", slug: "test")
    assert_not term.valid?
    assert_includes term.errors[:taxonomy], "must exist"
  end

  test "should require unique slug within taxonomy" do
    term = Term.new(
      taxonomy: @category_taxonomy,
      name: "Duplicate",
      slug: @uncategorized.slug
    )
    assert_not term.valid?
  end

  test "should allow same slug in different taxonomies" do
    term1 = @category_taxonomy.terms.create!(name: "Featured", slug: "featured")
    term2 = @tag_taxonomy.terms.create!(name: "Featured", slug: "featured")
    
    assert term1.valid?
    assert term2.valid?
  end

  test "should generate slug from name" do
    term = @category_taxonomy.terms.create!(name: "My Test Category")
    assert_equal "my-test-category", term.slug
  end

  test "should belong to taxonomy" do
    assert_equal @category_taxonomy, @uncategorized.taxonomy
  end

  test "should have parent-child relationships" do
    parent = @category_taxonomy.terms.create!(name: "Parent", slug: "parent")
    child = @category_taxonomy.terms.create!(name: "Child", slug: "child", parent: parent)
    
    assert_equal parent, child.parent
    assert_includes parent.children, child
  end

  test "should delete children when parent destroyed" do
    parent = @category_taxonomy.terms.create!(name: "Parent", slug: "parent-del")
    child = @category_taxonomy.terms.create!(name: "Child", slug: "child-del", parent: parent)
    
    assert_difference 'Term.count', -2 do
      parent.destroy
    end
  end

  test "should have term relationships" do
    assert_respond_to @uncategorized, :term_relationships
  end

  test "should count posts through term relationships" do
    term = @category_taxonomy.terms.create!(name: "Test", slug: "test-count")
    post = Post.create!(
      title: "Test Post",
      content: "Content",
      slug: "test-post",
      user: users(:admin),
      status: 'published'
    )
    term.term_relationships.create!(taggable: post)
    
    assert_equal 1, term.term_relationships.count
  end

  test "should scope by taxonomy" do
    category_terms = Term.by_taxonomy('category')
    tag_terms = Term.by_taxonomy('tag')
    
    assert_includes category_terms, @uncategorized
    assert_not_includes tag_terms, @uncategorized
  end

  test "should scope root terms" do
    parent = @category_taxonomy.terms.create!(name: "Parent", slug: "parent-root")
    child = @category_taxonomy.terms.create!(name: "Child", slug: "child-root", parent: parent)
    
    roots = Term.root
    assert_includes roots, parent
    assert_not_includes roots, child
  end

  test "should order by name" do
    @category_taxonomy.terms.create!(name: "Zebra", slug: "zebra")
    @category_taxonomy.terms.create!(name: "Apple", slug: "apple")
    
    ordered = @category_taxonomy.terms.ordered
    assert_equal "Apple", ordered.first.name
  end

  test "should have default count of 0" do
    term = Term.new(name: "Test", slug: "test", taxonomy: @category_taxonomy)
    assert_equal 0, term.count
  end

  test "should allow description" do
    term = @category_taxonomy.terms.create!(
      name: "Test",
      slug: "test-desc",
      description: "This is a test category"
    )
    
    assert_equal "This is a test category", term.description
  end

  test "should have meta fields as JSON" do
    term = @category_taxonomy.terms.create!(
      name: "Test",
      slug: "test-meta",
      meta: { 'color' => 'blue', 'icon' => 'star' }
    )
    
    term.reload
    assert_equal 'blue', term.meta['color']
    assert_equal 'star', term.meta['icon']
  end

  test "should check if hierarchical through taxonomy" do
    category_term = @category_taxonomy.terms.create!(name: "Cat", slug: "cat")
    tag_term = @tag_taxonomy.terms.create!(name: "Tag", slug: "tag-test")
    
    assert category_term.taxonomy.hierarchical
    assert_not tag_term.taxonomy.hierarchical
  end
end




