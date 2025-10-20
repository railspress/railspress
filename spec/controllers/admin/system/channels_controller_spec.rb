require 'rails_helper'

RSpec.describe Admin::System::ChannelsController, type: :controller do
  let(:user) { create(:user, role: 'administrator') }
  let(:web_channel) { create(:channel, :web) }
  let(:mobile_channel) { create(:channel, :mobile) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'returns a successful response' do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it 'assigns all channels' do
      get :index
      expect(assigns(:channels)).to include(web_channel, mobile_channel)
    end
  end

  describe 'GET #show' do
    it 'returns a successful response' do
      get :show, params: { id: web_channel.id }
      expect(response).to have_http_status(:ok)
    end

    it 'assigns the requested channel' do
      get :show, params: { id: web_channel.id }
      expect(assigns(:channel)).to eq(web_channel)
    end

    it 'assigns channel overrides' do
      override = create(:channel_override, channel: web_channel)
      get :show, params: { id: web_channel.id }
      expect(assigns(:overrides)).to include(override)
    end
  end

  describe 'GET #new' do
    it 'returns a successful response' do
      get :new
      expect(response).to have_http_status(:ok)
    end

    it 'assigns a new channel' do
      get :new
      expect(assigns(:channel)).to be_a_new(Channel)
    end
  end

  describe 'GET #edit' do
    it 'returns a successful response' do
      get :edit, params: { id: web_channel.id }
      expect(response).to have_http_status(:ok)
    end

    it 'assigns the requested channel' do
      get :edit, params: { id: web_channel.id }
      expect(assigns(:channel)).to eq(web_channel)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          name: 'Test Channel',
          slug: 'test-channel',
          domain: 'test.example.com',
          locale: 'en',
          metadata: { description: 'Test description' },
          settings: { theme: 'dark' }
        }
      end

      it 'creates a new channel' do
        expect {
          post :create, params: { channel: valid_attributes }
        }.to change(Channel, :count).by(1)
      end

      it 'redirects to the created channel' do
        post :create, params: { channel: valid_attributes }
        expect(response).to redirect_to(admin_system_channel_path(Channel.last))
      end

      it 'sets a success notice' do
        post :create, params: { channel: valid_attributes }
        expect(flash[:notice]).to eq('Channel was successfully created.')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { name: '' } }

      it 'does not create a new channel' do
        expect {
          post :create, params: { channel: invalid_attributes }
        }.not_to change(Channel, :count)
      end

      it 'renders the new template' do
        post :create, params: { channel: invalid_attributes }
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      let(:new_attributes) { { name: 'Updated Channel Name' } }

      it 'updates the channel' do
        patch :update, params: { id: web_channel.id, channel: new_attributes }
        web_channel.reload
        expect(web_channel.name).to eq('Updated Channel Name')
      end

      it 'redirects to the channel' do
        patch :update, params: { id: web_channel.id, channel: new_attributes }
        expect(response).to redirect_to(admin_system_channel_path(web_channel))
      end

      it 'sets a success notice' do
        patch :update, params: { id: web_channel.id, channel: new_attributes }
        expect(flash[:notice]).to eq('Channel was successfully updated.')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { name: '' } }

      it 'does not update the channel' do
        original_name = web_channel.name
        patch :update, params: { id: web_channel.id, channel: invalid_attributes }
        web_channel.reload
        expect(web_channel.name).to eq(original_name)
      end

      it 'renders the edit template' do
        patch :update, params: { id: web_channel.id, channel: invalid_attributes }
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the channel' do
      expect {
        delete :destroy, params: { id: web_channel.id }
      }.to change(Channel, :count).by(-1)
    end

    it 'redirects to the channels index' do
      delete :destroy, params: { id: web_channel.id }
      expect(response).to redirect_to(admin_system_channels_path)
    end

    it 'sets a success notice' do
      delete :destroy, params: { id: web_channel.id }
      expect(flash[:notice]).to eq('Channel was successfully deleted.')
    end
  end
end

