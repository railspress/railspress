require 'rails_helper'

RSpec.describe UserConsent, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:tenant) }
  end
  
  describe 'validations' do
    it { should validate_presence_of(:consent_type) }
    it { should validate_presence_of(:consent_text) }
    it { should validate_presence_of(:ip_address) }
    it { should validate_presence_of(:user_agent) }
    
    it { should validate_inclusion_of(:consent_type).in_array(UserConsent::CONSENT_TYPES) }
    
    it 'validates uniqueness of consent_type scoped to user_id' do
      create(:user_consent, user: user, consent_type: 'data_processing')
      duplicate = build(:user_consent, user: user, consent_type: 'data_processing')
      
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:consent_type]).to include('has already been taken')
    end
  end
  
  describe 'scopes' do
    let!(:granted_consent) { create(:user_consent, user: user, granted: true) }
    let!(:withdrawn_consent) { create(:user_consent, :withdrawn, user: user) }
    let!(:marketing_consent) { create(:user_consent, :marketing, user: user) }
    
    describe '.granted' do
      it 'returns only granted consents' do
        expect(UserConsent.granted).to include(granted_consent)
        expect(UserConsent.granted).not_to include(withdrawn_consent)
      end
    end
    
    describe '.withdrawn' do
      it 'returns only withdrawn consents' do
        expect(UserConsent.withdrawn).to include(withdrawn_consent)
        expect(UserConsent.withdrawn).not_to include(granted_consent)
      end
    end
    
    describe '.by_type' do
      it 'returns consents of specific type' do
        expect(UserConsent.by_type('marketing')).to include(marketing_consent)
        expect(UserConsent.by_type('marketing')).not_to include(granted_consent)
      end
    end
    
    describe '.recent' do
      it 'orders by updated_at desc' do
        old_consent = create(:user_consent, user: user, updated_at: 1.day.ago)
        recent_consent = create(:user_consent, user: user, updated_at: 1.hour.ago)
        
        expect(UserConsent.recent.first).to eq(recent_consent)
        expect(UserConsent.recent.last).to eq(old_consent)
      end
    end
  end
  
  describe 'callbacks' do
    describe 'before_validation on create' do
      it 'sets granted_at if granted is true' do
        consent = create(:user_consent, user: user, granted: true)
        
        expect(consent.granted_at).to be_present
        expect(consent.granted_at).to be_within(1.second).of(Time.current)
      end
      
      it 'does not set granted_at if granted is false' do
        consent = create(:user_consent, user: user, granted: false)
        
        expect(consent.granted_at).to be_nil
      end
    end
  end
  
  describe 'instance methods' do
    let(:consent) { create(:user_consent, user: user, granted: true) }
    let(:withdrawn_consent) { create(:user_consent, :withdrawn, user: user) }
    
    describe '#granted?' do
      it 'returns true for granted consents' do
        expect(consent.granted?).to be true
      end
      
      it 'returns false for withdrawn consents' do
        expect(withdrawn_consent.granted?).to be false
      end
    end
    
    describe '#withdrawn?' do
      it 'returns false for granted consents' do
        expect(consent.withdrawn?).to be false
      end
      
      it 'returns true for withdrawn consents' do
        expect(withdrawn_consent.withdrawn?).to be true
      end
    end
    
    describe '#withdraw!' do
      it 'withdraws consent' do
        consent.withdraw!
        
        expect(consent.reload.granted).to be false
        expect(consent.withdrawn_at).to be_present
        expect(consent.withdrawn?).to be true
      end
    end
    
    describe '#grant!' do
      let(:withdrawn_consent) { create(:user_consent, :withdrawn, user: user) }
      
      it 'grants consent' do
        withdrawn_consent.grant!
        
        expect(withdrawn_consent.reload.granted).to be true
        expect(withdrawn_consent.granted_at).to be_present
        expect(withdrawn_consent.withdrawn_at).to be_nil
        expect(withdrawn_consent.granted?).to be true
      end
    end
  end
  
  describe 'consent types' do
    UserConsent::CONSENT_TYPES.each do |consent_type|
      it "validates #{consent_type} consent type" do
        consent = build(:user_consent, user: user, consent_type: consent_type)
        expect(consent).to be_valid
      end
    end
  end
  
  describe 'data integrity' do
    it 'maintains referential integrity with user deletion' do
      consent = create(:user_consent, user: user)
      user_id = user.id
      
      user.destroy
      
      expect { consent.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it 'maintains referential integrity with tenant deletion' do
      consent = create(:user_consent, user: user)
      tenant_id = tenant.id
      
      tenant.destroy
      
      expect { consent.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
  
  describe 'edge cases' do
    it 'handles nil values gracefully' do
      consent = build(:user_consent, user: user, granted_at: nil, withdrawn_at: nil)
      
      expect(consent.granted?).to be false
      expect(consent.withdrawn?).to be false
    end
    
    it 'handles future timestamps' do
      future_time = 1.day.from_now
      consent = create(:user_consent, user: user, granted_at: future_time)
      
      expect(consent.granted_at).to eq(future_time)
    end
  end
end
