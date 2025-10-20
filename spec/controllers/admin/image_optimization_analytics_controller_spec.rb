require 'rails_helper'

RSpec.describe Admin::ImageOptimizationAnalyticsController, type: :controller do
  let(:tenant) { create(:tenant) }
  let(:admin_user) { create(:user, tenant: tenant, role: 'admin') }
  let(:regular_user) { create(:user, tenant: tenant, role: 'user') }

  before do
    sign_in admin_user
    ActsAsTenant.current_tenant = tenant
  end

  describe 'authentication' do
    context 'when user is not signed in' do
      before { sign_out admin_user }

      it 'redirects to login' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is not admin' do
      before { sign_in regular_user }

      it 'redirects to unauthorized page' do
        get :index
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET #index' do
    let!(:log1) { create(:image_optimization_log, status: 'success', bytes_saved: 100000, tenant: tenant) }
    let!(:log2) { create(:image_optimization_log, status: 'failed', bytes_saved: 0, tenant: tenant) }

    before do
      allow(ImageOptimizationLog).to receive(:recent).and_return(double(limit: double(includes: [log1, log2])))
      allow(ImageOptimizationLog).to receive(:compression_level_stats).and_return({'lossy' => 1})
      allow(ImageOptimizationLog).to receive(:optimization_type_stats).and_return({'upload' => 1})
      allow(ImageOptimizationLog).to receive(:daily_stats).and_return({Date.current => 1})
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end

    it 'assigns @stats' do
      get :index
      expect(assigns(:stats)).to be_present
    end

    it 'assigns @recent_optimizations' do
      get :index
      expect(assigns(:recent_optimizations)).to be_present
    end

    it 'assigns @compression_level_stats' do
      get :index
      expect(assigns(:compression_level_stats)).to be_present
    end

    it 'assigns @optimization_type_stats' do
      get :index
      expect(assigns(:optimization_type_stats)).to be_present
    end

    it 'assigns @daily_stats' do
      get :index
      expect(assigns(:daily_stats)).to be_present
    end
  end

  describe 'GET #report' do
    it 'renders the report template' do
      get :report
      expect(response).to render_template(:report)
    end

    it 'assigns @report_data' do
      allow(ImageOptimizationLog).to receive(:generate_report).and_return({total: 10})
      get :report
      expect(assigns(:report_data)).to be_present
    end

    context 'with date parameters' do
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
    it 'renders the failed template' do
      get :failed
      expect(response).to render_template(:failed)
    end

    it 'assigns @failed_optimizations' do
      allow(ImageOptimizationLog).to receive(:failed_optimizations).and_return([])
      get :failed
      expect(assigns(:failed_optimizations)).to be_present
    end

    context 'with pagination' do
      it 'handles page parameter' do
        get :failed, params: { page: 2 }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET #top_savings' do
    it 'renders the top_savings template' do
      get :top_savings
      expect(response).to render_template(:top_savings)
    end

    it 'assigns @top_savings' do
      allow(ImageOptimizationLog).to receive(:top_savings).and_return([])
      get :top_savings
      expect(assigns(:top_savings)).to be_present
    end

    context 'with limit parameter' do
      it 'limits results' do
        get :top_savings, params: { limit: 5 }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET #user_stats' do
    it 'renders the user_stats template' do
      get :user_stats
      expect(response).to render_template(:user_stats)
    end

    it 'assigns @user_stats' do
      allow(ImageOptimizationLog).to receive(:user_stats).and_return({})
      get :user_stats
      expect(assigns(:user_stats)).to be_present
    end
  end

  describe 'GET #tenant_stats' do
    it 'renders the tenant_stats template' do
      get :tenant_stats
      expect(response).to render_template(:tenant_stats)
    end

    it 'assigns @tenant_stats' do
      allow(ImageOptimizationLog).to receive(:tenant_stats).and_return({})
      get :tenant_stats
      expect(assigns(:tenant_stats)).to be_present
    end
  end

  describe 'GET #compression_levels' do
    it 'renders the compression_levels template' do
      get :compression_levels
      expect(response).to render_template(:compression_levels)
    end

    it 'assigns @compression_level_stats' do
      allow(ImageOptimizationLog).to receive(:compression_level_stats).and_return({})
      get :compression_levels
      expect(assigns(:compression_level_stats)).to be_present
    end

    it 'assigns @available_levels' do
      allow(ImageOptimizationService).to receive(:available_compression_levels).and_return({})
      get :compression_levels
      expect(assigns(:available_levels)).to be_present
    end
  end

  describe 'GET #performance' do
    it 'renders the performance template' do
      get :performance
      expect(response).to render_template(:performance)
    end

    it 'assigns @performance_data' do
      get :performance
      expect(assigns(:performance_data)).to be_present
    end
  end

  describe 'DELETE #clear_logs' do
    it 'clears all logs' do
      expect(ImageOptimizationLog).to receive(:delete_all)
      delete :clear_logs
      expect(response).to redirect_to(admin_image_optimization_analytics_index_path)
    end

    it 'sets flash notice' do
      allow(ImageOptimizationLog).to receive(:delete_all)
      delete :clear_logs
      expect(flash[:notice]).to eq('All optimization logs have been cleared.')
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

  describe 'private methods' do
    describe '#calculate_overview_stats' do
      before do
        allow(ImageOptimizationLog).to receive(:count).and_return(10)
        allow(ImageOptimizationLog).to receive(:successful).and_return(double(count: 8))
        allow(ImageOptimizationLog).to receive(:failed).and_return(double(count: 1))
        allow(ImageOptimizationLog).to receive(:skipped).and_return(double(count: 1))
        allow(ImageOptimizationLog).to receive(:total_bytes_saved).and_return(1000000)
        allow(ImageOptimizationLog).to receive(:average_size_reduction).and_return(25.5)
        allow(ImageOptimizationLog).to receive(:average_processing_time).and_return(1.2)
        allow(ImageOptimizationLog).to receive(:today).and_return(double(count: 2))
        allow(ImageOptimizationLog).to receive(:this_week).and_return(double(count: 5))
        allow(ImageOptimizationLog).to receive(:this_month).and_return(double(count: 8))
      end

      it 'calculates comprehensive stats' do
        controller.send(:calculate_overview_stats)
        stats = controller.instance_variable_get(:@stats)
        
        expect(stats[:total_optimizations]).to eq(10)
        expect(stats[:successful_optimizations]).to eq(8)
        expect(stats[:failed_optimizations]).to eq(1)
        expect(stats[:skipped_optimizations]).to eq(1)
        expect(stats[:total_bytes_saved]).to eq(1000000)
        expect(stats[:total_size_saved_mb]).to eq(0.95)
        expect(stats[:average_size_reduction]).to eq(25.5)
        expect(stats[:average_processing_time]).to eq(1.2)
        expect(stats[:today_optimizations]).to eq(2)
        expect(stats[:this_week_optimizations]).to eq(5)
        expect(stats[:this_month_optimizations]).to eq(8)
      end
    end
  end
end
