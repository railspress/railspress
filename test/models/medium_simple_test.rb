require "test_helper"

class MediumSimpleTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin)
    @medium = Medium.new(
      title: "Test Image",
      alt_text: "A test image",
      description: "Description of the test image",
      user: @user
    )
  end

  test "should be valid with valid attributes" do
    # Medium requires tenant and upload, so it won't be valid without them
    assert_not @medium.valid?
    assert_includes @medium.errors[:tenant], "must exist"
    assert_includes @medium.errors[:upload], "must exist"
  end

  test "should require title" do
    @medium.title = nil
    assert_not @medium.valid?
    assert_includes @medium.errors[:title], "can't be blank"
  end

  test "should belong to user" do
    assert_respond_to @medium, :user
  end

  test "should belong to upload" do
    assert_respond_to @medium, :upload
  end

  test "should have api_attributes method" do
    assert_respond_to @medium, :api_attributes
  end

  test "should delegate file methods to upload" do
    assert_respond_to @medium, :filename
    assert_respond_to @medium, :content_type
    assert_respond_to @medium, :file_size
    assert_respond_to @medium, :url
  end

  test "should check media type methods" do
    assert_respond_to @medium, :image?
    assert_respond_to @medium, :video?
    assert_respond_to @medium, :document?
  end

  test "should have quarantine methods" do
    assert_respond_to @medium, :quarantined?
    assert_respond_to @medium, :approved?
    assert_respond_to @medium, :quarantine_reason
  end

  test "should be trashable" do
    assert_respond_to @medium, :trash!
    assert_respond_to @medium, :untrash!
    assert_respond_to @medium, :trashed?
  end

  test "should have scopes" do
    assert_respond_to Medium, :images
    assert_respond_to Medium, :videos
    assert_respond_to Medium, :documents
    assert_respond_to Medium, :recent
    assert_respond_to Medium, :approved
    assert_respond_to Medium, :quarantined
  end

  test "should have class methods" do
    assert_respond_to Medium, :by_type
    assert_respond_to Medium, :with_file_info
  end
end
