require 'rails_helper'

RSpec.describe Channel, type: :model do
  describe 'associations' do
    it { should have_and_belongs_to_many(:posts) }
    it { should have_and_belongs_to_many(:pages) }
    it { should have_and_belongs_to_many(:media) }
    it { should have_many(:channel_overrides).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_presence_of(:locale) }
    it { should validate_uniqueness_of(:slug) }
  end

  describe 'scopes' do
    let!(:web_channel) { create(:channel, slug: 'web', domain: 'www.example.com') }
    let!(:mobile_channel) { create(:channel, slug: 'mobile', domain: 'm.example.com') }
    let!(:en_channel) { create(:channel, slug: 'en-channel', locale: 'en') }
    let!(:es_channel) { create(:channel, slug: 'es-channel', locale: 'es') }

    describe '.by_domain' do
      it 'returns channels by domain' do
        expect(Channel.by_domain('www.example.com')).to include(web_channel)
        expect(Channel.by_domain('www.example.com')).not_to include(mobile_channel)
      end
    end

    describe '.by_locale' do
      it 'returns channels by locale' do
        expect(Channel.by_locale('en')).to include(en_channel, web_channel, mobile_channel)
        expect(Channel.by_locale('es')).to include(es_channel)
      end
    end
  end

  describe 'methods' do
    let(:channel) { create(:channel) }
    let(:post) { create(:post) }
    let(:page) { create(:page) }

    describe '#find_by_domain' do
      it 'finds channel by domain' do
        channel.update(domain: 'test.example.com')
        expect(Channel.find_by_domain('test.example.com')).to eq(channel)
      end
    end

    describe '#find_by_slug' do
      it 'finds channel by slug' do
        expect(Channel.find_by_slug(channel.slug)).to eq(channel)
      end
    end

    describe '#override_for' do
      let!(:override) { create(:channel_override, channel: channel, resource_type: 'Post', resource_id: post.id, path: 'title') }

      it 'finds override for specific resource and path' do
        expect(channel.override_for('Post', post.id, 'title')).to eq(override)
      end

      it 'returns nil if no override found' do
        expect(channel.override_for('Post', post.id, 'content')).to be_nil
      end
    end

    describe '#excluded?' do
      let!(:exclusion) { create(:channel_override, channel: channel, resource_type: 'Post', resource_id: post.id, kind: 'exclude') }

      it 'returns true if resource is excluded' do
        expect(channel.excluded?('Post', post.id)).to be true
      end

      it 'returns false if resource is not excluded' do
        expect(channel.excluded?('Page', page.id)).to be false
      end
    end

    describe '#apply_overrides_to_data' do
      let!(:override) { create(:channel_override, channel: channel, resource_type: 'Post', resource_id: post.id, path: 'title', data: 'Overridden Title') }
      
      it 'applies overrides to data' do
        original_data = { title: 'Original Title', content: 'Original Content' }
        result = channel.apply_overrides_to_data(original_data, 'Post', post.id)
        
        expect(result[:title]).to eq('Overridden Title')
        expect(result[:content]).to eq('Original Content')
      end

      it 'returns original data if no overrides' do
        original_data = { title: 'Original Title' }
        result = channel.apply_overrides_to_data(original_data, 'Page', page.id)
        
        expect(result).to eq(original_data)
      end
    end
  end

  describe 'callbacks' do
    it 'sets default locale before validation' do
      channel = build(:channel, locale: nil)
      channel.valid?
      expect(channel.locale).to eq('en')
    end

    it 'generates slug from name if slug is blank' do
      channel = build(:channel, name: 'Test Channel', slug: nil)
      channel.valid?
      expect(channel.slug).to eq('test-channel')
    end
  end
end