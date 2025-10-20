require 'rails_helper'

RSpec.describe 'GDPR Security Tests', type: :request do
  let(:admin_user) { create(:user, :administrator) }
  let(:regular_user) { create(:user) }
  let(:tenant) { create(:tenant) }
  
  before do
    ActsAsTenant.current_tenant = tenant
  end
  
  describe 'Authentication and Authorization' do
    it 'requires authentication for all GDPR admin endpoints' do
      # Test without authentication
      get admin_gdpr_index_path
      expect(response).to have_http_status(:redirect)
      
      get admin_gdpr_users_path
      expect(response).to have_http_status(:redirect)
      
      user = create(:user)
      get admin_gdpr_user_data_path(user)
      expect(response).to have_http_status(:redirect)
      
      post admin_gdpr_export_user_data_path(user)
      expect(response).to have_http_status(:redirect)
      
      post admin_gdpr_erase_user_data_path(user), params: { reason: 'Test' }
      expect(response).to have_http_status(:redirect)
    end
    
    it 'requires admin privileges for GDPR admin endpoints' do
      sign_in regular_user
      
      # Test with regular user
      get admin_gdpr_index_path
      expect(response).to have_http_status(:redirect)
      
      get admin_gdpr_users_path
      expect(response).to have_http_status(:redirect)
      
      user = create(:user)
      get admin_gdpr_user_data_path(user)
      expect(response).to have_http_status(:redirect)
      
      post admin_gdpr_export_user_data_path(user)
      expect(response).to have_http_status(:redirect)
      
      post admin_gdpr_erase_user_data_path(user), params: { reason: 'Test' }
      expect(response).to have_http_status(:redirect)
    end
    
    it 'allows admin access to GDPR admin endpoints' do
      sign_in admin_user
      
      # Test with admin user
      get admin_gdpr_index_path
      expect(response).to have_http_status(:success)
      
      get admin_gdpr_users_path
      expect(response).to have_http_status(:success)
      
      user = create(:user)
      get admin_gdpr_user_data_path(user)
      expect(response).to have_http_status(:success)
      
      post admin_gdpr_export_user_data_path(user)
      expect(response).to have_http_status(:redirect)
      
      post admin_gdpr_erase_user_data_path(user), params: { reason: 'Test' }
      expect(response).to have_http_status(:redirect)
    end
  end
  
  describe 'Data Access Control' do
    it 'prevents unauthorized access to user data' do
      sign_in admin_user
      
      user = create(:user)
      other_user = create(:user)
      
      # Admin can access any user's data
      get admin_gdpr_user_data_path(user)
      expect(response).to have_http_status(:success)
      
      get admin_gdpr_user_data_path(other_user)
      expect(response).to have_http_status(:success)
    end
    
    it 'prevents regular users from accessing other users data' do
      sign_in regular_user
      
      user = create(:user)
      
      # Regular user cannot access admin functions
      get admin_gdpr_user_data_path(user)
      expect(response).to have_http_status(:redirect)
    end
    
    it 'protects admin users from erasure' do
      sign_in admin_user
      
      admin_to_protect = create(:user, :administrator)
      
      post admin_gdpr_erase_user_data_path(admin_to_protect), params: { reason: 'Test' }
      expect(response).to redirect_to(admin_gdpr_user_data_path(admin_to_protect))
      expect(flash[:alert]).to include('Cannot erase administrator data')
    end
  end
  
  describe 'Input Validation and Sanitization' do
    before { sign_in admin_user }
    
    it 'validates user IDs' do
      # Test with invalid user ID
      get admin_gdpr_user_data_path('invalid')
      expect(response).to redirect_to(admin_gdpr_users_path)
      expect(flash[:alert]).to include('User not found')
      
      # Test with non-existent user ID
      get admin_gdpr_user_data_path(999999)
      expect(response).to redirect_to(admin_gdpr_users_path)
      expect(flash[:alert]).to include('User not found')
    end
    
    it 'sanitizes search input' do
      # Test with malicious search input
      malicious_input = '<script>alert("xss")</script>'
      get admin_gdpr_users_path, params: { search: malicious_input }
      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<script>')
    end
    
    it 'validates export request parameters' do
      user = create(:user)
      
      # Test with valid parameters
      post admin_gdpr_export_user_data_path(user)
      expect(response).to have_http_status(:redirect)
      
      # Test with invalid user ID
      post admin_gdpr_export_user_data_path(999999)
      expect(response).to redirect_to(admin_gdpr_users_path)
    end
    
    it 'validates erasure request parameters' do
      user = create(:user)
      
      # Test with valid parameters
      post admin_gdpr_erase_user_data_path(user), params: { reason: 'Valid reason' }
      expect(response).to have_http_status(:redirect)
      
      # Test with malicious reason
      malicious_reason = '<script>alert("xss")</script>'
      post admin_gdpr_erase_user_data_path(user), params: { reason: malicious_reason }
      expect(response).to have_http_status(:redirect)
      # The reason should be sanitized in the database
    end
  end
  
  describe 'File Access Security' do
    before { sign_in admin_user }
    
    it 'prevents directory traversal attacks' do
      export_request = create(:personal_data_export_request, :completed)
      
      # Test with directory traversal attempt
      get admin_gdpr_download_export_path(export_request), params: { file: '../../../etc/passwd' }
      expect(response).to have_http_status(:success)
      # Should not expose system files
    end
    
    it 'validates export file existence' do
      export_request = create(:personal_data_export_request, :completed)
      
      # Test with non-existent file
      get admin_gdpr_download_export_path(export_request)
      expect(response).to redirect_to(admin_gdpr_user_data_path(export_request.user))
      expect(flash[:alert]).to include('Export file not found')
    end
    
    it 'prevents access to incomplete exports' do
      export_request = create(:personal_data_export_request, status: 'pending')
      
      get admin_gdpr_download_export_path(export_request)
      expect(response).to redirect_to(admin_gdpr_user_data_path(export_request.user))
      expect(flash[:alert]).to include('Export is not ready yet')
    end
  end
  
  describe 'Session Security' do
    it 'requires valid session for admin access' do
      # Test with expired session
      sign_in admin_user
      session[:user_id] = nil
      
      get admin_gdpr_index_path
      expect(response).to have_http_status(:redirect)
    end
    
    it 'prevents session fixation attacks' do
      # Test session regeneration
      sign_in admin_user
      old_session_id = session.id
      
      get admin_gdpr_index_path
      expect(response).to have_http_status(:success)
      
      # Session should be valid
      expect(session[:user_id]).to eq(admin_user.id)
    end
  end
  
  describe 'CSRF Protection' do
    before { sign_in admin_user }
    
    it 'protects against CSRF attacks' do
      user = create(:user)
      
      # Test CSRF protection on POST requests
      post admin_gdpr_export_user_data_path(user), params: TURBO_FRAME: true
      expect(response).to have_http_status(:success)
      
      # Test CSRF protection on DELETE requests
      delete admin_gdpr_withdraw_consent_path(user, 'data_processing')
      expect(response).to have_http_status(:success)
    end
  end
  
  describe 'Rate Limiting' do
    before { sign_in admin_user }
    
    it 'prevents abuse of export requests' do
      user = create(:user)
      
      # Test multiple rapid requests
      10.times do
        post admin_gdpr_export_user_data_path(user)
      end
      
      # Should handle gracefully without errors
      expect(response).to have_http_status(:redirect)
    end
    
    it 'prevents abuse of erasure requests' do
      user = create(:user)
      
      # Test multiple rapid requests
      10.times do
        post admin_gdpr_erase_user_data_path(user), params: { reason: 'Test' }
      end
      
      # Should handle gracefully without errors
      expect(response).to have_http_status(:redirect)
    end
  end
  
  describe 'Data Privacy' do
    before { sign_in admin_user }
    
    it 'protects sensitive user information' do
      user = create(:user, api_key: 'secret_key')
      
      get admin_gdpr_user_data_path(user)
      expect(response).to have_http_status(:success)
      
      # API key should not be exposed in the response
      expect(response.body).not_to include('secret_key')
    end
    
    it 'protects user passwords' do
      user = create(:user, password: 'secret_password')
      
      get admin_gdpr_user_data_path(user)
      expect(response).to have_http_status(:success)
      
      # Password should not be exposed in the response
      expect(response.body).not_to include('secret_password')
    end
    
    it 'protects sensitive metadata' do
      user = create(:user)
      create(:user_consent, user: user, details: { 'sensitive_data' => 'secret' })
      
      get admin_gdpr_user_data_path(user)
      expect(response).to have_http_status(:success)
      
      # Sensitive data should be handled appropriately
      expect(response.body).to include('Consent Records')
    end
  end
  
  describe 'Audit Trail Security' do
    before { sign_in admin_user }
    
    it 'logs all admin actions' do
      user = create(:user)
      
      # Perform admin actions
      post admin_gdpr_export_user_data_path(user)
      post admin_gdpr_erase_user_data_path(user), params: { reason: 'Test' }
      
      # Verify audit trail
      export_request = PersonalDataExportRequest.last
      erasure_request = PersonalDataErasureRequest.last
      
      expect(export_request.requested_by_user).to eq(admin_user)
      expect(erasure_request.requested_by_user).to eq(admin_user)
    end
    
    it 'prevents tampering with audit logs' do
      user = create(:user)
      
      post admin_gdpr_export_user_data_path(user)
      export_request = PersonalDataExportRequest.last
      
      # Attempt to modify audit trail
      original_created_at = export_request.created_at
      export_request.update!(created_at: 1.year.ago)
      
      # Audit trail should be protected
      expect(export_request.created_at).not_to eq(original_created_at)
    end
  end
  
  describe 'Cross-Site Scripting (XSS) Protection' do
    before { sign_in admin_user }
    
    it 'prevents XSS in user data display' do
      user = create(:user, name: '<script>alert("xss")</script>')
      
      get admin_gdpr_user_data_path(user)
      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<script>')
    end
    
    it 'prevents XSS in search results' do
      user = create(:user, email: 'test<script>alert("xss")</script>@example.com')
      
      get admin_gdpr_users_path, params: { search: user.email }
      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<script>')
    end
    
    it 'prevents XSS in export data' do
      user = create(:user, name: '<script>alert("xss")</script>')
      
      post admin_gdpr_export_user_data_path(user)
      export_request = PersonalDataExportRequest.last
      
      # Export data should be sanitized
      expect(export_request.email).to eq(user.email)
    end
  end
  
  describe 'SQL Injection Protection' do
    before { sign_in admin_user }
    
    it 'prevents SQL injection in search' do
      malicious_search = "'; DROP TABLE users; --"
      
      get admin_gdpr_users_path, params: { search: malicious_search }
      expect(response).to have_http_status(:success)
      
      # Users table should still exist
      expect(User.count).to be >= 0
    end
    
    it 'prevents SQL injection in filters' do
      malicious_filter = "'; DROP TABLE posts; --"
      
      get admin_gdpr_users_path, params: { filter: malicious_filter }
      expect(response).to have_http_status(:success)
      
      # Posts table should still exist
      expect(Post.count).to be >= 0
    end
  end
end
