require 'rails_helper'

RSpec.describe 'Image Optimization Integration', type: :feature do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }

  before do
    ActsAsTenant.current_tenant = tenant
    sign_in user
    
    # Enable optimization settings
    allow(SiteSetting).to receive(:get).with('auto_optimize_images', false).and_return(true)
    allow(SiteSetting).to receive(:get).with('image_compression_level', 'lossy').and_return('lossy')
    allow(SiteSetting).to receive(:get).with('image_quality', 85).and_return(85)
    allow(SiteSetting).to receive(:get).with('image_compression_level_value', 6).and_return(6)
    allow(SiteSetting).to receive(:get).with('image_max_width', 2000).and_return(2000)
    allow(SiteSetting).to receive(:get).with('image_max_height', 2000).and_return(2000)
    allow(SiteSetting).to receive(:get).with('strip_image_metadata', true).and_return(true)
    allow(SiteSetting).to receive(:get).with('enable_webp_variants', true).and_return(true)
    allow(SiteSetting).to receive(:get).with('enable_avif_variants', true).and_return(true)
    allow(SiteSetting).to receive(:get).with('enable_responsive_variants', true).and_return(true)
    allow(SiteSetting).to receive(:get).with('responsive_breakpoints', '320,640,768,1024,1200,1920').and_return('320,640,768')
    
    # Mock storage configuration
    storage_config = double('StorageConfigurationService')
    allow(StorageConfigurationService).to receive(:new).and_return(storage_config)
    allow(storage_config).to receive(:auto_optimize_enabled?).and_return(true)
    allow(storage_config).to receive(:cdn_enabled?).and_return(false)
  end

  describe 'Complete Upload and Optimization Workflow' do
    it 'processes image upload through complete optimization pipeline' do
      # Step 1: Create upload
      upload = create(:upload, user: user, tenant: tenant)
      
      # Step 2: Create medium
      medium = create(:medium, user: user, tenant: tenant, upload: upload)
      
      # Step 3: Mock file attachment
      file_double = double('file')
      allow(upload).to receive(:file).and_return(file_double)
      allow(file_double).to receive(:attached?).and_return(true)
      allow(file_double).to receive(:download).and_return('fake_image_data')
      allow(file_double).to receive(:filename).and_return(double(to_s: 'test.jpg', base: 'test'))
      allow(file_double).to receive(:content_type).and_return('image/jpeg')
      allow(file_double).to receive(:purge)
      allow(file_double).to receive(:attach)
      
      # Step 4: Mock image processing
      allow(ImageProcessing::Vips).to receive(:source).and_return(double(
        resize_to_limit: double(
          saver: double(call: double(path: '/tmp/processed.jpg'))
        ),
        convert: double(
          saver: double(call: double(path: '/tmp/variant.jpg'))
        )
      ))
      allow(File).to receive(:read).and_return('processed_data')
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:unlink)
      
      # Step 5: Mock ActiveStorage blob creation
      blob_double = double('blob', id: 123)
      allow(ActiveStorage::Blob).to receive(:create_and_upload!).and_return(blob_double)
      
      # Step 6: Mock upload updates
      allow(upload).to receive(:update!)
      
      # Step 7: Mock log creation
      log_double = double('log', id: 1, update!: true)
      allow(ImageOptimizationLog).to receive(:create!).and_return(log_double)
      
      # Step 8: Trigger optimization
      expect(OptimizeImageJob).to receive(:perform_later).with(
        medium_id: medium.id,
        optimization_type: 'upload',
        request_context: hash_including(:user_agent, :ip_address)
      )
      
      # Simulate the upload hook trigger
      medium.send(:trigger_media_uploaded_hook)
      
      # Verify optimization was queued
      expect(OptimizeImageJob).to have_received(:perform_later)
    end

    it 'handles optimization failure gracefully' do
      upload = create(:upload, user: user, tenant: tenant)
      medium = create(:medium, user: user, tenant: tenant, upload: upload)
      
      # Mock file attachment
      file_double = double('file')
      allow(upload).to receive(:file).and_return(file_double)
      allow(file_double).to receive(:attached?).and_return(true)
      allow(file_double).to receive(:download).and_return('fake_image_data')
      
      # Mock processing failure
      allow(ImageProcessing::Vips).to receive(:source).and_raise(StandardError.new('Processing failed'))
      
      # Mock log creation and update
      log_double = double('log', id: 1, update!: true)
      allow(ImageOptimizationLog).to receive(:create!).and_return(log_double)
      
      # Create service and test optimization
      service = ImageOptimizationService.new(medium)
      
      expect(service.optimize!).to be false
    end
  end

  describe 'Admin Interface Integration' do
    let(:admin_user) { create(:user, tenant: tenant, role: 'admin') }

    before { sign_in admin_user }

    it 'displays analytics dashboard correctly' do
      # Create some test data
      upload = create(:upload, user: user, tenant: tenant)
      medium = create(:medium, user: user, tenant: tenant, upload: upload)
      log = create(:image_optimization_log, 
                   medium: medium, 
                   upload: upload, 
                   user: user, 
                   tenant: tenant,
                   status: 'success',
                   bytes_saved: 100000,
                   size_reduction_percentage: 25.0)
      
      visit '/admin/media/optimization_analytics'
      
      expect(page).to have_content('Image Optimization Analytics')
      expect(page).to have_content('Total Images Optimized')
      expect(page).to have_content('Total Bytes Saved')
      expect(page).to have_content('Average Size Reduction')
    end

    it 'displays bulk optimization interface' do
      visit '/admin/media/bulk_optimization'
      
      expect(page).to have_content('Bulk Image Optimization')
      expect(page).to have_content('Current Compression Level')
      expect(page).to have_content('Start Bulk Optimization')
      expect(page).to have_content('Regenerate Variants')
    end

    it 'displays media settings with optimization options' do
      visit '/admin/settings/media'
      
      expect(page).to have_content('Image Optimization')
      expect(page).to have_content('Compression Level')
      expect(page).to have_content('View Optimization Analytics')
      expect(page).to have_content('Bulk Optimization')
    end
  end

  describe 'API Integration' do
    let(:api_key) { create(:api_key, user: user, tenant: tenant) }

    it 'provides analytics via REST API' do
      # Create test data
      upload = create(:upload, user: user, tenant: tenant)
      medium = create(:medium, user: user, tenant: tenant, upload: upload)
      log = create(:image_optimization_log, 
                   medium: medium, 
                   upload: upload, 
                   user: user, 
                   tenant: tenant,
                   status: 'success',
                   bytes_saved: 100000)
      
      get '/api/v1/image_optimization/analytics', 
          headers: { 'Authorization' => "Bearer #{api_key.token}" }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      expect(json).to include('total_images_optimized', 'total_bytes_saved', 'total_size_saved_mb')
      expect(json).to include('average_size_reduction', 'average_processing_time')
      expect(json).to include('compression_level_stats', 'optimization_type_stats')
    end

    it 'provides detailed report via REST API' do
      get '/api/v1/image_optimization/report', 
          headers: { 'Authorization' => "Bearer #{api_key.token}" }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      expect(json).to include('total_optimizations', 'successful_optimizations', 'failed_optimizations')
      expect(json).to include('total_bytes_saved', 'total_size_saved_mb', 'average_size_reduction')
    end

    it 'handles bulk optimization via REST API' do
      post '/api/v1/image_optimization/bulk_optimize', 
           headers: { 'Authorization' => "Bearer #{api_key.token}" }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      expect(json).to include('success', 'message', 'jobs_queued')
    end
  end

  describe 'GraphQL Integration' do
    it 'provides optimization data via GraphQL' do
      # Create test data
      upload = create(:upload, user: user, tenant: tenant)
      medium = create(:medium, user: user, tenant: tenant, upload: upload)
      log = create(:image_optimization_log, 
                   medium: medium, 
                   upload: upload, 
                   user: user, 
                   tenant: tenant,
                   status: 'success',
                   bytes_saved: 100000)
      
      query = <<~GRAPHQL
        query {
          imageOptimization {
            stats {
              totalImagesOptimized
              totalBytesSaved
              totalSizeSavedMb
              averageSizeReduction
            }
          }
        }
      GRAPHQL
      
      post '/graphql', params: { query: query }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      expect(json['data']['imageOptimization']['stats']).to include(
        'totalImagesOptimized', 'totalBytesSaved', 'totalSizeSavedMb', 'averageSizeReduction'
      )
    end

    it 'handles mutations via GraphQL' do
      mutation = <<~GRAPHQL
        mutation {
          bulkOptimizeImages {
            success
            message
            jobsQueued
          }
        }
      GRAPHQL
      
      post '/graphql', params: { query: mutation }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      expect(json['data']['bulkOptimizeImages']).to include('success', 'message', 'jobsQueued')
    end
  end

  describe 'Liquid Template Integration' do
    it 'renders optimized images in templates' do
      upload = create(:upload, user: user, tenant: tenant)
      medium = create(:medium, user: user, tenant: tenant, upload: upload)
      
      # Mock file URLs
      allow(upload).to receive(:url).and_return('/uploads/test.jpg')
      allow(upload).to receive(:webp_url).and_return('/uploads/test.webp')
      allow(upload).to receive(:avif_url).and_return('/uploads/test.avif')
      
      template = Liquid::Template.parse('{% image_optimized medium: medium, alt: "Test" %}')
      result = template.render('medium' => medium)
      
      expect(result).to include('<picture>')
      expect(result).to include('<source')
      expect(result).to include('<img')
      expect(result).to include('alt="Test"')
    end

    it 'renders optimization statistics in templates' do
      # Create test data
      upload = create(:upload, user: user, tenant: tenant)
      medium = create(:medium, user: user, tenant: tenant, upload: upload)
      log = create(:image_optimization_log, 
                   medium: medium, 
                   upload: upload, 
                   user: user, 
                   tenant: tenant,
                   status: 'success',
                   bytes_saved: 100000)
      
      template = Liquid::Template.parse('{% optimization_stats %}')
      result = template.render
      
      expect(result).to include('Total Images Optimized')
      expect(result).to include('Total Bytes Saved')
    end
  end

  describe 'Performance and Scalability' do
    it 'handles multiple concurrent optimizations' do
      uploads = create_list(:upload, 5, user: user, tenant: tenant)
      mediums = uploads.map { |upload| create(:medium, user: user, tenant: tenant, upload: upload) }
      
      # Mock file attachments
      uploads.each do |upload|
        file_double = double('file')
        allow(upload).to receive(:file).and_return(file_double)
        allow(file_double).to receive(:attached?).and_return(true)
        allow(file_double).to receive(:download).and_return('fake_image_data')
      end
      
      # Mock job queuing
      expect(OptimizeImageJob).to receive(:perform_later).exactly(5).times
      
      # Trigger optimizations
      mediums.each { |medium| medium.send(:trigger_media_uploaded_hook) }
    end

    it 'handles large batch optimization' do
      # Create many uploads
      uploads = create_list(:upload, 100, user: user, tenant: tenant)
      mediums = uploads.map { |upload| create(:medium, user: user, tenant: tenant, upload: upload) }
      
      # Mock file attachments
      uploads.each do |upload|
        file_double = double('file')
        allow(upload).to receive(:file).and_return(file_double)
        allow(file_double).to receive(:attached?).and_return(true)
        allow(file_double).to receive(:download).and_return('fake_image_data')
      end
      
      # Mock job queuing (should be limited to 100)
      expect(OptimizeImageJob).to receive(:perform_later).exactly(100).times
      
      # Simulate bulk optimization
      BulkOptimizationJob.perform_now
    end
  end

  describe 'Error Recovery and Resilience' do
    it 'recovers from temporary processing failures' do
      upload = create(:upload, user: user, tenant: tenant)
      medium = create(:medium, user: user, tenant: tenant, upload: upload)
      
      # Mock file attachment
      file_double = double('file')
      allow(upload).to receive(:file).and_return(file_double)
      allow(file_double).to receive(:attached?).and_return(true)
      allow(file_double).to receive(:download).and_return('fake_image_data')
      
      # Mock temporary failure then success
      call_count = 0
      allow(ImageProcessing::Vips).to receive(:source) do
        call_count += 1
        if call_count == 1
          raise StandardError.new('Temporary failure')
        else
          double(resize_to_limit: double(saver: double(call: double(path: '/tmp/processed.jpg'))))
        end
      end
      
      # Mock log creation
      log_double = double('log', id: 1, update!: true)
      allow(ImageOptimizationLog).to receive(:create!).and_return(log_double)
      
      # First attempt should fail
      service = ImageOptimizationService.new(medium)
      expect(service.optimize!).to be false
      
      # Second attempt should succeed
      expect(service.optimize!).to be true
    end

    it 'handles database connection issues gracefully' do
      upload = create(:upload, user: user, tenant: tenant)
      medium = create(:medium, user: user, tenant: tenant, upload: upload)
      
      # Mock database error
      allow(ImageOptimizationLog).to receive(:create!).and_raise(ActiveRecord::ConnectionNotEstablished.new('DB Error'))
      
      # Mock file attachment
      file_double = double('file')
      allow(upload).to receive(:file).and_return(file_double)
      allow(file_double).to receive(:attached?).and_return(true)
      allow(file_double).to receive(:download).and_return('fake_image_data')
      
      # Mock successful processing
      allow(ImageProcessing::Vips).to receive(:source).and_return(double(
        resize_to_limit: double(saver: double(call: double(path: '/tmp/processed.jpg')))
      ))
      allow(File).to receive(:read).and_return('processed_data')
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:unlink)
      
      # Service should handle the error gracefully
      service = ImageOptimizationService.new(medium)
      expect(service.optimize!).to be false
    end
  end
end
