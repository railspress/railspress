require 'rails_helper'

RSpec.describe GdprService, type: :service do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:admin_user) { create(:user, :administrator, tenant: tenant) }
  let(:other_user) { create(:user, tenant: tenant) }
  
  before do
    # Create some test data
    create(:post, user: user)
    create(:comment, email: user.email)
    create(:user_consent, user: user, consent_type: 'data_processing', granted: true)
  end
  
  describe '.create_export_request' do
    it 'creates an export request successfully' do
      expect {
        GdprService.create_export_request(user, admin_user)
      }.to change(PersonalDataExportRequest, :count).by(1)
      
      request = PersonalDataExportRequest.last
      expect(request.user).to eq(user)
      expect(request.email).to eq(user.email)
      expect(request.requested_by).to eq(admin_user.id)
      expect(request.status).to eq('pending')
      expect(request.tenant).to eq(tenant)
    end
    
    it 'queues the export job' do
      expect(PersonalDataExportWorker).to receive(:perform_async).with(kind_of(Integer))
      
      GdprService.create_export_request(user, admin_user)
    end
    
    it 'prevents duplicate pending requests' do
      create(:personal_data_export_request, user: user, status: 'pending')
      
      expect {
        GdprService.create_export_request(user, admin_user)
      }.to raise_error(StandardError, /already pending/)
    end
    
    it 'prevents duplicate processing requests' do
      create(:personal_data_export_request, user: user, status: 'processing')
      
      expect {
        GdprService.create_export_request(user, admin_user)
      }.to raise_error(StandardError, /already pending/)
    end
    
    it 'allows new request after previous one is completed' do
      create(:personal_data_export_request, user: user, status: 'completed')
      
      expect {
        GdprService.create_export_request(user, admin_user)
      }.not_to raise_error
    end
  end
  
  describe '.create_erasure_request' do
    it 'creates an erasure request successfully' do
      expect {
        GdprService.create_erasure_request(user, admin_user, 'User requested deletion')
      }.to change(PersonalDataErasureRequest, :count).by(1)
      
      request = PersonalDataErasureRequest.last
      expect(request.user).to eq(user)
      expect(request.email).to eq(user.email)
      expect(request.requested_by).to eq(admin_user.id)
      expect(request.status).to eq('pending_confirmation')
      expect(request.reason).to eq('User requested deletion')
      expect(request.tenant).to eq(tenant)
    end
    
    it 'gathers metadata about what will be erased' do
      request = GdprService.create_erasure_request(user, admin_user, 'Test reason')
      
      expect(request.metadata).to include(
        'user_posts_count' => 1,
        'user_comments_count' => 1,
        'user_media_count' => 0,
        'user_subscribers_count' => 0,
        'user_pageviews_count' => 0,
        'user_api_tokens_count' => 1, # API token is created by default
        'user_meta_fields_count' => 0,
        'account_age_days' => 0
      )
    end
    
    it 'prevents duplicate pending requests' do
      create(:personal_data_erasure_request, user: user, status: 'pending_confirmation')
      
      expect {
        GdprService.create_erasure_request(user, admin_user)
      }.to raise_error(StandardError, /already pending/)
    end
    
    it 'handles nil reason' do
      request = GdprService.create_erasure_request(user, admin_user, nil)
      
      expect(request.reason).to be_nil
    end
  end
  
  describe '.confirm_erasure_request' do
    let(:erasure_request) { create(:personal_data_erasure_request, user: user, status: 'pending_confirmation') }
    
    it 'confirms the erasure request' do
      GdprService.confirm_erasure_request(erasure_request, admin_user)
      
      erasure_request.reload
      expect(erasure_request.status).to eq('processing')
      expect(erasure_request.confirmed_at).to be_present
      expect(erasure_request.confirmed_by).to eq(admin_user.id)
    end
    
    it 'queues the erasure job' do
      expect(PersonalDataErasureWorker).to receive(:perform_async).with(erasure_request.id)
      
      GdprService.confirm_erasure_request(erasure_request, admin_user)
    end
    
    it 'logs the confirmation action' do
      expect(Rails.logger).to receive(:info).with(/GDPR Action: erasure_confirmed/)
      
      GdprService.confirm_erasure_request(erasure_request, admin_user)
    end
  end
  
  describe '.generate_portability_data' do
    let(:portability_data) { GdprService.generate_portability_data(user) }
    
    it 'includes user profile data' do
      expect(portability_data[:user_profile]).to include(
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        created_at: user.created_at,
        updated_at: user.updated_at
      )
    end
    
    it 'includes user posts' do
      expect(portability_data[:posts]).to be_an(Array)
      expect(portability_data[:posts].length).to eq(1)
      expect(portability_data[:posts].first).to include(:id, :title, :content, :status)
    end
    
    it 'includes user comments' do
      expect(portability_data[:comments]).to be_an(Array)
      expect(portability_data[:comments].length).to eq(1)
      expect(portability_data[:comments].first).to include(:content, :author_name, :created_at)
    end
    
    it 'includes consent records' do
      expect(portability_data[:consent_records]).to be_an(Array)
      expect(portability_data[:consent_records].length).to eq(1)
      expect(portability_data[:consent_records].first).to include(:consent_type, :granted)
    end
    
    it 'includes GDPR requests history' do
      expect(portability_data[:gdpr_requests]).to include(:export_requests, :erasure_requests)
    end
    
    it 'includes metadata' do
      expect(portability_data[:metadata]).to include(
        total_posts: 1,
        total_comments: 1,
        export_date: kind_of(Time)
      )
    end
  end
  
  describe '.get_user_gdpr_status' do
    let(:status) { GdprService.get_user_gdpr_status(user) }
    
    it 'returns comprehensive status information' do
      expect(status).to include(
        user_id: user.id,
        email: user.email,
        compliance_status: kind_of(Hash),
        data_retention: kind_of(Hash),
        pending_requests: kind_of(Hash),
        data_categories: kind_of(Hash),
        legal_basis: kind_of(Hash)
      )
    end
    
    it 'includes compliance status' do
      expect(status[:compliance_status]).to include(
        data_processing_consent: 'granted',
        marketing_consent: 'not_recorded',
        analytics_consent: 'not_recorded',
        cookie_consent: 'not_recorded'
      )
    end
    
    it 'includes data retention information' do
      expect(status[:data_retention]).to include(
        account_created: user.created_at,
        last_activity: kind_of(Time),
        data_age_days: kind_of(Integer)
      )
    end
    
    it 'includes pending requests count' do
      expect(status[:pending_requests]).to include(
        export_requests: 0,
        erasure_requests: 0
      )
    end
    
    it 'includes data categories' do
      expect(status[:data_categories]).to include(
        profile_data: true,
        content_data: true,
        communication_data: true,
        analytics_data: false,
        media_data: false,
        subscription_data: false
      )
    end
    
    it 'includes legal basis' do
      expect(status[:legal_basis]).to include(
        consent: true,
        withhold_consent: false,
        legitimate_interest: true
      )
    end
  end
  
  describe '.record_user_consent' do
    let(:consent_data) do
      {
        granted: true,
        consent_text: 'I agree to data processing',
        ip_address: '127.0.0.1',
        user_agent: 'Test Browser'
      }
    end
    
    it 'creates a new consent record' do
      expect {
        GdprService.record_user_consent(user, 'marketing', consent_data)
      }.to change(UserConsent, :count).by(1)
      
      consent = UserConsent.last
      expect(consent.user).to eq(user)
      expect(consent.consent_type).to eq('marketing')
      expect(consent.granted).to be true
      expect(consent.consent_text).to eq('I agree to data processing')
    end
    
    it 'updates existing consent record' do
      existing_consent = create(:user_consent, user: user, consent_type: 'marketing', granted: false)
      
      expect {
        GdprService.record_user_consent(user, 'marketing', consent_data)
      }.not_to change(UserConsent, :count)
      
      existing_consent.reload
      expect(existing_consent.granted).to be true
      expect(existing_consent.granted_at).to be_present
      expect(existing_consent.withdrawn_at).to be_nil
    end
    
    it 'handles consent withdrawal' do
      withdrawal_data = consent_data.merge(granted: false)
      
      GdprService.record_user_consent(user, 'marketing', withdrawal_data)
      
      consent = UserConsent.last
      expect(consent.granted).to be false
      expect(consent.withdrawn_at).to be_present
      expect(consent.granted_at).to be_nil
    end
  end
  
  describe '.withdraw_user_consent' do
    let!(:consent) { create(:user_consent, user: user, consent_type: 'marketing', granted: true) }
    
    it 'withdraws existing consent' do
      GdprService.withdraw_user_consent(user, 'marketing')
      
      consent.reload
      expect(consent.granted).to be false
      expect(consent.withdrawn_at).to be_present
    end
    
    it 'raises error for non-existent consent' do
      expect {
        GdprService.withdraw_user_consent(user, 'nonexistent')
      }.to raise_error(StandardError, /No consent record found/)
    end
  end
  
  describe '.get_audit_log' do
    before do
      create(:personal_data_export_request, user: user)
      create(:personal_data_erasure_request, user: user)
    end
    
    it 'returns audit log entries' do
      audit_log = GdprService.get_audit_log(1, 50)
      
      expect(audit_log).to be_an(Array)
      expect(audit_log.length).to be >= 2
      
      audit_log.each do |entry|
        expect(entry).to include(:id, :action, :user_email, :timestamp, :details)
      end
    end
    
    it 'supports pagination' do
      audit_log = GdprService.get_audit_log(1, 1)
      
      expect(audit_log.length).to eq(1)
    end
    
    it 'orders entries by timestamp desc' do
      audit_log = GdprService.get_audit_log(1, 10)
      
      timestamps = audit_log.map { |entry| entry[:timestamp] }
      expect(timestamps).to eq(timestamps.sort.reverse)
    end
  end
  
  describe 'error handling' do
    it 'handles missing user gracefully' do
      expect {
        GdprService.get_user_gdpr_status(nil)
      }.to raise_error(NoMethodError)
    end
    
    it 'handles invalid consent data gracefully' do
      expect {
        GdprService.record_user_consent(user, 'invalid_type', {})
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
  
  describe 'logging' do
    it 'logs export request actions' do
      expect(Rails.logger).to receive(:info).with(/GDPR Action: export_requested/)
      
      GdprService.create_export_request(user, admin_user)
    end
    
    it 'logs erasure request actions' do
      expect(Rails.logger).to receive(:info).with(/GDPR Action: erasure_requested/)
      
      GdprService.create_erasure_request(user, admin_user)
    end
    
    it 'logs consent recording actions' do
      consent_data = {
        granted: true,
        consent_text: 'Test consent',
        ip_address: '127.0.0.1',
        user_agent: 'Test Browser'
      }
      
      expect(Rails.logger).to receive(:info).with(/GDPR Action: consent_recorded/)
      
      GdprService.record_user_consent(user, 'marketing', consent_data)
    end
  end
end
