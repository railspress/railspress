require 'rails_helper'

RSpec.describe ChannelOverride, type: :model do
  describe 'associations' do
    it { should belong_to(:channel) }
  end

  describe 'validations' do
    it { should validate_presence_of(:resource_type) }
    it { should validate_presence_of(:kind) }
    it { should validate_presence_of(:path) }
    it { should validate_inclusion_of(:kind).in_array(%w[override exclude]) }
  end

  describe 'scopes' do
    let!(:override) { create(:channel_override, kind: 'override') }
    let!(:exclusion) { create(:channel_override, kind: 'exclude') }
    let!(:enabled_override) { create(:channel_override, enabled: true) }
    let!(:disabled_override) { create(:channel_override, enabled: false) }

    describe '.overrides' do
      it 'returns only override type' do
        expect(ChannelOverride.overrides).to include(override)
        expect(ChannelOverride.overrides).not_to include(exclusion)
      end
    end

    describe '.exclusions' do
      it 'returns only exclude type' do
        expect(ChannelOverride.exclusions).to include(exclusion)
        expect(ChannelOverride.exclusions).not_to include(override)
      end
    end

    describe '.enabled' do
      it 'returns only enabled overrides' do
        expect(ChannelOverride.enabled).to include(enabled_override)
        expect(ChannelOverride.enabled).not_to include(disabled_override)
      end
    end

    describe '.for_resource' do
      let!(:post_override) { create(:channel_override, resource_type: 'Post', resource_id: 1) }
      let!(:page_override) { create(:channel_override, resource_type: 'Page', resource_id: 1) }

      it 'returns overrides for specific resource' do
        expect(ChannelOverride.for_resource('Post', 1)).to include(post_override)
        expect(ChannelOverride.for_resource('Post', 1)).not_to include(page_override)
      end
    end
  end

  describe 'methods' do
    let(:channel) { create(:channel) }
    let(:post) { create(:post) }
    let(:override) { create(:channel_override, channel: channel, resource_type: 'Post', resource_id: post.id) }

    describe '#resource' do
      it 'returns the associated resource' do
        expect(override.resource).to eq(post)
      end

      it 'returns nil for unknown resource type' do
        override.update(resource_type: 'Unknown', resource_id: 999)
        expect(override.resource).to be_nil
      end
    end

    describe '#resource_name' do
      it 'returns resource title or name' do
        expect(override.resource_name).to eq(post.title)
      end

      it 'returns fallback name for missing resource' do
        override.update(resource_id: 999)
        expect(override.resource_name).to eq('Post #999')
      end
    end

    describe '#is_override?' do
      it 'returns true for override kind' do
        expect(override.is_override?).to be true
      end

      it 'returns false for exclude kind' do
        override.update(kind: 'exclude')
        expect(override.is_override?).to be false
      end
    end

    describe '#is_exclusion?' do
      it 'returns true for exclude kind' do
        override.update(kind: 'exclude')
        expect(override.is_exclusion?).to be true
      end

      it 'returns false for override kind' do
        expect(override.is_exclusion?).to be false
      end
    end

    describe '#apply_to_data' do
      it 'applies override to data' do
        override.update(path: 'title', data: 'New Title')
        data = { title: 'Old Title' }
        result = override.apply_to_data(data)
        expect(result[:title]).to eq('New Title')
      end

      it 'does not apply if disabled' do
        override.update(enabled: false, path: 'title', data: 'New Title')
        data = { title: 'Old Title' }
        result = override.apply_to_data(data)
        expect(result[:title]).to eq('Old Title')
      end

      it 'does not apply if not override kind' do
        override.update(kind: 'exclude', path: 'title', data: 'New Title')
        data = { title: 'Old Title' }
        result = override.apply_to_data(data)
        expect(result[:title]).to eq('Old Title')
      end
    end

    describe '#should_exclude_resource?' do
      it 'returns true for enabled exclusion' do
        override.update(kind: 'exclude', enabled: true)
        expect(override.should_exclude_resource?).to be true
      end

      it 'returns false for disabled exclusion' do
        override.update(kind: 'exclude', enabled: false)
        expect(override.should_exclude_resource?).to be false
      end

      it 'returns false for override kind' do
        expect(override.should_exclude_resource?).to be false
      end
    end
  end
end