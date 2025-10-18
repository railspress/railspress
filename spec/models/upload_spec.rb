require 'rails_helper'

RSpec.describe Upload, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:upload) { create(:upload, user: user, tenant: tenant) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:tenant) }
    it { should belong_to(:storage_provider).optional }
    it { should have_many(:media).dependent(:destroy) }
    it { should have_one_attached(:file) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:file) }
  end

  describe 'scopes' do
    let!(:image_upload) { create(:upload, :with_image, user: user, tenant: tenant) }
    let!(:video_upload) { create(:upload, :with_video, user: user, tenant: tenant) }
    let!(:document_upload) { create(:upload, :with_document, user: user, tenant: tenant) }
    let!(:quarantined_upload) { create(:upload, :quarantined, user: user, tenant: tenant) }

    describe '.images' do
      it 'returns only image uploads' do
        expect(Upload.images).to include(image_upload)
        expect(Upload.images).not_to include(video_upload, document_upload)
      end
    end

    describe '.videos' do
      it 'returns only video uploads' do
        expect(Upload.videos).to include(video_upload)
        expect(Upload.videos).not_to include(image_upload, document_upload)
      end
    end

    describe '.documents' do
      it 'returns only document uploads' do
        expect(Upload.documents).to include(document_upload)
        expect(Upload.documents).not_to include(image_upload, video_upload)
      end
    end

    describe '.quarantined' do
      it 'returns only quarantined uploads' do
        expect(Upload.quarantined).to include(quarantined_upload)
        expect(Upload.quarantined).not_to include(image_upload, video_upload, document_upload)
      end
    end

    describe '.approved' do
      it 'returns only approved uploads' do
        expect(Upload.approved).to include(image_upload, video_upload, document_upload)
        expect(Upload.approved).not_to include(quarantined_upload)
      end
    end

    describe '.recent' do
      it 'returns uploads ordered by creation date' do
        expect(Upload.recent.first).to eq(quarantined_upload)
      end
    end
  end

  describe 'callbacks' do
    it 'triggers upload hooks after commit' do
      expect(Railspress::PluginSystem).to receive(:do_action).with('upload_created', instance_of(Upload))
      expect(Railspress::PluginSystem).to receive(:do_action).with('upload_updated', instance_of(Upload))
      
      create(:upload, user: user, tenant: tenant)
    end

    it 'configures storage before validation' do
      expect_any_instance_of(StorageConfigurationService).to receive(:configure_active_storage)
      create(:upload, user: user, tenant: tenant)
    end
  end

  describe 'file type methods' do
    describe '#image?' do
      it 'returns true for image files' do
        image_upload = create(:upload, :with_image, user: user, tenant: tenant)
        expect(image_upload.image?).to be true
      end

      it 'returns false for non-image files' do
        video_upload = create(:upload, :with_video, user: user, tenant: tenant)
        expect(video_upload.image?).to be false
      end

      it 'returns false when no file is attached' do
        upload_without_file = build(:upload, user: user, tenant: tenant)
        upload_without_file.file = nil
        expect(upload_without_file.image?).to be false
      end
    end

    describe '#video?' do
      it 'returns true for video files' do
        video_upload = create(:upload, :with_video, user: user, tenant: tenant)
        expect(video_upload.video?).to be true
      end

      it 'returns false for non-video files' do
        image_upload = create(:upload, :with_image, user: user, tenant: tenant)
        expect(image_upload.video?).to be false
      end
    end

    describe '#document?' do
      it 'returns true for document files' do
        document_upload = create(:upload, :with_document, user: user, tenant: tenant)
        expect(document_upload.document?).to be true
      end

      it 'returns false for non-document files' do
        image_upload = create(:upload, :with_image, user: user, tenant: tenant)
        expect(image_upload.document?).to be false
      end
    end
  end

  describe 'file information methods' do
    let(:image_upload) { create(:upload, :with_image, user: user, tenant: tenant) }

    describe '#file_size' do
      it 'returns file size in bytes' do
        expect(image_upload.file_size).to be > 0
      end

      it 'returns 0 when no file is attached' do
        upload_without_file = build(:upload, user: user, tenant: tenant)
        upload_without_file.file = nil
        expect(upload_without_file.file_size).to eq(0)
      end
    end

    describe '#content_type' do
      it 'returns content type of attached file' do
        expect(image_upload.content_type).to start_with('image/')
      end

      it 'returns nil when no file is attached' do
        upload_without_file = build(:upload, user: user, tenant: tenant)
        upload_without_file.file = nil
        expect(upload_without_file.content_type).to be_nil
      end
    end

    describe '#filename' do
      it 'returns filename of attached file' do
        expect(image_upload.filename).to be_present
      end

      it 'returns nil when no file is attached' do
        upload_without_file = build(:upload, user: user, tenant: tenant)
        upload_without_file.file = nil
        expect(upload_without_file.filename).to be_nil
      end
    end
  end

  describe '#url' do
    let(:image_upload) { create(:upload, :with_image, user: user, tenant: tenant) }

    context 'when CDN is disabled' do
      before do
        SiteSetting.set('enable_cdn', false, 'boolean')
      end

      it 'returns regular Rails blob path' do
        expected_path = Rails.application.routes.url_helpers.rails_blob_path(image_upload.file, only_path: true)
        expect(image_upload.url).to eq(expected_path)
      end
    end

    context 'when CDN is enabled' do
      before do
        SiteSetting.set('enable_cdn', true, 'boolean')
        SiteSetting.set('cdn_url', 'https://cdn.example.com', 'string')
      end

      it 'returns CDN URL with blob path' do
        blob_path = Rails.application.routes.url_helpers.rails_blob_path(image_upload.file, only_path: true)
        expected_url = "https://cdn.example.com#{blob_path}"
        expect(image_upload.url).to eq(expected_url)
      end
    end

    context 'when CDN URL has trailing slash' do
      before do
        SiteSetting.set('enable_cdn', true, 'boolean')
        SiteSetting.set('cdn_url', 'https://cdn.example.com/', 'string')
      end

      it 'removes trailing slash from CDN URL' do
        blob_path = Rails.application.routes.url_helpers.rails_blob_path(image_upload.file, only_path: true)
        expected_url = "https://cdn.example.com#{blob_path}"
        expect(image_upload.url).to eq(expected_url)
      end
    end

    it 'returns nil when no file is attached' do
      upload_without_file = build(:upload, user: user, tenant: tenant)
      upload_without_file.file = nil
      expect(upload_without_file.url).to be_nil
    end
  end

  describe 'quarantine methods' do
    let(:quarantined_upload) { create(:upload, :quarantined, user: user, tenant: tenant) }
    let(:approved_upload) { create(:upload, user: user, tenant: tenant) }

    describe '#quarantined?' do
      it 'returns true for quarantined uploads' do
        expect(quarantined_upload.quarantined?).to be true
      end

      it 'returns false for approved uploads' do
        expect(approved_upload.quarantined?).to be false
      end
    end

    describe '#approved?' do
      it 'returns true for approved uploads' do
        expect(approved_upload.approved?).to be true
      end

      it 'returns false for quarantined uploads' do
        expect(quarantined_upload.approved?).to be false
      end
    end

    describe '#approve!' do
      it 'approves a quarantined upload' do
        quarantined_upload.approve!
        expect(quarantined_upload.reload.quarantined?).to be false
        expect(quarantined_upload.quarantine_reason).to be_nil
      end
    end

    describe '#reject!' do
      it 'destroys the upload' do
        expect { quarantined_upload.reject! }.to change { Upload.count }.by(-1)
      end
    end
  end

  describe 'storage configuration integration' do
    it 'configures storage when created' do
      expect_any_instance_of(StorageConfigurationService).to receive(:configure_active_storage)
      create(:upload, user: user, tenant: tenant)
    end

    it 'uses current storage settings for URL generation' do
      image_upload = create(:upload, :with_image, user: user, tenant: tenant)
      
      # Mock the storage configuration service
      storage_config = instance_double(StorageConfigurationService)
      allow(StorageConfigurationService).to receive(:new).and_return(storage_config)
      allow(storage_config).to receive(:cdn_enabled?).and_return(false)
      
      expect(image_upload.url).to be_present
    end
  end

  describe 'multi-tenancy' do
    let(:other_tenant) { create(:tenant) }
    let(:other_user) { create(:user, tenant: other_tenant) }

    it 'scopes uploads to current tenant' do
      ActsAsTenant.with_tenant(tenant) do
        upload1 = create(:upload, user: user, tenant: tenant)
        expect(Upload.count).to eq(1)
        expect(Upload.first).to eq(upload1)
      end

      ActsAsTenant.with_tenant(other_tenant) do
        upload2 = create(:upload, user: other_user, tenant: other_tenant)
        expect(Upload.count).to eq(1)
        expect(Upload.first).to eq(upload2)
      end
    end
  end

  describe 'trash functionality' do
    it 'includes Trashable module' do
      expect(Upload.included_modules).to include(Trashable)
    end

    it 'can be soft deleted' do
      upload = create(:upload, user: user, tenant: tenant)
      expect { upload.destroy }.not_to change { Upload.count }
      expect(upload.reload.deleted_at).to be_present
    end
  end
end