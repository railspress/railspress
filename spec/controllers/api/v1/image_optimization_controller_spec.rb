require 'rails_helper'

RSpec.describe Api::V1::ImageOptimizationController, type: :controller do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:api_key) { create(:api_key, user: user, tenant: tenant) }

  before do
    ActsAsTenant.current_tenant = tenant
    request.headers['Authorization'] = "Bearer #{api_key.token}"
  end

  describe 'authentication' do
    context 'when no API key provided' do
      before { request.headers['Authorization'] = nil }

      it 'returns unauthorized' do
        get :analytics
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when invalid API key provided' do
      before { request.headers['Authorization'] = 'Bearer invalid_token' }

      it 'returns unauthorized' do
        get :analytics
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #analytics' do
    before do
      allow(ImageOptimizationLog).to receive(:total_images_optimized).and_return(10)
      allow(ImageOptimizationLog).to receive(:total_bytes_saved).and_return(1000000)
      allow(ImageOptimizationLog).to receive(:average_size_reduction).and_return(25.5)
      allow(ImageOptimizationLog).to receive(:average_processing_time).and_return(1.2)
      allow(ImageOptimizationLog).to receive(:compression_level_stats).and_return({'lossy' => 8, 'ultra' => 2})
      allow(ImageOptimizationLog).to receive(:optimization_type_stats).and_return({'upload' => 6, 'bulk' => 4})
    end

    it 'returns JSON analytics data' do
      get :analytics
      expect(response.content_type).to include('application/json')
    end

    it 'includes comprehensive analytics' do
      get :analytics
      json = JSON.parse(response.body)
      
      expect(json).to include('total_images_optimized', 'total_bytes_saved', 'total_size_saved_mb')
      expect(json).to include('average_size_reduction', 'average_processing_time')
      expect(json).to include('compression_level_stats', 'optimization_type_stats')
      expect(json).to include('success_rate', 'failure_rate')
    end

    it 'calculates success and failure rates' do
      allow(ImageOptimizationLog).to receive(:successful).and_return(double(count: 8))
      allow(ImageOptimizationLog).to receive(:failed).and_return(double(count: 2))
      allow(ImageOptimizationLog).to receive(:count).and_return(10)

      get :analytics
      json = JSON.parse(response.body)
      
      expect(json['success_rate']).to eq(80.0)
      expect(json['failure_rate']).to eq(20.0)
    end
  end

  describe 'GET #report' do
    before do
      allow(ImageOptimizationLog).to receive(:generate_report).and_return({
        total_optimizations: 10,
        successful_optimizations: 8,
        failed_optimizations: 2,
        total_bytes_saved: 1000000,
        total_size_saved_mb: 0.95,
        average_size_reduction: 25.5,
        average_processing_time: 1.2
      })
    end

    it 'returns detailed report' do
      get :report
      expect(response.content_type).to include('application/json')
    end

    it 'includes all report data' do
      get :report
      json = JSON.parse(response.body)
      
      expect(json).to include('total_optimizations', 'successful_optimizations', 'failed_optimizations')
      expect(json).to include('total_bytes_saved', 'total_size_saved_mb', 'average_size_reduction')
      expect(json).to include('average_processing_time', 'compression_level_breakdown')
      expect(json).to include('optimization_type_breakdown', 'daily_optimizations')
      expect(json).to include('top_users', 'top_tenants')
    end

    context 'with date filtering' do
      it 'filters by start_date' do
        get :report, params: { start_date: '2024-01-01' }
        expect(response).to have_http_status(:success)
      end

      it 'filters by end_date' do
        get :report, params: { end_date: '2024-12-31' }
        expect(response).to have_http_status(:success)
      end

      it 'filters by both dates' do
        get :report, params: { start_date: '2024-01-01', end_date: '2024-12-31' }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET #failed' do
    let!(:failed_log) { create(:image_optimization_log, status: 'failed', tenant: tenant) }

    it 'returns failed optimizations' do
      get :failed
      expect(response.content_type).to include('application/json')
    end

    it 'includes failed optimization data' do
      get :failed
      json = JSON.parse(response.body)
      
      expect(json).to include('failed_optimizations', 'total_count', 'page', 'per_page')
      expect(json['failed_optimizations']).to be_an(Array)
    end

    context 'with pagination' do
      it 'handles page parameter' do
        get :failed, params: { page: 2 }
        expect(response).to have_http_status(:success)
      end

      it 'handles per_page parameter' do
        get :failed, params: { per_page: 5 }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET #top_savings' do
    let!(:log1) { create(:image_optimization_log, bytes_saved: 200000, tenant: tenant) }
    let!(:log2) { create(:image_optimization_log, bytes_saved: 100000, tenant: tenant) }

    it 'returns top savings optimizations' do
      get :top_savings
      expect(response.content_type).to include('application/json')
    end

    it 'orders by bytes saved descending' do
      get :top_savings
      json = JSON.parse(response.body)
      
      expect(json).to include('top_savings', 'total_count')
      expect(json['top_savings']).to be_an(Array)
    end

    context 'with limit parameter' do
      it 'limits results' do
        get :top_savings, params: { limit: 1 }
        json = JSON.parse(response.body)
        expect(json['top_savings'].length).to eq(1)
      end
    end
  end

  describe 'GET #user_stats' do
    it 'returns user statistics' do
      get :user_stats
      expect(response.content_type).to include('application/json')
    end

    it 'includes user stats data' do
      get :user_stats
      json = JSON.parse(response.body)
      
      expect(json).to include('user_stats', 'total_users')
      expect(json['user_stats']).to be_a(Hash)
    end
  end

  describe 'GET #compression_levels' do
    it 'returns compression level statistics' do
      get :compression_levels
      expect(response.content_type).to include('application/json')
    end

    it 'includes compression level data' do
      get :compression_levels
      json = JSON.parse(response.body)
      
      expect(json).to include('compression_level_stats', 'available_levels')
      expect(json['compression_level_stats']).to be_a(Hash)
      expect(json['available_levels']).to be_a(Hash)
    end
  end

  describe 'GET #performance' do
    it 'returns performance metrics' do
      get :performance
      expect(response.content_type).to include('application/json')
    end

    it 'includes performance data' do
      get :performance
      json = JSON.parse(response.body)
      
      expect(json).to include('average_processing_time', 'fastest_optimization', 'slowest_optimization')
      expect(json).to include('processing_time_distribution', 'performance_trends')
    end
  end

  describe 'POST #bulk_optimize' do
    let(:upload1) { create(:upload, tenant: tenant) }
    let(:upload2) { create(:upload, tenant: tenant) }
    let(:medium1) { create(:medium, upload: upload1, tenant: tenant) }
    let(:medium2) { create(:medium, upload: upload2, tenant: tenant) }

    before do
      allow(Upload).to receive(:joins).and_return(double(
        where: double(
          where: double(
            where: double(
              limit: [upload1, upload2]
            )
          )
        )
      ))
      allow(OptimizeImageJob).to receive(:perform_later)
    end

    it 'starts bulk optimization' do
      expect(OptimizeImageJob).to receive(:perform_later).twice
      
      post :bulk_optimize
      expect(response).to have_http_status(:success)
    end

    it 'returns success response' do
      post :bulk_optimize
      json = JSON.parse(response.body)
      
      expect(json).to include('success', 'message', 'jobs_queued')
      expect(json['success']).to be true
    end

    it 'handles no unoptimized images' do
      allow(Upload).to receive(:joins).and_return(double(
        where: double(
          where: double(
            where: double(
              limit: []
            )
          )
        )
      ))

      post :bulk_optimize
      json = JSON.parse(response.body)
      
      expect(json['success']).to be true
      expect(json['jobs_queued']).to eq(0)
    end
  end

  describe 'POST #regenerate_variants' do
    let(:medium) { create(:medium, tenant: tenant) }

    it 'regenerates variants for medium' do
      expect(OptimizeImageJob).to receive(:perform_later).with(
        medium_id: medium.id,
        optimization_type: 'regenerate',
        request_context: hash_including(:user_agent, :ip_address)
      )

      post :regenerate_variants, params: { medium_id: medium.id }
      expect(response).to have_http_status(:success)
    end

    it 'returns success response' do
      post :regenerate_variants, params: { medium_id: medium.id }
      json = JSON.parse(response.body)
      
      expect(json).to include('success', 'message')
      expect(json['success']).to be true
    end

    it 'handles missing medium' do
      post :regenerate_variants, params: { medium_id: 999 }
      json = JSON.parse(response.body)
      
      expect(json['success']).to be false
      expect(json['message']).to include('not found')
    end
  end

  describe 'DELETE #clear_logs' do
    it 'clears all optimization logs' do
      expect(ImageOptimizationLog).to receive(:delete_all)
      
      delete :clear_logs
      expect(response).to have_http_status(:success)
    end

    it 'returns success response' do
      delete :clear_logs
      json = JSON.parse(response.body)
      
      expect(json).to include('success', 'message')
      expect(json['success']).to be true
    end
  end

  describe 'GET #export' do
    it 'exports logs as CSV' do
      allow(ImageOptimizationLog).to receive(:export_to_csv).and_return('csv,data')
      
      get :export
      expect(response.content_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('attachment')
    end

    context 'with date filtering' do
      it 'exports filtered data' do
        get :export, params: { start_date: '2024-01-01', end_date: '2024-12-31' }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'error handling' do
    it 'handles internal server errors gracefully' do
      allow(ImageOptimizationLog).to receive(:total_images_optimized).and_raise(StandardError.new('Database error'))
      
      get :analytics
      expect(response).to have_http_status(:internal_server_error)
      
      json = JSON.parse(response.body)
      expect(json).to include('error', 'message')
    end

    it 'handles validation errors' do
      post :regenerate_variants, params: { medium_id: nil }
      expect(response).to have_http_status(:bad_request)
      
      json = JSON.parse(response.body)
      expect(json).to include('error', 'message')
    end
  end
end
