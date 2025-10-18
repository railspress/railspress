require 'rails_helper'

RSpec.describe Admin::SettingsController, type: :controller do
  let(:tenant) { create(:tenant) }
  let(:admin_user) { create(:user, :administrator, tenant: tenant) }
  let(:regular_user) { create(:user, :author, tenant: tenant) }

  before do
    ActsAsTenant.with_tenant(tenant) do
      sign_in admin_user
    end
  end

  describe 'GET #storage' do
    before do
      SiteSetting.set('storage_type', 'local', 'string')
      SiteSetting.set('local_storage_path', '/custom/path', 'string')
      SiteSetting.set('max_file_size', 15, 'integer')
      SiteSetting.set('allowed_file_types', 'jpg,png,pdf', 'string')
      SiteSetting.set('enable_cdn', true, 'boolean')
      SiteSetting.set('cdn_url', 'https://cdn.example.com', 'string')
      SiteSetting.set('auto_optimize_uploads', false, 'boolean')
    end

    it 'returns successful response' do
      get :storage
      expect(response).to have_http_status(:success)
    end

    it 'loads storage settings' do
      get :storage
      expect(assigns(:settings)).to be_present
      expect(assigns(:settings)[:storage_type]).to eq('local')
      expect(assigns(:settings)[:local_storage_path]).to eq('/custom/path')
      expect(assigns(:settings)[:max_file_size]).to eq(15)
      expect(assigns(:settings)[:allowed_file_types]).to eq('jpg,png,pdf')
      expect(assigns(:settings)[:enable_cdn]).to be true
      expect(assigns(:settings)[:cdn_url]).to eq('https://cdn.example.com')
      expect(assigns(:settings)[:auto_optimize_uploads]).to be false
    end

    it 'merges tenant settings with site settings' do
      tenant.update!(
        storage_type: 's3',
        storage_bucket: 'test-bucket',
        storage_region: 'us-west-2'
      )

      get :storage
      settings = assigns(:settings)
      expect(settings[:storage_type]).to eq('s3')
      expect(settings[:storage_bucket]).to eq('test-bucket')
      expect(settings[:storage_region]).to eq('us-west-2')
    end

    it 'requires admin access' do
      sign_in regular_user
      get :storage
      expect(response).to redirect_to(admin_root_path)
    end
  end

  describe 'PATCH #update_storage' do
    let(:storage_params) do
      {
        storage_type: 'local',
        settings: {
          local_storage_path: '/new/storage/path',
          max_file_size: '20',
          allowed_file_types: 'jpg,jpeg,png,gif,pdf,doc',
          enable_cdn: '1',
          cdn_url: 'https://new-cdn.example.com',
          auto_optimize_uploads: '0'
        }
      }
    end

    it 'updates storage settings successfully' do
      expect {
        patch :update_storage, params: storage_params
      }.to change { SiteSetting.get('local_storage_path') }.to('/new/storage/path')
        .and change { SiteSetting.get('max_file_size') }.to('20')
        .and change { SiteSetting.get('allowed_file_types') }.to('jpg,jpeg,png,gif,pdf,doc')
        .and change { SiteSetting.get('enable_cdn') }.to(true)
        .and change { SiteSetting.get('cdn_url') }.to('https://new-cdn.example.com')
        .and change { SiteSetting.get('auto_optimize_uploads') }.to(false)
    end

    it 'updates tenant storage configuration' do
      patch :update_storage, params: storage_params.merge(
        storage_type: 's3',
        storage_bucket: 'new-bucket',
        storage_region: 'us-east-1',
        storage_access_key: 'new-access-key',
        storage_secret_key: 'new-secret-key'
      )

      tenant.reload
      expect(tenant.storage_type).to eq('s3')
      expect(tenant.storage_bucket).to eq('new-bucket')
      expect(tenant.storage_region).to eq('us-east-1')
      expect(tenant.storage_access_key).to eq('new-access-key')
      expect(tenant.storage_secret_key).to eq('new-secret-key')
    end

    it 'applies storage configuration' do
      storage_config = instance_double(StorageConfigurationService)
      expect(StorageConfigurationService).to receive(:new).and_return(storage_config)
      expect(storage_config).to receive(:configure_active_storage)
      expect(storage_config).to receive(:update_storage_config)

      patch :update_storage, params: storage_params
    end

    it 'redirects to storage settings with success message' do
      patch :update_storage, params: storage_params
      expect(response).to redirect_to(admin_storage_settings_path)
      expect(flash[:notice]).to eq('Storage settings updated successfully.')
    end

    it 'handles storage configuration errors gracefully' do
      storage_config = instance_double(StorageConfigurationService)
      expect(StorageConfigurationService).to receive(:new).and_return(storage_config)
      expect(storage_config).to receive(:configure_active_storage).and_raise(StandardError.new('Configuration failed'))
      expect(storage_config).not_to receive(:update_storage_config)

      patch :update_storage, params: storage_params
      expect(response).to redirect_to(admin_storage_settings_path)
      expect(flash[:alert]).to include('Storage settings updated but configuration failed to apply')
    end

    it 'requires admin access' do
      sign_in regular_user
      patch :update_storage, params: storage_params
      expect(response).to redirect_to(admin_root_path)
    end

    context 'with S3 configuration' do
      let(:s3_params) do
        {
          storage_type: 's3',
          storage_bucket: 'test-bucket',
          storage_region: 'us-west-2',
          storage_access_key: 'access-key',
          storage_secret_key: 'secret-key',
          storage_endpoint: 'https://s3.amazonaws.com',
          storage_path: 'uploads/',
          settings: {
            max_file_size: '25',
            allowed_file_types: 'jpg,png,pdf,mp4',
            enable_cdn: '0',
            auto_optimize_uploads: '1'
          }
        }
      end

      it 'updates S3 settings correctly' do
        patch :update_storage, params: s3_params

        tenant.reload
        expect(tenant.storage_type).to eq('s3')
        expect(tenant.storage_bucket).to eq('test-bucket')
        expect(tenant.storage_region).to eq('us-west-2')
        expect(tenant.storage_access_key).to eq('access-key')
        expect(tenant.storage_secret_key).to eq('secret-key')
        expect(tenant.storage_endpoint).to eq('https://s3.amazonaws.com')
        expect(tenant.storage_path).to eq('uploads/')
      end

      it 'updates general settings for S3 storage' do
        patch :update_storage, params: s3_params

        expect(SiteSetting.get('max_file_size')).to eq('25')
        expect(SiteSetting.get('allowed_file_types')).to eq('jpg,png,pdf,mp4')
        expect(SiteSetting.get('enable_cdn')).to eq(false)
        expect(SiteSetting.get('auto_optimize_uploads')).to eq(true)
      end
    end

    context 'with invalid parameters' do
      it 'handles missing settings gracefully' do
        patch :update_storage, params: { storage_type: 'local' }
        expect(response).to redirect_to(admin_storage_settings_path)
        expect(flash[:notice]).to eq('Storage settings updated successfully.')
      end

      it 'handles empty settings' do
        patch :update_storage, params: { storage_type: 'local', settings: {} }
        expect(response).to redirect_to(admin_storage_settings_path)
        expect(flash[:notice]).to eq('Storage settings updated successfully.')
      end
    end
  end

  describe 'private methods' do
    describe '#load_storage_settings' do
      before do
        SiteSetting.set('storage_type', 'local', 'string')
        SiteSetting.set('local_storage_path', '/test/path', 'string')
        SiteSetting.set('max_file_size', 10, 'integer')
        SiteSetting.set('allowed_file_types', 'jpg,png', 'string')
        SiteSetting.set('enable_cdn', true, 'boolean')
        SiteSetting.set('cdn_url', 'https://test.com', 'string')
        SiteSetting.set('auto_optimize_uploads', false, 'boolean')
      end

      it 'loads all storage settings correctly' do
        controller.send(:load_storage_settings)
        settings = controller.instance_variable_get(:@settings)

        expect(settings[:storage_type]).to eq('local')
        expect(settings[:local_storage_path]).to eq('/test/path')
        expect(settings[:max_file_size]).to eq(10)
        expect(settings[:allowed_file_types]).to eq('jpg,png')
        expect(settings[:enable_cdn]).to be true
        expect(settings[:cdn_url]).to eq('https://test.com')
        expect(settings[:auto_optimize_uploads]).to be false
      end

      it 'merges tenant settings when available' do
        tenant.update!(
          storage_type: 's3',
          storage_bucket: 'tenant-bucket',
          storage_region: 'eu-west-1'
        )

        controller.send(:load_storage_settings)
        settings = controller.instance_variable_get(:@settings)

        expect(settings[:storage_type]).to eq('s3')
        expect(settings[:storage_bucket]).to eq('tenant-bucket')
        expect(settings[:storage_region]).to eq('eu-west-1')
      end
    end

    describe '#setting_type_for' do
      it 'returns correct types for boolean settings' do
        expect(controller.send(:setting_type_for, 'enable_cdn')).to eq('boolean')
        expect(controller.send(:setting_type_for, 'auto_optimize_uploads')).to eq('boolean')
        expect(controller.send(:setting_type_for, 'hide_branding')).to eq('boolean')
      end

      it 'returns correct types for integer settings' do
        expect(controller.send(:setting_type_for, 'max_file_size')).to eq('integer')
        expect(controller.send(:setting_type_for, 'posts_per_page')).to eq('integer')
        expect(controller.send(:setting_type_for, 'smtp_port')).to eq('integer')
      end

      it 'returns string for other settings' do
        expect(controller.send(:setting_type_for, 'storage_bucket')).to eq('string')
        expect(controller.send(:setting_type_for, 'cdn_url')).to eq('string')
        expect(controller.send(:setting_type_for, 'allowed_file_types')).to eq('string')
      end
    end
  end

  describe 'authentication and authorization' do
    it 'requires user authentication' do
      sign_out admin_user
      get :storage
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'requires admin role' do
      sign_in regular_user
      get :storage
      expect(response).to redirect_to(admin_root_path)
    end

    it 'allows administrators to access storage settings' do
      get :storage
      expect(response).to have_http_status(:success)
    end
  end

  describe 'multi-tenancy' do
    let(:other_tenant) { create(:tenant) }
    let(:other_admin) { create(:user, :administrator, tenant: other_tenant) }

    it 'scopes settings to current tenant' do
      ActsAsTenant.with_tenant(tenant) do
        SiteSetting.set('storage_type', 'local', 'string')
        get :storage
        expect(assigns(:settings)[:storage_type]).to eq('local')
      end

      ActsAsTenant.with_tenant(other_tenant) do
        SiteSetting.set('storage_type', 's3', 'string')
        get :storage
        expect(assigns(:settings)[:storage_type]).to eq('s3')
      end
    end
  end
end
