require "test_helper"

class MediumTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin)
    @tenant = @user.tenant
    @storage_provider = StorageProvider.create!(
      name: "Local Storage",
      provider_type: "local",
      config: { root_path: "/tmp/uploads" },
      active: true,
      tenant: @user.tenant
    )
    @medium = Medium.new(
      title: "Test Image",
      alt_text: "A test image",
      description: "Description of the test image",
      user: @user,
      tenant: @tenant
    )
  end

  test "should be valid with valid attributes" do
    assert @medium.valid?
  end

  test "should require title" do
    @medium.title = nil
    assert_not @medium.valid?
    assert_includes @medium.errors[:title], "can't be blank"
  end

  test "should require tenant" do
    @medium.tenant = nil
    assert_not @medium.valid?
    assert_includes @medium.errors[:tenant], "must exist"
  end

  test "should belong to user" do
    assert_respond_to @medium, :user
  end

  test "should belong to tenant" do
    assert_respond_to @medium, :tenant
  end

  test "should belong to upload" do
    assert_respond_to @medium, :upload
  end

  test "should have file attachment" do
    assert_respond_to @medium, :file
  end

  test "should be trashable" do
    assert_respond_to @medium, :trash!
    assert_respond_to @medium, :untrash!
    assert_respond_to @medium, :trashed?
  end

  test "should have api_attributes method" do
    @medium.save!
    assert_respond_to @medium, :api_attributes
    assert @medium.api_attributes.is_a?(Hash)
  end

  test "should scope by media type" do
    @medium.save!
    
    # Create an image upload for the medium
    image_upload = Upload.create!(
      title: "Test Image Upload",
      user: @user,
      tenant: @tenant,
      storage_provider: @storage_provider
    )
    
    @medium.update!(upload: image_upload)
    
    image_media = Medium.by_type("image").first
    assert_equal @medium, image_media
  end

  test "should scope recent media" do
    @medium.save!
    
    recent_medium = Medium.recent.first
    assert_equal @medium, recent_medium
  end

  test "should delegate file methods to upload" do
    upload = Upload.create!(
      title: "Test Upload",
      user: @user,
      tenant: @tenant,
      storage_provider: @storage_provider
    )
    
    @medium.upload = upload
    @medium.save!
    
    # These methods delegate to the upload's file attachment
    assert_respond_to @medium, :filename
    assert_respond_to @medium, :content_type
    assert_respond_to @medium, :file_size
  end

  test "should have file_url method" do
    @medium.save!
    assert_respond_to @medium, :file_url
  end

  test "should have file_attached? method" do
    @medium.save!
    assert_respond_to @medium, :file_attached?
  end

  test "should check if medium is image" do
    @medium.save!
    
    # Create an image upload
    image_upload = Upload.create!(
      title: "Test Image Upload",
      user: @user,
      tenant: @tenant,
      storage_provider: @storage_provider
    )
    
    @medium.update!(upload: image_upload)
    
    assert @medium.image?
  end

  test "should check if medium is video" do
    @medium.save!
    
    # Create a video upload
    video_upload = Upload.create!(
      title: "Test Video Upload",
      user: @user,
      tenant: @tenant,
      storage_provider: @storage_provider
    )
    
    @medium.update!(upload: video_upload)
    
    assert_respond_to @medium, :video?
  end

  test "should check if medium is document" do
    @medium.save!
    
    # Create a document upload
    doc_upload = Upload.create!(
      title: "Test Document Upload",
      user: @user,
      tenant: @tenant,
      storage_provider: @storage_provider
    )
    
    @medium.update!(upload: doc_upload)
    
    assert_respond_to @medium, :document?
  end
end
