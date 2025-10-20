require 'rails_helper'

RSpec.describe "Channel System Integration", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:web_channel) { create(:channel, :web) }
  let(:mobile_channel) { create(:channel, :mobile) }
  let(:newsletter_channel) { create(:channel, :newsletter) }
  let(:smarttv_channel) { create(:channel, :smarttv) }

  before do
    # Create test content
    @post = create(:post, title: "Test Post", content: "This is a test post")
    @page = create(:page, title: "Test Page", content: "This is a test page")
    @medium = create(:medium, title: "Test Image", file_name: "test.jpg", file_type: "image/jpeg")

    # Associate content with channels
    @post.channels << [web_channel, mobile_channel]
    @page.channels << [web_channel, newsletter_channel]
    @medium.channels << [mobile_channel, smarttv_channel]
  end

  describe "Out-of-the-Box Channel Defaults" do
    it "has all default channels with proper settings" do
      channels = Channel.all
      expect(channels.count).to eq(4)

      # Web channel
      web = channels.find { |c| c.slug == 'web' }
      expect(web.settings['theme_variant']).to eq('default')
      expect(web.settings['show_comments']).to be true
      expect(web.settings['max_content_width']).to eq('1200px')
      expect(web.metadata['device_type']).to eq('desktop')

      # Mobile channel
      mobile = channels.find { |c| c.slug == 'mobile' }
      expect(mobile.settings['theme_variant']).to eq('mobile')
      expect(mobile.settings['show_comments']).to be false
      expect(mobile.settings['max_content_width']).to eq('100%')
      expect(mobile.settings['touch_friendly']).to be true
      expect(mobile.metadata['device_type']).to eq('mobile')

      # Newsletter channel
      newsletter = channels.find { |c| c.slug == 'newsletter' }
      expect(newsletter.settings['max_content_width']).to eq('600px')
      expect(newsletter.settings['email_optimized']).to be true
      expect(newsletter.settings['inline_css']).to be true
      expect(newsletter.metadata['device_type']).to eq('email')

      # Smart TV channel
      smarttv = channels.find { |c| c.slug == 'smarttv' }
      expect(smarttv.settings['max_content_width']).to eq('1920px')
      expect(smarttv.settings['large_text']).to be true
      expect(smarttv.settings['remote_friendly']).to be true
      expect(smarttv.metadata['device_type']).to eq('smart_tv')
    end
  end

  describe "REST API Channel Filtering" do
    it "filters posts by web channel" do
      get "/api/v1/posts", params: { channel: 'web' }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(1)
      expect(json['data'].first['channel_context']).to eq('web')
      expect(json['data'].first['channels']).to include('web', 'mobile')
    end

    it "filters posts by mobile channel" do
      get "/api/v1/posts", params: { channel: 'mobile' }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(1)
      expect(json['data'].first['channel_context']).to eq('mobile')
    end

    it "filters pages by newsletter channel" do
      get "/api/v1/pages", params: { channel: 'newsletter' }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(1)
      expect(json['data'].first['channel_context']).to eq('newsletter')
      expect(json['data'].first['channels']).to include('web', 'newsletter')
    end

    it "filters media by smarttv channel" do
      get "/api/v1/media", params: { channel: 'smarttv' }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(1)
      expect(json['data'].first['channel_context']).to eq('smarttv')
      expect(json['data'].first['channels']).to include('mobile', 'smarttv')
    end
  end

  describe "GraphQL Channel Filtering" do
    it "filters posts by channel via GraphQL" do
      query = <<~GQL
        query {
          posts(channel: "web") {
            id
            title
            channelContext
            channels {
              slug
            }
          }
        }
      GQL

      post "/graphql", params: { query: query }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['posts'].length).to eq(1)
      expect(json['data']['posts'].first['channelContext']).to eq('web')
    end

    it "returns channel information via GraphQL" do
      query = <<~GQL
        query {
          channels {
            id
            name
            slug
            deviceType
            targetAudience
            settings
            metadata
          }
        }
      GQL

      post "/graphql", params: { query: query }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['channels'].length).to eq(4)
      
      web_channel_data = json['data']['channels'].find { |c| c['slug'] == 'web' }
      expect(web_channel_data['deviceType']).to eq('desktop')
      expect(web_channel_data['targetAudience']).to eq('general')
    end
  end

  describe "Channel Overrides and Exclusions" do
    it "applies title override for web channel" do
      create(:channel_override, 
             channel: web_channel, 
             resource_type: 'Post', 
             resource_id: @post.id,
             path: 'title',
             data: 'Web Optimized Title')

      get "/api/v1/posts/#{@post.id}", params: { channel: 'web' }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['title']).to eq('Web Optimized Title')
      expect(json['data']['provenance']['title']).to eq('channel_override')
    end

    it "excludes post from mobile channel" do
      create(:channel_override, :exclusion, 
             channel: mobile_channel, 
             resource_type: 'Post', 
             resource_id: @post.id)

      get "/api/v1/posts", params: { channel: 'mobile' }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']).to be_empty
    end

    it "applies content override for newsletter channel" do
      create(:channel_override, 
             channel: newsletter_channel, 
             resource_type: 'Page', 
             resource_id: @page.id,
             path: 'content',
             data: 'Newsletter optimized content')

      get "/api/v1/pages/#{@page.id}", params: { channel: 'newsletter' }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['content']).to eq('Newsletter optimized content')
    end
  end

  describe "Device Detection" do
    it "auto-detects iPhone and applies mobile channel" do
      get "/api/v1/posts", 
          headers: { 'User-Agent' => 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15' }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['meta']['filters']['channel']).to eq('mobile')
    end

    it "auto-detects Android and applies mobile channel" do
      get "/api/v1/posts", 
          headers: { 'User-Agent' => 'Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36' }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['meta']['filters']['channel']).to eq('mobile')
    end

    it "auto-detects iPad and applies mobile channel" do
      get "/api/v1/posts", 
          headers: { 'User-Agent' => 'Mozilla/5.0 (iPad; CPU OS 14_0 like Mac OS X) AppleWebKit/605.1.15' }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['meta']['filters']['channel']).to eq('mobile')
    end

    it "auto-detects Smart TV and applies smarttv channel" do
      get "/api/v1/posts", 
          headers: { 'User-Agent' => 'Mozilla/5.0 (SmartTV; Linux; Tizen 2.4.0) AppleWebKit/538.1' }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['meta']['filters']['channel']).to eq('smarttv')
    end

    it "defaults to web channel for desktop browsers" do
      get "/api/v1/posts", 
          headers: { 'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36' }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['meta']['filters']['channel']).to eq('web')
    end
  end

  describe "Admin Interface" do
    before do
      sign_in admin_user
    end

    it "displays channels in admin interface" do
      get "/admin/system/channels"
      
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Content Channels')
      expect(response.body).to include('Web')
      expect(response.body).to include('Mobile')
      expect(response.body).to include('Newsletter')
      expect(response.body).to include('Smart TV')
    end

    it "shows channel statistics" do
      get "/admin/system/channels"
      
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Total Channels')
      expect(response.body).to include('Active Channels')
      expect(response.body).to include('Total Overrides')
      expect(response.body).to include('Content Items')
    end
  end

  describe "Plugin Integration" do
    it "allows plugins to access channel information" do
      plugin = Railspress::PluginBase.new
      
      # Test channel access
      channels = plugin.all_channels
      expect(channels.count).to eq(4)
      
      # Test channel finding
      web_channel = plugin.find_channel('web')
      expect(web_channel.name).to eq('Web')
      
      # Test device detection
      mobile_channel = plugin.channel_for_device('mobile')
      expect(mobile_channel.slug).to eq('mobile')
    end

    it "allows plugins to process content for channels" do
      plugin = Railspress::PluginBase.new
      
      # Test content processing
      processed_content = plugin.process_content_for_channel(
        @post.content, 
        'mobile', 
        { resource_type: 'Post', resource_id: @post.id }
      )
      
      expect(processed_content).to be_present
      
      # Test multi-channel distribution
      distributed_content = plugin.distribute_content_to_channels(
        @post.content,
        { resource_type: 'Post', resource_id: @post.id }
      )
      
      expect(distributed_content).to be_a(Hash)
      expect(distributed_content.keys).to include('web', 'mobile', 'newsletter', 'smarttv')
    end
  end

  describe "Performance and Scalability" do
    it "handles multiple channels efficiently" do
      # Create additional channels
      10.times do |i|
        create(:channel, name: "Channel #{i}", slug: "channel_#{i}")
      end

      get "/api/v1/channels"
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(14) # 4 default + 10 new
    end

    it "handles large number of overrides efficiently" do
      # Create multiple overrides
      50.times do |i|
        create(:channel_override, 
               channel: web_channel, 
               resource_type: 'Post', 
               resource_id: @post.id,
               path: "field_#{i}",
               data: "value_#{i}")
      end

      get "/api/v1/posts/#{@post.id}", params: { channel: 'web' }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['provenance']).to be_present
    end
  end
end

