require 'rails_helper'

RSpec.describe Pageview, type: :model do
  describe 'tenant validation' do
    it 'allows creation without tenant (optional tenant)' do
      pageview = build(:pageview, tenant: nil)
      expect(pageview).to be_valid
    end
    
    it 'allows creation with tenant' do
      tenant = create(:tenant)
      pageview = build(:pageview, tenant: tenant)
      expect(pageview).to be_valid
    end
  end
  
  describe '.track' do
    let(:request) do
      Rack::Request.new({
        'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => '/test-page',
        'HTTP_HOST' => 'localhost:3000',
        'REMOTE_ADDR' => '127.0.0.1',
        'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
      })
    end
    
    it 'creates pageview successfully' do
      expect {
        Pageview.track(request, { title: 'Test Page' })
      }.to change(Pageview, :count).by(1)
    end
    
    it 'resolves tenant for localhost requests' do
      pageview = Pageview.track(request, { title: 'Test Page' })
      expect(pageview.tenant_id).to be_present
    end
    
    it 'handles admin paths without tenant' do
      admin_request = Rack::Request.new({
        'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => '/admin',
        'HTTP_HOST' => 'localhost:3000',
        'REMOTE_ADDR' => '127.0.0.1',
        'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
      })
      
      pageview = Pageview.track(admin_request, { title: 'Admin Page' })
      expect(pageview).to be_persisted
    end
    
    it 'skips bot requests by default' do
      bot_request = Rack::Request.new({
        'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => '/',
        'HTTP_HOST' => 'localhost:3000',
        'REMOTE_ADDR' => '127.0.0.1',
        'HTTP_USER_AGENT' => 'Googlebot/2.1 (+http://www.google.com/bot.html)'
      })
      
      expect {
        Pageview.track(bot_request)
      }.not_to change(Pageview, :count)
    end
  end
  
  describe 'scopes' do
    let!(:pageview1) { create(:pageview, bot: false, consented: true) }
    let!(:pageview2) { create(:pageview, bot: true, consented: false) }
    
    it 'filters non-bot pageviews' do
      expect(Pageview.non_bot).to include(pageview1)
      expect(Pageview.non_bot).not_to include(pageview2)
    end
    
    it 'filters consented pageviews' do
      expect(Pageview.consented_only).to include(pageview1)
      expect(Pageview.consented_only).not_to include(pageview2)
    end
  end
end
