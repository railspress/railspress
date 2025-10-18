require 'rails_helper'

RSpec.describe 'Feeds Integration', type: :request do
  describe 'Feed endpoints' do
    context 'when database is available' do
      it 'serves RSS feed at /feed' do
        get '/feed'
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/rss+xml')
        expect(response.body).to include('<?xml version="1.0" encoding="UTF-8"?>')
        expect(response.body).to include('<rss version="2.0"')
        expect(response.body).to include('xmlns:content="http://purl.org/rss/1.0/modules/content/"')
      end

      it 'serves XML feed at /feed.xml' do
        get '/feed.xml'
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/xml')
        expect(response.body).to include('<?xml version="1.0" encoding="UTF-8"?>')
        expect(response.body).to include('<rss version="2.0"')
        expect(response.body).to include('xmlns:content="http://purl.org/rss/1.0/modules/content/"')
      end

      it 'serves Atom feed at /feed.atom' do
        get '/feed.atom'
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/atom+xml')
        expect(response.body).to include('<?xml version="1.0" encoding="UTF-8"?>')
        expect(response.body).to include('<feed xmlns="http://www.w3.org/2005/Atom">')
      end

      it 'serves RSS feed at /feed.rss' do
        get '/feed.rss'
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/rss+xml')
        expect(response.body).to include('<?xml version="1.0" encoding="UTF-8"?>')
        expect(response.body).to include('<rss version="2.0"')
        expect(response.body).to include('xmlns:content="http://purl.org/rss/1.0/modules/content/"')
      end
    end

    context 'XML validation' do
      it 'RSS feed is valid XML' do
        get '/feed.rss'
        expect { Nokogiri::XML(response.body) { |config| config.strict } }.not_to raise_error
      end

      it 'XML feed is valid XML' do
        get '/feed.xml'
        expect { Nokogiri::XML(response.body) { |config| config.strict } }.not_to raise_error
      end

      it 'Atom feed is valid XML' do
        get '/feed.atom'
        expect { Nokogiri::XML(response.body) { |config| config.strict } }.not_to raise_error
      end
    end

    context 'namespace validation' do
      it 'RSS feed includes all required namespaces' do
        get '/feed.rss'
        expect(response.body).to include('xmlns:atom="http://www.w3.org/2005/Atom"')
        expect(response.body).to include('xmlns:dc="http://purl.org/dc/elements/1.1/"')
        expect(response.body).to include('xmlns:content="http://purl.org/rss/1.0/modules/content/"')
      end

      it 'XML feed includes all required namespaces' do
        get '/feed.xml'
        expect(response.body).to include('xmlns:atom="http://www.w3.org/2005/Atom"')
        expect(response.body).to include('xmlns:dc="http://purl.org/dc/elements/1.1/"')
        expect(response.body).to include('xmlns:content="http://purl.org/rss/1.0/modules/content/"')
      end
    end

    context 'cache headers' do
      it 'sets proper cache headers for RSS feed' do
        get '/feed.rss'
        expect(response.headers['Cache-Control']).to include('max-age=3600')
        expect(response.headers['Cache-Control']).to include('public')
      end

      it 'sets proper cache headers for XML feed' do
        get '/feed.xml'
        expect(response.headers['Cache-Control']).to include('max-age=3600')
        expect(response.headers['Cache-Control']).to include('public')
      end

      it 'sets proper cache headers for Atom feed' do
        get '/feed.atom'
        expect(response.headers['Cache-Control']).to include('max-age=3600')
        expect(response.headers['Cache-Control']).to include('public')
      end
    end
  end
end
