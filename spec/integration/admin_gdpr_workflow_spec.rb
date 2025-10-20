require 'rails_helper'

RSpec.describe 'Admin GDPR Workflow Integration', type: :request do
  let(:admin_user) { create(:user, :administrator) }
  let(:tenant) { create(:tenant) }
  
  before do
    ActsAsTenant.current_tenant = tenant
    sign_in admin_user
  end
  
  describe 'Complete GDPR Admin Workflow' do
    let(:user) { create(:user) }
    
    before do
      # Create some test data for the user
      create_list(:post, 3, user: user)
      create_list(:comment, 2, email: user.email)
      create(:user_consent, user: user, consent_type: 'data_processing', status: 'granted')
    end
    
    it 'completes full admin workflow from dashboard to data management' do
      # 1. Access GDPR dashboard
      get admin_gdpr_index_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('GDPR Compliance Dashboard')
      
      # 2. Navigate to user management
      get admin_gdpr_users_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('User Data Management')
      expect(response.body).to include(user.email)
      
      # 3. View individual user data
      get admin_gdpr_user_data_path(user)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(user.email)
      expect(response.body).to include('3') # Posts count
      expect(response.body).to include('2') # Comments count
      
      # 4. Create export request
      expect {
        post admin_gdpr_export_user_data_path(user)
      }.to change(PersonalDataExportRequest, :count).by(1)
      
      export_request = PersonalDataExportRequest.last
      expect(export_request.user).to eq(user)
      expect(export_request.status).to eq('pending')
      
      # 5. Simulate export completion
      export_request.update!(status: 'completed', file_path: Rails.root.join('tmp', 'test_export.json'))
      File.write(export_request.file_path, '{"test": "data"}')
      
      # 6. Download export
      get admin_gdpr_download_export_path(export_request)
      expect(response).to have_http_status(:success)
      expect(response.headers['Content-Type']).to include('application/json')
      
      # 7. Create erasure request
      expect {
        post admin_gdpr_erase_user_data_path(user), params: { reason: 'User requested deletion' }
      }.to change(PersonalDataErasureRequest, :count).by(1)
      
      erasure_request = PersonalDataErasureRequest.last
      expect(erasure_request.user).to eq(user)
      expect(erasure_request.status).to eq('pending_confirmation')
      
      # 8. Confirm erasure
      post admin_gdpr_confirm_erasure_path(erasure_request)
      erasure_request.reload
      expect(erasure_request.status).to eq('pending')
      
      # 9. View compliance report
      get admin_gdpr_compliance_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('GDPR Compliance Report')
      
      # Cleanup
      File.delete(export_request.file_path) if File.exist?(export_request.file_path)
    end
    
    it 'handles bulk operations workflow' do
      # Create multiple users
      users = create_list(:user, 5)
      
      # Navigate to users page
      get admin_gdpr_users_path
      expect(response).to have_http_status(:success)
      
      # Perform bulk export
      user_ids = users.map(&:id)
      post admin_gdpr_bulk_export_path, params: { user_ids: user_ids }
      
      expect(response).to redirect_to(admin_gdpr_users_path)
      expect(flash[:notice]).to include('Bulk export initiated for 5 users')
      
      # Verify export requests were created
      expect(PersonalDataExportRequest.where(user: users).count).to eq(5)
    end
    
    it 'handles search and filtering workflow' do
      # Create users with different emails
      user1 = create(:user, email: 'john@example.com')
      user2 = create(:user, email: 'jane@example.com')
      user3 = create(:user, email: 'bob@example.com')
      
      # Search for specific user
      get admin_gdpr_users_path, params: { search: 'john' }
      expect(response).to have_http_status(:success)
      expect(response.body).to include('john@example.com')
      expect(response.body).not_to include('jane@example.com')
      expect(response.body).not_to include('bob@example.com')
      
      # Filter by users with export requests
      create(:personal_data_export_request, user: user1)
      get admin_gdpr_users_path, params: { filter: 'with_exports' }
      expect(response).to have_http_status(:success)
      expect(response.body).to include('john@example.com')
    end
  end
  
  describe 'Error Handling Workflow' do
    it 'handles non-existent user gracefully throughout workflow' do
      # Try to access non-existent user
      get admin_gdpr_user_data_path(999999)
      expect(response).to redirect_to(admin_gdpr_users_path)
      expect(flash[:alert]).to include('User not found')
      
      # Try to export non-existent user
      post admin_gdpr_export_user_data_path(999999)
      expect(response).to redirect_to(admin_gdpr_users_path)
      expect(flash[:alert]).to include('User not found')
    end
    
    it 'handles export errors gracefully' do
      user = create(:user)
      
      # Mock service failure
      allow(GdprService).to receive(:create_export_request).and_raise(StandardError.new('Export failed'))
      
      post admin_gdpr_export_user_data_path(user)
      expect(response).to redirect_to(admin_gdpr_user_data_path(user))
      expect(flash[:alert]).to include('Failed to create export request')
    end
    
    it 'handles erasure errors gracefully' do
      user = create(:user)
      
      # Mock service failure
      allow(GdprService).to receive(:create_erasure_request).and_raise(StandardError.new('Erasure failed'))
      
      post admin_gdpr_erase_user_data_path(user), params: { reason: 'Test' }
      expect(response).to redirect_to(admin_gdpr_user_data_path(user))
      expect(flash[:alert]).to include('Failed to create erasure request')
    end
  end
  
  describe 'Security Workflow' do
    let(:regular_user) { create(:user) }
    
    it 'prevents non-admin access to GDPR functions' do
      sign_out admin_user
      sign_in regular_user
      
      # Try to access GDPR dashboard
      get admin_gdpr_index_path
      expect(response).to have_http_status(:redirect)
      
      # Try to access user management
      get admin_gdpr_users_path
      expect(response).to have_http_status(:redirect)
      
      # Try to export user data
      user = create(:user)
      post admin_gdpr_export_user_data_path(user)
      expect(response).to have_http_status(:redirect)
    end
    
    it 'prevents erasure of admin users' do
      admin_to_protect = create(:user, :administrator)
      
      post admin_gdpr_erase_user_data_path(admin_to_protect), params: { reason: 'Test' }
      expect(response).to redirect_to(admin_gdpr_user_data_path(admin_to_protect))
      expect(flash[:alert]).to include('Cannot erase administrator data')
    end
  end
  
  describe 'Performance Workflow' do
    it 'handles large datasets efficiently' do
      # Create large dataset
      users = create_list(:user, 100)
      users.each do |user|
        create_list(:post, 5, user: user)
        create_list(:comment, 3, email: user.email)
      end
      
      # Test dashboard performance
      start_time = Time.current
      get admin_gdpr_index_path
      end_time = Time.current
      expect(end_time - start_time).to be < 2.seconds
      
      # Test user management performance
      start_time = Time.current
      get admin_gdpr_users_path
      end_time = Time.current
      expect(end_time - start_time).to be < 2.seconds
      
      # Test individual user data performance
      start_time = Time.current
      get admin_gdpr_user_data_path(users.first)
      end_time = Time.current
      expect(end_time - start_time).to be < 2.seconds
    end
    
    it 'handles bulk operations efficiently' do
      users = create_list(:user, 50)
      user_ids = users.map(&:id)
      
      start_time = Time.current
      post admin_gdpr_bulk_export_path, params: { user_ids: user_ids }
      end_time = Time.current
      
      expect(response).to have_http_status(:redirect)
      expect(end_time - start_time).to be < 5.seconds
    end
  end
  
  describe 'Data Integrity Workflow' do
    it 'maintains data integrity during export process' do
      user = create(:user)
      original_post_count = user.posts.count
      original_comment_count = Comment.where(email: user.email).count
      
      # Create export request
      post admin_gdpr_export_user_data_path(user)
      export_request = PersonalDataExportRequest.last
      
      # Verify original data is unchanged
      user.reload
      expect(user.posts.count).to eq(original_post_count)
      expect(Comment.where(email: user.email).count).to eq(original_comment_count)
      
      # Simulate export completion
      export_request.update!(status: 'completed')
      
      # Verify data is still unchanged
      user.reload
      expect(user.posts.count).to eq(original_post_count)
      expect(Comment.where(email: user.email).count).to eq(original_comment_count)
    end
    
    it 'maintains audit trail throughout workflow' do
      user = create(:user)
      
      # Create export request
      post admin_gdpr_export_user_data_path(user)
      export_request = PersonalDataExportRequest.last
      
      # Verify audit trail
      expect(export_request.requested_by_user).to eq(admin_user)
      expect(export_request.email).to eq(user.email)
      
      # Create erasure request
      post admin_gdpr_erase_user_data_path(user), params: { reason: 'Test erasure' }
      erasure_request = PersonalDataErasureRequest.last
      
      # Verify audit trail
      expect(erasure_request.requested_by_user).to eq(admin_user)
      expect(erasure_request.email).to eq(user.email)
      expect(erasure_request.reason).to eq('Test erasure')
    end
  end
  
  describe 'UI/UX Workflow' do
    it 'provides consistent navigation experience' do
      user = create(:user)
      
      # Test navigation flow
      get admin_gdpr_index_path
      expect(response.body).to include('Back to Dashboard')
      
      get admin_gdpr_users_path
      expect(response.body).to include('Back to Users')
      
      get admin_gdpr_user_data_path(user)
      expect(response.body).to include('Back to Users')
      expect(response.body).to include('Consent History')
    end
    
    it 'provides appropriate feedback messages' do
      user = create(:user)
      
      # Test success messages
      post admin_gdpr_export_user_data_path(user)
      expect(flash[:notice]).to include('Data export request created successfully')
      
      post admin_gdpr_erase_user_data_path(user), params: { reason: 'Test' }
      expect(flash[:notice]).to include('Data erasure request created')
      
      # Test error messages
      allow(GdprService).to receive(:create_export_request).and_raise(StandardError.new('Export failed'))
      post admin_gdpr_export_user_data_path(user)
      expect(flash[:alert]).to include('Failed to create export request')
    end
  end
end
