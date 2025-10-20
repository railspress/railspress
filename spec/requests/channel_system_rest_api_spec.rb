require 'rails_helper'

RSpec.describe "Channel System REST API", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:web_channel) { create(:channel, :web) }
  let(:mobile_channel) { create(:channel, :mobile) }
  let(:post) { create(:post) }

  before do
    # Associate post with channels
    post.channels << [web_channel, mobile_channel]
  end

  describe "GET /api/v1/posts" do
    context "without channel parameter" do
      it "returns all posts" do
        get "/api/v1/posts"
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']).to be_an(Array)
        expect(json['data'].first['channels']).to include('web', 'mobile')
      end
    end

    context "with channel parameter" do
      it "returns posts filtered by channel" do
        get "/api/v1/posts", params: { channel: 'web' }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['meta']['filters']['channel']).to eq('web')
        expect(json['data'].first['channel_context']).to eq('web')
      end

      it "applies channel exclusions" do
        # Create an exclusion override
        create(:channel_override, :exclusion, 
               channel: web_channel, 
               resource_type: 'Post', 
               resource_id: post.id)

        get "/api/v1/posts", params: { channel: 'web' }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']).to be_empty
      end
    end

    context "with auto-detected channel" do
      it "detects mobile user agent and applies mobile channel" do
        get "/api/v1/posts", 
            headers: { 'User-Agent' => 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)' }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['meta']['filters']['channel']).to eq('mobile')
        expect(json['data'].first['channel_context']).to eq('mobile')
      end

      it "detects desktop user agent and applies web channel" do
        get "/api/v1/posts", 
            headers: { 'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)' }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['meta']['filters']['channel']).to eq('web')
        expect(json['data'].first['channel_context']).to eq('web')
      end
    end
  end

  describe "GET /api/v1/posts/:id" do
    it "returns post with channel context" do
      get "/api/v1/posts/#{post.id}", params: { channel: 'mobile' }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['channel_context']).to eq('mobile')
      expect(json['data']['channels']).to include('web', 'mobile')
    end
  end

  describe "GET /api/v1/channels" do
    it "returns all channels" do
      get "/api/v1/channels"
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']).to be_an(Array)
      expect(json['data'].length).to eq(2)
    end

    it "returns channel with correct structure" do
      get "/api/v1/channels"
      
      json = JSON.parse(response.body)
      channel_data = json['data'].first
      
      expect(channel_data).to include('id', 'name', 'slug', 'domain', 'locale')
      expect(channel_data['metadata']).to be_a(Hash)
      expect(channel_data['settings']).to be_a(Hash)
    end
  end

  describe "Channel Overrides" do
    let(:override) do
      create(:channel_override, 
             channel: web_channel, 
             resource_type: 'Post', 
             resource_id: post.id,
             path: 'title',
             data: 'Mobile Optimized Title')
    end

    it "applies overrides to post data" do
      override
      
      get "/api/v1/posts/#{post.id}", params: { channel: 'web' }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['title']).to eq('Mobile Optimized Title')
      expect(json['data']['provenance']['title']).to eq('channel_override')
    end
  end

  describe "Error Handling" do
    it "handles invalid channel gracefully" do
      get "/api/v1/posts", params: { channel: 'invalid' }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['meta']['filters']['channel']).to be_nil
    end

    it "handles missing post gracefully" do
      get "/api/v1/posts/99999", params: { channel: 'web' }
      
      expect(response).to have_http_status(:not_found)
    end
  end
end

