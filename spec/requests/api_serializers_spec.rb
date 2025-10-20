require 'rails_helper'

RSpec.describe 'API Serializers', type: :request do
  let(:web_channel) { create(:channel, :web) }
  let(:mobile_channel) { create(:channel, :mobile) }
  let(:post) { create(:post, title: 'Original Title', content: 'Original content') }
  let(:page) { create(:page, title: 'Original Page Title', content: 'Original page content') }
  let(:medium) { create(:medium, title: 'Original Media Title', file_name: 'test.jpg') }

  before do
    post.channels << web_channel
    page.channels << web_channel
    medium.channels << web_channel
  end

  describe 'Posts API Serializer' do
    context 'without channel parameter' do
      it 'returns posts with basic fields' do
        get '/api/v1/posts'
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)
        expect(response_data['success']).to be true
        expect(response_data['data']).to be_an(Array)
        expect(response_data['data'].first).to include('id', 'title', 'slug', 'status')
      end

      it 'includes channels field' do
        get '/api/v1/posts'
        response_data = JSON.parse(response.body)
        post_data = response_data['data'].first
        
        expect(post_data['channels']).to eq(['web'])
      end

      it 'includes channel_context field' do
        get '/api/v1/posts'
        response_data = JSON.parse(response.body)
        post_data = response_data['data'].first
        
        expect(post_data['channel_context']).to be_nil
      end
    end

    context 'with channel parameter' do
      it 'includes channel_context field' do
        get '/api/v1/posts', params: { channel: 'web' }
        response_data = JSON.parse(response.body)
        post_data = response_data['data'].first
        
        expect(post_data['channel_context']).to eq('web')
      end

      it 'includes provenance field when overrides are applied' do
        create(:channel_override,
          channel: web_channel,
          resource_type: 'Post',
          resource_id: post.id,
          kind: 'override',
          path: 'title',
          data: 'Overridden Title'
        )
        
        get '/api/v1/posts', params: { channel: 'web' }
        response_data = JSON.parse(response.body)
        post_data = response_data['data'].first
        
        expect(post_data['provenance']).to be_present
        expect(post_data['provenance']['title']).to eq('channel_override')
      end
    end

    context 'detailed post view' do
      it 'returns detailed post data' do
        get "/api/v1/posts/#{post.id}"
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)
        expect(response_data['success']).to be true
        expect(response_data['data']).to include('id', 'title', 'slug', 'status')
      end

      it 'applies channel overrides in detailed view' do
        create(:channel_override,
          channel: web_channel,
          resource_type: 'Post',
          resource_id: post.id,
          kind: 'override',
          path: 'title',
          data: 'Detailed Override Title'
        )
        
        get "/api/v1/posts/#{post.id}", params: { channel: 'web' }
        response_data = JSON.parse(response.body)
        post_data = response_data['data']
        
        expect(post_data['title']).to eq('Detailed Override Title')
        expect(post_data['provenance']['title']).to eq('channel_override')
      end
    end
  end

  describe 'Pages API Serializer' do
    context 'without channel parameter' do
      it 'returns pages with basic fields' do
        get '/api/v1/pages'
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)
        expect(response_data['success']).to be true
        expect(response_data['data']).to be_an(Array)
        expect(response_data['data'].first).to include('id', 'title', 'slug', 'status')
      end

      it 'includes channels field' do
        get '/api/v1/pages'
        response_data = JSON.parse(response.body)
        page_data = response_data['data'].first
        
        expect(page_data['channels']).to eq(['web'])
      end
    end

    context 'with channel parameter' do
      it 'applies channel overrides' do
        create(:channel_override,
          channel: web_channel,
          resource_type: 'Page',
          resource_id: page.id,
          kind: 'override',
          path: 'title',
          data: 'Overridden Page Title'
        )
        
        get '/api/v1/pages', params: { channel: 'web' }
        response_data = JSON.parse(response.body)
        page_data = response_data['data'].first
        
        expect(page_data['title']).to eq('Overridden Page Title')
        expect(page_data['channel_context']).to eq('web')
        expect(page_data['provenance']['title']).to eq('channel_override')
      end
    end
  end

  describe 'Media API Serializer' do
    context 'without channel parameter' do
      it 'returns media with basic fields' do
        get '/api/v1/media'
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)
        expect(response_data['success']).to be true
        expect(response_data['data']).to be_an(Array)
        expect(response_data['data'].first).to include('id', 'title', 'file_name', 'file_type')
      end

      it 'includes channels field' do
        get '/api/v1/media'
        response_data = JSON.parse(response.body)
        media_data = response_data['data'].first
        
        expect(media_data['channels']).to eq(['web'])
      end
    end

    context 'with channel parameter' do
      it 'applies channel overrides' do
        create(:channel_override,
          channel: web_channel,
          resource_type: 'Medium',
          resource_id: medium.id,
          kind: 'override',
          path: 'title',
          data: 'Overridden Media Title'
        )
        
        get '/api/v1/media', params: { channel: 'web' }
        response_data = JSON.parse(response.body)
        media_data = response_data['data'].first
        
        expect(media_data['title']).to eq('Overridden Media Title')
        expect(media_data['channel_context']).to eq('web')
        expect(media_data['provenance']['title']).to eq('channel_override')
      end
    end
  end

  describe 'Channels API Serializer' do
    it 'returns channels with all fields' do
      get '/api/v1/channels'
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)
      expect(response_data['success']).to be true
      expect(response_data['data']).to be_an(Array)
      
      channel_data = response_data['data'].first
      expect(channel_data).to include('id', 'name', 'slug', 'domain', 'locale', 'metadata', 'settings')
    end

    it 'returns specific channel' do
      get "/api/v1/channels/#{web_channel.id}"
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)
      expect(response_data['success']).to be true
      expect(response_data['data']['id']).to eq(web_channel.id)
      expect(response_data['data']['name']).to eq(web_channel.name)
    end
  end

  describe 'Response Format Consistency' do
    it 'maintains consistent success response format' do
      get '/api/v1/posts'
      response_data = JSON.parse(response.body)
      
      expect(response_data).to have_key('success')
      expect(response_data).to have_key('data')
      expect(response_data['success']).to be true
      expect(response_data['data']).to be_an(Array)
    end

    it 'includes meta information when applicable' do
      get '/api/v1/posts', params: { channel: 'web' }
      response_data = JSON.parse(response.body)
      
      expect(response_data).to have_key('meta')
      expect(response_data['meta']).to have_key('filters')
      expect(response_data['meta']['filters']).to have_key('channel')
    end

    it 'handles error responses consistently' do
      get '/api/v1/posts/999999'
      expect(response).to have_http_status(:not_found)
      
      response_data = JSON.parse(response.body)
      expect(response_data).to have_key('success')
      expect(response_data).to have_key('error')
      expect(response_data['success']).to be false
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

    it 'handles nested field overrides in serializers' do
      get '/api/v1/posts', params: { channel: 'web' }
      response_data = JSON.parse(response.body)
      post_data = response_data['data'].first
      
      expect(post_data['metadata']['author']).to eq('Channel Author')
      expect(post_data['provenance']['metadata.author']).to eq('channel_override')
    end

    it 'handles array overrides in serializers' do
      get '/api/v1/posts', params: { channel: 'web' }
      response_data = JSON.parse(response.body)
      post_data = response_data['data'].first
      
      expect(post_data['tags']).to eq(['web', 'channel', 'override'])
      expect(post_data['provenance']['tags']).to eq('channel_override')
    end

    it 'handles multiple overrides on same resource' do
      get '/api/v1/posts', params: { channel: 'web' }
      response_data = JSON.parse(response.body)
      post_data = response_data['data'].first
      
      expect(post_data['metadata']['author']).to eq('Channel Author')
      expect(post_data['tags']).to eq(['web', 'channel', 'override'])
      expect(post_data['provenance'].keys).to include('metadata.author', 'tags')
    end
  end

  describe 'Pagination and Meta Information' do
    before do
      # Create multiple posts for pagination testing
      25.times do |i|
        post = create(:post, title: "Post #{i}")
        post.channels << web_channel
      end
    end

    it 'includes pagination information' do
      get '/api/v1/posts', params: { page: 1, per_page: 10 }
      response_data = JSON.parse(response.body)
      
      expect(response_data['meta']).to have_key('pagination')
      expect(response_data['meta']['pagination']).to have_key('current_page')
      expect(response_data['meta']['pagination']).to have_key('per_page')
      expect(response_data['meta']['pagination']).to have_key('total_pages')
      expect(response_data['meta']['pagination']).to have_key('total_count')
    end

    it 'respects per_page parameter' do
      get '/api/v1/posts', params: { per_page: 5 }
      response_data = JSON.parse(response.body)
      
      expect(response_data['data'].length).to eq(5)
      expect(response_data['meta']['pagination']['per_page']).to eq(5)
    end

    it 'caps per_page at maximum limit' do
      get '/api/v1/posts', params: { per_page: 200 }
      response_data = JSON.parse(response.body)
      
      expect(response_data['meta']['pagination']['per_page']).to eq(100)
    end
  end
end

