require 'rails_helper'

RSpec.describe Term, type: :model do
  let(:tenant) { create(:tenant) }
  let(:taxonomy) { create(:taxonomy, tenant: tenant) }
  let(:term) { build(:term, taxonomy: taxonomy, tenant: tenant) }

  describe 'associations' do
    it { should belong_to(:taxonomy) }
    it { should belong_to(:parent).class_name('Term').optional }
    it { should have_many(:children).class_name('Term').dependent(:destroy) }
    it { should have_many(:term_relationships).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_uniqueness_of(:slug).scoped_to(:taxonomy_id) }
    it { should validate_presence_of(:taxonomy) }
  end

  describe 'serialization' do
    it 'serializes metadata as JSON hash' do
      term.metadata = { 'color' => 'blue', 'icon' => 'star' }
      term.save!
      term.reload
      expect(term.metadata['color']).to eq('blue')
      expect(term.metadata['icon']).to eq('star')
    end
  end

  describe 'friendly_id' do
    it 'generates slug from name' do
      term.name = 'My Test Term'
      term.save!
      expect(term.slug).to eq('my-test-term')
    end

    it 'updates slug when name changes' do
      term.save!
      term.update!(name: 'New Name')
      expect(term.slug).to eq('new-name')
    end

    it 'ensures slug uniqueness within taxonomy' do
      term1 = create(:term, taxonomy: taxonomy, name: 'Test Term')
      term2 = build(:term, taxonomy: taxonomy, name: 'Test Term')
      
      expect(term2).not_to be_valid
      expect(term2.errors[:slug]).to be_present
    end

    it 'allows same slug in different taxonomies' do
      taxonomy2 = create(:taxonomy, tenant: tenant)
      term1 = create(:term, taxonomy: taxonomy, name: 'Test Term')
      term2 = create(:term, taxonomy: taxonomy2, name: 'Test Term')
      
      expect(term1.slug).to eq(term2.slug)
      expect(term1).to be_valid
      expect(term2).to be_valid
    end
  end

  describe 'scopes' do
    let!(:root_term) { create(:term, taxonomy: taxonomy, parent: nil) }
    let!(:child_term) { create(:term, taxonomy: taxonomy, parent: root_term) }
    let!(:popular_term) { create(:term, taxonomy: taxonomy, count: 10) }
    let!(:unpopular_term) { create(:term, taxonomy: taxonomy, count: 1) }

    describe '.root_terms' do
      it 'returns terms without parent' do
        expect(Term.root_terms).to include(root_term)
        expect(Term.root_terms).not_to include(child_term)
      end
    end

    describe '.ordered' do
      it 'orders terms by name' do
        term_z = create(:term, taxonomy: taxonomy, name: 'Zebra')
        term_a = create(:term, taxonomy: taxonomy, name: 'Apple')
        
        ordered = Term.ordered
        expect(ordered.first.name).to eq('Apple')
        expect(ordered.last.name).to eq('Zebra')
      end
    end

    describe '.popular' do
      it 'orders terms by count descending' do
        popular = Term.popular
        expect(popular.first).to eq(popular_term)
        expect(popular.last).to eq(unpopular_term)
      end
    end

    describe '.for_taxonomy' do
      let(:taxonomy2) { create(:taxonomy, tenant: tenant) }
      let!(:term_in_taxonomy2) { create(:term, taxonomy: taxonomy2) }

      it 'returns terms for specific taxonomy' do
        terms = Term.for_taxonomy(taxonomy.slug)
        expect(terms).to include(root_term)
        expect(terms).not_to include(term_in_taxonomy2)
      end
    end
  end

  describe 'callbacks' do
    it 'sets default values on initialization' do
      new_term = Term.new(name: 'Test', taxonomy: taxonomy)
      expect(new_term.metadata).to eq({})
    end

    it 'updates count after save' do
      term.save!
      expect(term.count).to eq(0)
      
      create(:term_relationship, term: term)
      term.reload
      expect(term.count).to eq(1)
    end
  end

  describe 'instance methods' do
    let(:hierarchical_taxonomy) { create(:taxonomy, hierarchical: true, tenant: tenant) }
    let(:flat_taxonomy) { create(:taxonomy, hierarchical: false, tenant: tenant) }
    let(:hierarchical_term) { create(:term, taxonomy: hierarchical_taxonomy) }
    let(:flat_term) { create(:term, taxonomy: flat_taxonomy) }

    describe '#hierarchical?' do
      it 'returns true for hierarchical taxonomy terms' do
        expect(hierarchical_term.hierarchical?).to be true
      end

      it 'returns false for flat taxonomy terms' do
        expect(flat_term.hierarchical?).to be false
      end
    end

    describe '#breadcrumbs' do
      let(:grandparent) { create(:term, taxonomy: hierarchical_taxonomy) }
      let(:parent) { create(:term, taxonomy: hierarchical_taxonomy, parent: grandparent) }
      let(:child) { create(:term, taxonomy: hierarchical_taxonomy, parent: parent) }

      it 'returns array of terms from root to current' do
        breadcrumbs = child.breadcrumbs
        expect(breadcrumbs).to eq([grandparent, parent, child])
      end

      it 'returns single term for root term' do
        breadcrumbs = grandparent.breadcrumbs
        expect(breadcrumbs).to eq([grandparent])
      end
    end

    describe '#objects' do
      let(:post) { create(:post, tenant: tenant) }
      let(:page) { create(:page, tenant: tenant) }

      it 'returns all objects with this term' do
        create(:term_relationship, term: term, object: post)
        create(:term_relationship, term: term, object: page)
        
        objects = term.objects
        expect(objects).to include(post, page)
      end
    end

    describe '#objects_of_type' do
      let(:post) { create(:post, tenant: tenant) }
      let(:page) { create(:page, tenant: tenant) }

      it 'returns objects of specific type' do
        create(:term_relationship, term: term, object: post)
        create(:term_relationship, term: term, object: page)
        
        posts = term.objects_of_type('Post')
        expect(posts).to include(post)
        expect(posts).not_to include(page)
      end
    end

    describe '#posts' do
      let(:post) { create(:post, tenant: tenant) }

      it 'returns posts associated with this term' do
        create(:term_relationship, term: term, object: post)
        
        expect(term.posts).to include(post)
      end
    end

    describe '#to_liquid' do
      it 'returns liquid-compatible hash' do
        term.save!
        liquid = term.to_liquid
        
        expect(liquid['id']).to eq(term.id)
        expect(liquid['name']).to eq(term.name)
        expect(liquid['slug']).to eq(term.slug)
      end
    end
  end

  describe 'multi-tenancy' do
    let(:tenant1) { create(:tenant) }
    let(:tenant2) { create(:tenant) }
    let(:taxonomy1) { create(:taxonomy, tenant: tenant1) }
    let(:taxonomy2) { create(:taxonomy, tenant: tenant2) }

    it 'isolates terms by tenant' do
      term1 = create(:term, taxonomy: taxonomy1, slug: 'test')
      term2 = create(:term, taxonomy: taxonomy2, slug: 'test')

      expect(term1.slug).to eq(term2.slug)
      expect(term1.tenant).not_to eq(term2.tenant)
    end
  end
end
