require 'rails_helper'

RSpec.describe WebhookDelivery, type: :model do
  describe 'associations' do
    it { should belong_to(:webhook) }
  end

  describe 'validations' do
    it { should validate_presence_of(:event_type) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(%w[pending success failed]) }
  end

  describe 'enums' do
    it 'has correct status enum values' do
      expect(WebhookDelivery.statuses).to eq({
        'pending' => 'pending',
        'success' => 'success', 
        'failed' => 'failed'
      })
    end
  end

  describe 'scopes' do
    let!(:delivery1) { create(:webhook_delivery, status: 'success', created_at: 1.hour.ago) }
    let!(:delivery2) { create(:webhook_delivery, status: 'failed', created_at: 2.hours.ago) }
    let!(:delivery3) { create(:webhook_delivery, status: 'pending', created_at: 3.hours.ago) }

    describe '.recent' do
      it 'orders by created_at desc' do
        expect(WebhookDelivery.recent).to eq([delivery1, delivery2, delivery3])
      end
    end

    describe '.failed' do
      it 'returns only failed deliveries' do
        expect(WebhookDelivery.failed).to contain_exactly(delivery2)
      end
    end

    describe '.successful' do
      it 'returns only successful deliveries' do
        expect(WebhookDelivery.successful).to contain_exactly(delivery1)
      end
    end
  end

  describe '#success_status?' do
    it 'returns true for successful deliveries' do
      delivery = build(:webhook_delivery, status: 'success')
      expect(delivery.success_status?).to be true
    end

    it 'returns false for failed deliveries' do
      delivery = build(:webhook_delivery, status: 'failed')
      expect(delivery.success_status?).to be false
    end

    it 'returns false for pending deliveries' do
      delivery = build(:webhook_delivery, status: 'pending')
      expect(delivery.success_status?).to be false
    end
  end

  describe '#can_retry?' do
    let(:webhook) { create(:webhook, retry_limit: 3) }
    
    it 'returns true for failed deliveries under retry limit' do
      delivery = build(:webhook_delivery, webhook: webhook, status: 'failed', retry_count: 2)
      expect(delivery.can_retry?).to be true
    end

    it 'returns false for successful deliveries' do
      delivery = build(:webhook_delivery, webhook: webhook, status: 'success', retry_count: 0)
      expect(delivery.can_retry?).to be false
    end

    it 'returns false when retry limit reached' do
      delivery = build(:webhook_delivery, webhook: webhook, status: 'failed', retry_count: 3)
      expect(delivery.can_retry?).to be false
    end
  end

  describe '#mark_success!' do
    let(:webhook) { create(:webhook) }
    let(:delivery) { create(:webhook_delivery, webhook: webhook, status: 'pending') }

    it 'updates status to success' do
      delivery.mark_success!(200, 'OK')
      expect(delivery.status).to eq('success')
      expect(delivery.response_code).to eq(200)
      expect(delivery.response_body).to eq('OK')
      expect(delivery.delivered_at).to be_present
    end
  end

  describe '#mark_failed!' do
    let(:webhook) { create(:webhook) }
    let(:delivery) { create(:webhook_delivery, webhook: webhook, status: 'pending') }

    it 'updates status to failed' do
      delivery.mark_failed!('Connection timeout')
      expect(delivery.status).to eq('failed')
      expect(delivery.error_message).to eq('Connection timeout')
    end
  end
end
