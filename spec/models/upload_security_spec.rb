require 'rails_helper'

RSpec.describe UploadSecurity, type: :model do
  let(:tenant) { create(:tenant) }
  let(:upload_security) { create(:upload_security, tenant: tenant) }

  describe 'associations' do
    it { should belong_to(:tenant) }
  end

  describe 'validations' do
    it { should validate_presence_of(:max_file_size) }
    it { should validate_numericality_of(:max_file_size).is_greater_than(0) }
  end

  describe 'callbacks' do
    it 'sets defaults on validation' do
      security = UploadSecurity.new(tenant: tenant)
      security.valid?
      
      expect(security.max_file_size).to eq(10.megabytes)
      expect(security.allowed_extensions).to eq(UploadSecurity::DEFAULT_ALLOWED_EXTENSIONS)
      expect(security.blocked_extensions).to eq(UploadSecurity::DEFAULT_BLOCKED_EXTENSIONS)
    end
  end

  describe '.current' do
    it 'returns existing upload security for current tenant' do
      ActsAsTenant.with_tenant(tenant) do
        expect(UploadSecurity.current).to eq(upload_security)
      end
    end

    it 'creates default upload security if none exists' do
      new_tenant = create(:tenant)
      ActsAsTenant.with_tenant(new_tenant) do
        expect { UploadSecurity.current }.to change { UploadSecurity.count }.by(1)
      end
    end
  end

  describe '.create_default!' do
    it 'creates upload security with default values' do
      new_tenant = create(:tenant)
      ActsAsTenant.with_tenant(new_tenant) do
        security = UploadSecurity.create_default!
        
        expect(security.max_file_size).to eq(10.megabytes)
        expect(security.allowed_extensions).to eq(UploadSecurity::DEFAULT_ALLOWED_EXTENSIONS)
        expect(security.blocked_extensions).to eq(UploadSecurity::DEFAULT_BLOCKED_EXTENSIONS)
        expect(security.scan_for_viruses).to be false
        expect(security.quarantine_suspicious).to be true
        expect(security.auto_approve_trusted).to be false
      end
    end
  end

  describe '#max_file_size_human' do
    it 'returns human readable file size' do
      upload_security.max_file_size = 5.megabytes
      expect(upload_security.max_file_size_human).to eq('5 MB')
    end
  end

  describe '#max_file_size_human=' do
    it 'parses human readable file size' do
      upload_security.max_file_size_human = '10 MB'
      expect(upload_security.max_file_size).to eq(10.megabytes)
    end

    it 'handles different units' do
      upload_security.max_file_size_human = '1 GB'
      expect(upload_security.max_file_size).to eq(1.gigabyte)
      
      upload_security.max_file_size_human = '500 KB'
      expect(upload_security.max_file_size).to eq(500.kilobytes)
    end
  end

  describe '#allowed_extensions_list' do
    it 'returns comma-separated list of allowed extensions' do
      upload_security.allowed_extensions = ['jpg', 'png', 'pdf']
      expect(upload_security.allowed_extensions_list).to eq('jpg, png, pdf')
    end
  end

  describe '#allowed_extensions_list=' do
    it 'sets allowed extensions from comma-separated string' do
      upload_security.allowed_extensions_list = 'jpg, png, pdf, doc'
      expect(upload_security.allowed_extensions).to eq(['jpg', 'png', 'pdf', 'doc'])
    end

    it 'handles whitespace and case' do
      upload_security.allowed_extensions_list = ' JPG, PNG , PDF '
      expect(upload_security.allowed_extensions).to eq(['jpg', 'png', 'pdf'])
    end
  end

  describe '#blocked_extensions_list' do
    it 'returns comma-separated list of blocked extensions' do
      upload_security.blocked_extensions = ['exe', 'bat', 'sh']
      expect(upload_security.blocked_extensions_list).to eq('exe, bat, sh')
    end
  end

  describe '#blocked_extensions_list=' do
    it 'sets blocked extensions from comma-separated string' do
      upload_security.blocked_extensions_list = 'exe, bat, cmd, sh'
      expect(upload_security.blocked_extensions).to eq(['exe', 'bat', 'cmd', 'sh'])
    end
  end

  describe '#get_storage_settings' do
    before do
      SiteSetting.set('max_file_size', 15, 'integer')
      SiteSetting.set('allowed_file_types', 'jpg,png,pdf,doc', 'string')
      SiteSetting.set('storage_type', 'local', 'string')
      SiteSetting.set('local_storage_path', '/custom/path', 'string')
      SiteSetting.set('enable_cdn', true, 'boolean')
      SiteSetting.set('cdn_url', 'https://cdn.example.com', 'string')
      SiteSetting.set('auto_optimize_uploads', false, 'boolean')
    end

    it 'returns storage settings from SiteSetting' do
      settings = upload_security.get_storage_settings
      
      expect(settings[:max_file_size]).to eq(15)
      expect(settings[:allowed_file_types]).to eq('jpg,png,pdf,doc')
      expect(settings[:storage_type]).to eq('local')
      expect(settings[:local_storage_path]).to eq('/custom/path')
      expect(settings[:enable_cdn]).to be true
      expect(settings[:cdn_url]).to eq('https://cdn.example.com')
      expect(settings[:auto_optimize_uploads]).to be false
    end
  end

  describe '#file_allowed?' do
    let(:valid_file) { double('file', size: 5.megabytes, original_filename: 'test.jpg', content_type: 'image/jpeg') }
    let(:large_file) { double('file', size: 20.megabytes, original_filename: 'large.jpg', content_type: 'image/jpeg') }
    let(:blocked_extension_file) { double('file', size: 1.megabyte, original_filename: 'test.exe', content_type: 'application/x-executable') }
    let(:disallowed_extension_file) { double('file', size: 1.megabyte, original_filename: 'test.txt', content_type: 'text/plain') }

    before do
      # Set up storage settings
      SiteSetting.set('max_file_size', 10, 'integer')
      SiteSetting.set('allowed_file_types', 'jpg,png,pdf', 'string')
      
      # Set up upload security settings
      upload_security.update!(
        max_file_size: 15.megabytes,
        allowed_extensions: ['jpg', 'png', 'pdf'],
        blocked_extensions: ['exe', 'bat', 'sh']
      )
    end

    it 'allows valid files' do
      expect(upload_security.file_allowed?(valid_file)).to be true
    end

    it 'rejects files that exceed storage settings max size' do
      expect(upload_security.file_allowed?(large_file)).to be false
    end

    it 'rejects files with blocked extensions' do
      expect(upload_security.file_allowed?(blocked_extension_file)).to be false
    end

    it 'rejects files with extensions not in storage settings allowed list' do
      expect(upload_security.file_allowed?(disallowed_extension_file)).to be false
    end

    it 'handles nil file' do
      expect(upload_security.file_allowed?(nil)).to be false
    end

    it 'uses the more restrictive file size limit' do
      # Storage settings: 10MB, Upload security: 15MB -> should use 10MB
      SiteSetting.set('max_file_size', 10, 'integer')
      upload_security.update!(max_file_size: 15.megabytes)
      
      file_12mb = double('file', size: 12.megabytes, original_filename: 'test.jpg', content_type: 'image/jpeg')
      expect(upload_security.file_allowed?(file_12mb)).to be false
    end

    it 'prioritizes storage settings file types over upload security' do
      # Storage settings only allow jpg,png,pdf
      # Upload security allows jpg,png,pdf,doc
      # Should reject doc files because storage settings are more restrictive
      SiteSetting.set('allowed_file_types', 'jpg,png,pdf', 'string')
      upload_security.update!(allowed_extensions: ['jpg', 'png', 'pdf', 'doc'])
      
      doc_file = double('file', size: 1.megabyte, original_filename: 'test.doc', content_type: 'application/msword')
      expect(upload_security.file_allowed?(doc_file)).to be false
    end

    it 'checks MIME types when available' do
      # File has allowed extension but blocked MIME type
      upload_security.update!(blocked_mime_types: ['image/jpeg'])
      
      expect(upload_security.file_allowed?(valid_file)).to be false
    end

    it 'allows files with allowed MIME types' do
      upload_security.update!(allowed_mime_types: ['image/jpeg', 'image/png'])
      
      expect(upload_security.file_allowed?(valid_file)).to be true
    end
  end

  describe '#file_suspicious?' do
    let(:normal_file) { double('file', original_filename: 'test.jpg') }
    let(:double_extension_file) { double('file', original_filename: 'test.jpg.exe') }
    let(:suspicious_image_file) { double('file', original_filename: 'image.jpg.bat') }
    let(:suspicious_pdf_file) { double('file', original_filename: 'document.pdf.exe') }

    before do
      upload_security.update!(quarantine_suspicious: true)
    end

    it 'returns false when quarantine is disabled' do
      upload_security.update!(quarantine_suspicious: false)
      expect(upload_security.file_suspicious?(double_extension_file)).to be false
    end

    it 'returns false for normal files' do
      expect(upload_security.file_suspicious?(normal_file)).to be false
    end

    it 'detects double extensions' do
      expect(upload_security.file_suspicious?(double_extension_file)).to be true
    end

    it 'detects suspicious image patterns' do
      expect(upload_security.file_suspicious?(suspicious_image_file)).to be true
    end

    it 'detects suspicious PDF patterns' do
      expect(upload_security.file_suspicious?(suspicious_pdf_file)).to be true
    end

    it 'handles nil file' do
      expect(upload_security.file_suspicious?(nil)).to be false
    end
  end

  describe '#update_global_settings' do
    it 'updates Rails application config' do
      upload_security.update!(
        max_file_size: 20.megabytes,
        allowed_extensions: ['jpg', 'png'],
        blocked_extensions: ['exe', 'bat']
      )

      expect(Rails.application.config.upload_security[:max_file_size]).to eq(20.megabytes)
      expect(Rails.application.config.upload_security[:allowed_extensions]).to eq(['jpg', 'png'])
      expect(Rails.application.config.upload_security[:blocked_extensions]).to eq(['exe', 'bat'])
    end
  end

  describe 'integration with storage settings' do
    before do
      SiteSetting.set('max_file_size', 5, 'integer')
      SiteSetting.set('allowed_file_types', 'jpg,png', 'string')
    end

    it 'enforces storage settings limits' do
      file_8mb = double('file', size: 8.megabytes, original_filename: 'test.jpg', content_type: 'image/jpeg')
      expect(upload_security.file_allowed?(file_8mb)).to be false
    end

    it 'enforces storage settings file types' do
      pdf_file = double('file', size: 1.megabyte, original_filename: 'test.pdf', content_type: 'application/pdf')
      expect(upload_security.file_allowed?(pdf_file)).to be false
    end

    it 'allows files that meet both storage and security requirements' do
      valid_file = double('file', size: 2.megabytes, original_filename: 'test.jpg', content_type: 'image/jpeg')
      expect(upload_security.file_allowed?(valid_file)).to be true
    end
  end
end