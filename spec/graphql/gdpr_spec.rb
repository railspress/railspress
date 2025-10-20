require 'rails_helper'

RSpec.describe 'GDPR GraphQL API', type: :request do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:admin_user) { create(:user, :administrator, tenant: tenant) }
  let(:other_user) { create(:user, tenant: tenant) }
  
  before do
    # Create test data
    create(:post, user: user)
    create(:comment, email: user.email)
    create(:user_consent, user: user, consent_type: 'data_processing', granted: true)
  end
  
  describe 'queries' do
    describe 'gdprStatus' do
      let(:query) do
        <<~GQL
          query GetGdprStatus($userId: ID!) {
            gdprStatus(userId: $userId) {
              userId
              email
              complianceStatus {
                dataProcessingConsent
                marketingConsent
                analyticsConsent
                cookieConsent
              }
              dataRetention {
                accountCreated
                lastActivity
                dataAgeDays
              }
              pendingRequests {
                exportRequests
                erasureRequests
              }
              dataCategories {
                profileData
                contentData
                communicationData
                analyticsData
                mediaData
                subscriptionData
              }
              legalBasis {
                consent
                withholdConsent
                legitimateInterest
              }
              exportRequests {
                id
                email
                status
                requestedAt
                completedAt
                downloadUrl
              }
              erasureRequests {
                id
                email
                status
                reason
                requestedAt
                confirmedAt
                completedAt
              }
              consentRecords {
                id
                consentType
                granted
                consentText
                grantedAt
                withdrawnAt
              }
            }
          }
        GQL
      end
      
      context 'when user requests their own status' do
        it 'returns GDPR status successfully' do
          post '/graphql', params: { 
            query: query, 
            variables: { userId: user.id.to_s },
            context: { current_user: user }
          }
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['data']['gdprStatus']).to be_present
          expect(json_response['data']['gdprStatus']['userId']).to eq(user.id.to_s)
          expect(json_response['data']['gdprStatus']['email']).to eq(user.email)
          expect(json_response['data']['gdprStatus']['complianceStatus']).to be_present
          expect(json_response['data']['gdprStatus']['dataRetention']).to be_present
          expect(json_response['data']['gdprStatus']['pendingRequests']).to be_present
          expect(json_response['data']['gdprStatus']['dataCategories']).to be_present
          expect(json_response['data']['gdprStatus']['legalBasis']).to be_present
        end
      end
      
      context 'when admin requests status for another user' do
        it 'returns GDPR status successfully' do
          post '/graphql', params: { 
            query: query, 
            variables: { userId: user.id.to_s },
            context: { current_user: admin_user }
          }
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['data']['gdprStatus']).to be_present
        end
      end
      
      context 'when user tries to access another user\'s status' do
        it 'returns access denied error' do
          post '/graphql', params: { 
            query: query, 
            variables: { userId: other_user.id.to_s },
            context: { current_user: user }
          }
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['errors']).to be_present
          expect(json_response['errors'].first['message']).to include('Access denied')
        end
      end
    end
    
    describe 'gdprDataPortability' do
      let(:query) do
        <<~GQL
          query GetDataPortability($userId: ID!) {
            gdprDataPortability(userId: $userId) {
              userProfile
              posts
              pages
              comments
              media
              subscribers
              apiTokens
              metaFields
              analyticsData
              consentRecords
              gdprRequests
              metadata
            }
          }
        GQL
      end
      
      context 'when user requests their own data portability' do
        it 'returns comprehensive data portability information' do
          post '/graphql', params: { 
            query: query, 
            variables: { userId: user.id.to_s },
            context: { current_user: user }
          }
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['data']['gdprDataPortability']).to be_present
          expect(json_response['data']['gdprDataPortability']['userProfile']).to be_present
          expect(json_response['data']['gdprDataPortability']['posts']).to be_an(Array)
          expect(json_response['data']['gdprDataPortability']['comments']).to be_an(Array)
          expect(json_response['data']['gdprDataPortability']['consentRecords']).to be_an(Array)
          expect(json_response['data']['gdprDataPortability']['metadata']).to be_present
        end
      end
    end
    
    describe 'gdprAuditLog' do
      let(:query) do
        <<~GQL
          query GetAuditLog($page: Int, $perPage: Int) {
            gdprAuditLog(page: $page, perPage: $perPage) {
              id
              action
              userEmail
              timestamp
              details
            }
          }
        GQL
      end
      
      before do
        create(:personal_data_export_request, user: user)
        create(:personal_data_erasure_request, user: user)
      end
      
      context 'when admin requests audit log' do
        it 'returns audit log entries' do
          post '/graphql', params: { 
            query: query, 
            variables: { page: 1, perPage: 50 },
            context: { current_user: admin_user }
          }
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['data']['gdprAuditLog']).to be_an(Array)
          expect(json_response['data']['gdprAuditLog']).not_to be_empty
          
          audit_entry = json_response['data']['gdprAuditLog'].first
          expect(audit_entry).to include('id', 'action', 'userEmail', 'timestamp')
        end
      end
      
      context 'when non-admin requests audit log' do
        it 'returns access denied error' do
          post '/graphql', params: { 
            query: query, 
            variables: { page: 1, perPage: 50 },
            context: { current_user: user }
          }
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['errors']).to be_present
          expect(json_response['errors'].first['message']).to include('Access denied')
        end
      end
    end
  end
  
  describe 'mutations' do
    describe 'requestDataExport' do
      let(:mutation) do
        <<~GQL
          mutation RequestDataExport($userId: ID!) {
            requestDataExport(userId: $userId) {
              success
              message
              exportRequest {
                id
                email
                status
                token
                requestedAt
                downloadUrl
              }
              errors
            }
          }
        GQL
      end
      
      context 'when user requests their own data export' do
        it 'creates export request successfully' do
          expect {
            post '/graphql', params: { 
              query: mutation, 
              variables: { userId: user.id.to_s },
              context: { current_user: user }
            }
          }.to change(PersonalDataExportRequest, :count).by(1)
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['data']['requestDataExport']['success']).to be true
          expect(json_response['data']['requestDataExport']['message']).to include('successfully')
          expect(json_response['data']['requestDataExport']['exportRequest']).to be_present
          expect(json_response['data']['requestDataExport']['exportRequest']['status']).to eq('pending')
        end
      end
      
      context 'when admin requests export for another user' do
        it 'creates export request successfully' do
          expect {
            post '/graphql', params: { 
              query: mutation, 
              variables: { userId: user.id.to_s },
              context: { current_user: admin_user }
            }
          }.to change(PersonalDataExportRequest, :count).by(1)
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['data']['requestDataExport']['success']).to be true
        end
      end
      
      context 'when user tries to access another user\'s data' do
        it 'returns access denied error' do
          post '/graphql', params: { 
            query: mutation, 
            variables: { userId: other_user.id.to_s },
            context: { current_user: user }
          }
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['data']['requestDataExport']['success']).to be false
          expect(json_response['data']['requestDataExport']['message']).to include('Access denied')
        end
      end
    end
    
    describe 'requestDataErasure' do
      let(:mutation) do
        <<~GQL
          mutation RequestDataErasure($userId: ID!, $reason: String) {
            requestDataErasure(userId: $userId, reason: $reason) {
              success
              message
              erasureRequest {
                id
                email
                status
                reason
                requestedAt
                confirmationUrl
                metadata
              }
              errors
            }
          }
        GQL
      end
      
      context 'when user requests their own data erasure' do
        it 'creates erasure request successfully' do
          expect {
            post '/graphql', params: { 
              query: mutation, 
              variables: { userId: user.id.to_s, reason: 'User requested deletion' },
              context: { current_user: user }
            }
          }.to change(PersonalDataErasureRequest, :count).by(1)
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['data']['requestDataErasure']['success']).to be true
          expect(json_response['data']['requestDataErasure']['message']).to include('successfully')
          expect(json_response['data']['requestDataErasure']['erasureRequest']).to be_present
          expect(json_response['data']['requestDataErasure']['erasureRequest']['status']).to eq('pending_confirmation')
        end
      end
      
      context 'when trying to erase admin user data' do
        it 'prevents erasure of admin accounts' do
          post '/graphql', params: { 
            query: mutation, 
            variables: { userId: admin_user.id.to_s, reason: 'Test' },
            context: { current_user: admin_user }
          }
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['data']['requestDataErasure']['success']).to be false
          expect(json_response['data']['requestDataErasure']['message']).to include('administrator')
        end
      end
    end
    
    describe 'confirmDataErasure' do
      let(:erasure_request) { create(:personal_data_erasure_request, user: user, status: 'pending_confirmation') }
      let(:mutation) do
        <<~GQL
          mutation ConfirmDataErasure($token: String!) {
            confirmDataErasure(token: $token) {
              success
              message
              erasureRequest {
                id
                status
                confirmedAt
              }
              errors
            }
          }
        GQL
      end
      
      context 'when confirming a valid erasure request' do
        it 'confirms the erasure request' do
          post '/graphql', params: { 
            query: mutation, 
            variables: { token: erasure_request.token },
            context: { current_user: admin_user }
          }
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['data']['confirmDataErasure']['success']).to be true
          expect(json_response['data']['confirmDataErasure']['message']).to include('confirmed')
          expect(json_response['data']['confirmDataErasure']['erasureRequest']['status']).to eq('processing')
        end
      end
      
      context 'when token is invalid' do
        it 'returns not found error' do
          post '/graphql', params: { 
            query: mutation, 
            variables: { token: 'invalid_token' },
            context: { current_user: admin_user }
          }
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['data']['confirmDataErasure']['success']).to be false
          expect(json_response['data']['confirmDataErasure']['message']).to include('not found')
        end
      end
    end
    
    describe 'recordConsent' do
      let(:mutation) do
        <<~GQL
          mutation RecordConsent($userId: ID!, $consentType: String!, $consentData: JSON!) {
            recordConsent(userId: $userId, consentType: $consentType, consentData: $consentData) {
              success
              message
              consentRecord {
                id
                consentType
                granted
                consentText
                grantedAt
              }
              errors
            }
          }
        GQL
      end
      
      context 'when recording user consent' do
        it 'records consent successfully' do
          consent_data = {
            granted: true,
            consent_text: 'I agree to marketing',
            ip_address: '127.0.0.1',
            user_agent: 'Test Browser'
          }
          
          expect {
            post '/graphql', params: { 
              query: mutation, 
              variables: { 
                userId: user.id.to_s, 
                consentType: 'marketing',
                consentData: consent_data
              },
              context: { current_user: user }
            }
          }.to change(UserConsent, :count).by(1)
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['data']['recordConsent']['success']).to be true
          expect(json_response['data']['recordConsent']['message']).to include('successfully')
          expect(json_response['data']['recordConsent']['consentRecord']['consentType']).to eq('marketing')
          expect(json_response['data']['recordConsent']['consentRecord']['granted']).to be true
        end
      end
    end
    
    describe 'withdrawConsent' do
      let!(:consent) { create(:user_consent, user: user, consent_type: 'marketing', granted: true) }
      let(:mutation) do
        <<~GQL
          mutation WithdrawConsent($userId: ID!, $consentType: String!) {
            withdrawConsent(userId: $userId, consentType: $consentType) {
              success
              message
              consentRecord {
                id
                consentType
                granted
                withdrawnAt
              }
              errors
            }
          }
        GQL
      end
      
      context 'when withdrawing user consent' do
        it 'withdraws consent successfully' do
          post '/graphql', params: { 
            query: mutation, 
            variables: { userId: user.id.to_s, consentType: 'marketing' },
            context: { current_user: user }
          }
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['data']['withdrawConsent']['success']).to be true
          expect(json_response['data']['withdrawConsent']['message']).to include('successfully')
          expect(json_response['data']['withdrawConsent']['consentRecord']['granted']).to be false
        end
      end
    end
  end
  
  describe 'error handling' do
    it 'handles invalid queries gracefully' do
      post '/graphql', params: { 
        query: 'invalid query',
        context: { current_user: user }
      }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response['errors']).to be_present
    end
    
    it 'handles missing variables gracefully' do
      post '/graphql', params: { 
        query: 'query { gdprStatus(userId: $userId) { userId } }',
        context: { current_user: user }
      }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response['errors']).to be_present
    end
  end
  
  describe 'authentication' do
    it 'requires authentication for GDPR queries' do
      post '/graphql', params: { 
        query: 'query { gdprStatus(userId: "1") { userId } }'
      }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response['errors']).to be_present
    end
    
    it 'requires authentication for GDPR mutations' do
      post '/graphql', params: { 
        query: 'mutation { requestDataExport(userId: "1") { success } }'
      }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response['errors']).to be_present
    end
  end
end
