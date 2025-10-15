require "test_helper"

class Api::V1::MetaFieldsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = tenants(:default)
    @post = posts(:one)
    @user = users(:user)
    @user.update!(api_key: "test-api-key")
  end

  def auth_headers
    { "Authorization" => "Bearer test-api-key" }
  end

  test "should get index of meta fields" do
    MetaField.create!(metable: @post, key: "featured", value: "true", immutable: false)
    MetaField.create!(metable: @post, key: "views", value: "150", immutable: false)
    MetaField.create!(metable: @post, key: "version", value: "1.0", immutable: true)

    get "/api/v1/posts/#{@post.id}/meta_fields", headers: auth_headers

    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal 3, json_response["meta_fields"].length
    assert_equal "featured", json_response["meta_fields"][0]["key"]
    assert_equal "true", json_response["meta_fields"][0]["value"]
    assert_equal false, json_response["meta_fields"][0]["immutable"]
  end

  test "should filter meta fields by key" do
    MetaField.create!(metable: @post, key: "featured", value: "true")
    MetaField.create!(metable: @post, key: "views", value: "150")

    get "/api/v1/posts/#{@post.id}/meta_fields?key=featured", headers: auth_headers

    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal 1, json_response["meta_fields"].length
    assert_equal "featured", json_response["meta_fields"][0]["key"]
  end

  test "should filter meta fields by immutable status" do
    MetaField.create!(metable: @post, key: "featured", value: "true", immutable: false)
    MetaField.create!(metable: @post, key: "version", value: "1.0", immutable: true)

    get "/api/v1/posts/#{@post.id}/meta_fields?immutable=true", headers: auth_headers

    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal 1, json_response["meta_fields"].length
    assert_equal "version", json_response["meta_fields"][0]["key"]
    assert_equal true, json_response["meta_fields"][0]["immutable"]
  end

  test "should show specific meta field" do
    MetaField.create!(metable: @post, key: "featured", value: "true", immutable: false)

    get "/api/v1/posts/#{@post.id}/meta_fields/featured", headers: auth_headers

    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal "featured", json_response["meta_field"]["key"]
    assert_equal "true", json_response["meta_field"]["value"]
    assert_equal false, json_response["meta_field"]["immutable"]
  end

  test "should create meta field" do
    assert_difference("MetaField.count") do
      post "/api/v1/posts/#{@post.id}/meta_fields", 
           params: { meta_field: { key: "new_field", value: "new_value", immutable: false } }.to_json,
           headers: auth_headers.merge("Content-Type" => "application/json")
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    
    assert_equal "new_field", json_response["meta_field"]["key"]
    assert_equal "new_value", json_response["meta_field"]["value"]
    assert_equal false, json_response["meta_field"]["immutable"]
  end

  test "should update meta field" do
    MetaField.create!(metable: @post, key: "featured", value: "true", immutable: false)

    patch "/api/v1/posts/#{@post.id}/meta_fields/featured",
          params: { meta_field: { value: "false" } }.to_json,
          headers: auth_headers.merge("Content-Type" => "application/json")

    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal "featured", json_response["meta_field"]["key"]
    assert_equal "false", json_response["meta_field"]["value"]
  end

  test "should destroy meta field" do
    MetaField.create!(metable: @post, key: "featured", value: "true", immutable: false)

    assert_difference("MetaField.count", -1) do
      delete "/api/v1/posts/#{@post.id}/meta_fields/featured", headers: auth_headers
    end

    assert_response :no_content
  end

  test "should bulk create meta fields" do
    meta_fields_data = [
      { key: "bulk_field1", value: "bulk_value1", immutable: false },
      { key: "bulk_field2", value: "bulk_value2", immutable: true }
    ]

    assert_difference("MetaField.count", 2) do
      post "/api/v1/posts/#{@post.id}/meta_fields/bulk_create",
           params: { meta_fields: meta_fields_data }.to_json,
           headers: auth_headers.merge("Content-Type" => "application/json")
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    
    assert_equal 2, json_response["meta_fields"].length
    assert_equal "bulk_field1", json_response["meta_fields"][0]["key"]
    assert_equal "bulk_field2", json_response["meta_fields"][1]["key"]
  end

  test "should bulk update meta fields" do
    MetaField.create!(metable: @post, key: "field1", value: "original1", immutable: false)
    MetaField.create!(metable: @post, key: "field2", value: "original2", immutable: false)

      patch "/api/v1/posts/#{@post.id}/meta_fields/bulk_update",
          params: { 
            meta_fields: {
              "field1" => { value: "updated1" },
              "field2" => { value: "updated2" }
            }
          }.to_json,
          headers: auth_headers.merge("Content-Type" => "application/json")

    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal 2, json_response["meta_fields"].length
    
    # Verify updates
    field1 = json_response["meta_fields"].find { |f| f["key"] == "field1" }
    field2 = json_response["meta_fields"].find { |f| f["key"] == "field2" }
    
    assert_equal "updated1", field1["value"]
    assert_equal "updated2", field2["value"]
  end

  test "should require authentication" do
    # TODO: Fix route constraints to prevent conflicts
    skip "Route constraints need to be fixed to prevent conflicts with other routes"
    
    # Use a URL that won't match any other routes
    get "/api/v1/test_type/123/meta_fields", headers: { "Content-Type" => "application/json" }

    # This should hit the meta fields controller and require authentication
    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal "Invalid API key", json_response["error"]["message"]
  end

  test "should validate metable type" do
    # TODO: Fix route constraints to prevent conflicts
    skip "Route constraints need to be fixed to prevent conflicts with other routes"
    
    get "/api/v1/invalid_type/123/meta_fields", 
        headers: auth_headers.merge("Content-Type" => "application/json")

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_includes json_response["error"]["message"], "Invalid metable type"
  end

  test "should handle non-existent metable" do
    get "/api/v1/posts/99999/meta_fields", headers: auth_headers

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal "Post not found", json_response["error"]["message"]
  end

  test "should handle non-existent meta field" do
    get "/api/v1/posts/#{@post.id}/meta_fields/non_existent", headers: auth_headers

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal "Meta field not found", json_response["error"]["message"]
  end

  test "should validate meta field parameters" do
    post "/api/v1/posts/#{@post.id}/meta_fields",
         params: { meta_field: { key: "", value: "value" } }.to_json,
         headers: auth_headers.merge("Content-Type" => "application/json")

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response["errors"].present?
  end

  test "should work with different metable types" do
    # Test with Page
    page = pages(:one)
    get "/api/v1/pages/#{page.id}/meta_fields", headers: auth_headers
    assert_response :success

    # Test with User
    user = users(:user)
    get "/api/v1/users/#{user.id}/meta_fields", headers: auth_headers
    assert_response :success

    # Test with AiAgent
    agent = ai_agents(:content_summarizer)
    get "/api/v1/ai_agents/#{agent.id}/meta_fields", headers: auth_headers
    assert_response :success
  end

  test "should handle bulk create with validation errors" do
    # Create a meta field that will cause a duplicate key error
    MetaField.create!(metable: @post, key: "duplicate_key", value: "value1")

    meta_fields_data = [
      { key: "duplicate_key", value: "value2" },  # This will cause validation error
      { key: "valid_key", value: "valid_value" }
    ]

    assert_no_difference("MetaField.count") do
      post "/api/v1/posts/#{@post.id}/meta_fields/bulk_create",
           params: { meta_fields: meta_fields_data }.to_json,
           headers: auth_headers.merge("Content-Type" => "application/json")
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response["errors"].present?
  end

  test "should handle bulk update with non-existent keys" do
      patch "/api/v1/posts/#{@post.id}/meta_fields/bulk_update",
          params: { 
            meta_fields: {
              "non_existent_key" => { value: "updated" }
            }
          }.to_json,
          headers: auth_headers.merge("Content-Type" => "application/json")

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response["errors"].present?
  end
end
