require 'rails_helper'

RSpec.describe Api::V1::PostsController, type: :controller do
  let(:user) { create(:user, role: 'administrator') }
  let(:web_channel) { create(:channel, :web) }
  let(:mobile_channel) { create(:channel, :mobile) }
  let(:post1) { create(:post, title: 'Web Post', status: 'published') }
  let(:post2) { create(:post, title: 'Mobile Post', status: 'published') }
  let(:draft_post) { create(:post, title: 'Draft Post', status: 'draft') }

  before do
    # Associate posts with channels
    post1.channels << web_channel
    post2.channels << mobile_channel
  end

  describe 'GET #index' do
    context 'without channel parameter' do
      it 'returns all published posts' do
        get :index
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)['data']
        expect(response_data.length).to eq(2)
        expect(response_data.map { |p| p['title'] }).to include('Web Post', 'Mobile Post')
      end
    end

    context 'with channel parameter' do
      it 'returns posts for specific channel' do
        get :index, params: { channel: 'web' }
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)['data']
        expect(response_data.length).to eq(1)
        expect(response_data.first['title']).to eq('Web Post')
      end

      it 'includes channel context in response' do
        get :index, params: { channel: 'web' }
        
        response_data = JSON.parse(response.body)
        expect(response_data['meta']['filters']['channel']).to eq('web')
      end

      it 'returns empty array for non-existent channel' do
        get :index, params: { channel: 'nonexistent' }
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)['data']
        expect(response_data).to be_empty
      end
    end

    context 'with authenticated user' do
      before do
        allow(controller).to receive(:current_api_user).and_return(user)
      end

      it 'returns all posts including drafts for admin' do
        get :index
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)['data']
        expect(response_data.length).to eq(3)
        expect(response_data.map { |p| p['title'] }).to include('Web Post', 'Mobile Post', 'Draft Post')
      end
    end
  end

  describe 'channel filtering with exclusions' do
    let!(:exclusion_override) do
      create(:channel_override, 
        channel: web_channel, 
        resource_type: 'Post', 
        resource_id: post2.id, 
        kind: 'exclude'
      )
    end

    it 'excludes posts with exclusion overrides' do
      get :index, params: { channel: 'web' }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)['data']
      expect(response_data).to be_empty
    end
  end

  describe 'channel overrides' do
    let!(:title_override) do
      create(:channel_override,
        channel: web_channel,
        resource_type: 'Post',
        resource_id: post1.id,
        kind: 'override',
        path: 'title',
        data: 'Overridden Title'
      )
    end

    it 'applies channel overrides to post data' do
      get :index, params: { channel: 'web' }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)['data']
      expect(response_data.first['title']).to eq('Overridden Title')
    end

    it 'includes provenance information' do
      get :index, params: { channel: 'web' }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)['data']
      expect(response_data.first['provenance']).to be_present
      expect(response_data.first['provenance']['title']).to eq('channel_override')
    end
  end

  describe 'GET #show' do
    it 'returns a specific post' do
      get :show, params: { id: post1.id }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)['data']
      expect(response_data['id']).to eq(post1.id)
      expect(response_data['title']).to eq(post1.title)
    end

    context 'with channel parameter' do
      let!(:title_override) do
        create(:channel_override,
          channel: web_channel,
          resource_type: 'Post',
          resource_id: post1.id,
          kind: 'override',
          path: 'title',
          data: 'Overridden Title'
        )
      end

      it 'applies channel overrides to detailed post data' do
        get :show, params: { id: post1.id, channel: 'web' }
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)['data']
        expect(response_data['title']).to eq('Overridden Title')
        expect(response_data['provenance']).to be_present
      end
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        title: 'New Post',
        content: 'Post content',
        status: 'published',
        channel_ids: [web_channel.id]
      }
    end

    before do
      allow(controller).to receive(:current_api_user).and_return(user)
    end

    context 'with valid parameters' do
      it 'creates a new post' do
        expect {
          post :create, params: { post: valid_attributes }
        }.to change(Post, :count).by(1)
      end

      it 'associates post with channels' do
        post :create, params: { post: valid_attributes }
        new_post = Post.last
        expect(new_post.channels).to include(web_channel)
      end

      it 'returns a created response' do
        post :create, params: { post: valid_attributes }
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid parameters' do
      it 'returns an error response' do
        post :create, params: { post: { title: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH #update' do
    before do
      allow(controller).to receive(:current_api_user).and_return(user)
    end

    context 'with valid parameters' do
      let(:new_attributes) { { title: 'Updated Post', channel_ids: [mobile_channel.id] } }

      it 'updates the post' do
        patch :update, params: { id: post1.id, post: new_attributes }
        post1.reload
        expect(post1.title).to eq('Updated Post')
      end

      it 'updates channel associations' do
        patch :update, params: { id: post1.id, post: new_attributes }
        post1.reload
        expect(post1.channels).to include(mobile_channel)
        expect(post1.channels).not_to include(web_channel)
      end

      it 'returns a success response' do
        patch :update, params: { id: post1.id, post: new_attributes }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid parameters' do
      it 'returns an error response' do
        patch :update, params: { id: post1.id, post: { title: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      allow(controller).to receive(:current_api_user).and_return(user)
    end

    it 'destroys the post' do
      expect {
        delete :destroy, params: { id: post1.id }
      }.to change(Post, :count).by(-1)
    end

    it 'returns a success response' do
      delete :destroy, params: { id: post1.id }
      expect(response).to have_http_status(:ok)
    end
  end
end

