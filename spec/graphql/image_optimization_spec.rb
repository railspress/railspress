require 'rails_helper'

RSpec.describe 'Image Optimization GraphQL API', type: :request do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:upload) { create(:upload, user: user, tenant: tenant) }
  let(:medium) { create(:medium, user: user, tenant: tenant, upload: upload) }
  let!(:log_entry) { create(:image_optimization_log, medium: medium, upload: upload, user: user, tenant: tenant) }

  before do
    ActsAsTenant.current_tenant = tenant
    sign_in user
  end

  describe 'ImageOptimizationLogType' do
    let(:query) do
      <<~GRAPHQL
        query {
          imageOptimization {
            logs(first: 10) {
              edges {
                node {
                  id
                  filename
                  contentType
                  originalSize
                  optimizedSize
                  bytesSaved
                  sizeReductionPercentage
                  sizeReductionMb
                  compressionLevel
                  compressionLevelName
                  compressionLevelDescription
                  expectedSavings
                  recommendedFor
                  quality
                  processingTime
                  processingTimeFormatted
                  status
                  optimizationType
                  variantsGenerated
                  responsiveVariantsGenerated
                  errorMessage
                  warnings
                  user {
                    id
                    email
                  }
                  medium {
                    id
                    title
                  }
                  upload {
                    id
                    title
                  }
                  createdAt
                  updatedAt
                }
              }
            }
          }
        }
      GRAPHQL
    end

    it 'returns image optimization logs' do
      post '/graphql', params: { query: query }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      expect(json['data']['imageOptimization']['logs']['edges']).to be_an(Array)
      expect(json['data']['imageOptimization']['logs']['edges'].first['node']).to include(
        'id', 'filename', 'contentType', 'originalSize', 'optimizedSize', 'bytesSaved'
      )
    end

    it 'includes all required fields' do
      post '/graphql', params: { query: query }
      
      json = JSON.parse(response.body)
      node = json['data']['imageOptimization']['logs']['edges'].first['node']
      
      expect(node).to include('compressionLevelName', 'compressionLevelDescription')
      expect(node).to include('expectedSavings', 'recommendedFor', 'processingTimeFormatted')
      expect(node).to include('sizeReductionMb', 'variantsGenerated', 'responsiveVariantsGenerated')
      expect(node).to include('user', 'medium', 'upload')
    end
  end

  describe 'ImageOptimizationStatsType' do
    let(:query) do
      <<~GRAPHQL
        query {
          imageOptimization {
            stats {
              totalImagesOptimized
              totalBytesSaved
              totalSizeSavedMb
              averageSizeReduction
              averageProcessingTime
              compressionLevelStats
              optimizationTypeStats
              successRate
              failureRate
            }
          }
        }
      GRAPHQL
    end

    it 'returns optimization statistics' do
      post '/graphql', params: { query: query }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      stats = json['data']['imageOptimization']['stats']
      expect(stats).to include('totalImagesOptimized', 'totalBytesSaved', 'totalSizeSavedMb')
      expect(stats).to include('averageSizeReduction', 'averageProcessingTime')
      expect(stats).to include('compressionLevelStats', 'optimizationTypeStats')
      expect(stats).to include('successRate', 'failureRate')
    end
  end

  describe 'CompressionLevelType' do
    let(:query) do
      <<~GRAPHQL
        query {
          imageOptimization {
            compressionLevels {
              name
              description
              quality
              compressionLevel
              lossy
              expectedSavings
              recommendedFor
            }
          }
        }
      GRAPHQL
    end

    it 'returns available compression levels' do
      post '/graphql', params: { query: query }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      levels = json['data']['imageOptimization']['compressionLevels']
      expect(levels).to be_an(Array)
      expect(levels.first).to include('name', 'description', 'quality', 'compressionLevel')
      expect(levels.first).to include('lossy', 'expectedSavings', 'recommendedFor')
    end
  end

  describe 'ImageOptimizationReportType' do
    let(:query) do
      <<~GRAPHQL
        query {
          imageOptimization {
            report(startDate: "2024-01-01", endDate: "2024-12-31") {
              totalOptimizations
              successfulOptimizations
              failedOptimizations
              skippedOptimizations
              totalBytesSaved
              totalSizeSavedMb
              averageSizeReduction
              averageProcessingTime
              compressionLevelBreakdown
              optimizationTypeBreakdown
              dailyOptimizations
              topUsers {
                userId
                count
              }
              topTenants {
                tenantId
                count
              }
            }
          }
        }
      GRAPHQL
    end

    it 'returns detailed optimization report' do
      post '/graphql', params: { query: query }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      report = json['data']['imageOptimization']['report']
      expect(report).to include('totalOptimizations', 'successfulOptimizations', 'failedOptimizations')
      expect(report).to include('totalBytesSaved', 'totalSizeSavedMb', 'averageSizeReduction')
      expect(report).to include('compressionLevelBreakdown', 'optimizationTypeBreakdown')
      expect(report).to include('dailyOptimizations', 'topUsers', 'topTenants')
    end
  end

  describe 'mutations' do
    describe 'bulkOptimizeImages' do
      let(:mutation) do
        <<~GRAPHQL
          mutation {
            bulkOptimizeImages {
              success
              message
              jobsQueued
            }
          }
        GRAPHQL
      end

      it 'starts bulk optimization' do
        allow(OptimizeImageJob).to receive(:perform_later)
        
        post '/graphql', params: { query: mutation }
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        
        expect(json['data']['bulkOptimizeImages']).to include('success', 'message', 'jobsQueued')
        expect(json['data']['bulkOptimizeImages']['success']).to be true
      end
    end

    describe 'regenerateImageVariants' do
      let(:mutation) do
        <<~GRAPHQL
          mutation {
            regenerateImageVariants(mediumId: "#{medium.id}") {
              success
              message
            }
          }
        GRAPHQL
      end

      it 'regenerates variants for medium' do
        expect(OptimizeImageJob).to receive(:perform_later).with(
          medium_id: medium.id,
          optimization_type: 'regenerate',
          request_context: hash_including(:user_agent, :ip_address)
        )
        
        post '/graphql', params: { query: mutation }
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        
        expect(json['data']['regenerateImageVariants']).to include('success', 'message')
        expect(json['data']['regenerateImageVariants']['success']).to be true
      end

      it 'handles missing medium' do
        mutation = <<~GRAPHQL
          mutation {
            regenerateImageVariants(mediumId: "999") {
              success
              message
            }
          }
        GRAPHQL
        
        post '/graphql', params: { query: mutation }
        
        json = JSON.parse(response.body)
        expect(json['data']['regenerateImageVariants']['success']).to be false
      end
    end

    describe 'clearOptimizationLogs' do
      let(:mutation) do
        <<~GRAPHQL
          mutation {
            clearOptimizationLogs(confirm: true) {
              success
              message
            }
          }
        GRAPHQL
      end

      it 'clears all optimization logs' do
        expect(ImageOptimizationLog).to receive(:delete_all)
        
        post '/graphql', params: { query: mutation }
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        
        expect(json['data']['clearOptimizationLogs']).to include('success', 'message')
        expect(json['data']['clearOptimizationLogs']['success']).to be true
      end

      it 'requires confirmation' do
        mutation = <<~GRAPHQL
          mutation {
            clearOptimizationLogs(confirm: false) {
              success
              message
            }
          }
        GRAPHQL
        
        post '/graphql', params: { query: mutation }
        
        json = JSON.parse(response.body)
        expect(json['data']['clearOptimizationLogs']['success']).to be false
      end
    end
  end

  describe 'ImageOptimizationResolver' do
    let(:query) do
      <<~GRAPHQL
        query {
          imageOptimization {
            logs(first: 5) {
              edges {
                node {
                  id
                  filename
                }
              }
              pageInfo {
                hasNextPage
                hasPreviousPage
                startCursor
                endCursor
              }
            }
          }
        }
      GRAPHQL
    end

    it 'supports pagination' do
      post '/graphql', params: { query: query }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      expect(json['data']['imageOptimization']['logs']).to include('edges', 'pageInfo')
      expect(json['data']['imageOptimization']['logs']['pageInfo']).to include(
        'hasNextPage', 'hasPreviousPage', 'startCursor', 'endCursor'
      )
    end

    it 'supports filtering by status' do
      query = <<~GRAPHQL
        query {
          imageOptimization {
            logs(first: 5, status: "success") {
              edges {
                node {
                  id
                  status
                }
              }
            }
          }
        }
      GRAPHQL
      
      post '/graphql', params: { query: query }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      logs = json['data']['imageOptimization']['logs']['edges']
      logs.each do |edge|
        expect(edge['node']['status']).to eq('success')
      end
    end

    it 'supports filtering by compression level' do
      query = <<~GRAPHQL
        query {
          imageOptimization {
            logs(first: 5, compressionLevel: "lossy") {
              edges {
                node {
                  id
                  compressionLevel
                }
              }
            }
          }
        }
      GRAPHQL
      
      post '/graphql', params: { query: query }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      logs = json['data']['imageOptimization']['logs']['edges']
      logs.each do |edge|
        expect(edge['node']['compressionLevel']).to eq('lossy')
      end
    end

    it 'supports date range filtering' do
      query = <<~GRAPHQL
        query {
          imageOptimization {
            logs(first: 5, startDate: "2024-01-01", endDate: "2024-12-31") {
              edges {
                node {
                  id
                  createdAt
                }
              }
            }
          }
        }
      GRAPHQL
      
      post '/graphql', params: { query: query }
      
      expect(response).to have_http_status(:success)
    end
  end

  describe 'error handling' do
    it 'handles GraphQL errors gracefully' do
      query = <<~GRAPHQL
        query {
          imageOptimization {
            logs(first: -1) {
              edges {
                node {
                  id
                }
              }
            }
          }
        }
      GRAPHQL
      
      post '/graphql', params: { query: query }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      expect(json).to include('errors')
      expect(json['errors']).to be_an(Array)
    end

    it 'handles invalid field queries' do
      query = <<~GRAPHQL
        query {
          imageOptimization {
            logs(first: 5) {
              edges {
                node {
                  invalidField
                }
              }
            }
          }
        }
      GRAPHQL
      
      post '/graphql', params: { query: query }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      expect(json).to include('errors')
    end
  end

  describe 'authentication' do
    context 'when user is not signed in' do
      before { sign_out user }

      it 'returns authentication error' do
        query = <<~GRAPHQL
          query {
            imageOptimization {
              stats {
                totalImagesOptimized
              }
            }
          }
        GRAPHQL
        
        post '/graphql', params: { query: query }
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        
        expect(json).to include('errors')
        expect(json['errors'].first['message']).to include('authentication')
      end
    end
  end
end
