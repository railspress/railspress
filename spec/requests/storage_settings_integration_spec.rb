require 'rails_helper'

RSpec.describe 'Storage Settings Integration', type: :request do
  let(:tenant) { create(:tenant) }
  let(:admin_user) { create(:user, :administrator, tenant: tenant) }
  let(:author_user) { create(:user, :author, tenant: tenant) }

  before do
    ActsAsTenant.with_tenant(tenant) do
      sign_in admin_user
    end
  end

  describe 'Storage Settings Flow' do
    context 'when accessing storage settings page' do
      it 'loads storage settings successfully' do
        get admin_storage_settings_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Storage Settings')
        expect(response.body).to include('Storage Provider')
        expect(response.body).to include('Local Storage')
        expect(response.body).to include('Amazon S3')
      end

      it 'shows current storage configuration' do
        SiteSetting.set('storage_type', 'local', 'string')
        SiteSetting.set('local_storage_path', '/custom/path', 'string')
        SiteSetting.set('max_file_size', 20, 'integer')

        get admin_storage_settings_path
        expect(response.body).to include('value="local"')
        expect(response.body).to include('value="/custom/path"')
        expect(response.body).to include('value="20"')
      end

      it 'shows S3 configuration when S3 is selected' do
        SiteSetting.set('storage_type', 's3', 'string')
        tenant.update!(
          storage_bucket: 'test-bucket',
          storage_region: 'us-west-2'
        )

        get admin_storage_settings_path
        expect(response.body).to include('value="s3"')
        expect(response.body).to include('S3 Configuration')
      end
    end

    context 'when updating storage settings' do
      let(:storage_params) do
        {
          storage_type: 'local',
          settings: {
            local_storage_path: '/new/storage/path',
            max_file_size: '25',
            allowed_file_types: 'jpg,jpeg,png,gif,pdf,doc,mp4',
            enable_cdn: '1',
            cdn_url: 'https://cdn.example.com',
            auto_optimize_uploads: '0'
          }
        }
      end

      it 'updates storage settings and redirects' do
        patch admin_storage_settings_path, params: storage_params
        expect(response).to redirect_to(admin_storage_settings_path)
        expect(flash[:notice]).to eq('Storage settings updated successfully.')
      end

      it 'persists settings in database' do
        expect {
          patch admin_storage_settings_path, params: storage_params
        }.to change { SiteSetting.get('local_storage_path') }.to('/new/storage/path')
          .and change { SiteSetting.get('max_file_size') }.to('25')
          .and change { SiteSetting.get('allowed_file_types') }.to('jpg,jpeg,png,gif,pdf,doc,mp4')
          .and change { SiteSetting.get('enable_cdn') }.to(true)
          .and change { SiteSetting.get('cdn_url') }.to('https://cdn.example.com')
          .and change { SiteSetting.get('auto_optimize_uploads') }.to(false)
      end

      it 'updates tenant storage configuration for S3' do
        s3_params = storage_params.merge(
          storage_type: 's3',
          storage_bucket: 'new-bucket',
          storage_region: 'us-east-1',
          storage_access_key: 'access-key',
          storage_secret_key: 'secret-key'
        )

        patch admin_storage_settings_path, params: s3_params

        tenant.reload
        expect(tenant.storage_type).to eq('s3')
        expect(tenant.storage_bucket).to eq('new-bucket')
        expect(tenant.storage_region).to eq('us-east-1')
        expect(tenant.storage_access_key).to eq('access-key')
        expect(tenant.storage_secret_key).to eq('secret-key')
      end
    end
  end

  describe 'Upload Flow with Storage Settings' do
    let(:upload_params) do
      {
        medium: {
          title: 'Test Upload',
          file: fixture_file_upload('spec/fixtures/test_image.jpg', 'image/jpeg')
        }
      }
    end

    before do
      # Set up storage settings
      SiteSetting.set('max_file_size', 10, 'integer')
      SiteSetting.set('allowed_file_types', 'jpg,jpeg,png,gif', 'string')
      SiteSetting.set('storage_type', 'local', 'string')
      SiteSetting.set('local_storage_path', Rails.root.join('tmp', 'test_storage').to_s, 'string')
    end

    context 'when uploading valid files' do
      it 'creates upload successfully' do
        expect {
          post api_v1_media_index_path, params: upload_params
        }.to change { Upload.count }.by(1)
          .and change { Medium.count }.by(1)

        expect(response).to have_http_status(:created)
      end

      it 'respects storage settings for file validation' do
        # Test with file that exceeds storage settings limit
        large_file_params = upload_params.dup
        large_file_params[:medium][:file] = fixture_file_upload('spec/fixtures/large_file.jpg', 'image/jpeg')

        # Mock file size to exceed limit
        allow_any_instance_of(ActionDispatch::Http::UploadedFile).to receive(:size).and_return(15.megabytes)

        post api_v1_media_index_path, params: large_file_params
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['error']).to eq('File not allowed')
      end

      it 'respects allowed file types from storage settings' do
        # Test with disallowed file type
        disallowed_file_params = upload_params.dup
        disallowed_file_params[:medium][:file] = fixture_file_upload('spec/fixtures/test_document.pdf', 'application/pdf')

        post api_v1_media_index_path, params: disallowed_file_params
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['error']).to eq('File not allowed')
      end
    end

    context 'when CDN is enabled' do
      before do
        SiteSetting.set('enable_cdn', true, 'boolean')
        SiteSetting.set('cdn_url', 'https://cdn.example.com', 'string')
      end

      it 'generates CDN URLs for uploaded files' do
        post api_v1_media_index_path, params: upload_params
        expect(response).to have_http_status(:created)

        upload = Upload.last
        expect(upload.url).to start_with('https://cdn.example.com')
      end
    end

    context 'when auto-optimization is enabled' do
      before do
        SiteSetting.set('auto_optimize_uploads', true, 'boolean')
      end

      it 'processes uploads with optimization' do
        # This would test the optimization pipeline if implemented
        post api_v1_media_index_path, params: upload_params
        expect(response).to have_http_status(:created)
      end
    end
  end

  describe 'Storage Configuration Service Integration' do
    it 'configures ActiveStorage based on settings' do
      SiteSetting.set('storage_type', 'local', 'string')
      SiteSetting.set('local_storage_path', '/tmp/test_storage', 'string')

      storage_config = StorageConfigurationService.new
      expect(storage_config.storage_service_name).to eq('local')
      expect(storage_config.local_storage_root).to eq('/tmp/test_storage')
    end

    it 'validates files against storage settings' do
      SiteSetting.set('max_file_size', 5, 'integer')
      SiteSetting.set('allowed_file_types', 'jpg,png', 'string')

      storage_config = StorageConfigurationService.new
      
      # Valid file
      valid_file = double('file', size: 2.megabytes, original_filename: 'test.jpg')
      expect(storage_config.file_allowed?(valid_file)).to be true

      # File too large
      large_file = double('file', size: 10.megabytes, original_filename: 'test.jpg')
      expect(storage_config.file_allowed?(large_file)).to be false

      # Disallowed file type
      disallowed_file = double('file', size: 1.megabyte, original_filename: 'test.pdf')
      expect(storage_config.file_allowed?(disallowed_file)).to be false
    end
  end

  describe 'UploadSecurity Integration' do
    let(:upload_security) { UploadSecurity.current }

    before do
      SiteSetting.set('max_file_size', 8, 'integer')
      SiteSetting.set('allowed_file_types', 'jpg,png,pdf', 'string')
    end

    it 'uses storage settings for file validation' do
      # File that meets storage settings but exceeds upload security default
      file = double('file', size: 6.megabytes, original_filename: 'test.jpg', content_type: 'image/jpeg')
      
      # Should be allowed because it meets storage settings (8MB limit)
      expect(upload_security.file_allowed?(file)).to be true
    end

    it 'uses the more restrictive file size limit' do
      # Set upload security to be more restrictive
      upload_security.update!(max_file_size: 3.megabytes)
      
      file = double('file', size: 5.megabytes, original_filename: 'test.jpg', content_type: 'image/jpeg')
      
      # Should be rejected because upload security limit (3MB) is more restrictive
      expect(upload_security.file_allowed?(file)).to be false
    end

    it 'enforces storage settings file types' do
      file = double('file', size: 1.megabyte, original_filename: 'test.doc', content_type: 'application/msword')
      
      # Should be rejected because doc is not in storage settings allowed types
      expect(upload_security.file_allowed?(file)).to be false
    end
  end

  describe 'Multi-tenant Storage Settings' do
    let(:other_tenant) { create(:tenant) }
    let(:other_admin) { create(:user, :administrator, tenant: other_tenant) }

    it 'isolates storage settings between tenants' do
      ActsAsTenant.with_tenant(tenant) do
        SiteSetting.set('storage_type', 'local', 'string')
        SiteSetting.set('max_file_size', 10, 'integer')
      end

      ActsAsTenant.with_tenant(other_tenant) do
        SiteSetting.set('storage_type', 's3', 'string')
        SiteSetting.set('max_file_size', 20, 'integer')
      end

      ActsAsTenant.with_tenant(tenant) do
        expect(SiteSetting.get('storage_type')).to eq('local')
        expect(SiteSetting.get('max_file_size')).to eq('10')
      end

      ActsAsTenant.with_tenant(other_tenant) do
        expect(SiteSetting.get('storage_type')).to eq('s3')
        expect(SiteSetting.get('max_file_size')).to eq('20')
      end
    end

    it 'allows different storage configurations per tenant' do
      ActsAsTenant.with_tenant(tenant) do
        tenant.update!(storage_type: 'local')
        storage_config = StorageConfigurationService.new
        expect(storage_config.storage_service_name).to eq('local')
      end

      ActsAsTenant.with_tenant(other_tenant) do
        other_tenant.update!(storage_type: 's3', storage_bucket: 'other-bucket')
        storage_config = StorageConfigurationService.new
        expect(storage_config.storage_service_name).to eq('amazon')
        expect(storage_config.storage_settings[:storage_bucket]).to eq('other-bucket')
      end
    end
  end

  describe 'Error Handling' do
    it 'handles storage configuration errors gracefully' do
      # Mock storage configuration to raise an error
      allow_any_instance_of(StorageConfigurationService).to receive(:configure_active_storage).and_raise(StandardError.new('Config failed'))

      storage_params = {
        storage_type: 'local',
        settings: { local_storage_path: '/test/path' }
      }

      patch admin_storage_settings_path, params: storage_params
      expect(response).to redirect_to(admin_storage_settings_path)
      expect(flash[:alert]).to include('configuration failed to apply')
    end

    it 'handles invalid storage settings' do
      invalid_params = {
        storage_type: 'invalid_type',
        settings: { max_file_size: 'invalid_size' }
      }

      patch admin_storage_settings_path, params: invalid_params
      expect(response).to redirect_to(admin_storage_settings_path)
      # Settings should still be updated even if configuration fails
    end
  end

  describe 'Authorization' do
    it 'requires admin access for storage settings' do
      sign_in author_user
      
      get admin_storage_settings_path
      expect(response).to redirect_to(admin_root_path)
      
      patch admin_storage_settings_path, params: { storage_type: 'local' }
      expect(response).to redirect_to(admin_root_path)
    end

    it 'allows administrators to manage storage settings' do
      get admin_storage_settings_path
      expect(response).to have_http_status(:success)
      
      patch admin_storage_settings_path, params: { storage_type: 'local' }
      expect(response).to redirect_to(admin_storage_settings_path)
    end
  end
end
