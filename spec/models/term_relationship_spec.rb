require 'rails_helper'

RSpec.describe TermRelationship, type: :model do
  let(:tenant) { create(:tenant) }
  let(:taxonomy) { create(:taxonomy, tenant: tenant) }
  let(:term) { create(:term, taxonomy: taxonomy, tenant: tenant) }
  let(:post) { create(:post, tenant: tenant) }
  let(:term_relationship) { build(:term_relationship, term: term, object: post) }

  describe 'associations' do
    it { should belong_to(:term) }
    it { should belong_to(:object) }
  end

  describe 'validations' do
    it { should validate_presence_of(:term) }
    it { should validate_presence_of(:object) }
    it { should validate_uniqueness_of(:term_id).scoped_to([:object_type, :object_id]) }
  end

  describe 'callbacks' do
    it 'updates term count after create' do
      expect(term.count).to eq(0)
      
      term_relationship.save!
      
      term.reload
      expect(term.count).to eq(1)
    end

    it 'updates term count after destroy' do
      term_relationship.save!
      term.reload
      expect(term.count).to eq(1)
      
      term_relationship.destroy
      
      term.reload
      expect(term.count).to eq(0)
    end
  end

  describe 'polymorphic association' do
    let(:page) { create(:page, tenant: tenant) }

    it 'can associate with posts' do
      relationship = create(:term_relationship, term: term, object: post)
      expect(relationship.object).to eq(post)
      expect(relationship.object_type).to eq('Post')
    end

    it 'can associate with pages' do
      relationship = create(:term_relationship, term: term, object: page)
      expect(relationship.object).to eq(page)
      expect(relationship.object_type).to eq('Page')
    end
  end

  describe 'uniqueness constraint' do
    it 'prevents duplicate term-object relationships' do
      create(:term_relationship, term: term, object: post)
      
      duplicate = build(:term_relationship, term: term, object: post)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:term_id]).to be_present
    end

    it 'allows same term with different objects' do
      page = create(:page, tenant: tenant)
      
      create(:term_relationship, term: term, object: post)
      relationship2 = build(:term_relationship, term: term, object: page)
      
      expect(relationship2).to be_valid
    end

    it 'allows same object with different terms' do
      term2 = create(:term, taxonomy: taxonomy, tenant: tenant)
      
      create(:term_relationship, term: term, object: post)
      relationship2 = build(:term_relationship, term: term2, object: post)
      
      expect(relationship2).to be_valid
    end
  end

  describe 'counter cache' do
    it 'increments term count when created' do
      expect { term_relationship.save! }.to change { term.reload.count }.by(1)
    end

    it 'decrements term count when destroyed' do
      term_relationship.save!
      expect { term_relationship.destroy }.to change { term.reload.count }.by(-1)
    end
  end
end
