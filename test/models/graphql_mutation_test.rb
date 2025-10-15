require "test_helper"

class GraphqlMutationTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:admin)
    @tenant = @user.tenant
    
    # Create test data
    @post = posts(:one)
    @page = pages(:one)
  end

  test "should execute basic GraphQL mutation" do
    mutation = <<~GRAPHQL
      mutation {
        testField
      }
    GRAPHQL

    post "/graphql", params: { query: mutation }, headers: auth_headers
    assert_response :success
    
    data = JSON.parse(response.body)
    assert_equal "Hello World from RailsPress GraphQL!", data["data"]["testField"]
  end

  test "should create meta field via GraphQL" do
    mutation = <<~GRAPHQL
      mutation {
        createMetaField(input: {
          metableType: "posts"
          metableId: "#{@post.id}"
          key: "test_key"
          value: "test_value"
        }) {
          metaField {
            id
            key
            value
            metableType
            metableId
          }
          errors
        }
      }
    GRAPHQL

    post "/graphql", params: { query: mutation }, headers: auth_headers
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["data"]["createMetaField"]["metaField"]
    assert_equal "test_key", data["data"]["createMetaField"]["metaField"]["key"]
    assert_equal "test_value", data["data"]["createMetaField"]["metaField"]["value"]
  end

  test "should update meta field via GraphQL" do
    # First create a meta field
    meta_field = MetaField.create!(
      metable: @post,
      key: "update_test",
      value: "original_value",
      tenant: @tenant
    )

    mutation = <<~GRAPHQL
      mutation {
        updateMetaField(input: {
          id: "#{meta_field.id}"
          value: "updated_value"
        }) {
          metaField {
            id
            key
            value
          }
          errors
        }
      }
    GRAPHQL

    post "/graphql", params: { query: mutation }, headers: auth_headers
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["data"]["updateMetaField"]["metaField"]
    assert_equal "updated_value", data["data"]["updateMetaField"]["metaField"]["value"]
  end

  test "should handle mutation errors gracefully" do
    mutation = <<~GRAPHQL
      mutation {
        createMetaField(input: {
          metableType: "posts"
          metableId: "#{@post.id}"
          key: ""
          value: "test_value"
        }) {
          metaField {
            id
            key
            value
          }
          errors
        }
      }
    GRAPHQL

    post "/graphql", params: { query: mutation }, headers: auth_headers
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["data"]["createMetaField"]["errors"]
  end

  test "should require authentication for mutations" do
    mutation = <<~GRAPHQL
      mutation {
        createMetaField(input: {
          metableType: "posts"
          metableId: "#{@post.id}"
          key: "test_key"
          value: "test_value"
        }) {
          metaField {
            id
            key
            value
          }
          errors
        }
      }
    GRAPHQL

    post "/graphql", params: { query: mutation }
    assert_response :unauthorized
  end

  private

  def auth_headers
    {
      "Authorization" => "Bearer #{@user.api_token}",
      "Content-Type" => "application/json"
    }
  end
end