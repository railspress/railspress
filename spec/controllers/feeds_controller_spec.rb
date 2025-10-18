require 'rails_helper'

RSpec.describe FeedsController, type: :controller do
  describe 'GET #posts' do
    context 'with XML format' do
      it 'responds successfully' do
        get :posts, format: :xml
        expect(response).to have_http_status(:success)
      end
      
      it 'renders XML template' do
        get :posts, format: :xml
        expect(response.content_type).to include('application/xml')
      end
    end
    
    context 'with RSS format' do
      it 'responds successfully' do
        get :posts, format: :rss
        expect(response).to have_http_status(:success)
      end
      
      it 'renders RSS template' do
        get :posts, format: :rss
        expect(response.content_type).to include('application/rss+xml')
      end
    end
    
    context 'with Atom format' do
      it 'responds successfully' do
        get :posts, format: :atom
        expect(response).to have_http_status(:success)
      end
      
      it 'renders Atom template' do
        get :posts, format: :atom
        expect(response.content_type).to include('application/atom+xml')
      end
    end
  end
end
