require 'rails_helper'

RSpec.describe Api::V1::ChannelsController, type: :controller do
  let(:user) { create(:user, role: 'administrator') }
  let(:channel) { create(:channel) }
  let(:valid_attributes) do
    {
      name: 'Test Channel',
      slug: 'test-channel',
      domain: 'test.example.com',
      locale: 'en',
      metadata: { description: 'Test channel' },
      settings: { theme: 'default' }
    }
  end

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it 'returns all channels' do
      create_list(:channel, 3)
      get :index
      expect(JSON.parse(response.body)['data'].length).to eq(3)
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { id: channel.id }
      expect(response).to have_http_status(:ok)
    end

    it 'returns the channel data' do
      get :show, params: { id: channel.id }
      response_data = JSON.parse(response.body)['data']
      expect(response_data['id']).to eq(channel.id)
      expect(response_data['name']).to eq(channel.name)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new channel' do
        expect {
          post :create, params: { channel: valid_attributes }
        }.to change(Channel, :count).by(1)
      end

      it 'returns a created response' do
        post :create, params: { channel: valid_attributes }
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid parameters' do
      it 'returns an error response' do
        post :create, params: { channel: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      let(:new_attributes) { { name: 'Updated Channel' } }

      it 'updates the channel' do
        patch :update, params: { id: channel.id, channel: new_attributes }
        channel.reload
        expect(channel.name).to eq('Updated Channel')
      end

      it 'returns a success response' do
        patch :update, params: { id: channel.id, channel: new_attributes }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid parameters' do
      it 'returns an error response' do
        patch :update, params: { id: channel.id, channel: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the channel' do
      expect {
        delete :destroy, params: { id: channel.id }
      }.to change(Channel, :count).by(-1)
    end

    it 'returns a success response' do
      delete :destroy, params: { id: channel.id }
      expect(response).to have_http_status(:ok)
    end
  end
end

