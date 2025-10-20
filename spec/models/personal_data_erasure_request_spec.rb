require 'rails_helper'

RSpec.describe PersonalDataErasureRequest, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:admin_user) { create(:user, :administrator, tenant: tenant) }
  
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:tenant) }
  end
  
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:token) }
    it { should validate_presence_of(:status) }
    
    it 'validates email format' do
      valid_request = build(:personal_data_erasure_request, user: user, email: 'valid@example.com')
      invalid_request = build(:personal_data_erasure_request, user: user, email: 'invalid-email')
      
      expect(valid_request).to be_valid
      expect(invalid_request).not_to be_valid
      expect(invalid_request.errors[:email]).to include('is invalid')
    end
    
    it 'validates token uniqueness' do
      create(:personal_data_erasure_request, user: user, token: 'unique_token')
      duplicate = build(:personal_data_erasure_request, user: user, token: 'unique_token')
      
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:token]).to include('has already been taken')
    end
  end
  
  describe 'enums' do
    it 'defines status enum' do
      expect(PersonalDataErasureRequest.statuses).to eq({
        'pending_confirmation' => 'pending_confirmation',
        'processing' => 'processing',
        'completed' => 'completed', 
        'failed' => 'failed',
        'cancelled' => 'cancelled'
      })
    end
    
    it 'allows status transitions' do
      request = create(:personal_data_erasure_request, user: user, status: 'pending_confirmation')
      
      expect(request.pending_confirmation?).to be true
      
      request.update!(status: 'processing')
      expect(request.processing?).to be true
      
      request.update!(status: 'completed')
      expect(request.completed?).to be true
    end
  end
  
  describe 'scopes' do
    let!(:recent_request) { create(:personal_data_erasure_request, user: user, created_at: 1.hour.ago) }
    let!(:old_request) { create(:personal_data_erasure_request, user: user, created_at: 1.day.ago) }
    let!(:pending_request) { create(:personal_data_erasure_request, user: user, status: 'pending_confirmation') }
    let!(:completed_request) { create(:personal_data_erasure_request, user: user, status: 'completed') }
    
    describe '.recent' do
      it 'orders by created_at desc' do
        expect(PersonalDataErasureRequest.recent.first).to eq(recent_request)
        expect(PersonalDataErasureRequest.recent.last).to eq(old_request)
      end
    end
    
    describe '.awaiting_confirmation' do
      it 'finds requests awaiting confirmation' do
        expect(PersonalDataErasureRequest.awaiting_confirmation).to include(pending_request)
        expect(PersonalDataErasureRequest.awaiting_confirmation).not_to include(completed_request)
      end
    end
  end
  
  describe 'callbacks' do
    describe 'after_create' do
      it 'generates a token if not provided' do
        request = create(:personal_data_erasure_request, user: user, token: nil)
        
        expect(request.token).to be_present
        expect(request.token.length).to eq(64) # 32 hex characters
      end
      
      it 'does not override existing token' do
        existing_token = 'existing_token_123'
        request = create(:personal_data_erasure_request, user: user, token: existing_token)
        
        expect(request.token).to eq(existing_token)
      end
    end
  end
  
  describe 'instance methods' do
    let(:request) { create(:personal_data_erasure_request, user: user) }
    
    describe '#confirmable?' do
      it 'returns true when status is pending_confirmation' do
        request.update!(status: 'pending_confirmation')
        
        expect(request.confirmable?).to be true
      end
      
      it 'returns false for other statuses' do
        request.update!(status: 'processing')
        
        expect(request.confirmable?).to be false
      end
    end
    
    describe '#age_in_days' do
      it 'calculates age correctly' do
        request.update!(created_at: 3.days.ago)
        
        expect(request.age_in_days).to be_within(0.1).of(3.0)
      end
    end
    
    describe '#confirmation_age' do
      it 'returns nil when not confirmed' do
        expect(request.confirmation_age).to be_nil
      end
      
      it 'calculates confirmation age when confirmed' do
        request.update!(confirmed_at: 2.days.ago)
        
        expect(request.confirmation_age).to be_within(0.1).of(2.0)
      end
    end
  end
  
  describe 'data integrity' do
    it 'maintains referential integrity with user deletion' do
      request = create(:personal_data_erasure_request, user: user)
      user_id = user.id
      
      user.destroy
      
      expect { request.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it 'maintains referential integrity with tenant deletion' do
      request = create(:personal_data_erasure_request, user: user)
      tenant_id = tenant.id
      
      tenant.destroy
      
      expect { request.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
  
  describe 'business logic' do
    it 'prevents duplicate pending requests for same user' do
      create(:personal_data_erasure_request, user: user, status: 'pending_confirmation')
      
      expect {
        GdprService.create_erasure_request(user, admin_user)
      }.to raise_error(StandardError, /already pending/)
    end
    
    it 'prevents duplicate processing requests for same user' do
      create(:personal_data_erasure_request, user: user, status: 'processing')
      
      expect {
        GdprService.create_erasure_request(user, admin_user)
      }.to raise_error(StandardError, /already pending/)
    end
    
    it 'allows new request after previous one is completed' do
      create(:personal_data_erasure_request, user: user, status: 'completed')
      
      expect {
        GdprService.create_erasure_request(user, admin_user)
      }.not_to raise_error
    end
    
    it 'allows new request after previous one failed' do
      create(:personal_data_erasure_request, user: user, status: 'failed')
      
      expect {
        GdprService.create_erasure_request(user, admin_user)
      }.not_to raise_error
    end
    
    it 'allows new request after previous one is cancelled' do
      create(:personal_data_erasure_request, user: user, status: 'cancelled')
      
      expect {
        GdprService.create_erasure_request(user, admin_user)
      }.not_to raise_error
    end
  end
  
  describe 'metadata handling' do
    it 'stores and retrieves metadata as JSON' do
      metadata = {
        'user_posts_count' => 5,
        'user_comments_count' => 12,
        'user_media_count' => 3,
        'account_age_days' => 30
      }
      
      request = create(:personal_data_erasure_request, user: user, metadata: metadata)
      
      expect(request.reload.metadata).to eq(metadata)
      expect(request.metadata['user_posts_count']).to eq(5)
    end
    
    it 'handles nil metadata' do
      request = create(:personal_data_erasure_request, user: user, metadata: nil)
      
      expect(request.metadata).to be_nil
    end
  end
  
  describe 'confirmation workflow' do
    let(:request) { create(:personal_data_erasure_request, user: user, status: 'pending_confirmation') }
    
    it 'updates status to processing when confirmed' do
      GdprService.confirm_erasure_request(request, admin_user)
      
      expect(request.reload.status).to eq('processing')
      expect(request.confirmed_at).to be_present
      expect(request.confirmed_by).to eq(admin_user.id)
    end
    
    it 'prevents confirmation of already processed requests' do
      request.update!(status: 'completed')
      
      expect {
        GdprService.confirm_erasure_request(request, admin_user)
      }.to raise_error(StandardError, /already been processed/)
    end
  end
  
  describe 'reason handling' do
    it 'stores reason for erasure' do
      reason = 'User requested complete data deletion'
      request = create(:personal_data_erasure_request, user: user, reason: reason)
      
      expect(request.reason).to eq(reason)
    end
    
    it 'handles nil reason' do
      request = create(:personal_data_erasure_request, user: user, reason: nil)
      
      expect(request.reason).to be_nil
    end
    
    it 'handles long reasons' do
      long_reason = 'A' * 1000
      request = create(:personal_data_erasure_request, user: user, reason: long_reason)
      
      expect(request.reason).to eq(long_reason)
    end
  end
  
  describe 'timestamps' do
    let(:request) { create(:personal_data_erasure_request, user: user) }
    
    it 'tracks creation time' do
      expect(request.created_at).to be_present
      expect(request.created_at).to be_within(1.second).of(Time.current)
    end
    
    it 'tracks update time' do
      original_updated_at = request.updated_at
      
      request.update!(reason: 'Updated reason')
      
      expect(request.updated_at).to be > original_updated_at
    end
    
    it 'tracks confirmation time when confirmed' do
      GdprService.confirm_erasure_request(request, admin_user)
      
      expect(request.reload.confirmed_at).to be_present
      expect(request.confirmed_at).to be_within(1.second).of(Time.current)
    end
    
    it 'tracks completion time when completed' do
      request.update!(status: 'completed', completed_at: Time.current)
      
      expect(request.completed_at).to be_present
    end
  end
end