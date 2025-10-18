require 'rails_helper'

RSpec.describe StorageConfigurationService, type: :service do
  let(:tenant) { create(:tenant) }
  let(:service) { described_class.new(tenant) }

  describe '#initialize' do
    it 'loads storage settings correctly' do
      expect(service.storage_settings).to be_a(Hash)
      expect(service.storage_settings).to include(:storage_type, :local_storage_path, :max_file_size)
    end

    it 'uses current tenant when no tenant provided' do
      ActsAsTenant.with_tenant(tenant) do
        service = described_class.new
        expect(service.storage_settings).to be_a(Hash)
      end
    end
  end

  describe '#storage_settings' do
    before do
      SiteSetting.set('storage_type', 'local', 'string')
      SiteSetting.set('local_storage_path', '/custom/path', 'string')
      SiteSetting.set('max_file_size', 25, 'integer')
      SiteSetting.set('allowed_file_types', 'jpg,png,pdf', 'string')
      SiteSetting.set('enable_cdn', true, 'boolean')
      SiteSetting.set('cdn_url', 'https://cdn.example.com', 'string')
    end

    it 'returns correct storage settings' do
      settings = service.storage_settings
      
      expect(settings[:storage_type]).to eq('local')
      expect(settings[:local_storage_path]).to eq('/custom/path')
      expect(settings[:max_file_size]).to eq(25)
      expect(settings[:allowed_file_types]).to eq('jpg,png,pdf')
      expect(settings[:enable_cdn]).to be true
      expect(settings[:cdn_url]).to eq('https://cdn.example.com')
    end

    it 'merges tenant settings with site settings' do
      tenant.update!(
        storage_type: 's3',
        storage_bucket: 'test-bucket',
        storage_region: 'us-west-2'
      )

      settings = service.storage_settings
      expect(settings[:storage_type]).to eq('s3')
      expect(settings[:storage_bucket]).to eq('test-bucket')
      expect(settings[:storage_region]).to eq('us-west-2')
    end
  end

  describe '#storage_service_name' do
    it 'returns correct service name for local storage' do
      SiteSetting.set('storage_type', 'local', 'string')
      expect(service.storage_service_name).to eq('local')
    end

    it 'returns correct service name for S3 storage' do
      SiteSetting.set('storage_type', 's3', 'string')
      expect(service.storage_service_name).to eq('amazon')
    end

    it 'defaults to local storage' do
      SiteSetting.set('storage_type', 'invalid', 'string')
      expect(service.storage_service_name).to eq('local')
    end
  end

  describe '#local_storage_root' do
    it 'returns custom storage path when set' do
      SiteSetting.set('local_storage_path', '/custom/storage', 'string')
      expect(service.local_storage_root).to eq('/custom/storage')
    end

    it 'returns default path when not set' do
      SiteSetting.set('local_storage_path', '', 'string')
      expect(service.local_storage_root).to eq(Rails.root.join('storage').to_s)
    end
  end

  describe '#cdn_enabled?' do
    it 'returns true when CDN is enabled and URL is set' do
      SiteSetting.set('enable_cdn', true, 'boolean')
      SiteSetting.set('cdn_url', 'https://cdn.example.com', 'string')
      expect(service.cdn_enabled?).to be true
    end

    it 'returns false when CDN is disabled' do
      SiteSetting.set('enable_cdn', false, 'boolean')
      SiteSetting.set('cdn_url', 'https://cdn.example.com', 'string')
      expect(service.cdn_enabled?).to be false
    end

    it 'returns false when CDN URL is not set' do
      SiteSetting.set('enable_cdn', true, 'boolean')
      SiteSetting.set('cdn_url', '', 'string')
      expect(service.cdn_enabled?).to be false
    end
  end

  describe '#cdn_url' do
    it 'returns CDN URL when enabled' do
      SiteSetting.set('enable_cdn', true, 'boolean')
      SiteSetting.set('cdn_url', 'https://cdn.example.com', 'string')
      expect(service.cdn_url).to eq('https://cdn.example.com')
    end

    it 'returns nil when CDN is disabled' do
      SiteSetting.set('enable_cdn', false, 'boolean')
      expect(service.cdn_url).to be_nil
    end
  end

  describe '#auto_optimize_enabled?' do
    it 'returns true when auto-optimize is enabled' do
      SiteSetting.set('auto_optimize_uploads', true, 'boolean')
      expect(service.auto_optimize_enabled?).to be true
    end

    it 'returns false when auto-optimize is disabled' do
      SiteSetting.set('auto_optimize_uploads', false, 'boolean')
      expect(service.auto_optimize_enabled?).to be false
    end
  end

  describe '#max_file_size_bytes' do
    it 'converts MB to bytes correctly' do
      SiteSetting.set('max_file_size', 10, 'integer')
      expect(service.max_file_size_bytes).to eq(10 * 1024 * 1024)
    end
  end

  describe '#allowed_file_types' do
    it 'returns array of allowed file types' do
      SiteSetting.set('allowed_file_types', 'jpg,png,pdf,doc', 'string')
      expect(service.allowed_file_types).to eq(['jpg', 'png', 'pdf', 'doc'])
    end

    it 'handles empty string' do
      SiteSetting.set('allowed_file_types', '', 'string')
      expect(service.allowed_file_types).to eq([])
    end

    it 'strips whitespace and converts to lowercase' do
      SiteSetting.set('allowed_file_types', ' JPG, PNG , PDF ', 'string')
      expect(service.allowed_file_types).to eq(['jpg', 'png', 'pdf'])
    end
  end

  describe '#file_allowed?' do
    let(:mock_file) { double('file', size: 5 * 1024 * 1024, original_filename: 'test.jpg') }

    before do
      SiteSetting.set('max_file_size', 10, 'integer')
      SiteSetting.set('allowed_file_types', 'jpg,png,pdf', 'string')
    end

    it 'allows valid files' do
      expect(service.file_allowed?(mock_file)).to be true
    end

    it 'rejects files that are too large' do
      large_file = double('file', size: 20 * 1024 * 1024, original_filename: 'large.jpg')
      expect(service.file_allowed?(large_file)).to be false
    end

    it 'rejects files with disallowed extensions' do
      disallowed_file = double('file', size: 1 * 1024 * 1024, original_filename: 'test.exe')
      expect(service.file_allowed?(disallowed_file)).to be false
    end

    it 'handles nil file' do
      expect(service.file_allowed?(nil)).to be false
    end
  end

  describe '#s3_config' do
    before do
      SiteSetting.set('storage_type', 's3', 'string')
      SiteSetting.set('storage_bucket', 'test-bucket', 'string')
      SiteSetting.set('storage_region', 'us-west-2', 'string')
      SiteSetting.set('storage_access_key', 'access-key', 'string')
      SiteSetting.set('storage_secret_key', 'secret-key', 'string')
      SiteSetting.set('storage_endpoint', 'https://s3.amazonaws.com', 'string')
      SiteSetting.set('storage_path', 'uploads/', 'string')
    end

    it 'returns S3 configuration when storage type is S3' do
      config = service.s3_config
      
      expect(config[:service]).to eq('S3')
      expect(config[:access_key_id]).to eq('access-key')
      expect(config[:secret_access_key]).to eq('secret-key')
      expect(config[:region]).to eq('us-west-2')
      expect(config[:bucket]).to eq('test-bucket')
      expect(config[:endpoint]).to eq('https://s3.amazonaws.com')
      expect(config[:path]).to eq('uploads/')
    end

    it 'returns empty hash when storage type is not S3' do
      SiteSetting.set('storage_type', 'local', 'string')
      expect(service.s3_config).to eq({})
    end

    it 'excludes nil values from config' do
      SiteSetting.set('storage_endpoint', '', 'string')
      SiteSetting.set('storage_path', '', 'string')
      
      config = service.s3_config
      expect(config).not_to have_key(:endpoint)
      expect(config).not_to have_key(:path)
    end
  end

  describe '#configure_active_storage' do
    it 'configures local storage' do
      SiteSetting.set('storage_type', 'local', 'string')
      SiteSetting.set('local_storage_path', '/tmp/test-storage', 'string')
      
      expect(FileUtils).to receive(:mkdir_p).with('/tmp/test-storage')
      expect(FileUtils).to receive(:chmod).with(0755, '/tmp/test-storage')
      
      service.configure_active_storage
    end

    it 'configures S3 storage' do
      SiteSetting.set('storage_type', 's3', 'string')
      
      # S3 configuration doesn't require file system operations
      expect { service.configure_active_storage }.not_to raise_error
    end
  end

  describe '#update_storage_config' do
    let(:storage_yml_path) { Rails.root.join('config', 'storage.yml') }
    let(:backup_path) { Rails.root.join('config', 'storage.yml.backup') }

    before do
      # Backup existing storage.yml if it exists
      if File.exist?(storage_yml_path)
        FileUtils.cp(storage_yml_path, backup_path)
      end
    end

    after do
      # Restore backup if it existed
      if File.exist?(backup_path)
        FileUtils.mv(backup_path, storage_yml_path)
      elsif File.exist?(storage_yml_path)
        File.delete(storage_yml_path)
      end
    end

    it 'updates storage.yml for local storage' do
      SiteSetting.set('storage_type', 'local', 'string')
      SiteSetting.set('local_storage_path', '/custom/storage', 'string')
      
      service.update_storage_config
      
      expect(File.exist?(storage_yml_path)).to be true
      config = YAML.load_file(storage_yml_path)
      expect(config['local']['service']).to eq('Disk')
      expect(config['local']['root']).to eq('/custom/storage')
    end

    it 'updates storage.yml for S3 storage' do
      SiteSetting.set('storage_type', 's3', 'string')
      SiteSetting.set('storage_bucket', 'test-bucket', 'string')
      SiteSetting.set('storage_region', 'us-west-2', 'string')
      SiteSetting.set('storage_access_key', 'access-key', 'string')
      SiteSetting.set('storage_secret_key', 'secret-key', 'string')
      
      service.update_storage_config
      
      expect(File.exist?(storage_yml_path)).to be true
      config = YAML.load_file(storage_yml_path)
      expect(config['amazon']['service']).to eq('S3')
      expect(config['amazon']['bucket']).to eq('test-bucket')
      expect(config['amazon']['region']).to eq('us-west-2')
    end
  end
end
