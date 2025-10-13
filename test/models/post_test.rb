require "test_helper"

class PostTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin)
    @category_taxonomy = taxonomies(:category)
    @tag_taxonomy = taxonomies(:tag)
    @technology_term = terms(:technology)
    
    @post = Post.new(
      title: "Test Post",
      content: "This is test content",
      excerpt: "Test excerpt",
      slug: "test-post",
      status: "published",
      user: @user
    )
  end

  test "should be valid with valid attributes" do
    assert @post.valid?
  end

  test "should require title" do
    @post.title = nil
    assert_not @post.valid?
    assert_includes @post.errors[:title], "can't be blank"
  end

  test "should require content" do
    @post.content = nil
    assert_not @post.valid?
  end

  test "should require user" do
    @post.user = nil
    assert_not @post.valid?
  end

  test "should require valid status" do
    @post.status = "invalid_status"
    assert_not @post.valid?
  end

  test "should accept valid statuses" do
    valid_statuses = %w[draft published private_post pending_review scheduled]
    valid_statuses.each do |status|
      @post.status = status
      assert @post.valid?, "#{status} should be valid"
    end
  end

  test "should generate slug from title" do
    @post.title = "My Amazing Post Title"
    @post.save!
    assert_equal "my-amazing-post-title", @post.slug
  end

  test "should handle slug uniqueness" do
    @post.save!
    duplicate_post = Post.new(
      title: "Test Post",
      content: "Different content",
      user: @user,
      status: "published"
    )
    duplicate_post.save!
    assert_not_equal @post.slug, duplicate_post.slug
  end

  test "should have terms association via taxonomy" do
    @post.save!
    @post.term_relationships.create!(term: @technology_term)
    
    assert_includes @post.terms, @technology_term
  end

  test "should have categories via taxonomy" do
    @post.save!
    @post.term_relationships.create!(term: @technology_term)
    
    categories = @post.terms.where(taxonomy: @category_taxonomy)
    assert_includes categories, @technology_term
  end

  test "should have tags via taxonomy" do
    @post.save!
    tag = @tag_taxonomy.terms.create!(name: 'test-tag', slug: 'test-tag')
    @post.term_relationships.create!(term: tag)
    
    tags = @post.terms.where(taxonomy: @tag_taxonomy)
    assert_includes tags, tag
  end

  test "should have comments association" do
    @post.save!
    comment = @post.comments.create!(
      content: "Great post!", 
      user: @user,
      author_name: @user.name,
      author_email: @user.email,
      status: "approved"
    )
    assert_includes @post.comments, comment
  end

  test "should scope published posts" do
    published_post = Post.create!(title: "Published", content: "Content", user: @user, status: "published")
    draft_post = Post.create!(title: "Draft", content: "Content", user: @user, status: "draft")
    
    published_posts = Post.published_status
    assert_includes published_posts, published_post
    assert_not_includes published_posts, draft_post
  end

  test "should scope draft posts" do
    published_post = Post.create!(title: "Published", content: "Content", user: @user, status: "published")
    draft_post = Post.create!(title: "Draft", content: "Content", user: @user, status: "draft")
    
    draft_posts = Post.draft_status
    assert_includes draft_posts, draft_post
    assert_not_includes draft_posts, published_post
  end

  test "should filter by category term" do
    tech_category = @category_taxonomy.terms.create!(name: "Tech", slug: "tech")
    design_category = @category_taxonomy.terms.create!(name: "Design", slug: "design")
    
    post1 = Post.create!(title: "Post 1", content: "Content", user: @user, status: "published")
    post2 = Post.create!(title: "Post 2", content: "Content", user: @user, status: "published")
    
    post1.term_relationships.create!(term: tech_category)
    post2.term_relationships.create!(term: design_category)
    
    tech_posts = Post.joins(:term_relationships).where(term_relationships: { term: tech_category })
    assert_includes tech_posts, post1
    assert_not_includes tech_posts, post2
  end

  test "should filter by tag term" do
    tag1 = @tag_taxonomy.terms.create!(name: "tag1", slug: "tag1")
    tag2 = @tag_taxonomy.terms.create!(name: "tag2", slug: "tag2")
    
    post1 = Post.create!(title: "Post 1", content: "Content", user: @user, status: "published")
    post2 = Post.create!(title: "Post 2", content: "Content", user: @user, status: "published")
    
    post1.term_relationships.create!(term: tag1)
    post2.term_relationships.create!(term: tag2)
    
    tagged_posts = Post.joins(:term_relationships).where(term_relationships: { term: tag1 })
    assert_includes tagged_posts, post1
    assert_not_includes tagged_posts, post2
  end

  test "should scope recent posts" do
    old_post = Post.create!(title: "Old", content: "C", user: @user, status: "published", created_at: 1.year.ago)
    recent_post = Post.create!(title: "Recent", content: "C", user: @user, status: "published", created_at: 1.day.ago)
    
    recent_posts = Post.order(created_at: :desc).limit(1)
    assert_includes recent_posts, recent_post
  end

  test "should handle special characters in title" do
    @post.title = "Post with Special Characters: !@#$%^&*()"
    @post.save!
    assert_match /post-with-special-characters/, @post.slug
  end

  test "should handle unicode characters in title" do
    @post.title = "Post with Unicode: ñáéíóú"
    @post.save!
    assert_not_nil @post.slug
  end

  test "should have published_at timestamp when published" do
    @post.status = "published"
    @post.save!
    assert_not_nil @post.published_at
  end

  test "should allow custom slug" do
    @post.slug = "custom-slug-123"
    @post.save!
    assert_equal "custom-slug-123", @post.slug
  end

  test "should have HasTaxonomies concern" do
    assert @post.respond_to?(:terms)
    assert @post.respond_to?(:term_relationships)
  end

  test "should assign multiple categories" do
    @post.save!
    cat1 = @category_taxonomy.terms.create!(name: "Cat1", slug: "cat1")
    cat2 = @category_taxonomy.terms.create!(name: "Cat2", slug: "cat2")
    
    @post.term_relationships.create!(term: cat1)
    @post.term_relationships.create!(term: cat2)
    
    assert_equal 2, @post.terms.where(taxonomy: @category_taxonomy).count
  end

  test "should assign multiple tags" do
    @post.save!
    tag1 = @tag_taxonomy.terms.create!(name: "ruby", slug: "ruby")
    tag2 = @tag_taxonomy.terms.create!(name: "rails", slug: "rails")
    
    @post.term_relationships.create!(term: tag1)
    @post.term_relationships.create!(term: tag2)
    
    assert_equal 2, @post.terms.where(taxonomy: @tag_taxonomy).count
  end
end
