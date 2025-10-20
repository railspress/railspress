require 'rails_helper'

RSpec.describe 'GDPR Performance Tests', type: :request do
  let(:admin_user) { create(:user, :administrator) }
  let(:tenant) { create(:tenant) }
  
  before do
    ActsAsTenant.current_tenant = tenant
    sign_in admin_user
  end
  
  describe 'Admin Interface Performance' do
    it 'handles large user datasets efficiently' do
      # Create large dataset
      users = create_list(:user, 500)
      users.each do |user|
        create_list(:post, 3, user: user)
        create_list(:comment, 2, email: user.email)
        create(:user_consent, user: user)
      end
      
      # Test dashboard performance
      start_time = Time.current
      get admin_gdpr_index_path
      end_time = Time.current
      
      expect(response).to have_http_status(:success)
      expect(end_time - start_time).to be < 3.seconds
      expect(response.body).to include('500') # Total users
    end
    
    it 'handles user management with large datasets' do
      # Create large dataset
      users = create_list(:user, 1000)
      
      # Test user list performance
      start_time = Time.current
      get admin_gdpr_users_path
      end_time = Time.current
      
      expect(response).to have_http_status(:success)
      expect(end_time - start_time).to be < 5.seconds
    end
    
    it 'handles search performance with large datasets' do
      # Create large dataset
      users = create_list(:user, 1000)
      target_user = create(:user, email: 'target@example.com')
      
      # Test search performance
      start_time = Time.current
      get admin_gdpr_users_path, params: { search: 'target' }
      end_time = Time.current
      
      expect(response).to have_http_status(:success)
      expect(end_time - start_time).to be < 2.seconds
      expect(response.body).to include('target@example.com')
    end
    
    it 'handles individual user data efficiently' do
      user = create(:user)
      
      # Create large amount of data for user
      create_list(:post, 100, user: user)
      create_list(:comment, 200, email: user.email)
      create_list(:user_consent, 10, user: user)
      
      # Test individual user data performance
      start_time = Time.current
      get admin_gdpr_user_data_path(user)
      end_time = Time.current
      
      expect(response).to have_http_status(:success)
      expect(end_time - start_time).to be < 2.seconds
      expect(response.body).to include('100') # Posts count
      expect(response.body).to include('200') # Comments count
    end
  end
  
  describe 'Bulk Operations Performance' do
    it 'handles large bulk export operations efficiently' do
      users = create_list(:user, 100)
      user_ids = users.map(&:id)
      
      start_time = Time.current
      post admin_gdpr_bulk_export_path, params: { user_ids: user_ids }
      end_time = Time.current
      
      expect(response).to have_http_status(:redirect)
      expect(end_time - start_time).to be < 10.seconds
      expect(PersonalDataExportRequest.count).to eq(100)
    end
    
    it 'handles bulk operations with concurrent requests' do
      users = create_list(:user, 50)
      user_ids = users.map(&:id)
      
      # Simulate concurrent bulk operations
      threads = []
      start_time = Time.current
      
      5.times do
        threads << Thread.new do
          post admin_gdpr_bulk_export_path, params: { user_ids: user_ids }
        end
      end
      
      threads.each(&:join)
      end_time = Time.current
      
      expect(end_time - start_time).to be < 15.seconds
    end
  end
  
  describe 'Export Processing Performance' do
    it 'handles large data exports efficiently' do
      user = create(:user)
      
      # Create large amount of data
      create_list(:post, 1000, user: user)
      create_list(:comment, 2000, email: user.email)
      create_list(:user_consent, 50, user: user)
      
      # Test export request creation
      start_time = Time.current
      post admin_gdpr_export_user_data_path(user)
      end_time = Time.current
      
      expect(response).to have_http_status(:redirect)
      expect(end_time - start_time).to be < 2.seconds
      
      # Test export processing (simulate worker execution)
      export_request = PersonalDataExportRequest.last
      start_time = Time.current
      PersonalDataExportWorker.new.perform(export_request.id)
      end_time = Time.current
      
      expect(end_time - start_time).to be < 30.seconds
      export_request.reload
      expect(export_request.status).to eq('completed')
    end
    
    it 'handles multiple concurrent export requests' do
      users = create_list(:user, 10)
      
      # Create concurrent export requests
      start_time = Time.current
      users.each do |user|
        post admin_gdpr_export_user_data_path(user)
      end
      end_time = Time.current
      
      expect(end_time - start_time).to be < 5.seconds
      expect(PersonalDataExportRequest.count).to eq(10)
    end
  end
  
  describe 'Erasure Processing Performance' do
    it 'handles large data erasures efficiently' do
      user = create(:user)
      
      # Create large amount of data
      create_list(:post, 1000, user: user)
      create_list(:comment, 2000, email: user.email)
      create_list(:user_consent, 50, user: user)
      
      # Test erasure request creation
      start_time = Time.current
      post admin_gdpr_erase_user_data_path(user), params: { reason: 'Performance test' }
      end_time = Time.current
      
      expect(response).to have_http_status(:redirect)
      expect(end_time - start_time).to be < 2.seconds
      
      # Test erasure processing (simulate worker execution)
      erasure_request = PersonalDataErasureRequest.last
      start_time = Time.current
      PersonalDataErasureWorker.new.perform(erasure_request.id)
      end_time = Time.current
      
      expect(end_time - start_time).to be < 30.seconds
      erasure_request.reload
      expect(erasure_request.status).to eq('completed')
    end
    
    it 'handles multiple concurrent erasure requests' do
      users = create_list(:user, 5)
      
      # Create concurrent erasure requests
      start_time = Time.current
      users.each do |user|
        post admin_gdpr_erase_user_data_path(user), params: { reason: 'Performance test' }
      end
      end_time = Time.current
      
      expect(end_time - start_time).to be < 5.seconds
      expect(PersonalDataErasureRequest.count).to eq(5)
    end
  end
  
  describe 'Memory Usage Performance' do
    it 'handles large datasets without memory issues' do
      # Create large dataset
      users = create_list(:user, 1000)
      users.each do |user|
        create_list(:post, 5, user: user)
        create_list(:comment, 3, email: user.email)
      end
      
      # Monitor memory usage
      initial_memory = `ps -o rss= -p #{Process.pid}`.to_i
      
      # Perform operations
      get admin_gdpr_index_path
      get admin_gdpr_users_path
      
      final_memory = `ps -o rss= -p #{Process.pid}`.to_i
      memory_increase = final_memory - initial_memory
      
      # Memory increase should be reasonable (less than 100MB)
      expect(memory_increase).to be < 100000
    end
    
    it 'handles bulk operations without memory leaks' do
      users = create_list(:user, 100)
      user_ids = users.map(&:id)
      
      # Monitor memory usage
      initial_memory = `ps -o rss= -p #{Process.pid}`.to_i
      
      # Perform bulk operations
      post admin_gdpr_bulk_export_path, params: { user_ids: user_ids }
      
      final_memory = `ps -o rss= -p #{Process.pid}`.to_i
      memory_increase = final_memory - initial_memory
      
      # Memory increase should be reasonable
      expect(memory_increase).to be < 50000
    end
  end
  
  describe 'Database Performance' do
    it 'uses efficient database queries' do
      # Create test data
      users = create_list(:user, 100)
      users.each do |user|
        create_list(:post, 3, user: user)
        create(:user_consent, user: user)
      end
      
      # Monitor database queries
      query_count = 0
      ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
        query_count += 1
      end
      
      # Perform operation
      get admin_gdpr_users_path
      
      # Query count should be reasonable (less than 20 queries)
      expect(query_count).to be < 20
    end
    
    it 'uses efficient pagination' do
      # Create large dataset
      users = create_list(:user, 1000)
      
      # Test pagination performance
      start_time = Time.current
      get admin_gdpr_users_path, params: { page: 2 }
      end_time = Time.current
      
      expect(response).to have_http_status(:success)
      expect(end_time - start_time).to be < 2.seconds
    end
  end
  
  describe 'Concurrent User Performance' do
    it 'handles multiple admin users simultaneously' do
      admin_users = create_list(:user, 5, :administrator)
      test_users = create_list(:user, 50)
      
      # Simulate concurrent admin operations
      threads = []
      start_time = Time.current
      
      admin_users.each do |admin|
        threads << Thread.new do
          # Sign in as admin
          sign_in admin
          
          # Perform operations
          get admin_gdpr_index_path
          get admin_gdpr_users_path
          
          # Create some export requests
          test_users.first(10).each do |user|
            post admin_gdpr_export_user_data_path(user)
          end
        end
      end
      
      threads.each(&:join)
      end_time = Time.current
      
      expect(end_time - start_time).to be < 20.seconds
      expect(PersonalDataExportRequest.count).to eq(50)
    end
  end
  
  describe 'Stress Testing' do
    it 'handles stress conditions gracefully' do
      # Create stress conditions
      users = create_list(:user, 1000)
      users.each do |user|
        create_list(:post, 10, user: user)
        create_list(:comment, 15, email: user.email)
        create_list(:user_consent, 3, user: user)
      end
      
      # Perform stress operations
      start_time = Time.current
      
      # Multiple concurrent operations
      threads = []
      10.times do
        threads << Thread.new do
          get admin_gdpr_index_path
          get admin_gdpr_users_path
          get admin_gdpr_compliance_path
        end
      end
      
      threads.each(&:join)
      end_time = Time.current
      
      expect(end_time - start_time).to be < 30.seconds
    end
    
    it 'maintains performance under load' do
      # Create load conditions
      users = create_list(:user, 500)
      
      # Perform load operations
      start_time = Time.current
      
      100.times do
        get admin_gdpr_users_path
        get admin_gdpr_index_path
      end
      
      end_time = Time.current
      average_time = (end_time - start_time) / 200
      
      # Average response time should be reasonable
      expect(average_time).to be < 1.second
    end
  end
end
