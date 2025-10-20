require 'rails_helper'

RSpec.describe "Channel System GraphQL API", type: :request do
  let(:web_channel) { create(:channel, :web) }
  let(:mobile_channel) { create(:channel, :mobile) }
  let(:post) { create(:post) }

  before do
    # Associate post with channels
    post.channels << [web_channel, mobile_channel]
  end

  describe "Channel Queries" do
    it "returns all channels" do
      query = <<~GQL
        query {
          channels {
            id
            name
            slug
            domain
            locale
            enabled
            deviceType
            targetAudience
            contentCount
            overrideCount
          }
        }
      GQL

      post "/graphql", params: { query: query }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['channels']).to be_an(Array)
      expect(json['data']['channels'].length).to eq(2)
      
      channel_data = json['data']['channels'].first
      expect(channel_data).to include('id', 'name', 'slug', 'domain', 'locale', 'enabled')
      expect(channel_data['deviceType']).to be_present
      expect(channel_data['targetAudience']).to be_present
    end

    it "returns single channel by slug" do
      query = <<~GQL
        query {
          channel(slug: "web") {
            id
            name
            slug
            metadata
            settings
            posts {
              id
              title
            }
          }
        }
      GQL

      post "/graphql", params: { query: query }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['channel']).to be_present
      expect(json['data']['channel']['slug']).to eq('web')
      expect(json['data']['channel']['posts']).to be_an(Array)
    end

    it "filters channels by device type" do
      query = <<~GQL
        query {
          channels(deviceType: "mobile") {
            id
            name
            slug
            deviceType
          }
        }
      GQL

      post "/graphql", params: { query: query }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['channels']).to be_an(Array)
      expect(json['data']['channels'].length).to eq(1)
      expect(json['data']['channels'].first['slug']).to eq('mobile')
    end
  end

  describe "Posts with Channel Filtering" do
    it "returns posts without channel filter" do
      query = <<~GQL
        query {
          posts {
            id
            title
            slug
            channels {
              id
              name
              slug
            }
            channelContext
            provenance
          }
        }
      GQL

      post "/graphql", params: { query: query }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['posts']).to be_an(Array)
      expect(json['data']['posts'].first['channels']).to be_an(Array)
      expect(json['data']['posts'].first['channels'].length).to eq(2)
    end

    it "filters posts by channel" do
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
      expect(json['data']['posts']).to be_an(Array)
      expect(json['data']['posts'].first['channelContext']).to eq('web')
    end

    it "applies channel exclusions" do
      # Create an exclusion override
      create(:channel_override, :exclusion, 
             channel: web_channel, 
             resource_type: 'Post', 
             resource_id: post.id)

      query = <<~GQL
        query {
          posts(channel: "web") {
            id
            title
          }
        }
      GQL

      post "/graphql", params: { query: query }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['posts']).to be_empty
    end
  end

  describe "Channel Overrides" do
    let(:override) do
      create(:channel_override, 
             channel: web_channel, 
             resource_type: 'Post', 
             resource_id: post.id,
             path: 'title',
             data: 'GraphQL Override Title')
    end

    it "returns channel overrides" do
      override
      
      query = <<~GQL
        query {
          channel(slug: "web") {
            id
            name
            overrides {
              id
              kind
              path
              data
              enabled
              resourceType
              resourceId
              resourceName
              isOverride
              isExclusion
            }
          }
        }
      GQL

      post "/graphql", params: { query: query }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      overrides = json['data']['channel']['overrides']
      expect(overrides).to be_an(Array)
      expect(overrides.length).to eq(1)
      
      override_data = overrides.first
      expect(override_data['kind']).to eq('override')
      expect(override_data['path']).to eq('title')
      expect(override_data['data']).to eq('GraphQL Override Title')
      expect(override_data['isOverride']).to be true
      expect(override_data['isExclusion']).to be false
    end
  end

  describe "Pages and Media with Channel Support" do
    let(:page) { create(:page) }
    let(:medium) { create(:medium) }

    before do
      page.channels << web_channel
      medium.channels << mobile_channel
    end

    it "returns pages with channel filtering" do
      query = <<~GQL
        query {
          pages(channel: "web") {
            id
            title
            slug
            channels {
              slug
            }
            channelContext
          }
        }
      GQL

      post "/graphql", params: { query: query }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['pages']).to be_an(Array)
      expect(json['data']['pages'].first['channelContext']).to eq('web')
    end

    it "returns media with channel filtering" do
      query = <<~GQL
        query {
          media(channel: "mobile") {
            id
            title
            fileName
            fileType
            channels {
              slug
            }
            channelContext
            isImage
            isVideo
            isDocument
          }
        }
      GQL

      post "/graphql", params: { query: query }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['media']).to be_an(Array)
      expect(json['data']['media'].first['channelContext']).to eq('mobile')
      expect(json['data']['media'].first['isImage']).to be_in([true, false])
    end
  end

  describe "Error Handling" do
    it "handles invalid queries gracefully" do
      query = <<~GQL
        query {
          invalidField {
            id
          }
        }
      GQL

      post "/graphql", params: { query: query }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end

    it "handles missing channel gracefully" do
      query = <<~GQL
        query {
          channel(slug: "invalid") {
            id
            name
          }
        }
      GQL

      post "/graphql", params: { query: query }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['channel']).to be_nil
    end
  end

  describe "Complex Queries" do
    it "supports nested channel queries" do
      query = <<~GQL
        query {
          channels {
            id
            name
            posts {
              id
              title
              channels {
                name
                settings
              }
            }
            overrides {
              id
              path
              data
            }
          }
        }
      GQL

      post "/graphql", params: { query: query }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['channels']).to be_an(Array)
      
      channel_data = json['data']['channels'].first
      expect(channel_data['posts']).to be_an(Array)
      expect(channel_data['overrides']).to be_an(Array)
    end
  end
end

