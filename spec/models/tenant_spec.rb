require 'rails_helper'

RSpec.describe Tenant, type: :model do
  let(:tenant) { build(:tenant) }

  describe 'associations' do
    it { should have_many(:posts).dependent(:destroy) }
    it { should have_many(:pages).dependent(:destroy) }
    it { should have_many(:media).dependent(:destroy) }
    it { should have_many(:comments).dependent(:destroy) }
    it { should have_many(:taxonomies).dependent(:destroy) }
    it { should have_many(:terms).through(:taxonomies) }
    it { should have_many(:menus).dependent(:destroy) }
    it { should have_many(:widgets).dependent(:destroy) }
    it { should have_many(:themes).dependent(:destroy) }
    it { should have_many(:site_settings).dependent(:destroy) }
    it { should have_many(:users).dependent(:nullify) }
    it { should have_many(:email_logs) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:theme) }
    it { should validate_presence_of(:storage_type) }
    it { should validate_inclusion_of(:storage_type).in_array(%w[local s3]) }
    
    it 'validates uniqueness of domain' do
      create(:tenant, domain: 'example.com')
      duplicate_tenant = build(:tenant, domain: 'example.com')
      expect(duplicate_tenant).not_to be_valid
    end
    
    it 'validates uniqueness of subdomain' do
      create(:tenant, subdomain: 'test')
      duplicate_tenant = build(:tenant, subdomain: 'test')
      expect(duplicate_tenant).not_to be_valid
    end
  end

  describe 'scopes' do
    let!(:active_tenant) { create(:tenant, active: true) }
    let!(:inactive_tenant) { create(:tenant, active: false) }

    describe '.active' do
      it 'returns only active tenants' do
        expect(Tenant.active).to include(active_tenant)
        expect(Tenant.active).not_to include(inactive_tenant)
      end
    end

    describe '.by_domain' do
      it 'finds tenant by domain' do
        expect(Tenant.by_domain(active_tenant.domain)).to eq([active_tenant])
      end
    end

    describe '.by_subdomain' do
      it 'finds tenant by subdomain' do
        expect(Tenant.by_subdomain(active_tenant.subdomain)).to eq([active_tenant])
      end
    end
  end

  describe 'class methods' do
    describe '.find_by_request' do
      let(:request) { double('request', host: 'example.com', subdomains: ['test']) }
      
      it 'finds tenant by domain' do
        tenant = create(:tenant, domain: 'example.com')
        expect(Tenant.find_by_request(request)).to eq(tenant)
      end
      
      it 'finds tenant by subdomain' do
        tenant = create(:tenant, subdomain: 'test')
        request_no_domain = double('request', host: 'railspress.app', subdomains: ['test'])
        expect(Tenant.find_by_request(request_no_domain)).to eq(tenant)
      end
    end

    describe '.current' do
      it 'returns current tenant from ActsAsTenant' do
        expect(Tenant.current).to eq(ActsAsTenant.current_tenant)
      end
    end
  end

  describe 'instance methods' do
    describe '#activate!' do
      it 'activates the tenant' do
        tenant = create(:tenant, active: false)
        tenant.activate!
        expect(tenant.reload.active).to be true
      end
    end

    describe '#deactivate!' do
      it 'deactivates the tenant' do
        tenant = create(:tenant, active: true)
        tenant.deactivate!
        expect(tenant.reload.active).to be false
      end
    end

    describe '#full_url' do
      it 'returns domain URL when domain is present' do
        tenant = build(:tenant, domain: 'example.com', subdomain: nil)
        expect(tenant.full_url).to eq('https://example.com')
      end
      
      it 'returns subdomain URL when subdomain is present' do
        tenant = build(:tenant, domain: nil, subdomain: 'test')
        expect(tenant.full_url).to eq('https://test.railspress.app')
      end
      
      it 'returns nil when neither domain nor subdomain is present' do
        tenant = build(:tenant, domain: nil, subdomain: nil)
        expect(tenant.full_url).to be_nil
      end
    end

    describe '#default_domain' do
      it 'returns APP_DOMAIN from environment' do
        allow(ENV).to receive(:[]).with('APP_DOMAIN').and_return('custom.com')
        expect(tenant.default_domain).to eq('custom.com')
      end
      
      it 'returns default domain when APP_DOMAIN is not set' do
        allow(ENV).to receive(:[]).with('APP_DOMAIN').and_return(nil)
        expect(tenant.default_domain).to eq('railspress.app')
      end
    end

    describe '#locale_list' do
      it 'returns array of locales' do
        tenant = build(:tenant, locales: 'en,es,fr')
        expect(tenant.locale_list).to eq(['en', 'es', 'fr'])
      end
      
      it 'returns default locale when locales is nil' do
        tenant = build(:tenant, locales: nil)
        expect(tenant.locale_list).to eq(['en'])
      end
    end

    describe '#locale_list=' do
      it 'sets locales from array' do
        tenant = build(:tenant)
        tenant.locale_list = ['en', 'es']
        expect(tenant.locales).to eq('en,es')
      end
    end

    describe '#using_s3?' do
      it 'returns true when storage_type is s3' do
        tenant = build(:tenant, storage_type: 's3')
        expect(tenant.using_s3?).to be true
      end
      
      it 'returns false when storage_type is local' do
        tenant = build(:tenant, storage_type: 'local')
        expect(tenant.using_s3?).to be false
      end
    end

    describe '#using_local_storage?' do
      it 'returns true when storage_type is local' do
        tenant = build(:tenant, storage_type: 'local')
        expect(tenant.using_local_storage?).to be true
      end
      
      it 'returns false when storage_type is s3' do
        tenant = build(:tenant, storage_type: 's3')
        expect(tenant.using_local_storage?).to be false
      end
    end

    describe '#storage_configured?' do
      context 'with S3 storage' do
        let(:tenant) { build(:tenant, storage_type: 's3') }
        
        it 'returns true when all S3 settings are present' do
          tenant.storage_bucket = 'bucket'
          tenant.storage_region = 'us-east-1'
          tenant.storage_access_key = 'key'
          tenant.storage_secret_key = 'secret'
          expect(tenant.storage_configured?).to be true
        end
        
        it 'returns false when S3 settings are missing' do
          expect(tenant.storage_configured?).to be false
        end
      end
      
      context 'with local storage' do
        let(:tenant) { build(:tenant, storage_type: 'local') }
        
        it 'returns true' do
          expect(tenant.storage_configured?).to be true
        end
      end
    end

    describe '#storage_service' do
      it 'returns :amazon for S3 storage' do
        tenant = build(:tenant, storage_type: 's3')
        expect(tenant.storage_service).to eq(:amazon)
      end
      
      it 'returns :local for local storage' do
        tenant = build(:tenant, storage_type: 'local')
        expect(tenant.storage_service).to eq(:local)
      end
    end

    describe '#get_setting' do
      it 'returns setting value' do
        tenant = build(:tenant, settings: { 'test_key' => 'test_value' })
        expect(tenant.get_setting('test_key')).to eq('test_value')
      end
      
      it 'returns default when setting not found' do
        tenant = build(:tenant, settings: {})
        expect(tenant.get_setting('missing_key', 'default')).to eq('default')
      end
    end

    describe '#set_setting' do
      it 'sets setting value' do
        tenant = build(:tenant, settings: {})
        allow(tenant).to receive(:save).and_return(true)
        tenant.set_setting('test_key', 'test_value')
        expect(tenant.settings['test_key']).to eq('test_value')
      end
    end
  end

  describe 'callbacks' do
    describe 'after_initialize' do
      it 'sets default values' do
        tenant = Tenant.new
        expect(tenant.theme).to eq('default')
        expect(tenant.locales).to eq('en')
        expect(tenant.active).to be true
        expect(tenant.storage_type).to eq('local')
        expect(tenant.settings).to eq({})
      end
    end

    describe 'after_create' do
      it 'creates default settings' do
        expect { create(:tenant) }.to change(SiteSetting, :count).by(5)
      end
    end
  end

  describe 'validations' do
    describe 'must_have_domain_or_subdomain' do
      it 'is valid when domain is present' do
        tenant = build(:tenant, domain: 'example.com', subdomain: nil)
        expect(tenant).to be_valid
      end
      
      it 'is valid when subdomain is present' do
        tenant = build(:tenant, domain: nil, subdomain: 'test')
        expect(tenant).to be_valid
      end
      
      it 'is invalid when neither domain nor subdomain is present' do
        tenant = build(:tenant, domain: nil, subdomain: nil)
        expect(tenant).not_to be_valid
        expect(tenant.errors[:base]).to include('Must have either a domain or subdomain')
      end
    end
  end
end
