require 'rails_helper'

RSpec.describe 'Channel Override Logic', type: :model do
  let(:web_channel) { create(:channel, :web) }
  let(:mobile_channel) { create(:channel, :mobile) }
  let(:post) { create(:post, title: 'Original Title', content: 'Original content') }

  describe 'ChannelOverride#apply_to_data' do
    let(:override) do
      create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post.id,
        kind: 'override',
        path: 'title',
        data: 'Overridden Title'
      )
    end

    it 'applies simple field overrides' do
      original_data = { title: 'Original Title', content: 'Original content' }
      result = override.apply_to_data(original_data)
      
      expect(result['title']).to eq('Overridden Title')
      expect(result['content']).to eq('Original content')
    end

    it 'applies nested field overrides' do
      nested_override = create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post.id,
        kind: 'override',
        path: 'metadata.author',
        data: 'Channel Author'
      )
      
      original_data = { 
        title: 'Original Title',
        metadata: { author: 'Original Author', date: '2024-01-01' }
      }
      
      result = nested_override.apply_to_data(original_data)
      
      expect(result['metadata']['author']).to eq('Channel Author')
      expect(result['metadata']['date']).to eq('2024-01-01')
    end

    it 'applies array overrides' do
      array_override = create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post.id,
        kind: 'override',
        path: 'tags',
        data: ['web', 'channel', 'override']
      )
      
      original_data = { title: 'Original Title', tags: ['original', 'tag'] }
      result = array_override.apply_to_data(original_data)
      
      expect(result['tags']).to eq(['web', 'channel', 'override'])
    end

    it 'handles deep nested overrides' do
      deep_override = create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post.id,
        kind: 'override',
        path: 'settings.theme.colors.primary',
        data: '#ff0000'
      )
      
      original_data = {
        title: 'Original Title',
        settings: {
          theme: {
            colors: {
              primary: '#000000',
              secondary: '#ffffff'
            },
            font: 'Arial'
          }
        }
      }
      
      result = deep_override.apply_to_data(original_data)
      
      expect(result['settings']['theme']['colors']['primary']).to eq('#ff0000')
      expect(result['settings']['theme']['colors']['secondary']).to eq('#ffffff')
      expect(result['settings']['theme']['font']).to eq('Arial')
    end
  end

  describe 'ChannelOverride#should_exclude_resource?' do
    let(:exclusion_override) do
      create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post.id,
        kind: 'exclude'
      )
    end

    it 'returns true for exclusion overrides' do
      expect(exclusion_override.should_exclude_resource?).to be true
    end

    it 'returns false for override types' do
      override = create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post.id,
        kind: 'override',
        path: 'title',
        data: 'New Title'
      )
      
      expect(override.should_exclude_resource?).to be false
    end

    it 'returns false for disabled exclusions' do
      exclusion_override.update(enabled: false)
      expect(exclusion_override.should_exclude_resource?).to be false
    end
  end

  describe 'Channel#apply_overrides_to_data' do
    let!(:title_override) do
      create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post.id,
        kind: 'override',
        path: 'title',
        data: 'Channel Title'
      )
    end

    let!(:content_override) do
      create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post.id,
        kind: 'override',
        path: 'content',
        data: 'Channel Content'
      )
    end

    it 'applies multiple overrides to data' do
      original_data = { title: 'Original Title', content: 'Original content' }
      result = web_channel.apply_overrides_to_data(original_data, 'Post', post.id)
      
      expect(result['title']).to eq('Channel Title')
      expect(result['content']).to eq('Channel Content')
    end

    it 'returns provenance information' do
      original_data = { title: 'Original Title', content: 'Original content' }
      result, provenance = web_channel.apply_overrides_to_data(original_data, 'Post', post.id, true)
      
      expect(provenance['title']).to eq('channel_override')
      expect(provenance['content']).to eq('channel_override')
    end

    it 'handles disabled overrides' do
      title_override.update(enabled: false)
      
      original_data = { title: 'Original Title', content: 'Original content' }
      result = web_channel.apply_overrides_to_data(original_data, 'Post', post.id)
      
      expect(result['title']).to eq('Original Title')
      expect(result['content']).to eq('Channel Content')
    end

    it 'handles conflicting overrides (last one wins)' do
      create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post.id,
        kind: 'override',
        path: 'title',
        data: 'Second Title'
      )
      
      original_data = { title: 'Original Title' }
      result = web_channel.apply_overrides_to_data(original_data, 'Post', post.id)
      
      expect(result['title']).to eq('Second Title')
    end
  end

  describe 'Complex Override Scenarios' do
    let(:complex_post) { create(:post) }
    
    before do
      complex_post.channels << web_channel
    end

    it 'handles mixed override types' do
      # Create multiple overrides
      create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: complex_post.id,
        kind: 'override',
        path: 'title',
        data: 'Overridden Title'
      )
      
      create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: complex_post.id,
        kind: 'override',
        path: 'metadata.author',
        data: 'Channel Author'
      )
      
      create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: complex_post.id,
        kind: 'override',
        path: 'tags',
        data: ['web', 'channel']
      )
      
      original_data = {
        title: 'Original Title',
        content: 'Original content',
        metadata: { author: 'Original Author', date: '2024-01-01' },
        tags: ['original']
      }
      
      result = web_channel.apply_overrides_to_data(original_data, 'Post', complex_post.id)
      
      expect(result['title']).to eq('Overridden Title')
      expect(result['content']).to eq('Original content')
      expect(result['metadata']['author']).to eq('Channel Author')
      expect(result['metadata']['date']).to eq('2024-01-01')
      expect(result['tags']).to eq(['web', 'channel'])
    end

    it 'handles array element overrides' do
      create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: complex_post.id,
        kind: 'override',
        path: 'categories.0',
        data: 'Web Category'
      )
      
      original_data = {
        categories: ['Original Category', 'Another Category']
      }
      
      result = web_channel.apply_overrides_to_data(original_data, 'Post', complex_post.id)
      
      expect(result['categories'][0]).to eq('Web Category')
      expect(result['categories'][1]).to eq('Another Category')
    end

    it 'handles hash key overrides' do
      create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: complex_post.id,
        kind: 'override',
        path: 'settings.theme',
        data: { colors: { primary: '#ff0000' }, font: 'Arial' }
      )
      
      original_data = {
        settings: {
          theme: {
            colors: { primary: '#000000', secondary: '#ffffff' },
            font: 'Times'
          },
          layout: 'default'
        }
      }
      
      result = web_channel.apply_overrides_to_data(original_data, 'Post', complex_post.id)
      
      expect(result['settings']['theme']['colors']['primary']).to eq('#ff0000')
      expect(result['settings']['theme']['font']).to eq('Arial')
      expect(result['settings']['layout']).to eq('default')
    end
  end

  describe 'Error Handling' do
    it 'handles invalid paths gracefully' do
      invalid_override = create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post.id,
        kind: 'override',
        path: 'nonexistent.deep.path',
        data: 'Value'
      )
      
      original_data = { title: 'Original Title' }
      result = invalid_override.apply_to_data(original_data)
      
      expect(result['title']).to eq('Original Title')
      expect(result['nonexistent']).to be_nil
    end

    it 'handles nil data gracefully' do
      nil_override = create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post.id,
        kind: 'override',
        path: 'title',
        data: nil
      )
      
      original_data = { title: 'Original Title' }
      result = nil_override.apply_to_data(original_data)
      
      expect(result['title']).to be_nil
    end

    it 'handles empty data gracefully' do
      empty_override = create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post.id,
        kind: 'override',
        path: 'title',
        data: ''
      )
      
      original_data = { title: 'Original Title' }
      result = empty_override.apply_to_data(original_data)
      
      expect(result['title']).to eq('')
    end
  end

  describe 'Performance Considerations' do
    it 'efficiently handles many overrides' do
      # Create many overrides
      100.times do |i|
        create(:channel_override,
          channel: web_channel,
          resource_type: 'Post',
          resource_id: post.id,
          kind: 'override',
          path: "field_#{i}",
          data: "Value #{i}"
        )
      end
      
      original_data = {}
      100.times { |i| original_data["field_#{i}"] = "Original #{i}" }
      
      # Should complete quickly
      start_time = Time.current
      result = web_channel.apply_overrides_to_data(original_data, 'Post', post.id)
      end_time = Time.current
      
      expect(end_time - start_time).to be < 1.second
      expect(result.keys.length).to eq(100)
    end
  end
end

