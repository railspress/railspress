require 'rails_helper'

RSpec.describe 'Channel System Integration', type: :request do
  let(:user) { create(:user, role: 'administrator') }
  let(:web_channel) { create(:channel, :web) }
  let(:mobile_channel) { create(:channel, :mobile) }
  let(:post) { create(:post, title: 'Original Title', content: 'Original content') }
  let(:page) { create(:page, title: 'Original Page Title', content: 'Original page content') }
  let(:medium) { create(:medium, title: 'Original Media Title') }

  before do
    # Associate content with channels
    post.channels << web_channel
    page.channels << web_channel
    medium.channels << web_channel
  end

  describe 'API Channel Filtering' do
    context 'Posts API' do
      it 'filters posts by channel' do
        get '/api/v1/posts', params: { channel: 'web' }
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)
        expect(response_data['data'].length).to eq(1)
        expect(response_data['data'].first['title']).to eq('Original Title')
        expect(response_data['meta']['filters']['channel']).to eq('web')
      end

      it 'returns empty array for non-existent channel' do
        get '/api/v1/posts', params: { channel: 'nonexistent' }
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)
        expect(response_data['data']).to be_empty
      end
    end

    context 'Pages API' do
      it 'filters pages by channel' do
        get '/api/v1/pages', params: { channel: 'web' }
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)
        expect(response_data['data'].length).to eq(1)
        expect(response_data['data'].first['title']).to eq('Original Page Title')
        expect(response_data['meta']['filters']['channel']).to eq('web')
      end
    end

    context 'Media API' do
      it 'filters media by channel' do
        get '/api/v1/media', params: { channel: 'web' }
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)
        expect(response_data['data'].length).to eq(1)
        expect(response_data['data'].first['title']).to eq('Original Media Title')
        expect(response_data['meta']['filters']['channel']).to eq('web')
      end
    end
  end

  describe 'Channel Overrides' do
    let!(:title_override) do
      create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post.id,
        kind: 'override',
        path: 'title',
        data: 'Overridden Title'
      )
    end

    let!(:content_override) do
      create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post.id,
        kind: 'override',
        path: 'content',
        data: 'Overridden content'
      )
    end

    it 'applies overrides to post data via API' do
      get '/api/v1/posts', params: { channel: 'web' }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)
      post_data = response_data['data'].first
      
      expect(post_data['title']).to eq('Overridden Title')
      expect(post_data['content']).to eq('Overridden content')
      expect(post_data['provenance']).to be_present
      expect(post_data['provenance']['title']).to eq('channel_override')
      expect(post_data['provenance']['content']).to eq('channel_override')
    end

    it 'applies overrides to individual post via API' do
      get "/api/v1/posts/#{post.id}", params: { channel: 'web' }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)
      post_data = response_data['data']
      
      expect(post_data['title']).to eq('Overridden Title')
      expect(post_data['content']).to eq('Overridden content')
      expect(post_data['provenance']).to be_present
    end
  end

  describe 'Channel Exclusions' do
    let!(:exclusion_override) do
      create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post.id,
        kind: 'exclude'
      )
    end

    it 'excludes posts with exclusion overrides' do
      get '/api/v1/posts', params: { channel: 'web' }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)
      expect(response_data['data']).to be_empty
    end

    it 'does not exclude posts for other channels' do
      get '/api/v1/posts', params: { channel: 'mobile' }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)
      expect(response_data['data']).to be_empty # No posts associated with mobile channel
    end
  end

  describe 'Admin Interface' do
    before do
      sign_in user
    end

    it 'allows creating channels via admin interface' do
      get '/admin/system/channels/new'
      expect(response).to have_http_status(:ok)

      post '/admin/system/channels', params: {
        channel: {
          name: 'Test Channel',
          slug: 'test-channel',
          domain: 'test.example.com',
          locale: 'en'
        }
      }
      
      expect(response).to redirect_to(admin_system_channel_path(Channel.last))
      expect(Channel.last.name).to eq('Test Channel')
    end

    it 'allows managing channel overrides via admin interface' do
      get "/admin/system/channels/#{web_channel.id}/channel_overrides/new"
      expect(response).to have_http_status(:ok)

      post "/admin/system/channels/#{web_channel.id}/channel_overrides", params: {
        channel_override: {
          resource_type: 'Post',
          resource_id: post.id,
          kind: 'override',
          path: 'title',
          data: 'Admin Override Title',
          enabled: true
        }
      }
      
      expect(response).to redirect_to(admin_system_channel_path(web_channel))
      expect(ChannelOverride.last.data).to eq('Admin Override Title')
    end

    it 'allows copying overrides between channels' do
      source_override = create(:channel_override, channel: mobile_channel, resource: post)
      
      post "/admin/system/channels/#{web_channel.id}/channel_overrides/copy_from_channel", params: {
        source_channel_id: mobile_channel.id
      }
      
      expect(response).to redirect_to(admin_system_channel_path(web_channel))
      expect(web_channel.channel_overrides.count).to eq(1)
    end
  end

  describe 'Complex Override Scenarios' do
    let!(:nested_override) do
      create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post.id,
        kind: 'override',
        path: 'metadata.author',
        data: 'Channel Author'
      )
    end

    let!(:array_override) do
      create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post.id,
        kind: 'override',
        path: 'tags',
        data: ['web', 'channel', 'override']
      )
    end

    it 'handles nested path overrides' do
      get '/api/v1/posts', params: { channel: 'web' }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)
      post_data = response_data['data'].first
      
      expect(post_data['metadata']['author']).to eq('Channel Author')
      expect(post_data['provenance']['metadata.author']).to eq('channel_override')
    end

    it 'handles array overrides' do
      get '/api/v1/posts', params: { channel: 'web' }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)
      post_data = response_data['data'].first
      
      expect(post_data['tags']).to eq(['web', 'channel', 'override'])
      expect(post_data['provenance']['tags']).to eq('channel_override')
    end
  end

  describe 'Channel Association Management' do
    it 'allows associating content with multiple channels' do
      post.channels << mobile_channel
      
      expect(post.channels).to include(web_channel, mobile_channel)
      
      # Should appear in both channel APIs
      get '/api/v1/posts', params: { channel: 'web' }
      web_response = JSON.parse(response.body)
      
      get '/api/v1/posts', params: { channel: 'mobile' }
      mobile_response = JSON.parse(response.body)
      
      expect(web_response['data'].length).to eq(1)
      expect(mobile_response['data'].length).to eq(1)
    end

    it 'allows removing content from channels' do
      post.channels.delete(web_channel)
      
      get '/api/v1/posts', params: { channel: 'web' }
      response_data = JSON.parse(response.body)
      
      expect(response_data['data']).to be_empty
    end
  end

  describe 'Error Handling' do
    it 'handles invalid channel parameters gracefully' do
      get '/api/v1/posts', params: { channel: 'invalid-channel' }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)
      expect(response_data['data']).to be_empty
    end

    it 'handles malformed override data gracefully' do
      create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post.id,
        kind: 'override',
        path: 'title',
        data: nil
      )
      
      get '/api/v1/posts', params: { channel: 'web' }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)
      expect(response_data['data']).to be_present
    end
  end
end

