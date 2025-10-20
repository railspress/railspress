require 'rails_helper'

RSpec.describe Api::V1::GdprController, type: :request do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:admin_user) { create(:user, :administrator, tenant: tenant) }
  let(:other_user) { create(:user, tenant: tenant) }
  
  let(:valid_headers) do
    {
      'Authorization' => "Bearer #{user.api_token}",
      'Content-Type' => 'application/json'
    }
  end
  
  let(:admin_headers) do
    {
      'Authorization' => "Bearer #{admin_user.api_token}",
      'Content-Type' => 'application/json'
    }
  end
  
  describe 'GET /api/v1/gdpr/data-export/:user_id' do
    context 'when user requests their own data export' do
      it 'creates an export request successfully' do
        get "/api/v1/gdpr/data-export/#{user.id}", headers: valid_headers
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be true
        expect(json_response['message']).to include('Personal data export request created')
        expect(json_response['data']['request_id']).to be_present
        expect(json_response['data']['token']).to be_present
        expect(json_response['data']['status']).to eq('pending')
        expect(json_response['data']['download_url']).to be_present
      end
    end
    
    context 'when admin requests data export for another user' do
      it 'creates an export request successfully' do
        get "/api/v1/gdpr/data-export/#{other_user.id}", headers: admin_headers
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be true
        expect(json_response['data']['request_id']).to be_present
      end
    end
    
    context 'when user tries to access another user\'s data' do
      it 'returns access denied' do
        get "/api/v1/gdpr/data-export/#{other_user.id}", headers: valid_headers
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq('Access denied')
      end
    end
    
    context 'when user is not authenticated' do
      it 'returns unauthorized' do
        get "/api/v1/gdpr/data-export/#{user.id}"
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  
  describe 'GET /api/v1/gdpr/data-export/download/:token' do
    let(:export_request) { create(:personal_data_export_request, user: user, status: 'completed') }
    
    before do
      # Create a mock file
      FileUtils.mkdir_p(File.dirname(export_request.file_path))
      File.write(export_request.file_path, '{"test": "data"}')
    end
    
    after do
      File.delete(export_request.file_path) if File.exist?(export_request.file_path)
    end
    
    context 'when export is completed' do
      it 'downloads the export file' do
        get "/api/v1/gdpr/data-export/download/#{export_request.token}", headers: valid_headers
        
        expect(response).to have_http_status(:ok)
        expect(response.headers['Content-Type']).to eq('application/json')
        expect(response.headers['Content-Disposition']).to include('attachment')
      end
    end
    
    context 'when export is not ready' do
      let(:pending_request) { create(:personal_data_export_request, user: user, status: 'pending') }
      
      it 'returns not ready message' do
        get "/api/v1/gdpr/data-export/download/#{pending_request.token}", headers: valid_headers
        
        expect(response).to have_http_status(:accepted)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq('Export is not ready yet')
      end
    end
    
    context 'when token is invalid' do
      it 'returns not found' do
        get '/api/v1/gdpr/data-export/download/invalid_token', headers: valid_headers
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq('Export request not found')
      end
    end
  end
  
  describe 'POST /api/v1/gdpr/data-erasure/:user_id' do
    context 'when user requests their own data erasure' do
      it 'creates an erasure request successfully' do
        post "/api/v1/gdpr/data-erasure/#{user.id}", 
             params: { reason: 'User requested data deletion' }.to_json,
             headers: valid_headers
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be true
        expect(json_response['message']).to include('Data erasure request created')
        expect(json_response['data']['request_id']).to be_present
        expect(json_response['data']['status']).to eq('pending_confirmation')
        expect(json_response['data']['confirmation_url']).to be_present
      end
    end
    
    context 'when admin requests data erasure for another user' do
      it 'creates an erasure request successfully' do
        post "/api/v1/gdpr/data-erasure/#{other_user.id}", 
             params: { reason: 'Admin requested data deletion' }.to_json,
             headers: admin_headers
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be true
        expect(json_response['data']['request_id']).to be_present
      end
    end
    
    context 'when trying to erase admin user data' do
      it 'prevents erasure of admin accounts' do
        post "/api/v1/gdpr/data-erasure/#{admin_user.id}", 
             params: { reason: 'Attempted admin deletion' }.to_json,
             headers: admin_headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be false
        expect(json_response['message']).to include('administrator accounts')
      end
    end
  end
  
  describe 'POST /api/v1/gdpr/data-erasure/confirm/:token' do
    let(:erasure_request) { create(:personal_data_erasure_request, user: user, status: 'pending_confirmation') }
    
    context 'when confirming a valid erasure request' do
      it 'confirms the erasure request' do
        post "/api/v1/gdpr/data-erasure/confirm/#{erasure_request.token}", headers: admin_headers
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be true
        expect(json_response['message']).to include('confirmed and queued')
        expect(json_response['data']['status']).to eq('processing')
        expect(json_response['data']['confirmed_at']).to be_present
      end
    end
    
    context 'when token is invalid' do
      it 'returns not found' do
        post '/api/v1/gdpr/data-erasure/confirm/invalid_token', headers: admin_headers
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq('Erasure request not found')
      end
    end
  end
  
  describe 'GET /api/v1/gdpr/data-portability/:user_id' do
    before do
      create(:post, user: user)
      create(:comment, email: user.email)
    end
    
    context 'when user requests their own data portability' do
      it 'returns comprehensive data portability information' do
        get "/api/v1/gdpr/data-portability/#{user.id}", headers: valid_headers
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be true
        expect(json_response['data']['user_profile']).to be_present
        expect(json_response['data']['posts']).to be_an(Array)
        expect(json_response['data']['comments']).to be_an(Array)
        expect(json_response['data']['metadata']).to be_present
      end
    end
  end
  
  describe 'GET /api/v1/gdpr/requests' do
    before do
      create(:personal_data_export_request, user: user)
      create(:personal_data_erasure_request, user: user)
    end
    
    context 'when user requests their own GDPR requests' do
      it 'returns user\'s GDPR requests' do
        get '/api/v1/gdpr/requests', headers: valid_headers
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be true
        expect(json_response['data']['export_requests']).to be_an(Array)
        expect(json_response['data']['erasure_requests']).to be_an(Array)
      end
    end
    
    context 'when admin requests GDPR requests' do
      it 'returns all GDPR requests' do
        get '/api/v1/gdpr/requests', headers: admin_headers
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be true
        expect(json_response['data']['export_requests']).to be_an(Array)
        expect(json_response['data']['erasure_requests']).to be_an(Array)
      end
    end
  end
  
  describe 'GET /api/v1/gdpr/status/:user_id' do
    before do
      create(:user_consent, user: user, consent_type: 'data_processing', granted: true)
    end
    
    context 'when user requests their own GDPR status' do
      it 'returns GDPR compliance status' do
        get "/api/v1/gdpr/status/#{user.id}", headers: valid_headers
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be true
        expect(json_response['data']['compliance_status']).to be_present
        expect(json_response['data']['data_retention']).to be_present
        expect(json_response['data']['data_categories']).to be_present
        expect(json_response['data']['legal_basis']).to be_present
      end
    end
  end
  
  describe 'POST /api/v1/gdpr/consent/:user_id' do
    context 'when recording user consent' do
      it 'records consent successfully' do
        consent_data = {
          consent_type: 'marketing',
          granted: true,
          consent_text: 'I agree to receive marketing emails',
          ip_address: '127.0.0.1',
          user_agent: 'Test Browser'
        }
        
        post "/api/v1/gdpr/consent/#{user.id}", 
             params: consent_data.to_json,
             headers: valid_headers
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be true
        expect(json_response['message']).to include('Consent recorded successfully')
        expect(json_response['data']['consent_type']).to eq('marketing')
        expect(json_response['data']['granted']).to be true
      end
    end
  end
  
  describe 'DELETE /api/v1/gdpr/consent/:user_id' do
    before do
      create(:user_consent, user: user, consent_type: 'marketing', granted: true)
    end
    
    context 'when withdrawing user consent' do
      it 'withdraws consent successfully' do
        delete "/api/v1/gdpr/consent/#{user.id}?consent_type=marketing", headers: valid_headers
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be true
        expect(json_response['message']).to include('Consent withdrawn successfully')
      end
    end
  end
  
  describe 'GET /api/v1/gdpr/audit-log' do
    context 'when admin requests audit log' do
      it 'returns audit log' do
        get '/api/v1/gdpr/audit-log', headers: admin_headers
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be true
        expect(json_response['data']).to be_an(Array)
      end
    end
    
    context 'when non-admin requests audit log' do
      it 'returns access denied' do
        get '/api/v1/gdpr/audit-log', headers: valid_headers
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq('Access denied')
      end
    end
  end
  
  describe 'edge cases and error handling' do
    context 'when user does not exist' do
      it 'returns not found for data export' do
        get '/api/v1/gdpr/data-export/999999', headers: valid_headers
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq('User not found')
      end
      
      it 'returns not found for data erasure' do
        post '/api/v1/gdpr/data-erasure/999999', 
             params: { reason: 'Test' }.to_json,
             headers: valid_headers
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq('User not found')
      end
    end
    
    context 'when API token is invalid' do
      let(:invalid_headers) do
        {
          'Authorization' => 'Bearer invalid_token',
          'Content-Type' => 'application/json'
        }
      end
      
      it 'returns unauthorized' do
        get "/api/v1/gdpr/data-export/#{user.id}", headers: invalid_headers
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
    
    context 'when request format is invalid' do
      it 'handles malformed JSON gracefully' do
        post "/api/v1/gdpr/data-erasure/#{user.id}", 
             params: 'invalid json',
             headers: valid_headers
        
        expect(response).to have_http_status(:bad_request)
      end
    end
    
    context 'when database errors occur' do
      before do
        allow(PersonalDataExportRequest).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
      end
      
      it 'handles database errors gracefully' do
        get "/api/v1/gdpr/data-export/#{user.id}", headers: valid_headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be false
        expect(json_response['message']).to include('Failed to create export request')
      end
    end
  end
  
  describe 'rate limiting and security' do
    context 'when making multiple requests' do
      it 'handles concurrent requests appropriately' do
        # Create multiple requests simultaneously
        threads = []
        results = []
        
        5.times do
          threads << Thread.new do
            get "/api/v1/gdpr/data-export/#{user.id}", headers: valid_headers
            results << response.status
          end
        end
        
        threads.each(&:join)
        
        # Should handle multiple requests without crashing
        expect(results.all? { |status| [201, 422].include?(status) }).to be true
      end
    end
    
    context 'when accessing sensitive endpoints' do
      it 'validates user permissions for audit log' do
        get '/api/v1/gdpr/audit-log', headers: valid_headers
        
        expect(response).to have_http_status(:forbidden)
      end
      
      it 'prevents cross-user data access' do
        other_user = create(:user, tenant: user.tenant)
        
        get "/api/v1/gdpr/data-export/#{other_user.id}", headers: valid_headers
        
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
  
  describe 'data validation and sanitization' do
    context 'when providing consent data' do
      it 'validates consent data format' do
        invalid_consent_data = {
          consent_type: 'invalid_type',
          consent_data: { granted: 'invalid_boolean' }
        }
        
        post "/api/v1/gdpr/consent/#{user.id}",
             params: invalid_consent_data.to_json,
             headers: valid_headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be false
      end
      
      it 'sanitizes user input in erasure reasons' do
        malicious_reason = '<script>alert("xss")</script>'
        
        post "/api/v1/gdpr/data-erasure/#{user.id}", 
             params: { reason: malicious_reason }.to_json,
             headers: valid_headers
        
        expect(response).to have_http_status(:created)
        
        erasure_request = PersonalDataErasureRequest.last
        expect(erasure_request.reason).not_to include('<script>')
      end
    end
  end
  
  describe 'performance and scalability' do
    context 'when handling large datasets' do
      before do
        # Create large dataset
        create_list(:post, 50, user: user)
        create_list(:comment, 100, email: user.email)
      end
      
      it 'handles large data exports efficiently' do
        start_time = Time.current
        
        get "/api/v1/gdpr/data-export/#{user.id}", headers: valid_headers
        
        end_time = Time.current
        
        # Should complete within reasonable time
        expect(end_time - start_time).to be < 5.seconds
        expect(response).to have_http_status(:created)
      end
      
      it 'handles large data portability requests efficiently' do
        start_time = Time.current
        
        get "/api/v1/gdpr/data-portability/#{user.id}", headers: valid_headers
        
        end_time = Time.current
        
        # Should complete within reasonable time
        expect(end_time - start_time).to be < 3.seconds
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['data']['posts'].length).to eq(50)
        expect(json_response['data']['comments'].length).to eq(100)
      end
    end
  end
  
  describe 'compliance and audit requirements' do
    context 'when tracking GDPR actions' do
      it 'logs all GDPR actions for audit purposes' do
        expect(Rails.logger).to receive(:info).with(/GDPR Action: export_requested/)
        
        get "/api/v1/gdpr/data-export/#{user.id}", headers: valid_headers
      end
      
      it 'maintains data retention compliance' do
        # Create old export request
        old_request = create(:personal_data_export_request, 
                           user: user, 
                           status: 'completed',
                           completed_at: 8.days.ago)
        
        # Should be included in pending expiry scope
        expect(PersonalDataExportRequest.pending_expiry).to include(old_request)
      end
    end
    
    context 'when handling data subject rights' do
      it 'provides complete data portability information' do
        get "/api/v1/gdpr/data-portability/#{user.id}", headers: valid_headers
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        # Should include all required data categories
        expect(json_response['data']).to include(
          'user_profile',
          'posts',
          'comments',
          'media',
          'subscribers',
          'api_tokens',
          'meta_fields',
          'analytics_data',
          'consent_records',
          'gdpr_requests',
          'metadata'
        )
      end
      
      it 'respects user consent preferences' do
        # Create consent record
        create(:user_consent, user: user, consent_type: 'marketing', granted: false)
        
        get "/api/v1/gdpr/status/#{user.id}", headers: valid_headers
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['data']['compliance_status']['marketing_consent']).to eq('withdrawn')
      end
    end
  end
end
