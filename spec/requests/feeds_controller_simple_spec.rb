require 'rails_helper'

RSpec.describe FeedsController, type: :request do
  describe 'GET /feed.xml' do
    it 'handles XML format requests' do
      get '/feed.xml'
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/xml')
    end
    
    it 'includes proper XML structure' do
      get '/feed.xml'
      
      expect(response.body).to include('<?xml version="1.0" encoding="UTF-8"?>')
      expect(response.body).to include('<rss version="2.0"')
      expect(response.body).to include('xmlns:content="http://purl.org/rss/1.0/modules/content/"')
    end
    
    it 'is valid XML' do
      get '/feed.xml'
      
      expect { Nokogiri::XML(response.body) { |config| config.strict } }.not_to raise_error
    end
  end

  describe 'GET /feed.rss' do
    it 'handles RSS format requests' do
      get '/feed.rss'
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/rss+xml')
    end
    
    it 'includes proper RSS structure' do
      get '/feed.rss'
      
      expect(response.body).to include('<?xml version="1.0" encoding="UTF-8"?>')
      expect(response.body).to include('<rss version="2.0"')
      expect(response.body).to include('xmlns:content="http://purl.org/rss/1.0/modules/content/"')
    end
    
    it 'is valid XML' do
      get '/feed.rss'
      
      expect { Nokogiri::XML(response.body) { |config| config.strict } }.not_to raise_error
    end
  end

  describe 'GET /feed.atom' do
    it 'handles Atom format requests' do
      get '/feed.atom'
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/atom+xml')
    end
    
    it 'includes proper Atom structure' do
      get '/feed.atom'
      
      expect(response.body).to include('<?xml version="1.0" encoding="UTF-8"?>')
      expect(response.body).to include('<feed xmlns="http://www.w3.org/2005/Atom">')
    end
    
    it 'is valid XML' do
      get '/feed.atom'
      
      expect { Nokogiri::XML(response.body) { |config| config.strict } }.not_to raise_error
    end
  end

  describe 'GET /feed' do
    it 'handles default RSS format requests' do
      get '/feed'
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/rss+xml')
    end
  end

  describe 'XML namespace validation' do
    it 'RSS feed has all required namespaces' do
      get '/feed.rss'
      
      expect(response.body).to include('xmlns:atom="http://www.w3.org/2005/Atom"')
      expect(response.body).to include('xmlns:dc="http://purl.org/dc/elements/1.1/"')
      expect(response.body).to include('xmlns:content="http://purl.org/rss/1.0/modules/content/"')
    end

    it 'XML feed has all required namespaces' do
      get '/feed.xml'
      
      expect(response.body).to include('xmlns:atom="http://www.w3.org/2005/Atom"')
      expect(response.body).to include('xmlns:dc="http://purl.org/dc/elements/1.1/"')
      expect(response.body).to include('xmlns:content="http://purl.org/rss/1.0/modules/content/"')
    end
  end

  describe 'cache headers' do
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
