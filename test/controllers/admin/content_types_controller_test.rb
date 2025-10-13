require "test_helper"

class Admin::ContentTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @content_type = ContentType.create!(
      ident: "test",
      label: "Test Type",
      singular: "Test",
      plural: "Tests"
    )
    sign_in @admin
  end

  test "should get index" do
    get admin_content_types_url
    assert_response :success
  end

  test "should get new" do
    get new_admin_content_type_url
    assert_response :success
  end

  test "should create content_type" do
    assert_difference("ContentType.count") do
      post admin_content_types_url, params: { 
        content_type: { 
          ident: "portfolio",
          label: "Portfolio",
          singular: "Portfolio Item",
          plural: "Portfolio Items",
          public: true,
          active: true
        }
      }
    end

    assert_redirected_to admin_content_types_url
  end

  test "should get edit" do
    get edit_admin_content_type_url(@content_type)
    assert_response :success
  end

  test "should update content_type" do
    patch admin_content_type_url(@content_type), params: { 
      content_type: { 
        label: "Updated Type"
      }
    }
    assert_redirected_to admin_content_types_url
    @content_type.reload
    assert_equal "Updated Type", @content_type.label
  end

  test "should destroy content_type" do
    content_type = ContentType.create!(ident: "deletable", label: "Deletable", singular: "Deletable", plural: "Deletables")
    assert_difference("ContentType.count", -1) do
      delete admin_content_type_url(content_type)
    end

    assert_redirected_to admin_content_types_url
  end

  test "should not destroy default post content_type" do
    post_type = ContentType.create!(ident: "post", label: "Post", singular: "Post", plural: "Posts")
    assert_no_difference("ContentType.count") do
      delete admin_content_type_url(post_type)
    end
  end
end

