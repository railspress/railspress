require 'rails_helper'

RSpec.describe SiteSetting, type: :model do
  let(:tenant) { create(:tenant) }
  let(:site_setting) { build(:site_setting, tenant: tenant) }

  describe 'associations' do
    it { should belong_to(:tenant).optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:key) }
    it { should validate_presence_of(:setting_type) }
    it { should validate_uniqueness_of(:key).scoped_to(:tenant_id) }
    it { should validate_inclusion_of(:setting_type).in_array(SiteSetting::SETTING_TYPES) }
  end

  describe 'constants' do
    it 'defines SETTING_TYPES' do
      expect(SiteSetting::SETTING_TYPES).to eq(%w[string integer boolean text])
    end
  end

  describe 'class methods' do
    describe '.get' do
      let!(:setting) { create(:site_setting, key: 'test_key', value: 'test_value', setting_type: 'string', tenant: tenant) }
      
      it 'returns setting value when tenant is set' do
        ActsAsTenant.with_tenant(tenant) do
          expect(SiteSetting.get('test_key')).to eq('test_value')
        end
      end
      
      it 'returns default when setting not found' do
        ActsAsTenant.with_tenant(tenant) do
          expect(SiteSetting.get('missing_key', 'default')).to eq('default')
        end
      end
      
      it 'returns default when no tenant is set' do
        expect(SiteSetting.get('test_key', 'default')).to eq('default')
      end
    end

    describe '.set' do
      it 'creates new setting when tenant is set' do
        ActsAsTenant.with_tenant(tenant) do
          expect {
            SiteSetting.set('new_key', 'new_value', 'string')
          }.to change(SiteSetting, :count).by(1)
          
          setting = SiteSetting.last
          expect(setting.key).to eq('new_key')
          expect(setting.value).to eq('new_value')
          expect(setting.setting_type).to eq('string')
          expect(setting.tenant).to eq(tenant)
        end
      end
      
      it 'updates existing setting' do
        setting = create(:site_setting, key: 'existing_key', value: 'old_value', setting_type: 'string', tenant: tenant)
        
        ActsAsTenant.with_tenant(tenant) do
          SiteSetting.set('existing_key', 'new_value', 'string')
          expect(setting.reload.value).to eq('new_value')
        end
      end
      
      it 'creates setting without tenant when no tenant is set' do
        expect {
          SiteSetting.set('global_key', 'global_value', 'string')
        }.to change(SiteSetting, :count).by(1)
        
        setting = SiteSetting.last
        expect(setting.key).to eq('global_key')
        expect(setting.value).to eq('global_value')
        expect(setting.tenant).to be_nil
      end
    end
  end

  describe 'instance methods' do
    describe '#typed_value' do
      it 'returns integer value for integer type' do
        setting = build(:site_setting, value: '42', setting_type: 'integer')
        expect(setting.typed_value).to eq(42)
      end
      
      it 'returns boolean true for boolean type' do
        setting = build(:site_setting, value: 'true', setting_type: 'boolean')
        expect(setting.typed_value).to be true
      end
      
      it 'returns boolean true for "1" boolean type' do
        setting = build(:site_setting, value: '1', setting_type: 'boolean')
        expect(setting.typed_value).to be true
      end
      
      it 'returns boolean false for boolean type' do
        setting = build(:site_setting, value: 'false', setting_type: 'boolean')
        expect(setting.typed_value).to be false
      end
      
      it 'returns string value for string type' do
        setting = build(:site_setting, value: 'test', setting_type: 'string')
        expect(setting.typed_value).to eq('test')
      end
      
      it 'returns string value for text type' do
        setting = build(:site_setting, value: 'long text', setting_type: 'text')
        expect(setting.typed_value).to eq('long text')
      end
      
      it 'returns value as-is for unknown type' do
        setting = build(:site_setting, value: 'unknown', setting_type: 'unknown')
        expect(setting.typed_value).to eq('unknown')
      end
    end
  end
end
