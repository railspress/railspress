require 'rails_helper'

RSpec.describe Api::V1::MediaController, type: :controller do
  let(:user) { create(:user, role: 'administrator') }
  let(:web_channel) { create(:channel, :web) }
  let(:mobile_channel) { create(:channel, :mobile) }
  let(:medium1) { create(:medium, title: 'Web Image', file_name: 'web.jpg') }
  let(:medium2) { create(:medium, title: 'Mobile Image', file_name: 'mobile.jpg') }

  before do
    # Associate media with channels
    medium1.channels << web_channel
    medium2.channels << mobile_channel
  end

  describe 'GET #index' do
    context 'without channel parameter' do
      it 'returns all media' do
        get :index
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)['data']
        expect(response_data.length).to eq(2)
        expect(response_data.map { |m| m['title'] }).to include('Web Image', 'Mobile Image')
      end
    end

    context 'with channel parameter' do
      it 'returns media for specific channel' do
        get :index, params: { channel: 'web' }
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)['data']
        expect(response_data.length).to eq(1)
        expect(response_data.first['title']).to eq('Web Image')
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
  end

  describe 'channel filtering with exclusions' do
    let!(:exclusion_override) do
      create(:channel_override, 
        channel: web_channel, 
        resource_type: 'Medium', 
        resource_id: medium2.id, 
        kind: 'exclude'
      )
    end

    it 'excludes media with exclusion overrides' do
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
        resource_type: 'Medium',
        resource_id: medium1.id,
        kind: 'override',
        path: 'title',
        data: 'Overridden Media Title'
      )
    end

    it 'applies channel overrides to media data' do
      get :index, params: { channel: 'web' }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)['data']
      expect(response_data.first['title']).to eq('Overridden Media Title')
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
    it 'returns a specific medium' do
      get :show, params: { id: medium1.id }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)['data']
      expect(response_data['id']).to eq(medium1.id)
      expect(response_data['title']).to eq(medium1.title)
    end

    context 'with channel parameter' do
      let!(:title_override) do
        create(:channel_override,
          channel: web_channel,
          resource_type: 'Medium',
          resource_id: medium1.id,
          kind: 'override',
          path: 'title',
          data: 'Overridden Media Title'
        )
      end

      it 'applies channel overrides to detailed media data' do
        get :show, params: { id: medium1.id, channel: 'web' }
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)['data']
        expect(response_data['title']).to eq('Overridden Media Title')
        expect(response_data['provenance']).to be_present
      end
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        title: 'New Media',
        file_name: 'new.jpg',
        file_type: 'image/jpeg',
        channel_ids: [web_channel.id]
      }
    end

    before do
      allow(controller).to receive(:current_api_user).and_return(user)
    end

    context 'with valid parameters' do
      it 'creates a new medium' do
        expect {
          post :create, params: { medium: valid_attributes }
        }.to change(Medium, :count).by(1)
      end

      it 'associates medium with channels' do
        post :create, params: { medium: valid_attributes }
        new_medium = Medium.last
        expect(new_medium.channels).to include(web_channel)
      end

      it 'returns a created response' do
        post :create, params: { medium: valid_attributes }
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid parameters' do
      it 'returns an error response' do
        post :create, params: { medium: { title: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH #update' do
    before do
      allow(controller).to receive(:current_api_user).and_return(user)
    end

    context 'with valid parameters' do
      let(:new_attributes) { { title: 'Updated Media', channel_ids: [mobile_channel.id] } }

      it 'updates the medium' do
        patch :update, params: { id: medium1.id, medium: new_attributes }
        medium1.reload
        expect(medium1.title).to eq('Updated Media')
      end

      it 'updates channel associations' do
        patch :update, params: { id: medium1.id, medium: new_attributes }
        medium1.reload
        expect(medium1.channels).to include(mobile_channel)
        expect(medium1.channels).not_to include(web_channel)
      end

      it 'returns a success response' do
        patch :update, params: { id: medium1.id, medium: new_attributes }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid parameters' do
      it 'returns an error response' do
        patch :update, params: { id: medium1.id, medium: { title: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      allow(controller).to receive(:current_api_user).and_return(user)
    end

    it 'destroys the medium' do
      expect {
        delete :destroy, params: { id: medium1.id }
      }.to change(Medium, :count).by(-1)
    end

    it 'returns a success response' do
      delete :destroy, params: { id: medium1.id }
      expect(response).to have_http_status(:ok)
    end
  end
end

