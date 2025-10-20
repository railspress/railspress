require 'rails_helper'

RSpec.describe PersonalDataExportRequest, type: :model do
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
      valid_request = build(:personal_data_export_request, user: user, email: 'valid@example.com')
      invalid_request = build(:personal_data_export_request, user: user, email: 'invalid-email')
      
      expect(valid_request).to be_valid
      expect(invalid_request).not_to be_valid
      expect(invalid_request.errors[:email]).to include('is invalid')
    end
    
    it 'validates token uniqueness' do
      create(:personal_data_export_request, user: user, token: 'unique_token')
      duplicate = build(:personal_data_export_request, user: user, token: 'unique_token')
      
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:token]).to include('has already been taken')
    end
  end
  
  describe 'enums' do
    it 'defines status enum' do
      expect(PersonalDataExportRequest.statuses).to eq({
        'pending' => 'pending',
        'processing' => 'processing', 
        'completed' => 'completed',
        'failed' => 'failed'
      })
    end
    
    it 'allows status transitions' do
      request = create(:personal_data_export_request, user: user, status: 'pending')
      
      expect(request.pending?).to be true
      
      request.update!(status: 'processing')
      expect(request.processing?).to be true
      
      request.update!(status: 'completed')
      expect(request.completed?).to be true
    end
  end
  
  describe 'scopes' do
    let!(:recent_request) { create(:personal_data_export_request, user: user, created_at: 1.hour.ago) }
    let!(:old_request) { create(:personal_data_export_request, user: user, created_at: 1.day.ago) }
    let!(:completed_old_request) { create(:personal_data_export_request, user: user, status: 'completed', completed_at: 8.days.ago) }
    
    describe '.recent' do
      it 'orders by created_at desc' do
        expect(PersonalDataExportRequest.recent.first).to eq(recent_request)
        expect(PersonalDataExportRequest.recent.last).to eq(old_request)
      end
    end
    
    describe '.pending_expiry' do
      it 'finds requests completed more than 7 days ago' do
        expect(PersonalDataExportRequest.pending_expiry).to include(completed_old_request)
        expect(PersonalDataExportRequest.pending_expiry).not_to include(recent_request)
      end
    end
  end
  
  describe 'callbacks' do
    describe 'after_create' do
      it 'generates a token if not provided' do
        request = create(:personal_data_export_request, user: user, token: nil)
        
        expect(request.token).to be_present
        expect(request.token.length).to eq(64) # 32 hex characters
      end
      
      it 'does not override existing token' do
        existing_token = 'existing_token_123'
        request = create(:personal_data_export_request, user: user, token: existing_token)
        
        expect(request.token).to eq(existing_token)
      end
    end
  end
  
  describe 'instance methods' do
    let(:request) { create(:personal_data_export_request, user: user) }
    
    describe '#file_exists?' do
      it 'returns true when file exists' do
        allow(File).to receive(:exist?).with(request.file_path).and_return(true)
        
        expect(request.file_exists?).to be true
      end
      
      it 'returns false when file does not exist' do
        allow(File).to receive(:exist?).with(request.file_path).and_return(false)
        
        expect(request.file_exists?).to be false
      end
    end
    
    describe '#downloadable?' do
      it 'returns true when completed and file exists' do
        request.update!(status: 'completed')
        allow(File).to receive(:exist?).with(request.file_path).and_return(true)
        
        expect(request.downloadable?).to be true
      end
      
      it 'returns false when not completed' do
        request.update!(status: 'pending')
        
        expect(request.downloadable?).to be false
      end
      
      it 'returns false when file does not exist' do
        request.update!(status: 'completed')
        allow(File).to receive(:exist?).with(request.file_path).and_return(false)
        
        expect(request.downloadable?).to be false
      end
    end
    
    describe '#age_in_days' do
      it 'calculates age correctly' do
        request.update!(created_at: 3.days.ago)
        
        expect(request.age_in_days).to be_within(0.1).of(3.0)
      end
    end
  end
  
  describe 'data integrity' do
    it 'maintains referential integrity with user deletion' do
      request = create(:personal_data_export_request, user: user)
      user_id = user.id
      
      user.destroy
      
      expect { request.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it 'maintains referential integrity with tenant deletion' do
      request = create(:personal_data_export_request, user: user)
      tenant_id = tenant.id
      
      tenant.destroy
      
      expect { request.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
  
  describe 'business logic' do
    it 'prevents duplicate pending requests for same user' do
      create(:personal_data_export_request, user: user, status: 'pending')
      
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
    
    it 'allows new request after previous one failed' do
      create(:personal_data_export_request, user: user, status: 'failed')
      
      expect {
        GdprService.create_export_request(user, admin_user)
      }.not_to raise_error
    end
  end
  
  describe 'metadata handling' do
    it 'stores and retrieves metadata as JSON' do
      metadata = {
        'total_posts' => 5,
        'total_comments' => 12,
        'export_size' => '2.5MB'
      }
      
      request = create(:personal_data_export_request, user: user, metadata: metadata)
      
      expect(request.reload.metadata).to eq(metadata)
      expect(request.metadata['total_posts']).to eq(5)
    end
    
    it 'handles nil metadata' do
      request = create(:personal_data_export_request, user: user, metadata: nil)
      
      expect(request.metadata).to be_nil
    end
  end
  
  describe 'file path handling' do
    it 'generates consistent file paths' do
      request1 = create(:personal_data_export_request, user: user)
      request2 = create(:personal_data_export_request, user: user)
      
      expect(request1.file_path).to include("personal_data_#{request1.id}")
      expect(request2.file_path).to include("personal_data_#{request2.id}")
      expect(request1.file_path).not_to eq(request2.file_path)
    end
    
    it 'handles file path updates' do
      request = create(:personal_data_export_request, user: user)
      new_path = '/new/path/file.json'
      
      request.update!(file_path: new_path)
      
      expect(request.file_path).to eq(new_path)
    end
  end
end