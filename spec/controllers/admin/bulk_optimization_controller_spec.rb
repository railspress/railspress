require 'rails_helper'

RSpec.describe Admin::BulkOptimizationController, type: :controller do
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
    before do
      allow(ImageOptimizationService).to receive(:available_compression_levels).and_return({
        'lossy' => { name: 'Lossy', description: 'Balanced quality and compression' }
      })
      allow(ImageOptimizationLog).to receive(:total_images_optimized).and_return(10)
      allow(ImageOptimizationLog).to receive(:total_bytes_saved).and_return(1000000)
      allow(ImageOptimizationLog).to receive(:average_size_reduction).and_return(25.5)
      allow(Upload).to receive(:joins).and_return(double(where: double(count: 5)))
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end

    it 'assigns @compression_levels' do
      get :index
      expect(assigns(:compression_levels)).to be_present
    end

    it 'assigns @current_level' do
      allow(SiteSetting).to receive(:get).with('image_compression_level', 'lossy').and_return('lossy')
      get :index
      expect(assigns(:current_level)).to eq('lossy')
    end

    it 'assigns @stats' do
      get :index
      expect(assigns(:stats)).to be_present
    end

    it 'assigns @unoptimized_count' do
      get :index
      expect(assigns(:unoptimized_count)).to eq(5)
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

    it 'queues optimization jobs for unoptimized images' do
      expect(OptimizeImageJob).to receive(:perform_later).with(
        medium_id: medium1.id,
        optimization_type: 'bulk',
        request_context: hash_including(:user_agent, :ip_address)
      )
      expect(OptimizeImageJob).to receive(:perform_later).with(
        medium_id: medium2.id,
        optimization_type: 'bulk',
        request_context: hash_including(:user_agent, :ip_address)
      )

      post :bulk_optimize
    end

    it 'redirects with success message' do
      post :bulk_optimize
      expect(response).to redirect_to(admin_media_bulk_optimization_path)
      expect(flash[:notice]).to include('Bulk optimization started')
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
      expect(response).to redirect_to(admin_media_bulk_optimization_path)
      expect(flash[:notice]).to include('No unoptimized images found')
    end

    it 'limits to 100 images per batch' do
      uploads = Array.new(150) { create(:upload, tenant: tenant) }
      allow(Upload).to receive(:joins).and_return(double(
        where: double(
          where: double(
            where: double(
              limit: uploads.first(100)
            )
          )
        )
      ))

      expect(OptimizeImageJob).to receive(:perform_later).exactly(100).times
      post :bulk_optimize
    end
  end

  describe 'GET #bulk_optimize_status' do
    before do
      allow(ImageOptimizationLog).to receive(:where).and_return(double(count: 5))
      allow(ImageOptimizationLog).to receive(:successful).and_return(double(count: 4))
      allow(ImageOptimizationLog).to receive(:failed).and_return(double(count: 1))
    end

    it 'returns JSON status' do
      get :bulk_optimize_status, format: :json
      expect(response.content_type).to include('application/json')
    end

    it 'includes optimization counts' do
      get :bulk_optimize_status, format: :json
      json = JSON.parse(response.body)
      expect(json).to include('total', 'successful', 'failed', 'in_progress')
    end

    it 'calculates in_progress count' do
      get :bulk_optimize_status, format: :json
      json = JSON.parse(response.body)
      expect(json['in_progress']).to eq(0) # 5 total - 4 successful - 1 failed
    end
  end

  describe 'POST #regenerate_variants' do
    let(:medium) { create(:medium, tenant: tenant) }

    it 'queues variant regeneration job' do
      expect(OptimizeImageJob).to receive(:perform_later).with(
        medium_id: medium.id,
        optimization_type: 'regenerate',
        request_context: hash_including(:user_agent, :ip_address)
      )

      post :regenerate_variants, params: { medium_id: medium.id }
    end

    it 'redirects with success message' do
      post :regenerate_variants, params: { medium_id: medium.id }
      expect(response).to redirect_to(admin_media_bulk_optimization_path)
      expect(flash[:notice]).to include('Variant regeneration started')
    end

    it 'handles missing medium' do
      post :regenerate_variants, params: { medium_id: 999 }
      expect(response).to redirect_to(admin_media_bulk_optimization_path)
      expect(flash[:alert]).to include('Medium not found')
    end
  end

  describe 'DELETE #clear_variants' do
    let(:upload) { create(:upload, tenant: tenant, variants: {'webp' => {blob_id: 1}}) }

    it 'clears variants from upload' do
      expect(upload).to receive(:update!).with(variants: {})
      allow(Upload).to receive(:find).with(upload.id.to_s).and_return(upload)

      delete :clear_variants, params: { upload_id: upload.id }
    end

    it 'redirects with success message' do
      allow(Upload).to receive(:find).with(upload.id.to_s).and_return(upload)
      allow(upload).to receive(:update!)

      delete :clear_variants, params: { upload_id: upload.id }
      expect(response).to redirect_to(admin_media_bulk_optimization_path)
      expect(flash[:notice]).to include('Variants cleared')
    end

    it 'handles missing upload' do
      delete :clear_variants, params: { upload_id: 999 }
      expect(response).to redirect_to(admin_media_bulk_optimization_path)
      expect(flash[:alert]).to include('Upload not found')
    end
  end

  describe 'GET #optimization_report' do
    before do
      allow(ImageOptimizationLog).to receive(:generate_report).and_return({
        total_optimizations: 10,
        successful_optimizations: 8,
        failed_optimizations: 2
      })
    end

    it 'renders the optimization_report template' do
      get :optimization_report
      expect(response).to render_template(:optimization_report)
    end

    it 'assigns @report_data' do
      get :optimization_report
      expect(assigns(:report_data)).to be_present
    end

    context 'with date filtering' do
      it 'filters by start_date' do
        get :optimization_report, params: { start_date: '2024-01-01' }
        expect(response).to have_http_status(:success)
      end

      it 'filters by end_date' do
        get :optimization_report, params: { end_date: '2024-12-31' }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'private methods' do
    describe '#load_compression_levels' do
      it 'loads available compression levels' do
        controller.send(:load_compression_levels)
        expect(assigns(:compression_levels)).to be_present
      end
    end

    describe '#load_stats' do
      it 'loads optimization statistics' do
        controller.send(:load_stats)
        expect(assigns(:stats)).to be_present
      end
    end

    describe '#load_unoptimized_count' do
      it 'loads count of unoptimized images' do
        controller.send(:load_unoptimized_count)
        expect(assigns(:unoptimized_count)).to be_present
      end
    end
  end
end
