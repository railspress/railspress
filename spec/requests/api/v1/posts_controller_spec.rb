require 'rails_helper'

RSpec.describe Api::V1::PostsController, type: :controller do
  let(:user) { create(:user, role: 'administrator') }
  let(:channel) { create(:channel) }
  let(:post) { create(:post) }
  let(:channel_post) { create(:post) }

  before do
    sign_in user
    # Assign post to channel
    channel.posts << channel_post
  end

  describe 'GET #index with channel filtering' do
    it 'returns posts for specific channel' do
      get :index, params: { channel: channel.slug }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)['data']
      expect(response_data.length).to eq(1)
      expect(response_data.first['id']).to eq(channel_post.id)
    end

    it 'returns global posts when no channel specified' do
      get :index
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)['data']
      expect(response_data.length).to eq(2) # Both posts
    end

    it 'applies channel exclusions' do
      # Create an exclusion for the channel_post
      create(:channel_override, 
             channel: channel, 
             resource_type: 'Post', 
             resource_id: channel_post.id, 
             kind: 'exclude')
      
      get :index, params: { channel: channel.slug }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)['data']
      expect(response_data.length).to eq(0) # No posts due to exclusion
    end

    it 'applies channel overrides' do
      # Create an override for the channel_post
      create(:channel_override, 
             channel: channel, 
             resource_type: 'Post', 
             resource_id: channel_post.id, 
             path: 'title', 
             data: 'Overridden Title')
      
      get :index, params: { channel: channel.slug }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)['data']
      expect(response_data.first['title']).to eq('Overridden Title')
      expect(response_data.first['provenance']['title']).to eq('channel_override')
    end

    it 'includes channel context in response' do
      get :index, params: { channel: channel.slug }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)['data']
      expect(response_data.first['channel_context']).to eq(channel.slug)
      expect(response_data.first['channels']).to include(channel.slug)
    end
  end
end

