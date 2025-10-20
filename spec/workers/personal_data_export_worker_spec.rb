require 'rails_helper'

RSpec.describe PersonalDataExportWorker, type: :worker do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:request) { create(:personal_data_export_request, user: user, status: 'pending') }
  
  before do
    # Create test data for export
    create(:post, user: user, title: 'Test Post', content: 'Test content')
    create(:comment, email: user.email, content: 'Test comment')
    create(:user_consent, user: user, consent_type: 'data_processing', granted: true)
  end
  
  describe '#perform' do
    it 'processes export request successfully' do
      expect(request.status).to eq('pending')
      
      PersonalDataExportWorker.new.perform(request.id)
      
      request.reload
      expect(request.status).to eq('completed')
      expect(request.completed_at).to be_present
      expect(request.file_path).to be_present
    end
    
    it 'updates status to processing during execution' do
      allow(PersonalDataExportRequest).to receive(:find).with(request.id).and_return(request)
      allow(request).to receive(:update).and_call_original
      
      worker = PersonalDataExportWorker.new
      worker.perform(request.id)
      
      expect(request).to have_received(:update).with(status: 'processing')
    end
    
    it 'creates export file with correct content' do
      PersonalDataExportWorker.new.perform(request.id)
      
      expect(File.exist?(request.reload.file_path)).to be true
      
      file_content = JSON.parse(File.read(request.file_path))
      
      expect(file_content).to include(
        'request_info' => hash_including(
          'requested_at' => request.created_at.iso8601,
          'email' => user.email,
          'export_date' => kind_of(String)
        ),
        'user_profile' => hash_including(
          'id' => user.id,
          'email' => user.email,
          'name' => user.name,
          'role' => user.role
        ),
        'posts' => array_including(
          hash_including(
            'title' => 'Test Post',
            'content' => 'Test content'
          )
        ),
        'comments' => array_including(
          hash_including(
            'content' => 'Test comment'
          )
        ),
        'metadata' => hash_including(
          'total_posts' => 1,
          'total_comments' => 1,
          'export_date' => kind_of(String)
        )
      )
    end
    
    it 'includes all required data categories' do
      PersonalDataExportWorker.new.perform(request.id)
      
      file_content = JSON.parse(File.read(request.reload.file_path))
      
      expect(file_content.keys).to include(
        'request_info',
        'user_profile',
        'posts',
        'comments',
        'subscribers',
        'pageviews',
        'metadata'
      )
    end
    
    it 'handles user with no posts' do
      user_without_posts = create(:user, tenant: tenant)
      request_no_posts = create(:personal_data_export_request, user: user_without_posts, status: 'pending')
      
      PersonalDataExportWorker.new.perform(request_no_posts.id)
      
      file_content = JSON.parse(File.read(request_no_posts.reload.file_path))
      
      expect(file_content['posts']).to eq([])
      expect(file_content['metadata']['total_posts']).to eq(0)
    end
    
    it 'handles user with no comments' do
      user_without_comments = create(:user, tenant: tenant)
      create(:post, user: user_without_comments)
      request_no_comments = create(:personal_data_export_request, user: user_without_comments, status: 'pending')
      
      PersonalDataExportWorker.new.perform(request_no_comments.id)
      
      file_content = JSON.parse(File.read(request_no_comments.reload.file_path))
      
      expect(file_content['comments']).to eq([])
      expect(file_content['metadata']['total_comments']).to eq(0)
    end
    
    it 'handles missing file gracefully' do
      # Simulate file deletion after creation
      allow(File).to receive(:write).and_call_original
      allow(File).to receive(:exist?).and_return(false)
      
      PersonalDataExportWorker.new.perform(request.id)
      
      request.reload
      expect(request.status).to eq('completed')
      expect(request.file_path).to be_present
    end
  end
  
  describe 'error handling' do
    it 'handles missing request gracefully' do
      expect {
        PersonalDataExportWorker.new.perform(999999)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it 'updates status to failed on error' do
      allow(PersonalDataExportRequest).to receive(:find).with(request.id).and_raise(StandardError, 'Test error')
      allow(request).to receive(:update)
      
      expect {
        PersonalDataExportWorker.new.perform(request.id)
      }.to raise_error(StandardError, 'Test error')
      
      expect(request).to have_received(:update).with(status: 'failed')
    end
    
    it 'logs errors appropriately' do
      allow(PersonalDataExportRequest).to receive(:find).with(request.id).and_raise(StandardError, 'Test error')
      allow(Rails.logger).to receive(:error)
      
      expect {
        PersonalDataExportWorker.new.perform(request.id)
      }.to raise_error(StandardError, 'Test error')
      
      expect(Rails.logger).to have_received(:error).with(/Personal data export #{request.id} failed: Test error/)
    end
  end
  
  describe 'file handling' do
    it 'creates file in tmp directory' do
      PersonalDataExportWorker.new.perform(request.id)
      
      file_path = request.reload.file_path
      expect(file_path).to start_with(Rails.root.join('tmp').to_s)
      expect(file_path).to include("personal_data_#{request.id}")
      expect(file_path).to end_with('.json')
    end
    
    it 'creates valid JSON file' do
      PersonalDataExportWorker.new.perform(request.id)
      
      file_path = request.reload.file_path
      file_content = File.read(file_path)
      
      expect { JSON.parse(file_content) }.not_to raise_error
    end
    
    it 'creates pretty-formatted JSON' do
      PersonalDataExportWorker.new.perform(request.id)
      
      file_path = request.reload.file_path
      file_content = File.read(file_path)
      
      # Pretty JSON should have newlines
      expect(file_content).to include("\n")
      
      # Should be valid JSON
      parsed = JSON.parse(file_content)
      expect(parsed).to be_a(Hash)
    end
  end
  
  describe 'data completeness' do
    it 'exports all user posts' do
      create_list(:post, 3, user: user)
      
      PersonalDataExportWorker.new.perform(request.id)
      
      file_content = JSON.parse(File.read(request.reload.file_path))
      
      expect(file_content['posts'].length).to eq(4) # 1 from before + 3 new
      expect(file_content['metadata']['total_posts']).to eq(4)
    end
    
    it 'exports all user comments by email' do
      create_list(:comment, 2, email: user.email)
      create(:comment, email: 'other@example.com') # Should not be included
      
      PersonalDataExportWorker.new.perform(request.id)
      
      file_content = JSON.parse(File.read(request.reload.file_path))
      
      expect(file_content['comments'].length).to eq(3) # 1 from before + 2 new
      expect(file_content['metadata']['total_comments']).to eq(3)
    end
    
    it 'includes pageview data' do
      # Create some pageviews for the user
      create(:pageview, user_id: user.id, path: '/test-page')
      create(:pageview, user_id: user.id, path: '/another-page')
      
      PersonalDataExportWorker.new.perform(request.id)
      
      file_content = JSON.parse(File.read(request.reload.file_path))
      
      expect(file_content['pageviews']).to include(
        '/test-page' => 1,
        '/another-page' => 1
      )
      expect(file_content['metadata']['total_pageviews']).to eq(2)
    end
  end
  
  describe 'performance' do
    it 'handles large datasets efficiently' do
      # Create a large number of posts
      create_list(:post, 100, user: user)
      
      start_time = Time.current
      PersonalDataExportWorker.new.perform(request.id)
      end_time = Time.current
      
      # Should complete within reasonable time (adjust threshold as needed)
      expect(end_time - start_time).to be < 10.seconds
      
      request.reload
      expect(request.status).to eq('completed')
      
      file_content = JSON.parse(File.read(request.file_path))
      expect(file_content['posts'].length).to eq(100)
    end
  end
  
  describe 'sidekiq configuration' do
    it 'has correct sidekiq options' do
      expect(PersonalDataExportWorker.sidekiq_options).to include(
        'retry' => 2,
        'queue' => 'default'
      )
    end
  end
end
