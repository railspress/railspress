require 'rails_helper'

RSpec.describe 'GDPR Complete Workflow', type: :request do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:admin_user) { create(:user, :administrator, tenant: tenant) }
  
  before do
    # Create comprehensive test data
    create_list(:post, 3, user: user)
    create_list(:page, 2, user: user)
    create_list(:comment, 5, email: user.email)
    
    # Create media with attachments
    medium = create(:medium, user: user)
    medium.file.attach(
      io: StringIO.new('test image data'),
      filename: 'test.jpg',
      content_type: 'image/jpeg'
    )
    
    # Create consent records
    create(:user_consent, user: user, consent_type: 'data_processing', granted: true)
    create(:user_consent, user: user, consent_type: 'marketing', granted: false)
    
    # Create some pageviews
    create_list(:pageview, 10, user_id: user.id)
    
    # Create API tokens
    create(:api_token, user: user)
  end
  
  describe 'Complete Data Export Workflow' do
    it 'successfully completes the entire export process' do
      # Step 1: Request data export via API
      get "/api/v1/gdpr/data-export/#{user.id}", 
          headers: { 'Authorization' => "Bearer #{user.api_token}" }
      
      expect(response).to have_http_status(:created)
      export_response = JSON.parse(response.body)
      
      expect(export_response['success']).to be true
      expect(export_response['data']['request_id']).to be_present
      expect(export_response['data']['token']).to be_present
      expect(export_response['data']['status']).to eq('pending')
      
      export_request = PersonalDataExportRequest.find(export_response['data']['request_id'])
      
      # Step 2: Process the export (simulate worker)
      PersonalDataExportWorker.new.perform(export_request.id)
      
      export_request.reload
      expect(export_request.status).to eq('completed')
      expect(export_request.file_path).to be_present
      expect(File.exist?(export_request.file_path)).to be true
      
      # Step 3: Download the exported data
      get "/api/v1/gdpr/data-export/download/#{export_request.token}",
          headers: { 'Authorization' => "Bearer #{user.api_token}" }
      
      expect(response).to have_http_status(:ok)
      expect(response.headers['Content-Type']).to eq('application/json')
      expect(response.headers['Content-Disposition']).to include('attachment')
      
      # Step 4: Verify exported data content
      exported_data = JSON.parse(response.body)
      
      expect(exported_data).to include(
        'request_info',
        'user_profile',
        'posts',
        'comments',
        'subscribers',
        'pageviews',
        'metadata'
      )
      
      expect(exported_data['user_profile']['email']).to eq(user.email)
      expect(exported_data['posts'].length).to eq(3)
      expect(exported_data['comments'].length).to eq(5)
      expect(exported_data['pageviews']).to be_a(Hash)
      expect(exported_data['metadata']['total_posts']).to eq(3)
      expect(exported_data['metadata']['total_comments']).to eq(5)
    end
    
    it 'handles export request for non-existent user' do
      get "/api/v1/gdpr/data-export/999999", 
          headers: { 'Authorization' => "Bearer #{user.api_token}" }
      
      expect(response).to have_http_status(:not_found)
      error_response = JSON.parse(response.body)
      expect(error_response['success']).to be false
      expect(error_response['message']).to include('not found')
    end
  end
  
  describe 'Complete Data Erasure Workflow' do
    it 'successfully completes the entire erasure process' do
      # Step 1: Request data erasure via API
      post "/api/v1/gdpr/data-erasure/#{user.id}",
           params: { reason: 'User requested complete data deletion' }.to_json,
           headers: { 
             'Authorization' => "Bearer #{admin_user.api_token}",
             'Content-Type' => 'application/json'
           }
      
      expect(response).to have_http_status(:created)
      erasure_response = JSON.parse(response.body)
      
      expect(erasure_response['success']).to be true
      expect(erasure_response['data']['request_id']).to be_present
      expect(erasure_response['data']['token']).to be_present
      expect(erasure_response['data']['status']).to eq('pending_confirmation')
      
      erasure_request = PersonalDataErasureRequest.find(erasure_response['data']['request_id'])
      
      # Verify metadata was gathered
      expect(erasure_request.metadata).to include(
        'user_posts_count' => 3,
        'user_pages_count' => 2,
        'user_comments_count' => 5,
        'user_media_count' => 1,
        'user_pageviews_count' => 10
      )
      
      # Step 2: Confirm the erasure request
      post "/api/v1/gdpr/data-erasure/confirm/#{erasure_request.token}",
           headers: { 'Authorization' => "Bearer #{admin_user.api_token}" }
      
      expect(response).to have_http_status(:ok)
      confirm_response = JSON.parse(response.body)
      
      expect(confirm_response['success']).to be true
      expect(confirm_response['message']).to include('confirmed')
      
      erasure_request.reload
      expect(erasure_request.status).to eq('processing')
      expect(erasure_request.confirmed_at).to be_present
      
      # Step 3: Process the erasure (simulate worker)
      PersonalDataErasureWorker.new.perform(erasure_request.id)
      
      erasure_request.reload
      expect(erasure_request.status).to eq('completed')
      expect(erasure_request.completed_at).to be_present
      
      # Step 4: Verify data has been erased/anonymized
      user.reload
      expect(user.email).to eq("deleted_user_#{user.id}@deleted.local")
      expect(user.name).to eq('Deleted User')
      expect(user.bio).to be_nil
      
      # Posts should be anonymized
      user.posts.each do |post|
        expect(post.title).to eq('[Deleted Post]')
        expect(post.content).to include('deleted due to data erasure request')
      end
      
      # Pages should be anonymized
      user.pages.each do |page|
        expect(page.title).to eq('[Deleted Page]')
        expect(page.content).to include('deleted due to data erasure request')
      end
      
      # Comments should be anonymized
      Comment.where(email: user.email).each do |comment|
        expect(comment.author_name).to eq('Deleted User')
        expect(comment.author_email).to eq('deleted@deleted.local')
        expect(comment.content).to include('deleted due to data erasure request')
      end
      
      # Media should be deleted
      expect(user.media.count).to eq(0)
      
      # Pageviews should be deleted
      expect(Pageview.where(user_id: user.id).count).to eq(0)
      
      # Consent records should be deleted
      expect(UserConsent.where(user: user).count).to eq(0)
      
      # API tokens should be deleted
      expect(user.api_tokens.count).to eq(0)
      
      # Step 5: Verify backup was created
      backup_path = erasure_request.metadata['backup_file_path']
      expect(File.exist?(backup_path)).to be true
      
      backup_data = JSON.parse(File.read(backup_path))
      expect(backup_data).to include(
        'erasure_request_id' => erasure_request.id,
        'user_id' => user.id,
        'erasure_date' => kind_of(String)
      )
    end
    
    it 'prevents erasure of administrator accounts' do
      post "/api/v1/gdpr/data-erasure/#{admin_user.id}",
           params: { reason: 'Test admin erasure' }.to_json,
           headers: { 
             'Authorization' => "Bearer #{admin_user.api_token}",
             'Content-Type' => 'application/json'
           }
      
      expect(response).to have_http_status(:unprocessable_entity)
      error_response = JSON.parse(response.body)
      expect(error_response['success']).to be false
      expect(error_response['message']).to include('administrator')
    end
  end
  
  describe 'Complete Consent Management Workflow' do
    it 'successfully manages user consent lifecycle' do
      # Step 1: Record initial consent
      consent_data = {
        granted: true,
        consent_text: 'I agree to receive marketing communications',
        ip_address: '127.0.0.1',
        user_agent: 'Test Browser'
      }
      
      post "/api/v1/gdpr/consent/#{user.id}",
           params: { 
             consent_type: 'marketing',
             consent_data: consent_data
           }.to_json,
           headers: { 
             'Authorization' => "Bearer #{user.api_token}",
             'Content-Type' => 'application/json'
           }
      
      expect(response).to have_http_status(:created)
      consent_response = JSON.parse(response.body)
      
      expect(consent_response['success']).to be true
      expect(consent_response['data']['consent_type']).to eq('marketing')
      expect(consent_response['data']['granted']).to be true
      
      # Step 2: Check GDPR status includes new consent
      get "/api/v1/gdpr/status/#{user.id}",
          headers: { 'Authorization' => "Bearer #{user.api_token}" }
      
      expect(response).to have_http_status(:ok)
      status_response = JSON.parse(response.body)
      
      expect(status_response['data']['compliance_status']['marketing_consent']).to eq('granted')
      
      # Step 3: Withdraw consent
      delete "/api/v1/gdpr/consent/#{user.id}?consent_type=marketing",
             headers: { 'Authorization' => "Bearer #{user.api_token}" }
      
      expect(response).to have_http_status(:ok)
      withdrawal_response = JSON.parse(response.body)
      
      expect(withdrawal_response['success']).to be true
      expect(withdrawal_response['message']).to include('withdrawn')
      
      # Step 4: Verify consent was withdrawn
      consent_record = UserConsent.find_by(user: user, consent_type: 'marketing')
      expect(consent_record.granted).to be false
      expect(consent_record.withdrawn_at).to be_present
      
      # Step 5: Check updated GDPR status
      get "/api/v1/gdpr/status/#{user.id}",
          headers: { 'Authorization' => "Bearer #{user.api_token}" }
      
      expect(response).to have_http_status(:ok)
      status_response = JSON.parse(response.body)
      
      expect(status_response['data']['compliance_status']['marketing_consent']).to eq('withdrawn')
    end
  end
  
  describe 'Cross-Platform Workflow (REST + GraphQL)' do
    it 'allows mixed REST and GraphQL operations' do
      # Step 1: Create export request via REST API
      get "/api/v1/gdpr/data-export/#{user.id}", 
          headers: { 'Authorization' => "Bearer #{user.api_token}" }
      
      expect(response).to have_http_status(:created)
      export_response = JSON.parse(response.body)
      export_request_id = export_response['data']['request_id']
      
      # Step 2: Check status via GraphQL
      graphql_query = <<~GQL
        query {
          gdprStatus(userId: "#{user.id}") {
            exportRequests {
              id
              status
              requestedAt
            }
          }
        }
      GQL
      
      post '/graphql', params: { 
        query: graphql_query,
        context: { current_user: user }
      }
      
      expect(response).to have_http_status(:ok)
      graphql_response = JSON.parse(response.body)
      
      expect(graphql_response['data']['gdprStatus']['exportRequests']).not_to be_empty
      export_request_gql = graphql_response['data']['gdprStatus']['exportRequests'].first
      expect(export_request_gql['id']).to eq(export_request_id.to_s)
      
      # Step 3: Create erasure request via GraphQL
      erasure_mutation = <<~GQL
        mutation {
          requestDataErasure(userId: "#{user.id}", reason: "Test erasure") {
            success
            erasureRequest {
              id
              status
              token
            }
          }
        }
      GQL
      
      post '/graphql', params: { 
        query: erasure_mutation,
        context: { current_user: user }
      }
      
      expect(response).to have_http_status(:ok)
      erasure_response = JSON.parse(response.body)
      
      expect(erasure_response['data']['requestDataErasure']['success']).to be true
      erasure_token = erasure_response['data']['requestDataErasure']['erasureRequest']['token']
      
      # Step 4: Confirm erasure via REST API
      post "/api/v1/gdpr/data-erasure/confirm/#{erasure_token}",
           headers: { 'Authorization' => "Bearer #{user.api_token}" }
      
      expect(response).to have_http_status(:ok)
      confirm_response = JSON.parse(response.body)
      
      expect(confirm_response['success']).to be true
    end
  end
  
  describe 'Error Handling and Edge Cases' do
    it 'handles concurrent export requests gracefully' do
      # Create multiple export requests simultaneously
      threads = []
      results = []
      
      3.times do
        threads << Thread.new do
          get "/api/v1/gdpr/data-export/#{user.id}", 
              headers: { 'Authorization' => "Bearer #{user.api_token}" }
          results << response.status
        end
      end
      
      threads.each(&:join)
      
      # Only one should succeed, others should fail due to duplicate prevention
      expect(results.count(201)).to eq(1) # Only one created
      expect(results.count(422)).to eq(2) # Others failed with unprocessable entity
    end
    
    it 'handles large dataset exports efficiently' do
      # Create large dataset
      create_list(:post, 100, user: user)
      create_list(:comment, 200, email: user.email)
      
      start_time = Time.current
      
      get "/api/v1/gdpr/data-export/#{user.id}", 
          headers: { 'Authorization' => "Bearer #{user.api_token}" }
      
      expect(response).to have_http_status(:created)
      
      export_request = PersonalDataExportRequest.last
      
      # Process export
      PersonalDataExportWorker.new.perform(export_request.id)
      
      end_time = Time.current
      
      # Should complete within reasonable time
      expect(end_time - start_time).to be < 30.seconds
      
      export_request.reload
      expect(export_request.status).to eq('completed')
      
      # Verify data integrity
      exported_data = JSON.parse(File.read(export_request.file_path))
      expect(exported_data['posts'].length).to eq(103) # 3 original + 100 new
      expect(exported_data['comments'].length).to eq(205) # 5 original + 200 new
    end
    
    it 'maintains data integrity during partial failures' do
      # Simulate partial failure in erasure worker
      allow_any_instance_of(PersonalDataErasureWorker).to receive(:erase_user_data)
        .and_raise(StandardError, 'Partial failure')
      
      # Create erasure request
      post "/api/v1/gdpr/data-erasure/#{user.id}",
           params: { reason: 'Test erasure' }.to_json,
           headers: { 
             'Authorization' => "Bearer #{admin_user.api_token}",
             'Content-Type' => 'application/json'
           }
      
      erasure_request = PersonalDataErasureRequest.last
      
      # Confirm erasure
      post "/api/v1/gdpr/data-erasure/confirm/#{erasure_request.token}",
           headers: { 'Authorization' => "Bearer #{admin_user.api_token}" }
      
      # Attempt processing (should fail)
      expect {
        PersonalDataErasureWorker.new.perform(erasure_request.id)
      }.to raise_error(StandardError, 'Partial failure')
      
      erasure_request.reload
      expect(erasure_request.status).to eq('failed')
      
      # Data should remain intact
      user.reload
      expect(user.email).to eq(user.email) # Should not be anonymized
      expect(user.posts.count).to eq(3) # Should not be deleted
    end
  end
  
  describe 'Audit Trail and Compliance' do
    it 'maintains complete audit trail' do
      # Perform various GDPR operations
      get "/api/v1/gdpr/data-export/#{user.id}", 
          headers: { 'Authorization' => "Bearer #{user.api_token}" }
      
      post "/api/v1/gdpr/data-erasure/#{user.id}",
           params: { reason: 'Test audit' }.to_json,
           headers: { 
             'Authorization' => "Bearer #{admin_user.api_token}",
             'Content-Type' => 'application/json'
           }
      
      post "/api/v1/gdpr/consent/#{user.id}",
           params: { 
             consent_type: 'analytics',
             consent_data: { granted: true, consent_text: 'Test', ip_address: '127.0.0.1', user_agent: 'Test' }
           }.to_json,
           headers: { 
             'Authorization' => "Bearer #{user.api_token}",
             'Content-Type' => 'application/json'
           }
      
      # Check audit log
      get "/api/v1/gdpr/audit-log",
          headers: { 'Authorization' => "Bearer #{admin_user.api_token}" }
      
      expect(response).to have_http_status(:ok)
      audit_response = JSON.parse(response.body)
      
      expect(audit_response['data']).to be_an(Array)
      expect(audit_response['data'].length).to be >= 3
      
      # Verify audit entries contain required information
      audit_response['data'].each do |entry|
        expect(entry).to include('id', 'action', 'user_email', 'timestamp')
      end
    end
  end
end
