require "test_helper"

class Admin::MediaControllerTest < ActionDispatch::IntegrationTest
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
    sign_in @user
    get admin_media_index_url
    assert_response :success
    assert_select "h1", text: /Media/
  end

  test "should get show" do
    sign_in @user
    get admin_medium_url(@medium)
    assert_response :success
    assert_select "h1", text: @medium.title
  end

  test "should get new" do
    sign_in @user
    get new_admin_medium_url
    assert_response :success
    assert_select "form"
  end

  test "should create medium" do
    sign_in @user
    
    assert_difference("Medium.count") do
      post admin_media_index_url, params: {
        medium: {
          title: "New Image",
          alt_text: "A new image",
          upload_id: @upload.id
        }
      }
    end
    
    assert_redirected_to admin_medium_url(Medium.last)
    assert_equal "Media created successfully.", flash[:notice]
  end

  test "should not create medium without title" do
    sign_in @user
    
    assert_no_difference("Medium.count") do
      post admin_media_index_url, params: {
        medium: {
          title: "",
          alt_text: "A new image",
          upload_id: @upload.id
        }
      }
    end
    
    assert_response :unprocessable_entity
  end

  test "should get edit" do
    sign_in @user
    get edit_admin_medium_url(@medium)
    assert_response :success
    assert_select "form"
  end

  test "should update medium" do
    sign_in @user
    
    patch admin_medium_url(@medium), params: {
      medium: {
        title: "Updated Image",
        alt_text: "An updated image"
      }
    }
    
    assert_redirected_to admin_medium_url(@medium)
    assert_equal "Media updated successfully.", flash[:notice]
    
    @medium.reload
    assert_equal "Updated Image", @medium.title
    assert_equal "An updated image", @medium.alt_text
  end

  test "should not update medium with invalid data" do
    sign_in @user
    
    patch admin_medium_url(@medium), params: {
      medium: {
        title: ""
      }
    }
    
    assert_response :unprocessable_entity
  end

  test "should destroy medium" do
    sign_in @user
    
    assert_difference("Medium.count", -1) do
      delete admin_medium_url(@medium)
    end
    
    assert_redirected_to admin_media_index_url
    assert_equal "Media deleted successfully.", flash[:notice]
  end

  test "should trash medium" do
    sign_in @user
    
    assert_no_difference("Medium.count") do
      post trash_admin_medium_url(@medium)
    end
    
    assert_redirected_to admin_media_index_url
    assert_equal "Media moved to trash.", flash[:notice]
    
    @medium.reload
    assert @medium.trashed?
  end

  test "should restore medium" do
    sign_in @user
    @medium.trash!(@user)
    
    assert_no_difference("Medium.count") do
      post restore_admin_medium_url(@medium)
    end
    
    assert_redirected_to admin_medium_url(@medium)
    assert_equal "Media restored from trash.", flash[:notice]
    
    @medium.reload
    assert_not @medium.trashed?
  end

  test "should bulk upload media" do
    sign_in @user
    
    # Create test files
    files = [
      fixture_file_upload(Rails.root.join("test/fixtures/files/test1.jpg"), "image/jpeg"),
      fixture_file_upload(Rails.root.join("test/fixtures/files/test2.png"), "image/png")
    ]
    
    assert_difference("Upload.count", 2) do
      assert_difference("Medium.count", 2) do
        post bulk_upload_admin_media_index_url, params: {
          files: files
        }
      end
    end
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "success", response_data["status"]
    assert_equal 2, response_data["uploaded_count"]
  end

  test "should not bulk upload without files" do
    sign_in @user
    
    assert_no_difference("Upload.count") do
      assert_no_difference("Medium.count") do
        post bulk_upload_admin_media_index_url, params: {
          files: []
        }
      end
    end
    
    assert_response :unprocessable_entity
  end

  test "should filter media by type" do
    sign_in @user
    
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
    
    get admin_media_index_url, params: { type: "image" }
    assert_response :success
    
    # Should only show image media
    assert_select ".media-item", count: 1
  end

  test "should search media" do
    sign_in @user
    
    get admin_media_index_url, params: { search: "test" }
    assert_response :success
    
    # Should show media matching search term
    assert_select ".media-item"
  end

  test "should require authentication" do
    get admin_media_index_url
    assert_redirected_to new_user_session_url
  end

  test "should require admin role" do
    # Create a non-admin user
    subscriber = User.create!(
      name: "Subscriber",
      email: "subscriber@example.com",
      password: "password123",
      role: "subscriber",
      tenant: @tenant
    )
    
    sign_in subscriber
    get admin_media_index_url
    assert_redirected_to root_url
  end

  test "should handle file attachment errors gracefully" do
    sign_in @user
    
    # Mock file upload failure
    Upload.any_instance.stubs(:save).returns(false)
    Upload.any_instance.stubs(:errors).returns(
      ActiveModel::Errors.new(Upload.new).tap do |errors|
        errors.add(:file, "Upload failed")
      end
    )
    
    post admin_media_index_url, params: {
      medium: {
        title: "New Image",
        alt_text: "A new image"
      }
    }
    
    assert_response :unprocessable_entity
  end

  test "should handle storage provider errors gracefully" do
    sign_in @user
    
    # Mock storage provider failure
    StorageProvider.any_instance.stubs(:configure_active_storage).raises(StandardError, "Storage error")
    
    get admin_media_index_url
    assert_response :success
    # Should still render the page but show an error message
  end
end

