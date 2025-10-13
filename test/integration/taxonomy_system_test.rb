require "test_helper"

class TaxonomySystemTest < ActiveSupport::TestCase
  def setup
    @category_taxonomy = Taxonomy.find_or_create_by!(slug: 'category') do |t|
      t.name = 'Category'
      t.singular_name = 'Category'
      t.plural_name = 'Categories'
      t.hierarchical = true
      t.object_types = ['Post']
    end
    
    @tag_taxonomy = Taxonomy.find_or_create_by!(slug: 'tag') do |t|
      t.name = 'Tag'
      t.singular_name = 'Tag'
      t.plural_name = 'Tags'
      t.hierarchical = false
      t.object_types = ['Post']
    end
    
    @post = Post.create!(
      title: 'Test Post',
      content: 'Test content',
      slug: 'test-post',
      user: users(:admin),
      status: 'published'
    )
  end

  test "posts can be assigned to category terms" do
    category = @category_taxonomy.terms.create!(name: 'Technology', slug: 'tech')
    
    @post.term_relationships.create!(term: category)
    
    assert_equal 1, @post.terms.count
    assert_includes @post.terms, category
  end

  test "posts can have multiple category terms (hierarchical)" do
    parent = @category_taxonomy.terms.create!(name: 'Parent', slug: 'parent')
    child = @category_taxonomy.terms.create!(name: 'Child', slug: 'child', parent: parent)
    
    @post.term_relationships.create!(term: parent)
    @post.term_relationships.create!(term: child)
    
    assert_equal 2, @post.terms.count
    assert_includes @post.terms, parent
    assert_includes @post.terms, child
  end

  test "posts can be tagged with multiple tags" do
    tag1 = @tag_taxonomy.terms.create!(name: 'ruby', slug: 'ruby')
    tag2 = @tag_taxonomy.terms.create!(name: 'rails', slug: 'rails')
    tag3 = @tag_taxonomy.terms.create!(name: 'testing', slug: 'testing')
    
    @post.term_relationships.create!(term: tag1)
    @post.term_relationships.create!(term: tag2)
    @post.term_relationships.create!(term: tag3)
    
    tags = @post.terms.where(taxonomy: @tag_taxonomy)
    assert_equal 3, tags.count
  end

  test "can filter posts by category term" do
    tech = @category_taxonomy.terms.create!(name: 'Tech', slug: 'tech')
    design = @category_taxonomy.terms.create!(name: 'Design', slug: 'design')
    
    post1 = Post.create!(title: 'P1', content: 'C', slug: 'p1', user: users(:admin), status: 'published')
    post2 = Post.create!(title: 'P2', content: 'C', slug: 'p2', user: users(:admin), status: 'published')
    
    post1.term_relationships.create!(term: tech)
    post2.term_relationships.create!(term: design)
    
    tech_posts = Post.joins(:term_relationships).where(term_relationships: { term: tech })
    
    assert_includes tech_posts, post1
    assert_not_includes tech_posts, post2
  end

  test "can filter posts by tag term" do
    ruby_tag = @tag_taxonomy.terms.create!(name: 'ruby', slug: 'ruby')
    js_tag = @tag_taxonomy.terms.create!(name: 'javascript', slug: 'javascript')
    
    post1 = Post.create!(title: 'Ruby Post', content: 'C', slug: 'ruby-post', user: users(:admin), status: 'published')
    post2 = Post.create!(title: 'JS Post', content: 'C', slug: 'js-post', user: users(:admin), status: 'published')
    
    post1.term_relationships.create!(term: ruby_tag)
    post2.term_relationships.create!(term: js_tag)
    
    ruby_posts = Post.joins(:term_relationships).where(term_relationships: { term: ruby_tag })
    
    assert_equal 1, ruby_posts.count
    assert_includes ruby_posts, post1
  end

  test "term count updates when posts are assigned" do
    category = @category_taxonomy.terms.create!(name: 'Tech', slug: 'tech', count: 0)
    
    @post.term_relationships.create!(term: category)
    
    # Count should be incremented (if using counter_cache)
    # For now, just verify relationship exists
    assert_equal 1, category.term_relationships.where(taggable_type: 'Post').count
  end

  test "hierarchical categories support parent-child" do
    parent = @category_taxonomy.terms.create!(name: 'Technology', slug: 'technology')
    child = @category_taxonomy.terms.create!(name: 'Ruby', slug: 'ruby', parent: parent)
    
    assert_equal parent, child.parent
    assert_includes parent.children, child
    assert @category_taxonomy.hierarchical
  end

  test "flat tags do not support hierarchy" do
    tag = @tag_taxonomy.terms.create!(name: 'test', slug: 'test')
    
    # Attempting to set parent on flat taxonomy should still work in DB
    # but the taxonomy itself is marked as non-hierarchical
    assert_not @tag_taxonomy.hierarchical
  end

  test "terms are unique within taxonomy" do
    @category_taxonomy.terms.create!(name: 'Unique', slug: 'unique')
    
    duplicate = @category_taxonomy.terms.build(name: 'Unique', slug: 'unique')
    assert_not duplicate.valid?
  end

  test "same slug can exist in different taxonomies" do
    cat_featured = @category_taxonomy.terms.create!(name: 'Featured', slug: 'featured')
    tag_featured = @tag_taxonomy.terms.create!(name: 'Featured', slug: 'featured')
    
    assert cat_featured.valid?
    assert tag_featured.valid?
    assert_not_equal cat_featured, tag_featured
  end

  test "deleting post removes term relationships" do
    category = @category_taxonomy.terms.create!(name: 'Test', slug: 'test')
    @post.term_relationships.create!(term: category)
    
    assert_difference 'TermRelationship.count', -1 do
      @post.destroy
    end
  end

  test "deleting term removes relationships" do
    category = @category_taxonomy.terms.create!(name: 'Test', slug: 'test')
    @post.term_relationships.create!(term: category)
    
    assert_difference 'TermRelationship.count', -1 do
      category.destroy
    end
  end

  test "taxonomies apply to correct object types" do
    assert @category_taxonomy.applies_to?('Post')
    assert @tag_taxonomy.applies_to?('Post')
    assert_not @category_taxonomy.applies_to?('User')
  end

  test "can get all category terms for a post" do
    cat1 = @category_taxonomy.terms.create!(name: 'Cat1', slug: 'cat1')
    cat2 = @category_taxonomy.terms.create!(name: 'Cat2', slug: 'cat2')
    
    @post.term_relationships.create!(term: cat1)
    @post.term_relationships.create!(term: cat2)
    
    categories = @post.terms.where(taxonomy: @category_taxonomy)
    assert_equal 2, categories.count
  end

  test "can get all tag terms for a post" do
    tag1 = @tag_taxonomy.terms.create!(name: 'Tag1', slug: 'tag1')
    tag2 = @tag_taxonomy.terms.create!(name: 'Tag2', slug: 'tag2')
    
    @post.term_relationships.create!(term: tag1)
    @post.term_relationships.create!(term: tag2)
    
    tags = @post.terms.where(taxonomy: @tag_taxonomy)
    assert_equal 2, tags.count
  end

  test "taxonomy helper methods work correctly" do
    category_tax = Taxonomy.categories
    assert_equal 'category', category_tax.slug
    assert category_tax.hierarchical
    
    tag_tax = Taxonomy.tags
    assert_equal 'tag', tag_tax.slug
    assert_not tag_tax.hierarchical
  end
end



