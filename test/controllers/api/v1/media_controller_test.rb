require "test_helper"

class Api::V1::MediaControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:admin)
    @tenant = @user.tenant
    @storage_provider = StorageProvider.create!(
      name: "Local Storage",
      provider_type: "local",
      configuration: { root_path: "/tmp/uploads" },
      active: true,
      tenant: @tenant
    )
    @upload = Upload.create!(
      filename: "test-image.jpg",
      content_type: "image/jpeg",
      file_size: 1024,
      storage_provider: @storage_provider,
      tenant: @tenant
    )
    @medium = Medium.create!(
      title: "Test Image",
      alt_text: "A test image",
      upload: @upload,
      user: @user,
      tenant: @tenant
    )
  end

  test "should get index" do
    get api_v1_media_index_url, headers: auth_headers(@user)
    assert_response :success
    assert_equal "application/json", response.content_type
    
    data = JSON.parse(response.body)
    assert data.key?("media")
    assert data.key?("meta")
    assert data["media"].is_a?(Array)
  end

  test "should get index with pagination" do
    get api_v1_media_index_url, params: { page: 1, per_page: 5 }, headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data.key?("media")
    assert data.key?("meta")
    assert data["meta"].key?("pagination")
  end

  test "should get index with filtering by type" do
    # Create different media types
    image_upload = Upload.create!(
      filename: "image.jpg",
      content_type: "image/jpeg",
      file_size: 1024,
      storage_provider: @storage_provider,
      tenant: @tenant
    )
    
    video_upload = Upload.create!(
      filename: "video.mp4",
      content_type: "video/mp4",
      file_size: 2048,
      storage_provider: @storage_provider,
      tenant: @tenant
    )
    
    Medium.create!(
      title: "Image",
      upload: image_upload,
      user: @user,
      tenant: @tenant
    )
    
    Medium.create!(
      title: "Video",
      upload: video_upload,
      user: @user,
      tenant: @tenant
    )
    
    get api_v1_media_index_url, params: { type: "image" }, headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    data["media"].each do |media|
      assert_equal "image", media["media_type"]
    end
  end

  test "should get index with search" do
    get api_v1_media_index_url, params: { search: "test" }, headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["media"].any? { |media| media["title"].include?("test") }
  end

  test "should get show" do
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    assert_equal "application/json", response.content_type
    
    data = JSON.parse(response.body)
    assert data.key?("medium")
    assert_equal @medium.id, data["medium"]["id"]
    assert_equal @medium.title, data["medium"]["title"]
  end

  test "should create medium" do
    assert_difference("Medium.count") do
      post api_v1_media_index_url, params: {
        medium: {
          title: "New API Media",
          alt_text: "A new media item created via API",
          upload_id: @upload.id
        }
      }, headers: auth_headers(@user)
    end
    
    assert_response :created
    assert_equal "application/json", response.content_type
    
    data = JSON.parse(response.body)
    assert data.key?("medium")
    assert_equal "New API Media", data["medium"]["title"]
    assert_equal "A new media item created via API", data["medium"]["alt_text"]
  end

  test "should not create medium without title" do
    assert_no_difference("Medium.count") do
      post api_v1_media_index_url, params: {
        medium: {
          title: "",
          alt_text: "A media item without title",
          upload_id: @upload.id
        }
      }, headers: auth_headers(@user)
    end
    
    assert_response :unprocessable_entity
    
    data = JSON.parse(response.body)
    assert data.key?("errors")
    assert data["errors"].key?("title")
  end

  test "should update medium" do
    patch api_v1_medium_url(@medium), params: {
      medium: {
        title: "Updated API Media",
        alt_text: "This media has been updated via API"
      }
    }, headers: auth_headers(@user)
    
    assert_response :success
    assert_equal "application/json", response.content_type
    
    data = JSON.parse(response.body)
    assert data.key?("medium")
    assert_equal "Updated API Media", data["medium"]["title"]
    
    @medium.reload
    assert_equal "Updated API Media", @medium.title
    assert_equal "This media has been updated via API", @medium.alt_text
  end

  test "should not update medium with invalid data" do
    patch api_v1_medium_url(@medium), params: {
      medium: {
        title: ""
      }
    }, headers: auth_headers(@user)
    
    assert_response :unprocessable_entity
    
    data = JSON.parse(response.body)
    assert data.key?("errors")
    assert data["errors"].key?("title")
  end

  test "should destroy medium" do
    assert_difference("Medium.count", -1) do
      delete api_v1_medium_url(@medium), headers: auth_headers(@user)
    end
    
    assert_response :no_content
  end

  test "should require authentication" do
    get api_v1_media_index_url
    assert_response :unauthorized
    
    data = JSON.parse(response.body)
    assert data.key?("error")
    assert_includes data["error"], "authentication"
  end

  test "should require valid API token" do
    get api_v1_media_index_url, headers: { "Authorization" => "Bearer invalid-token" }
    assert_response :unauthorized
  end

  test "should handle media with file information" do
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("file")
    assert data["medium"]["file"].key?("filename")
    assert data["medium"]["file"].key?("content_type")
    assert data["medium"]["file"].key?("file_size")
    assert_equal "test-image.jpg", data["medium"]["file"]["filename"]
    assert_equal "image/jpeg", data["medium"]["file"]["content_type"]
    assert_equal 1024, data["medium"]["file"]["file_size"]
  end

  test "should handle media with file URL" do
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("file_url")
    assert_not_nil data["medium"]["file_url"]
  end

  test "should handle media with media type" do
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("media_type")
    assert_equal "image", data["medium"]["media_type"]
  end

  test "should handle media with dimensions" do
    # Mock image dimensions
    @upload.stubs(:image?).returns(true)
    @upload.stubs(:width).returns(800)
    @upload.stubs(:height).returns(600)
    
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("dimensions")
    assert data["medium"]["dimensions"].key?("width")
    assert data["medium"]["dimensions"].key?("height")
  end

  test "should handle media with thumbnail URL" do
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("thumbnail_url")
  end

  test "should handle media with author information" do
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("author")
    assert_equal @medium.user.name, data["medium"]["author"]["name"]
    assert_equal @medium.user.email, data["medium"]["author"]["email"]
  end

  test "should handle media with creation dates" do
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("created_at")
    assert data["medium"].key?("updated_at")
  end

  test "should handle media with slug" do
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("slug")
    assert_equal @medium.slug, data["medium"]["slug"]
  end

  test "should handle media with description" do
    @medium.update!(description: "This is a detailed description of the media")
    
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("description")
    assert_equal "This is a detailed description of the media", data["medium"]["description"]
  end

  test "should handle media with caption" do
    @medium.update!(caption: "This is a caption for the media")
    
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("caption")
    assert_equal "This is a caption for the media", data["medium"]["caption"]
  end

  test "should handle media with alt text" do
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("alt_text")
    assert_equal "A test image", data["medium"]["alt_text"]
  end

  test "should handle media with file extension" do
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("file_extension")
    assert_equal "jpg", data["medium"]["file_extension"]
  end

  test "should handle media with formatted file size" do
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("formatted_file_size")
    assert_equal "1.0 KB", data["medium"]["formatted_file_size"]
  end

  test "should handle media with storage provider information" do
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("storage_provider")
    assert_equal @storage_provider.name, data["medium"]["storage_provider"]["name"]
    assert_equal @storage_provider.provider_type, data["medium"]["storage_provider"]["provider_type"]
  end

  test "should handle media with usage count" do
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("usage_count")
    assert data["medium"]["usage_count"].is_a?(Integer)
  end

  test "should handle media with tags" do
    # Create taxonomy and term
    taxonomy = Taxonomy.create!(
      name: "Media Tags",
      taxonomy_type: "tag",
      tenant: @tenant
    )
    
    tag = Term.create!(
      name: "nature",
      slug: "nature",
      taxonomy: taxonomy,
      tenant: @tenant
    )
    
    # Assign tag to medium
    @medium.terms << tag
    
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("tags")
    assert data["medium"]["tags"].any? { |t| t["name"] == "nature" }
  end

  test "should handle media with custom fields" do
    # Create custom field
    custom_field = CustomField.create!(
      name: "photographer",
      field_type: "text",
      tenant: @tenant
    )
    
    # Create custom field value
    custom_field_value = CustomFieldValue.create!(
      custom_field: custom_field,
      value: "John Doe",
      custom_fieldable: @medium,
      tenant: @tenant
    )
    
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("custom_fields")
    assert_equal "John Doe", data["medium"]["custom_fields"]["photographer"]
  end

  test "should handle media with metadata" do
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("metadata")
    assert data["medium"]["metadata"].is_a?(Hash)
  end

  test "should handle media with EXIF data for images" do
    # Mock EXIF data
    @upload.stubs(:image?).returns(true)
    @upload.stubs(:exif_data).returns({
      "camera" => "Canon EOS 5D",
      "lens" => "24-70mm f/2.8",
      "iso" => 100,
      "aperture" => "f/2.8",
      "shutter_speed" => "1/125"
    })
    
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("exif_data")
    assert data["medium"]["exif_data"].key?("camera")
    assert_equal "Canon EOS 5D", data["medium"]["exif_data"]["camera"]
  end

  test "should handle media with color palette" do
    # Mock color palette
    @upload.stubs(:image?).returns(true)
    @upload.stubs(:color_palette).returns([
      "#FF0000", "#00FF00", "#0000FF"
    ])
    
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("color_palette")
    assert data["medium"]["color_palette"].is_a?(Array)
    assert_equal 3, data["medium"]["color_palette"].length
  end

  test "should handle media with dominant color" do
    # Mock dominant color
    @upload.stubs(:image?).returns(true)
    @upload.stubs(:dominant_color).returns("#FF0000")
    
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("dominant_color")
    assert_equal "#FF0000", data["medium"]["dominant_color"]
  end

  test "should handle media with blur hash" do
    # Mock blur hash
    @upload.stubs(:image?).returns(true)
    @upload.stubs(:blur_hash).returns("L6PZfSi_.AyE_3t7t7R**0o#DgR4")
    
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("blur_hash")
    assert_equal "L6PZfSi_.AyE_3t7t7R**0o#DgR4", data["medium"]["blur_hash"]
  end

  test "should handle media with AI-generated descriptions" do
    # Mock AI description
    @medium.stubs(:ai_description).returns("A beautiful sunset over the mountains")
    
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("ai_description")
    assert_equal "A beautiful sunset over the mountains", data["medium"]["ai_description"]
  end

  test "should handle media with AI-generated tags" do
    # Mock AI tags
    @medium.stubs(:ai_tags).returns(["sunset", "mountains", "nature", "landscape"])
    
    get api_v1_medium_url(@medium), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["medium"].key?("ai_tags")
    assert data["medium"]["ai_tags"].is_a?(Array)
    assert data["medium"]["ai_tags"].include?("sunset")
  end

  private

  def auth_headers(user)
    {
      "Authorization" => "Bearer #{user.api_token}",
      "Content-Type" => "application/json"
    }
  end
end


