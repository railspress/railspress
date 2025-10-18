require 'rails_helper'

RSpec.describe Taxonomy, type: :model do
  let(:tenant) { create(:tenant) }
  let(:taxonomy) { build(:taxonomy, tenant: tenant) }

  describe 'associations' do
    it { should have_many(:terms).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_uniqueness_of(:slug) }
  end

  describe 'serialization' do
    it 'serializes object_types as JSON array' do
      taxonomy.object_types = ['Post', 'Page']
      taxonomy.save!
      taxonomy.reload
      expect(taxonomy.object_types).to eq(['Post', 'Page'])
    end

    it 'serializes settings as JSON hash' do
      taxonomy.settings = { 'show_in_menu' => true, 'color' => 'blue' }
      taxonomy.save!
      taxonomy.reload
      expect(taxonomy.settings['show_in_menu']).to be true
      expect(taxonomy.settings['color']).to eq('blue')
    end
  end

  describe 'friendly_id' do
    it 'generates slug from name' do
      taxonomy.name = 'My Custom Taxonomy'
      taxonomy.save!
      expect(taxonomy.slug).to eq('my-custom-taxonomy')
    end

    it 'updates slug when name changes' do
      taxonomy.save!
      taxonomy.update!(name: 'New Name')
      expect(taxonomy.slug).to eq('new-name')
    end
  end

  describe 'scopes' do
    let!(:hierarchical_taxonomy) { create(:taxonomy, hierarchical: true, tenant: tenant) }
    let!(:flat_taxonomy) { create(:taxonomy, hierarchical: false, tenant: tenant) }
    let!(:post_taxonomy) { create(:taxonomy, object_types: ['Post'], tenant: tenant) }
    let!(:page_taxonomy) { create(:taxonomy, object_types: ['Page'], tenant: tenant) }

    describe '.hierarchical' do
      it 'returns only hierarchical taxonomies' do
        expect(Taxonomy.hierarchical).to include(hierarchical_taxonomy)
        expect(Taxonomy.hierarchical).not_to include(flat_taxonomy)
      end
    end

    describe '.flat' do
      it 'returns only flat taxonomies' do
        expect(Taxonomy.flat).to include(flat_taxonomy)
        expect(Taxonomy.flat).not_to include(hierarchical_taxonomy)
      end
    end

    describe '.for_posts' do
      it 'returns taxonomies that apply to posts' do
        expect(Taxonomy.for_posts).to include(post_taxonomy)
        expect(Taxonomy.for_posts).not_to include(page_taxonomy)
      end
    end

    describe '.for_pages' do
      it 'returns taxonomies that apply to pages' do
        expect(Taxonomy.for_pages).to include(page_taxonomy)
        expect(Taxonomy.for_pages).not_to include(post_taxonomy)
      end
    end
  end

  describe 'callbacks' do
    it 'sets default values on initialization' do
      new_taxonomy = Taxonomy.new(name: 'Test', slug: 'test')
      expect(new_taxonomy.hierarchical).to be false
      expect(new_taxonomy.object_types).to eq([])
      expect(new_taxonomy.settings).to eq({})
    end
  end

  describe 'instance methods' do
    let(:taxonomy_with_terms) { create(:taxonomy, tenant: tenant) }
    let!(:root_term) { create(:term, taxonomy: taxonomy_with_terms, parent: nil) }
    let!(:child_term) { create(:term, taxonomy: taxonomy_with_terms, parent: root_term) }

    describe '#root_terms' do
      it 'returns terms without parent' do
        expect(taxonomy_with_terms.root_terms).to include(root_term)
        expect(taxonomy_with_terms.root_terms).not_to include(child_term)
      end
    end

    describe '#term_count' do
      it 'returns count of terms' do
        expect(taxonomy_with_terms.term_count).to eq(2)
      end
    end

    describe '#applies_to?' do
      let(:taxonomy) { create(:taxonomy, object_types: ['Post', 'Page'], tenant: tenant) }

      it 'returns true for applicable object types' do
        expect(taxonomy.applies_to?('Post')).to be true
        expect(taxonomy.applies_to?(:Page)).to be true
      end

      it 'returns false for non-applicable object types' do
        expect(taxonomy.applies_to?('User')).to be false
      end
    end
  end

  describe 'class methods' do
    describe '.categories' do
      it 'finds or creates categories taxonomy' do
        taxonomy = Taxonomy.categories
        expect(taxonomy.slug).to eq('category')
        expect(taxonomy.hierarchical).to be true
        expect(taxonomy.object_types).to include('Post')
      end
    end

    describe '.tags' do
      it 'finds or creates tags taxonomy' do
        taxonomy = Taxonomy.tags
        expect(taxonomy.slug).to eq('post_tag')
        expect(taxonomy.hierarchical).to be false
        expect(taxonomy.object_types).to include('Post')
      end
    end
  end

  describe 'multi-tenancy' do
    let(:tenant1) { create(:tenant) }
    let(:tenant2) { create(:tenant) }

    it 'isolates taxonomies by tenant' do
      taxonomy1 = create(:taxonomy, tenant: tenant1, slug: 'test')
      taxonomy2 = create(:taxonomy, tenant: tenant2, slug: 'test')

      expect(taxonomy1.slug).to eq(taxonomy2.slug)
      expect(taxonomy1.tenant).not_to eq(taxonomy2.tenant)
    end
  end
end
