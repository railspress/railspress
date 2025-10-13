require "test_helper"

class Api::V1::ContentTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @content_type = ContentType.create!(
      ident: "test",
      label: "Test Type",
      singular: "Test",
      plural: "Tests",
      active: true
    )
  end

  test "should get index" do
    get api_v1_content_types_url, as: :json
    assert_response :success
    json = JSON.parse(@response.body)
    assert json["data"].is_a?(Array)
  end

  test "should get content type by id" do
    get api_v1_content_type_url(@content_type), as: :json
    assert_response :success
    json = JSON.parse(@response.body)
    assert_equal @content_type.ident, json["data"]["ident"]
  end

  test "should get content type by ident" do
    get api_v1_content_type_url("test"), as: :json
    assert_response :success
    json = JSON.parse(@response.body)
    assert_equal @content_type.id, json["data"]["id"]
  end

  test "should return 404 for non-existent content type" do
    get api_v1_content_type_url(99999), as: :json
    assert_response :not_found
  end
end



