require 'rails_helper'

RSpec.describe HasTaxonomies, type: :model do
  let(:tenant) { create(:tenant) }
  let(:category_taxonomy) { create(:taxonomy, slug: 'category', hierarchical: true, object_types: ['Post'], tenant: tenant) }
  let(:tag_taxonomy) { create(:taxonomy, slug: 'post_tag', hierarchical: false, object_types: ['Post'], tenant: tenant) }
  let(:post) { create(:post, tenant: tenant) }

  before do
    # Ensure taxonomies exist
    category_taxonomy
    tag_taxonomy
  end

  describe 'associations' do
    it 'has many term_relationships' do
      expect(post).to respond_to(:term_relationships)
    end

    it 'has many terms through term_relationships' do
      expect(post).to respond_to(:terms)
    end
  end

  describe 'has_taxonomy class method' do
    let(:post_class) { Post }

    it 'defines taxonomy-specific associations' do
      expect(post_class).to respond_to(:has_taxonomy)
    end

    it 'creates category association' do
      expect(post).to respond_to(:category)
      expect(post).to respond_to(:category_relationships)
    end

    it 'creates post_tag association' do
      expect(post).to respond_to(:post_tag)
      expect(post).to respond_to(:post_tag_relationships)
    end
  end

  describe 'taxonomy helper methods' do
    let(:category1) { create(:term, taxonomy: category_taxonomy, name: 'Tech') }
    let(:category2) { create(:term, taxonomy: category_taxonomy, name: 'Design') }
    let(:tag1) { create(:term, taxonomy: tag_taxonomy, name: 'ruby') }
    let(:tag2) { create(:term, taxonomy: tag_taxonomy, name: 'rails') }

    describe '#category_list' do
      it 'returns comma-separated category names' do
        post.category = [category1, category2]
        expect(post.category_list).to eq('Tech, Design')
      end

      it 'returns empty string when no categories' do
        expect(post.category_list).to eq('')
      end
    end

    describe '#category_list=' do
      it 'creates and assigns categories from comma-separated string' do
        post.category_list = 'Tech, Design, Business'
        
        expect(post.category.count).to eq(3)
        expect(post.category.pluck(:name)).to contain_exactly('Tech', 'Design', 'Business')
      end

      it 'handles extra whitespace' do
        post.category_list = ' Tech , Design , Business '
        
        expect(post.category.count).to eq(3)
        expect(post.category.pluck(:name)).to contain_exactly('Tech', 'Design', 'Business')
      end

      it 'ignores blank entries' do
        post.category_list = 'Tech, , Design,'
        
        expect(post.category.count).to eq(2)
        expect(post.category.pluck(:name)).to contain_exactly('Tech', 'Design')
      end
    end

    describe '#post_tag_list' do
      it 'returns comma-separated tag names' do
        post.post_tag = [tag1, tag2]
        expect(post.post_tag_list).to eq('ruby, rails')
      end
    end

    describe '#post_tag_list=' do
      it 'creates and assigns tags from comma-separated string' do
        post.post_tag_list = 'ruby, rails, testing'
        
        expect(post.post_tag.count).to eq(3)
        expect(post.post_tag.pluck(:name)).to contain_exactly('ruby', 'rails', 'testing')
      end
    end
  end

  describe 'instance methods' do
    let(:category) { create(:term, taxonomy: category_taxonomy) }
    let(:tag) { create(:term, taxonomy: tag_taxonomy) }

    describe '#terms_for_taxonomy' do
      it 'returns terms for specific taxonomy' do
        post.terms = [category, tag]
        
        categories = post.terms_for_taxonomy('category')
        expect(categories).to include(category)
        expect(categories).not_to include(tag)
      end

      it 'returns empty relation for non-existent taxonomy' do
        result = post.terms_for_taxonomy('non_existent')
        expect(result).to be_empty
      end
    end

    describe '#set_terms_for_taxonomy' do
      let(:category1) { create(:term, taxonomy: category_taxonomy) }
      let(:category2) { create(:term, taxonomy: category_taxonomy) }
      let(:category3) { create(:term, taxonomy: category_taxonomy) }

      it 'replaces existing terms for taxonomy' do
        post.terms = [category1, category2]
        post.set_terms_for_taxonomy('category', [category2.id, category3.id])
        
        expect(post.terms_for_taxonomy('category')).to contain_exactly(category2, category3)
      end

      it 'removes all terms when empty array provided' do
        post.terms = [category1, category2]
        post.set_terms_for_taxonomy('category', [])
        
        expect(post.terms_for_taxonomy('category')).to be_empty
      end
    end

    describe '#add_term' do
      it 'adds term by object' do
        post.add_term(category, 'category')
        
        expect(post.terms_for_taxonomy('category')).to include(category)
      end

      it 'adds term by name' do
        post.add_term('New Category', 'category')
        
        new_category = category_taxonomy.terms.find_by(name: 'New Category')
        expect(post.terms_for_taxonomy('category')).to include(new_category)
      end

      it 'does not add duplicate terms' do
        post.terms = [category]
        post.add_term(category, 'category')
        
        expect(post.terms_for_taxonomy('category').count).to eq(1)
      end

      it 'ignores non-existent taxonomy' do
        post.add_term(category, 'non_existent')
        
        expect(post.terms).to be_empty
      end
    end

    describe '#remove_term' do
      it 'removes term from object' do
        post.terms = [category, tag]
        post.remove_term(category)
        
        expect(post.terms).to include(tag)
        expect(post.terms).not_to include(category)
      end
    end

    describe '#has_term?' do
      before { post.terms = [category] }

      it 'returns true for existing term object' do
        expect(post.has_term?(category)).to be true
      end

      it 'returns true for existing term slug' do
        expect(post.has_term?(category.slug)).to be true
      end

      it 'returns false for non-existing term' do
        other_term = create(:term, taxonomy: category_taxonomy)
        expect(post.has_term?(other_term)).to be false
      end

      it 'returns false for non-existing slug' do
        expect(post.has_term?('non-existent')).to be false
      end
    end

    describe '#term_names_for' do
      it 'returns array of term names for taxonomy' do
        post.terms = [category, tag]
        
        category_names = post.term_names_for('category')
        expect(category_names).to eq([category.name])
      end
    end
  end

  describe 'integration with Post model' do
    let(:category) { create(:term, taxonomy: category_taxonomy) }
    let(:tag) { create(:term, taxonomy: tag_taxonomy) }

    it 'allows posts to have categories and tags' do
      post.category = [category]
      post.post_tag = [tag]
      
      expect(post.category).to include(category)
      expect(post.post_tag).to include(tag)
      expect(post.terms).to include(category, tag)
    end

    it 'maintains relationships when post is saved' do
      post.category = [category]
      post.save!
      
      post.reload
      expect(post.category).to include(category)
    end

    it 'cleans up relationships when post is destroyed' do
      post.terms = [category, tag]
      post.save!
      
      expect { post.destroy }.to change { TermRelationship.count }.by(-2)
    end
  end
end
