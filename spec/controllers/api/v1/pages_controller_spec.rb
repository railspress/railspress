require 'rails_helper'

RSpec.describe Api::V1::PagesController, type: :controller do
  let(:user) { create(:user, role: 'administrator') }
  let(:web_channel) { create(:channel, :web) }
  let(:mobile_channel) { create(:channel, :mobile) }
  let(:page1) { create(:page, title: 'Web Page', status: 'published') }
  let(:page2) { create(:page, title: 'Mobile Page', status: 'published') }
  let(:draft_page) { create(:page, title: 'Draft Page', status: 'draft') }

  before do
    # Associate pages with channels
    page1.channels << web_channel
    page2.channels << mobile_channel
  end

  describe 'GET #index' do
    context 'without channel parameter' do
      it 'returns all published pages' do
        get :index
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)['data']
        expect(response_data.length).to eq(2)
        expect(response_data.map { |p| p['title'] }).to include('Web Page', 'Mobile Page')
      end
    end

    context 'with channel parameter' do
      it 'returns pages for specific channel' do
        get :index, params: { channel: 'web' }
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)['data']
        expect(response_data.length).to eq(1)
        expect(response_data.first['title']).to eq('Web Page')
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

      it 'returns all pages including drafts for admin' do
        get :index
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)['data']
        expect(response_data.length).to eq(3)
        expect(response_data.map { |p| p['title'] }).to include('Web Page', 'Mobile Page', 'Draft Page')
      end
    end
  end

  describe 'channel filtering with exclusions' do
    let!(:exclusion_override) do
      create(:channel_override, 
        channel: web_channel, 
        resource_type: 'Page', 
        resource_id: page2.id, 
        kind: 'exclude'
      )
    end

    it 'excludes pages with exclusion overrides' do
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
        resource_type: 'Page',
        resource_id: page1.id,
        kind: 'override',
        path: 'title',
        data: 'Overridden Page Title'
      )
    end

    it 'applies channel overrides to page data' do
      get :index, params: { channel: 'web' }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)['data']
      expect(response_data.first['title']).to eq('Overridden Page Title')
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
    it 'returns a specific page' do
      get :show, params: { id: page1.id }
      expect(response).to have_http_status(:ok)
      
      response_data = JSON.parse(response.body)['data']
      expect(response_data['id']).to eq(page1.id)
      expect(response_data['title']).to eq(page1.title)
    end

    context 'with channel parameter' do
      let!(:title_override) do
        create(:channel_override,
          channel: web_channel,
          resource_type: 'Page',
          resource_id: page1.id,
          kind: 'override',
          path: 'title',
          data: 'Overridden Page Title'
        )
      end

      it 'applies channel overrides to detailed page data' do
        get :show, params: { id: page1.id, channel: 'web' }
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)['data']
        expect(response_data['title']).to eq('Overridden Page Title')
        expect(response_data['provenance']).to be_present
      end
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        title: 'New Page',
        content: 'Page content',
        status: 'published',
        channel_ids: [web_channel.id]
      }
    end

    before do
      allow(controller).to receive(:current_api_user).and_return(user)
    end

    context 'with valid parameters' do
      it 'creates a new page' do
        expect {
          post :create, params: { page: valid_attributes }
        }.to change(Page, :count).by(1)
      end

      it 'associates page with channels' do
        post :create, params: { page: valid_attributes }
        new_page = Page.last
        expect(new_page.channels).to include(web_channel)
      end

      it 'returns a created response' do
        post :create, params: { page: valid_attributes }
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid parameters' do
      it 'returns an error response' do
        post :create, params: { page: { title: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH #update' do
    before do
      allow(controller).to receive(:current_api_user).and_return(user)
    end

    context 'with valid parameters' do
      let(:new_attributes) { { title: 'Updated Page', channel_ids: [mobile_channel.id] } }

      it 'updates the page' do
        patch :update, params: { id: page1.id, page: new_attributes }
        page1.reload
        expect(page1.title).to eq('Updated Page')
      end

      it 'updates channel associations' do
        patch :update, params: { id: page1.id, page: new_attributes }
        page1.reload
        expect(page1.channels).to include(mobile_channel)
        expect(page1.channels).not_to include(web_channel)
      end

      it 'returns a success response' do
        patch :update, params: { id: page1.id, page: new_attributes }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid parameters' do
      it 'returns an error response' do
        patch :update, params: { id: page1.id, page: { title: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      allow(controller).to receive(:current_api_user).and_return(user)
    end

    it 'destroys the page' do
      expect {
        delete :destroy, params: { id: page1.id }
      }.to change(Page, :count).by(-1)
    end

    it 'returns a success response' do
      delete :destroy, params: { id: page1.id }
      expect(response).to have_http_status(:ok)
    end
  end
end

