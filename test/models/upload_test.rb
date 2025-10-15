require "test_helper"

class UploadTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.first
    @storage_provider = StorageProvider.first
    @upload = Upload.new(
      filename: "test-file.jpg",
      content_type: "image/jpeg",
      file_size: 1024,
      storage_provider: @storage_provider,
      tenant: @tenant
    )
  end

  test "should be valid with valid attributes" do
    assert @upload.valid?
  end

  test "should require filename" do
    @upload.filename = nil
    assert_not @upload.valid?
    assert_includes @upload.errors[:filename], "can't be blank"
  end

  test "should require content_type" do
    @upload.content_type = nil
    assert_not @upload.valid?
    assert_includes @upload.errors[:content_type], "can't be blank"
  end

  test "should require file_size" do
    @upload.file_size = nil
    assert_not @upload.valid?
    assert_includes @upload.errors[:file_size], "can't be blank"
  end

  test "should require storage_provider" do
    @upload.storage_provider = nil
    assert_not @upload.valid?
    assert_includes @upload.errors[:storage_provider], "must exist"
  end

  test "should require tenant" do
    @upload.tenant = nil
    assert_not @upload.valid?
    assert_includes @upload.errors[:tenant], "must exist"
  end

  test "should validate file_size is positive" do
    @upload.file_size = -1
    assert_not @upload.valid?
    assert_includes @upload.errors[:file_size], "must be greater than 0"
  end

  test "should belong to storage_provider" do
    assert_respond_to @upload, :storage_provider
  end

  test "should belong to tenant" do
    assert_respond_to @upload, :tenant
  end

  test "should have many media" do
    assert_respond_to @upload, :media
  end

  test "should have file attachment" do
    assert_respond_to @upload, :file
  end

  test "should generate unique file key" do
    @upload.save!
    assert_not_nil @upload.file_key
    assert_match /\A[a-f0-9]{32}\.jpg\z/, @upload.file_key
  end

  test "should scope by storage provider" do
    @upload.save!
    
    provider_uploads = Upload.by_provider(@storage_provider)
    assert_includes provider_uploads, @upload
  end

  test "should scope by content type" do
    @upload.save!
    
    image_uploads = Upload.by_content_type("image/jpeg")
    assert_includes image_uploads, @upload
  end

  test "should scope recent uploads" do
    @upload.save!
    
    recent_uploads = Upload.recent
    assert_includes recent_uploads, @upload
  end

  test "should scope quarantined uploads" do
    @upload.quarantined = true
    @upload.quarantine_reason = "Suspicious file detected"
    @upload.save!
    
    quarantined_uploads = Upload.quarantined
    assert_includes quarantined_uploads, @upload
  end

  test "should be trashable" do
    assert_respond_to @upload, :trash!
    assert_respond_to @upload, :restore!
    assert_respond_to @upload, :trashed?
  end

  test "should have file_url method" do
    @upload.save!
    assert_respond_to @upload, :file_url
  end

  test "should have file_attached? method" do
    @upload.save!
    assert_respond_to @upload, :file_attached?
  end

  test "should detect file extension" do
    @upload.filename = "document.pdf"
    assert_equal "pdf", @upload.file_extension
  end

  test "should detect if file is image" do
    @upload.content_type = "image/jpeg"
    assert @upload.image?
    
    @upload.content_type = "text/plain"
    assert_not @upload.image?
  end

  test "should detect if file is video" do
    @upload.content_type = "video/mp4"
    assert @upload.video?
    
    @upload.content_type = "text/plain"
    assert_not @upload.video?
  end

  test "should detect if file is document" do
    @upload.content_type = "application/pdf"
    assert @upload.document?
    
    @upload.content_type = "text/plain"
    assert_not @upload.document?
  end

  test "should format file size" do
    @upload.file_size = 1024
    assert_equal "1.0 KB", @upload.formatted_file_size
    
    @upload.file_size = 1048576
    assert_equal "1.0 MB", @upload.formatted_file_size
  end

  test "should validate against upload security settings" do
    # Create upload security settings
    upload_security = UploadSecurity.create!(
      max_file_size: 1.megabyte,
      allowed_extensions: %w[jpg jpeg png],
      blocked_extensions: %w[exe bat],
      allowed_mime_types: %w[image/jpeg image/png],
      blocked_mime_types: %w[application/x-executable],
      tenant: @tenant
    )
    
    # Valid upload
    @upload.file_size = 512.kilobytes
    @upload.content_type = "image/jpeg"
    assert @upload.valid?
    
    # Invalid file size
    @upload.file_size = 2.megabytes
    assert_not @upload.valid?
    
    # Reset for next test
    @upload.file_size = 512.kilobytes
    
    # Invalid content type
    @upload.content_type = "application/x-executable"
    assert_not @upload.valid?
  end

  test "should quarantine suspicious files" do
    # Create upload security settings that quarantine certain files
    upload_security = UploadSecurity.create!(
      quarantine_suspicious: true,
      tenant: @tenant
    )
    
    @upload.content_type = "application/x-executable"
    @upload.save!
    
    assert @upload.quarantined?
    assert_not_nil @upload.quarantine_reason
  end
end


