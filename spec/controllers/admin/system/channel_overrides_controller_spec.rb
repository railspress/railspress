require 'rails_helper'

RSpec.describe Admin::System::ChannelOverridesController, type: :controller do
  let(:user) { create(:user, role: 'administrator') }
  let(:web_channel) { create(:channel, :web) }
  let(:mobile_channel) { create(:channel, :mobile) }
  let(:post) { create(:post) }
  let(:override) { create(:channel_override, channel: web_channel, resource: post) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'returns a successful response' do
      get :index, params: { channel_id: web_channel.id }
      expect(response).to have_http_status(:ok)
    end

    it 'assigns the channel' do
      get :index, params: { channel_id: web_channel.id }
      expect(assigns(:channel)).to eq(web_channel)
    end

    it 'assigns channel overrides' do
      get :index, params: { channel_id: web_channel.id }
      expect(assigns(:overrides)).to include(override)
    end
  end

  describe 'GET #show' do
    it 'returns a successful response' do
      get :show, params: { channel_id: web_channel.id, id: override.id }
      expect(response).to have_http_status(:ok)
    end

    it 'assigns the requested override' do
      get :show, params: { channel_id: web_channel.id, id: override.id }
      expect(assigns(:override)).to eq(override)
    end
  end

  describe 'GET #new' do
    it 'returns a successful response' do
      get :new, params: { channel_id: web_channel.id }
      expect(response).to have_http_status(:ok)
    end

    it 'assigns a new override' do
      get :new, params: { channel_id: web_channel.id }
      expect(assigns(:override)).to be_a_new(ChannelOverride)
    end

    it 'assigns the channel' do
      get :new, params: { channel_id: web_channel.id }
      expect(assigns(:channel)).to eq(web_channel)
    end
  end

  describe 'GET #edit' do
    it 'returns a successful response' do
      get :edit, params: { channel_id: web_channel.id, id: override.id }
      expect(response).to have_http_status(:ok)
    end

    it 'assigns the requested override' do
      get :edit, params: { channel_id: web_channel.id, id: override.id }
      expect(assigns(:override)).to eq(override)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          resource_type: 'Post',
          resource_id: post.id,
          kind: 'override',
          path: 'title',
          data: 'New Title',
          enabled: true
        }
      end

      it 'creates a new override' do
        expect {
          post :create, params: { channel_id: web_channel.id, channel_override: valid_attributes }
        }.to change(ChannelOverride, :count).by(1)
      end

      it 'redirects to the channel' do
        post :create, params: { channel_id: web_channel.id, channel_override: valid_attributes }
        expect(response).to redirect_to(admin_system_channel_path(web_channel))
      end

      it 'sets a success notice' do
        post :create, params: { channel_id: web_channel.id, channel_override: valid_attributes }
        expect(flash[:notice]).to eq('Channel override was successfully created.')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { resource_type: '' } }

      it 'does not create a new override' do
        expect {
          post :create, params: { channel_id: web_channel.id, channel_override: invalid_attributes }
        }.not_to change(ChannelOverride, :count)
      end

      it 'renders the new template' do
        post :create, params: { channel_id: web_channel.id, channel_override: invalid_attributes }
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      let(:new_attributes) { { path: 'content', data: 'New Content' } }

      it 'updates the override' do
        patch :update, params: { channel_id: web_channel.id, id: override.id, channel_override: new_attributes }
        override.reload
        expect(override.path).to eq('content')
        expect(override.data).to eq('New Content')
      end

      it 'redirects to the channel' do
        patch :update, params: { channel_id: web_channel.id, id: override.id, channel_override: new_attributes }
        expect(response).to redirect_to(admin_system_channel_path(web_channel))
      end

      it 'sets a success notice' do
        patch :update, params: { channel_id: web_channel.id, id: override.id, channel_override: new_attributes }
        expect(flash[:notice]).to eq('Channel override was successfully updated.')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { resource_type: '' } }

      it 'does not update the override' do
        original_path = override.path
        patch :update, params: { channel_id: web_channel.id, id: override.id, channel_override: invalid_attributes }
        override.reload
        expect(override.path).to eq(original_path)
      end

      it 'renders the edit template' do
        patch :update, params: { channel_id: web_channel.id, id: override.id, channel_override: invalid_attributes }
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the override' do
      expect {
        delete :destroy, params: { channel_id: web_channel.id, id: override.id }
      }.to change(ChannelOverride, :count).by(-1)
    end

    it 'redirects to the channel' do
      delete :destroy, params: { channel_id: web_channel.id, id: override.id }
      expect(response).to redirect_to(admin_system_channel_path(web_channel))
    end

    it 'sets a success notice' do
      delete :destroy, params: { channel_id: web_channel.id, id: override.id }
      expect(flash[:notice]).to eq('Channel override was successfully deleted.')
    end
  end

  describe 'POST #copy_from_channel' do
    let(:source_channel) { mobile_channel }
    let!(:source_override) { create(:channel_override, channel: source_channel, resource: post) }

    it 'copies overrides from source channel' do
      expect {
        post :copy_from_channel, params: { 
          channel_id: web_channel.id, 
          source_channel_id: source_channel.id 
        }
      }.to change(ChannelOverride, :count).by(1)
    end

    it 'redirects to the channel' do
      post :copy_from_channel, params: { 
        channel_id: web_channel.id, 
        source_channel_id: source_channel.id 
      }
      expect(response).to redirect_to(admin_system_channel_path(web_channel))
    end

    it 'sets a success notice' do
      post :copy_from_channel, params: { 
        channel_id: web_channel.id, 
        source_channel_id: source_channel.id 
      }
      expect(flash[:notice]).to eq('Overrides copied successfully.')
    end
  end

  describe 'GET #export' do
    it 'returns a successful response' do
      get :export, params: { channel_id: web_channel.id }
      expect(response).to have_http_status(:ok)
    end

    it 'returns JSON format' do
      get :export, params: { channel_id: web_channel.id }
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'POST #import' do
    let(:import_data) do
      [
        {
          resource_type: 'Post',
          resource_id: post.id,
          kind: 'override',
          path: 'title',
          data: 'Imported Title',
          enabled: true
        }
      ].to_json
    end

    it 'imports overrides from JSON data' do
      expect {
        post :import, params: { 
          channel_id: web_channel.id, 
          import_data: import_data 
        }
      }.to change(ChannelOverride, :count).by(1)
    end

    it 'redirects to the channel' do
      post :import, params: { 
        channel_id: web_channel.id, 
        import_data: import_data 
      }
      expect(response).to redirect_to(admin_system_channel_path(web_channel))
    end

    it 'sets a success notice' do
      post :import, params: { 
        channel_id: web_channel.id, 
        import_data: import_data 
      }
      expect(flash[:notice]).to eq('Overrides imported successfully.')
    end
  end
end

