require 'rails_helper'

RSpec.describe 'Content Types and Taxonomies Integration', type: :integration do
  let(:tenant) { create(:tenant) }
  let(:content_type) { create(:content_type, ident: 'portfolio', label: 'Portfolio', tenant: tenant) }
  let(:category_taxonomy) { create(:taxonomy, slug: 'category', hierarchical: true, object_types: ['Post'], tenant: tenant) }
  let(:tag_taxonomy) { create(:taxonomy, slug: 'post_tag', hierarchical: false, object_types: ['Post'], tenant: tenant) }
  let(:portfolio_taxonomy) { create(:taxonomy, slug: 'portfolio_category', hierarchical: true, object_types: ['Post'], tenant: tenant) }

  before do
    # Ensure taxonomies exist
    category_taxonomy
    tag_taxonomy
    portfolio_taxonomy
  end

  describe 'posts with content types and taxonomies' do
    let(:post) { create(:post, content_type: content_type, tenant: tenant) }
    let(:category) { create(:term, taxonomy: category_taxonomy, name: 'Technology') }
    let(:tag) { create(:term, taxonomy: tag_taxonomy, name: 'ruby') }
    let(:portfolio_category) { create(:term, taxonomy: portfolio_taxonomy, name: 'Web Development') }

    it 'allows posts to have content type and taxonomies' do
      post.category = [category]
      post.post_tag = [tag]
      
      expect(post.content_type).to eq(content_type)
      expect(post.category).to include(category)
      expect(post.post_tag).to include(tag)
    end

    it 'maintains relationships when post is saved' do
      post.category = [category]
      post.post_tag = [tag]
      post.save!
      
      post.reload
      expect(post.content_type).to eq(content_type)
      expect(post.category).to include(category)
      expect(post.post_tag).to include(tag)
    end

    it 'allows filtering posts by content type and taxonomy' do
      regular_post = create(:post, tenant: tenant)
      portfolio_post = create(:post, content_type: content_type, tenant: tenant)
      
      portfolio_post.category = [category]
      portfolio_post.save!
      
      # Filter by content type
      portfolio_posts = Post.where(content_type: content_type)
      expect(portfolio_posts).to include(portfolio_post)
      expect(portfolio_posts).not_to include(regular_post)
      
      # Filter by taxonomy
      tech_posts = Post.joins(:term_relationships)
                      .where(term_relationships: { term: category })
      expect(tech_posts).to include(portfolio_post)
      expect(tech_posts).not_to include(regular_post)
    end

    it 'supports custom taxonomies for content types' do
      # Create a custom taxonomy specifically for portfolio posts
      portfolio_post = create(:post, content_type: content_type, tenant: tenant)
      portfolio_post.add_term(portfolio_category, 'portfolio_category')
      
      expect(portfolio_post.terms_for_taxonomy('portfolio_category')).to include(portfolio_category)
    end
  end

  describe 'content type features and taxonomy support' do
    let(:content_type_with_features) do
      create(:content_type, 
             ident: 'product', 
             label: 'Product',
             supports: ['title', 'editor', 'thumbnail', 'custom_fields'],
             tenant: tenant)
    end

    let(:product_taxonomy) do
      create(:taxonomy, 
             slug: 'product_category', 
             hierarchical: true, 
             object_types: ['Post'],
             settings: { 'show_in_menu' => true, 'color' => 'blue' },
             tenant: tenant)
    end

    it 'supports content type features' do
      expect(content_type_with_features.supports?('title')).to be true
      expect(content_type_with_features.supports?('thumbnail')).to be true
      expect(content_type_with_features.supports?('custom_fields')).to be true
      expect(content_type_with_features.supports?('comments')).to be false
    end

    it 'supports taxonomy settings' do
      expect(product_taxonomy.settings['show_in_menu']).to be true
      expect(product_taxonomy.settings['color']).to eq('blue')
    end

    it 'integrates content type features with taxonomies' do
      product_post = create(:post, content_type: content_type_with_features, tenant: tenant)
      product_category = create(:term, taxonomy: product_taxonomy, name: 'Electronics')
      
      product_post.add_term(product_category, 'product_category')
      
      expect(product_post.content_type.supports?('thumbnail')).to be true
      expect(product_post.terms_for_taxonomy('product_category')).to include(product_category)
    end
  end

  describe 'hierarchical taxonomies with content types' do
    let(:parent_category) { create(:term, taxonomy: category_taxonomy, name: 'Technology') }
    let(:child_category) { create(:term, taxonomy: category_taxonomy, name: 'Programming', parent: parent_category) }
    let(:grandchild_category) { create(:term, taxonomy: category_taxonomy, name: 'Ruby', parent: child_category) }

    it 'supports hierarchical relationships' do
      expect(parent_category.children).to include(child_category)
      expect(child_category.parent).to eq(parent_category)
      expect(grandchild_category.breadcrumbs).to eq([parent_category, child_category, grandchild_category])
    end

    it 'allows posts to be assigned to any level of hierarchy' do
      post = create(:post, content_type: content_type, tenant: tenant)
      post.category = [grandchild_category]
      
      expect(post.category).to include(grandchild_category)
      expect(post.category).not_to include(parent_category, child_category)
    end

    it 'supports filtering by hierarchical terms' do
      post1 = create(:post, content_type: content_type, tenant: tenant)
      post2 = create(:post, content_type: content_type, tenant: tenant)
      
      post1.category = [parent_category]
      post2.category = [grandchild_category]
      
      # Filter by parent category should include all descendants
      tech_posts = Post.joins(:term_relationships)
                      .where(term_relationships: { term: [parent_category, child_category, grandchild_category] })
      
      expect(tech_posts).to include(post1, post2)
    end
  end

  describe 'multi-tenancy with content types and taxonomies' do
    let(:tenant1) { create(:tenant) }
    let(:tenant2) { create(:tenant) }
    let(:content_type1) { create(:content_type, ident: 'portfolio', tenant: tenant1) }
    let(:content_type2) { create(:content_type, ident: 'portfolio', tenant: tenant2) }
    let(:taxonomy1) { create(:taxonomy, slug: 'category', tenant: tenant1) }
    let(:taxonomy2) { create(:taxonomy, slug: 'category', tenant: tenant2) }

    it 'isolates content types by tenant' do
      expect(content_type1.ident).to eq(content_type2.ident)
      expect(content_type1.tenant).not_to eq(content_type2.tenant)
    end

    it 'isolates taxonomies by tenant' do
      expect(taxonomy1.slug).to eq(taxonomy2.slug)
      expect(taxonomy1.tenant).not_to eq(taxonomy2.tenant)
    end

    it 'prevents cross-tenant associations' do
      post1 = create(:post, content_type: content_type1, tenant: tenant1)
      term1 = create(:term, taxonomy: taxonomy1, tenant: tenant1)
      
      # This should work within the same tenant
      post1.add_term(term1, 'category')
      expect(post1.terms_for_taxonomy('category')).to include(term1)
      
      # Cross-tenant associations should be prevented by multi-tenancy
      post2 = create(:post, tenant: tenant2)
      expect { post2.add_term(term1, 'category') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'content type capabilities and taxonomy permissions' do
    let(:restricted_content_type) do
      create(:content_type,
             ident: 'restricted',
             label: 'Restricted',
             capabilities: { 'can_edit' => false, 'can_delete' => false },
             tenant: tenant)
    end

    let(:restricted_taxonomy) do
      create(:taxonomy,
             slug: 'restricted_category',
             settings: { 'restricted' => true, 'admin_only' => true },
             tenant: tenant)
    end

    it 'supports content type capabilities' do
      expect(restricted_content_type.can?('can_edit')).to be false
      expect(restricted_content_type.can?('can_delete')).to be false
      expect(restricted_content_type.can?('can_view')).to be false
    end

    it 'supports taxonomy restrictions' do
      expect(restricted_taxonomy.settings['restricted']).to be true
      expect(restricted_taxonomy.settings['admin_only']).to be true
    end

    it 'integrates capabilities with taxonomy restrictions' do
      restricted_post = create(:post, content_type: restricted_content_type, tenant: tenant)
      restricted_term = create(:term, taxonomy: restricted_taxonomy, name: 'Admin Only')
      
      # Even with restricted content type, taxonomy relationships should work
      restricted_post.add_term(restricted_term, 'restricted_category')
      expect(restricted_post.terms_for_taxonomy('restricted_category')).to include(restricted_term)
    end
  end
end
