require 'rails_helper'

RSpec.describe Admin::GdprController, type: :request do
  let(:admin_user) { create(:user, :administrator) }
  let(:regular_user) { create(:user) }
  let(:tenant) { create(:tenant) }
  
  before do
    ActsAsTenant.current_tenant = tenant
    sign_in admin_user
  end
  
  describe 'GET #index' do
    it 'renders the GDPR dashboard' do
      get admin_gdpr_index_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('GDPR Compliance Dashboard')
      expect(response.body).to include('Total Users')
      expect(response.body).to include('Pending Exports')
    end
    
    it 'shows statistics' do
      create_list(:user, 3)
      get admin_gdpr_index_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('3') # Total users
    end
    
    it 'shows recent requests' do
      export_request = create(:personal_data_export_request, user: regular_user)
      erasure_request = create(:personal_data_erasure_request, user: regular_user)
      
      get admin_gdpr_index_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(regular_user.email)
    end
  end
  
  describe 'GET #users' do
    it 'renders the users management page' do
      get admin_gdpr_users_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('User Data Management')
    end
    
    it 'shows all users' do
      users = create_list(:user, 5)
      get admin_gdpr_users_path
      expect(response).to have_http_status(:success)
      
      users.each do |user|
        expect(response.body).to include(user.email)
      end
    end
    
    it 'filters users by search term' do
      user1 = create(:user, email: 'john@example.com')
      user2 = create(:user, email: 'jane@example.com')
      
      get admin_gdpr_users_path, params: { search: 'john' }
      expect(response).to have_http_status(:success)
      expect(response.body).to include('john@example.com')
      expect(response.body).not_to include('jane@example.com')
    end
    
    it 'filters users by export requests' do
      user_with_export = create(:user)
      user_without_export = create(:user)
      create(:personal_data_export_request, user: user_with_export)
      
      get admin_gdpr_users_path, params: { filter: 'with_exports' }
      expect(response).to have_http_status(:success)
      expect(response.body).to include(user_with_export.email)
    end
  end
  
  describe 'GET #user_data' do
    let(:user) { create(:user) }
    
    it 'renders user data page' do
      get admin_gdpr_user_data_path(user)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(user.email)
      expect(response.body).to include('User Data Management')
    end
    
    it 'shows user statistics' do
      create_list(:post, 3, user: user)
      create_list(:comment, 2, email: user.email)
      
      get admin_gdpr_user_data_path(user)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('3') # Posts count
      expect(response.body).to include('2') # Comments count
    end
    
    it 'shows export requests' do
      export_request = create(:personal_data_export_request, user: user)
      get admin_gdpr_user_data_path(user)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(export_request.status)
    end
    
    it 'shows erasure requests' do
      erasure_request = create(:personal_data_erasure_request, user: user)
      get admin_gdpr_user_data_path(user)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(erasure_request.status)
    end
    
    it 'shows consent records' do
      consent = create(:user_consent, user: user)
      get admin_gdpr_user_data_path(user)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(consent.consent_type)
    end
  end
  
  describe 'POST #export_user_data' do
    let(:user) { create(:user) }
    
    it 'creates an export request' do
      expect {
        post admin_gdpr_export_user_data_path(user)
      }.to change(PersonalDataExportRequest, :count).by(1)
      
      expect(response).to redirect_to(admin_gdpr_user_data_path(user))
      expect(flash[:notice]).to include('Data export request created successfully')
    end
    
    it 'queues the export worker' do
      expect {
        post admin_gdpr_export_user_data_path(user)
      }.to have_enqueued_job(PersonalDataExportWorker)
    end
    
    it 'handles errors gracefully' do
      allow(GdprService).to receive(:create_export_request).and_raise(StandardError.new('Export failed'))
      
      post admin_gdpr_export_user_data_path(user)
      expect(response).to redirect_to(admin_gdpr_user_data_path(user))
      expect(flash[:alert]).to include('Failed to create export request')
    end
  end
  
  describe 'POST #erase_user_data' do
    let(:user) { create(:user) }
    
    it 'creates an erasure request' do
      expect {
        post admin_gdpr_erase_user_data_path(user), params: { reason: 'User requested deletion' }
      }.to change(PersonalDataErasureRequest, :count).by(1)
      
      expect(response).to redirect_to(admin_gdpr_user_data_path(user))
      expect(flash[:notice]).to include('Data erasure request created')
    end
    
    it 'prevents erasure of admin users' do
      admin_user_to_protect = create(:user, :administrator)
      
      post admin_gdpr_erase_user_data_path(admin_user_to_protect), params: { reason: 'Test' }
      expect(response).to redirect_to(admin_gdpr_user_data_path(admin_user_to_protect))
      expect(flash[:alert]).to include('Cannot erase administrator data')
    end
    
    it 'handles errors gracefully' do
      allow(GdprService).to receive(:create_erasure_request).and_raise(StandardError.new('Erasure failed'))
      
      post admin_gdpr_erase_user_data_path(user), params: { reason: 'Test' }
      expect(response).to redirect_to(admin_gdpr_user_data_path(user))
      expect(flash[:alert]).to include('Failed to create erasure request')
    end
  end
  
  describe 'GET #download_export' do
    let(:export_request) { create(:personal_data_export_request, :completed) }
    
    before do
      # Create a dummy export file
      FileUtils.mkdir_p(File.dirname(export_request.file_path))
      File.write(export_request.file_path, '{"test": "data"}')
    end
    
    after do
      File.delete(export_request.file_path) if File.exist?(export_request.file_path)
    end
    
    it 'downloads completed export' do
      get admin_gdpr_download_export_path(export_request)
      expect(response).to have_http_status(:success)
      expect(response.headers['Content-Type']).to include('application/json')
      expect(response.headers['Content-Disposition']).to include('attachment')
    end
    
    it 'redirects if export not ready' do
      export_request.update!(status: 'pending')
      get admin_gdpr_download_export_path(export_request)
      expect(response).to redirect_to(admin_gdpr_user_data_path(export_request.user))
      expect(flash[:alert]).to include('Export is not ready yet')
    end
    
    it 'redirects if file not found' do
      File.delete(export_request.file_path)
      get admin_gdpr_download_export_path(export_request)
      expect(response).to redirect_to(admin_gdpr_user_data_path(export_request.user))
      expect(flash[:alert]).to include('Export file not found')
    end
  end
  
  describe 'POST #confirm_erasure' do
    let(:erasure_request) { create(:personal_data_erasure_request, status: 'pending_confirmation') }
    
    it 'confirms erasure request' do
      post admin_gdpr_confirm_erasure_path(erasure_request)
      expect(response).to redirect_to(admin_gdpr_user_data_path(erasure_request.user))
      expect(flash[:notice]).to include('Data erasure confirmed')
    end
    
    it 'queues the erasure worker' do
      expect {
        post admin_gdpr_confirm_erasure_path(erasure_request)
      }.to have_enqueued_job(PersonalDataErasureWorker)
    end
    
    it 'handles errors gracefully' do
      allow(GdprService).to receive(:confirm_erasure_request).and_raise(StandardError.new('Confirmation failed'))
      
      post admin_gdpr_confirm_erasure_path(erasure_request)
      expect(response).to redirect_to(admin_gdpr_user_data_path(erasure_request.user))
      expect(flash[:alert]).to include('Failed to confirm erasure')
    end
  end
  
  describe 'GET #compliance' do
    it 'renders compliance report' do
      get admin_gdpr_compliance_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('GDPR Compliance Report')
      expect(response.body).to include('Article 7')
      expect(response.body).to include('Article 17')
      expect(response.body).to include('Article 20')
      expect(response.body).to include('Article 25')
    end
    
    it 'shows compliance statistics' do
      create_list(:user, 5)
      create_list(:user_consent, 3)
      
      get admin_gdpr_compliance_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('5') # Total users
      expect(response.body).to include('3') # Users with consent
    end
  end
  
  describe 'POST #bulk_export' do
    let(:users) { create_list(:user, 3) }
    
    it 'creates bulk export requests' do
      user_ids = users.map(&:id)
      post admin_gdpr_bulk_export_path, params: { user_ids: user_ids }
      
      expect(response).to redirect_to(admin_gdpr_users_path)
      expect(flash[:notice]).to include('Bulk export initiated for 3 users')
    end
    
    it 'handles empty selection' do
      post admin_gdpr_bulk_export_path
      expect(response).to redirect_to(admin_gdpr_users_path)
      expect(flash[:alert]).to include('Please select users to export')
    end
    
    it 'handles partial failures' do
      allow(GdprService).to receive(:create_export_request).and_raise(StandardError.new('Export failed'))
      
      user_ids = users.map(&:id)
      post admin_gdpr_bulk_export_path, params: { user_ids: user_ids }
      
      expect(response).to redirect_to(admin_gdpr_users_path)
      expect(flash[:notice]).to include('Bulk export initiated')
    end
  end
  
  describe 'Authorization' do
    context 'when user is not admin' do
      before { sign_in regular_user }
      
      it 'denies access to GDPR dashboard' do
        get admin_gdpr_index_path
        expect(response).to have_http_status(:redirect)
      end
      
      it 'denies access to user management' do
        get admin_gdpr_users_path
        expect(response).to have_http_status(:redirect)
      end
      
      it 'denies access to user data' do
        user = create(:user)
        get admin_gdpr_user_data_path(user)
        expect(response).to have_http_status(:redirect)
      end
    end
    
    context 'when user is not signed in' do
      before { sign_out admin_user }
      
      it 'redirects to login' do
        get admin_gdpr_index_path
        expect(response).to have_http_status(:redirect)
      end
    end
  end
  
  describe 'Error Handling' do
    let(:user) { create(:user) }
    
    it 'handles non-existent user gracefully' do
      get admin_gdpr_user_data_path(999999)
      expect(response).to redirect_to(admin_gdpr_users_path)
      expect(flash[:alert]).to include('User not found')
    end
    
    it 'handles non-existent export request gracefully' do
      get admin_gdpr_download_export_path(999999)
      expect(response).to redirect_to(admin_gdpr_requests_path)
      expect(flash[:alert]).to include('Export request not found')
    end
    
    it 'handles non-existent erasure request gracefully' do
      post admin_gdpr_confirm_erasure_path(999999)
      expect(response).to redirect_to(admin_gdpr_requests_path)
      expect(flash[:alert]).to include('Erasure request not found')
    end
  end
  
  describe 'Performance' do
    it 'handles large user lists efficiently' do
      create_list(:user, 100)
      
      start_time = Time.current
      get admin_gdpr_users_path
      end_time = Time.current
      
      expect(response).to have_http_status(:success)
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
end
