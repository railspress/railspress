require "test_helper"

class GraphqlQueryTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:admin)
    @tenant = @user.tenant
    
    # Create test data
    @post = posts(:one)
    @page = pages(:one)
    @content_type = content_types(:one)
  end

  test "should execute basic GraphQL query" do
    query = <<~GRAPHQL
      query {
        testField
      }
    GRAPHQL

    post "/graphql", params: { query: query }, headers: auth_headers
    assert_response :success
    
    data = JSON.parse(response.body)
    assert_equal "Hello World from RailsPress GraphQL!", data["data"]["testField"]
  end

  test "should query posts" do
    query = <<~GRAPHQL
      query {
        posts {
          id
          title
          slug
          status
        }
      }
    GRAPHQL

    post "/graphql", params: { query: query }, headers: auth_headers
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["data"]["posts"].is_a?(Array)
  end

  test "should query single post by id" do
    query = <<~GRAPHQL
      query {
        post(id: "#{@post.id}") {
          id
          title
          slug
          content
        }
      }
    GRAPHQL

    post "/graphql", params: { query: query }, headers: auth_headers
    assert_response :success
    
    data = JSON.parse(response.body)
    assert_equal @post.id.to_s, data["data"]["post"]["id"]
    assert_equal @post.title, data["data"]["post"]["title"]
  end

  test "should query single post by slug" do
    query = <<~GRAPHQL
      query {
        post(slug: "#{@post.slug}") {
          id
          title
          slug
        }
      }
    GRAPHQL

    post "/graphql", params: { query: query }, headers: auth_headers
    assert_response :success
    
    data = JSON.parse(response.body)
    assert_equal @post.slug, data["data"]["post"]["slug"]
  end

  test "should query pages" do
    query = <<~GRAPHQL
      query {
        pages {
          id
          title
          slug
          status
        }
      }
    GRAPHQL

    post "/graphql", params: { query: query }, headers: auth_headers
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["data"]["pages"].is_a?(Array)
  end

  test "should query single page by id" do
    query = <<~GRAPHQL
      query {
        page(id: "#{@page.id}") {
          id
          title
          slug
          content
        }
      }
    GRAPHQL

    post "/graphql", params: { query: query }, headers: auth_headers
    assert_response :success
    
    data = JSON.parse(response.body)
    assert_equal @page.id.to_s, data["data"]["page"]["id"]
  end

  test "should query content types" do
    query = <<~GRAPHQL
      query {
        contentTypes {
          id
          name
          identifier
          active
        }
      }
    GRAPHQL

    post "/graphql", params: { query: query }, headers: auth_headers
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["data"]["contentTypes"].is_a?(Array)
  end

  test "should query single content type" do
    query = <<~GRAPHQL
      query {
        contentType(id: "#{@content_type.id}") {
          id
          name
          identifier
        }
      }
    GRAPHQL

    post "/graphql", params: { query: query }, headers: auth_headers
    assert_response :success
    
    data = JSON.parse(response.body)
    assert_equal @content_type.id.to_s, data["data"]["contentType"]["id"]
  end

  test "should handle GraphQL errors gracefully" do
    query = <<~GRAPHQL
      query {
        nonExistentField
      }
    GRAPHQL

    post "/graphql", params: { query: query }, headers: auth_headers
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data.key?("errors")
  end

  test "should require authentication for protected queries" do
    query = <<~GRAPHQL
      query {
        posts {
          id
          title
        }
      }
    GRAPHQL

    post "/graphql", params: { query: query }
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



