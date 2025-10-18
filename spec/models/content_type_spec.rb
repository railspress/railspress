require 'rails_helper'

RSpec.describe ContentType, type: :model do
  let(:tenant) { create(:tenant) }
  let(:content_type) { build(:content_type, tenant: tenant) }

  describe 'associations' do
    it { should have_many(:posts).dependent(:nullify) }
  end

  describe 'validations' do
    it { should validate_presence_of(:ident) }
    it { should validate_presence_of(:label) }
    it { should validate_presence_of(:singular) }
    it { should validate_presence_of(:plural) }
    it { should validate_uniqueness_of(:ident) }
    
    it 'validates ident format' do
      content_type.ident = 'Invalid Format!'
      expect(content_type).not_to be_valid
      expect(content_type.errors[:ident]).to include('only allows lowercase letters, numbers, hyphens, and underscores')
    end

    it 'accepts valid ident formats' do
      valid_idents = ['post', 'custom-post', 'post_type', 'post123']
      valid_idents.each do |ident|
        content_type.ident = ident
        expect(content_type).to be_valid, "#{ident} should be valid"
      end
    end
  end

  describe 'JSON attributes' do
    it 'has default supports array' do
      content_type.save!
      expect(content_type.supports).to include('title', 'editor', 'excerpt', 'thumbnail', 'comments')
    end

    it 'has default capabilities hash' do
      content_type.save!
      expect(content_type.capabilities).to eq({})
    end

    it 'can modify supports array' do
      content_type.supports = ['title', 'editor', 'custom_field']
      content_type.save!
      content_type.reload
      expect(content_type.supports).to eq(['title', 'editor', 'custom_field'])
    end

    it 'can modify capabilities hash' do
      content_type.capabilities = { 'can_edit' => true, 'can_delete' => false }
      content_type.save!
      content_type.reload
      expect(content_type.capabilities['can_edit']).to be true
      expect(content_type.capabilities['can_delete']).to be false
    end
  end

  describe 'scopes' do
    let!(:active_content_type) { create(:content_type, active: true, tenant: tenant) }
    let!(:inactive_content_type) { create(:content_type, active: false, tenant: tenant) }
    let!(:public_content_type) { create(:content_type, public: true, tenant: tenant) }
    let!(:private_content_type) { create(:content_type, public: false, tenant: tenant) }

    describe '.active' do
      it 'returns only active content types' do
        expect(ContentType.active).to include(active_content_type)
        expect(ContentType.active).not_to include(inactive_content_type)
      end
    end

    describe '.public_types' do
      it 'returns only public content types' do
        expect(ContentType.public_types).to include(public_content_type)
        expect(ContentType.public_types).not_to include(private_content_type)
      end
    end

    describe '.ordered' do
      it 'orders by menu_position then label' do
        type1 = create(:content_type, menu_position: 2, label: 'B', tenant: tenant)
        type2 = create(:content_type, menu_position: 1, label: 'A', tenant: tenant)
        type3 = create(:content_type, menu_position: 1, label: 'C', tenant: tenant)
        
        ordered = ContentType.ordered
        expect(ordered).to eq([type2, type3, type1])
      end
    end
  end

  describe 'callbacks' do
    it 'sets default values on create' do
      content_type.save!
      
      expect(content_type.rest_base).to eq(content_type.ident.pluralize)
      expect(content_type.singular).to eq(content_type.label)
      expect(content_type.plural).to eq(content_type.label.pluralize)
      expect(content_type.icon).to eq('document-text')
      expect(content_type.public).to be true
      expect(content_type.active).to be true
      expect(content_type.hierarchical).to be false
      expect(content_type.has_archive).to be true
    end

    it 'normalizes ident before validation' do
      content_type.ident = 'Test Content Type!'
      content_type.save!
      
      expect(content_type.ident).to eq('test-content-type-')
    end
  end

  describe 'class methods' do
    describe '.find_by_ident' do
      let!(:content_type) { create(:content_type, ident: 'test-type', tenant: tenant) }

      it 'finds content type by ident' do
        found = ContentType.find_by_ident('test-type')
        expect(found).to eq(content_type)
      end

      it 'is case insensitive' do
        found = ContentType.find_by_ident('TEST-TYPE')
        expect(found).to eq(content_type)
      end

      it 'handles string conversion' do
        found = ContentType.find_by_ident(:test_type)
        expect(found).to eq(content_type)
      end

      it 'returns nil for non-existent ident' do
        found = ContentType.find_by_ident('non-existent')
        expect(found).to be_nil
      end
    end

    describe '.default_type' do
      it 'returns post type if exists' do
        post_type = create(:content_type, ident: 'post', tenant: tenant)
        expect(ContentType.default_type).to eq(post_type)
      end

      it 'returns first type if post type does not exist' do
        other_type = create(:content_type, ident: 'other', tenant: tenant)
        expect(ContentType.default_type).to eq(other_type)
      end
    end
  end

  describe 'instance methods' do
    let(:content_type) { create(:content_type, ident: 'portfolio', label: 'Portfolio', tenant: tenant) }

    describe '#to_param' do
      it 'returns ident' do
        expect(content_type.to_param).to eq('portfolio')
      end
    end

    describe '#display_name' do
      it 'returns label' do
        expect(content_type.display_name).to eq('Portfolio')
      end
    end

    describe '#supports?' do
      it 'returns true for supported features' do
        content_type.supports = ['title', 'editor']
        expect(content_type.supports?('title')).to be true
        expect(content_type.supports?('editor')).to be true
      end

      it 'returns false for unsupported features' do
        content_type.supports = ['title']
        expect(content_type.supports?('editor')).to be false
      end

      it 'handles string and symbol input' do
        content_type.supports = ['title']
        expect(content_type.supports?(:title)).to be true
        expect(content_type.supports?('title')).to be true
      end
    end

    describe '#add_support' do
      it 'adds feature to supports array' do
        content_type.supports = ['title']
        content_type.add_support('editor')
        
        expect(content_type.supports).to include('title', 'editor')
      end

      it 'does not add duplicate features' do
        content_type.supports = ['title']
        content_type.add_support('title')
        
        expect(content_type.supports.count('title')).to eq(1)
      end

      it 'handles string and symbol input' do
        content_type.supports = []
        content_type.add_support(:editor)
        
        expect(content_type.supports).to include('editor')
      end
    end

    describe '#remove_support' do
      it 'removes feature from supports array' do
        content_type.supports = ['title', 'editor']
        content_type.remove_support('title')
        
        expect(content_type.supports).to include('editor')
        expect(content_type.supports).not_to include('title')
      end

      it 'handles non-existent features gracefully' do
        content_type.supports = ['title']
        content_type.remove_support('non-existent')
        
        expect(content_type.supports).to include('title')
      end
    end

    describe '#can?' do
      it 'returns true for granted capabilities' do
        content_type.capabilities = { 'can_edit' => true }
        expect(content_type.can?('can_edit')).to be true
      end

      it 'returns false for denied capabilities' do
        content_type.capabilities = { 'can_edit' => false }
        expect(content_type.can?('can_edit')).to be false
      end

      it 'returns false for non-existent capabilities' do
        content_type.capabilities = {}
        expect(content_type.can?('can_edit')).to be false
      end

      it 'handles string and symbol input' do
        content_type.capabilities = { 'can_edit' => true }
        expect(content_type.can?(:can_edit)).to be true
        expect(content_type.can?('can_edit')).to be true
      end
    end

    describe '#rest_endpoint' do
      it 'returns rest_base if present' do
        content_type.rest_base = 'custom-endpoint'
        expect(content_type.rest_endpoint).to eq('custom-endpoint')
      end

      it 'returns pluralized ident if rest_base is blank' do
        content_type.rest_base = ''
        expect(content_type.rest_endpoint).to eq('portfolios')
      end

      it 'returns pluralized ident if rest_base is nil' do
        content_type.rest_base = nil
        expect(content_type.rest_endpoint).to eq('portfolios')
      end
    end
  end

  describe 'multi-tenancy' do
    let(:tenant1) { create(:tenant) }
    let(:tenant2) { create(:tenant) }

    it 'isolates content types by tenant' do
      type1 = create(:content_type, tenant: tenant1, ident: 'test')
      type2 = create(:content_type, tenant: tenant2, ident: 'test')

      expect(type1.ident).to eq(type2.ident)
      expect(type1.tenant).not_to eq(type2.tenant)
    end
  end

  describe 'integration with posts' do
    let(:content_type) { create(:content_type, tenant: tenant) }
    let(:post) { create(:post, content_type: content_type, tenant: tenant) }

    it 'associates with posts' do
      expect(content_type.posts).to include(post)
    end

    it 'nullifies posts when destroyed' do
      post_id = post.id
      content_type.destroy
      
      post.reload
      expect(post.content_type).to be_nil
    end
  end
end
