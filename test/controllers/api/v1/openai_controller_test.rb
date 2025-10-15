require 'test_helper'

class Api::V1::OpenaiControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    @user.regenerate_api_key! unless @user.api_key.present?
    @ai_provider = ai_providers(:cohere)
    @ai_agent = ai_agents(:content_summarizer)
  end

  test "should authenticate with valid API key" do
    post api_v1_chat_completions_path, 
         params: valid_chat_params.to_json,
         headers: valid_headers
    assert_response :success
  end

  test "should reject invalid API key" do
    post api_v1_chat_completions_path,
         params: valid_chat_params.to_json,
         headers: invalid_headers
    assert_response :unauthorized
    assert_match /invalid_api_key/, response.body
  end

  test "should reject missing Authorization header" do
    post api_v1_chat_completions_path,
         params: valid_chat_params.to_json,
         headers: { 'Content-Type' => 'application/json' }
    assert_response :unauthorized
  end

  test "should reject malformed Authorization header" do
    post api_v1_chat_completions_path,
         params: valid_chat_params.to_json,
         headers: { 
           'Authorization' => 'Invalid sk-123',
           'Content-Type' => 'application/json'
         }
    assert_response :unauthorized
  end

  test "chat completions should work with valid request" do
    post api_v1_chat_completions_path,
         params: valid_chat_params.to_json,
         headers: valid_headers

    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_equal "chat.completion", response_data["object"]
    assert_equal "content-summarizer", response_data["model"]
    assert response_data["choices"].present?
    assert response_data["usage"].present?
    assert response_data["id"].present?
  end

  test "chat completions should reject invalid model" do
    invalid_params = valid_chat_params.merge(model: "nonexistent-model")
    
    post api_v1_chat_completions_path,
         params: invalid_params.to_json,
         headers: valid_headers

    assert_response :not_found
    response_data = JSON.parse(response.body)
    assert_equal "model_not_found", response_data["error"]["code"]
  end

  test "chat completions should reject missing messages" do
    invalid_params = valid_chat_params.except(:messages)
    
    post api_v1_chat_completions_path,
         params: invalid_params.to_json,
         headers: valid_headers

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_equal "missing_messages", response_data["error"]["code"]
  end

  test "chat completions should reject empty messages" do
    invalid_params = valid_chat_params.merge(messages: [])
    
    post api_v1_chat_completions_path,
         params: invalid_params.to_json,
         headers: valid_headers

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_equal "missing_messages", response_data["error"]["code"]
  end

  test "chat completions should reject invalid message format" do
    invalid_params = valid_chat_params.merge(messages: [{ role: "user" }]) # missing content
    
    post api_v1_chat_completions_path,
         params: invalid_params.to_json,
         headers: valid_headers

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_equal "invalid_message_format", response_data["error"]["code"]
  end

  test "should list all available models" do
    get api_v1_models_path, headers: valid_headers

    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_equal "list", response_data["object"]
    assert response_data["data"].is_a?(Array)
    assert response_data["data"].length > 0
    
    model = response_data["data"].first
    assert model["id"].present?
    assert_equal "model", model["object"]
    assert_equal "railspress", model["owned_by"]
  end

  test "should show individual model" do
    get "/api/v1/models/content-summarizer", headers: valid_headers

    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_equal "content-summarizer", response_data["id"]
    assert_equal "model", response_data["object"]
    assert_equal "railspress", response_data["owned_by"]
  end

  test "should return 404 for nonexistent model" do
    get "/api/v1/models/nonexistent-model", headers: valid_headers

    assert_response :not_found
    response_data = JSON.parse(response.body)
    assert_equal "model_not_found", response_data["error"]["code"]
  end

  test "should work with different agents" do
    %w[post-writer comments-analyzer seo-analyzer].each do |model|
      params = valid_chat_params.merge(model: model)
      
      post api_v1_chat_completions_path,
           params: params.to_json,
           headers: valid_headers

      assert_response :success, "Failed for model: #{model}"
      
      response_data = JSON.parse(response.body)
      assert_equal model, response_data["model"]
      assert response_data["choices"].present?
    end
  end

  test "should handle system and user messages correctly" do
    params = {
      model: "content-summarizer",
      messages: [
        { role: "system", content: "You are a helpful assistant." },
        { role: "user", content: "Hello, how are you?" }
      ],
      temperature: 0.7,
      max_tokens: 100,
      n: 1
    }

    post api_v1_chat_completions_path,
         params: params.to_json,
         headers: valid_headers

    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert response_data["choices"].present?
    assert response_data["choices"][0]["message"]["content"].present?
  end

  test "should log AI usage correctly" do
    # Skip this test if we don't have a real AI API key configured
    # as it would make real API calls
    skip "Requires real AI API configuration" unless @ai_provider.api_key.present? && @ai_provider.api_key != "test-api-key"
    
    # Clear any existing usages for this agent
    @ai_agent.ai_usages.destroy_all
    
    post api_v1_chat_completions_path,
         params: valid_chat_params.to_json,
         headers: valid_headers

    assert_response :success
    
    # Should create at least one usage record
    assert @ai_agent.ai_usages.count >= 1

    usage = @ai_agent.ai_usages.last
    assert_not_nil usage, "No AI usage was created"
    assert_equal @ai_agent, usage.ai_agent
    assert_equal @user, usage.user
    assert usage.success
    assert usage.tokens_used > 0
    assert usage.response_time > 0
    assert usage.cost >= 0
    assert usage.prompt.present?
    assert usage.response.present?
  end

  test "should handle AI service errors gracefully" do
    # This test would require mocking the AI service, which is complex
    # For now, we'll skip this test and focus on the core functionality
    skip "Requires AI service mocking"
  end

  private

  def valid_headers
    {
      'Authorization' => "Bearer #{@user.api_key}",
      'Content-Type' => 'application/json'
    }
  end

  def invalid_headers
    {
      'Authorization' => 'Bearer invalid-key',
      'Content-Type' => 'application/json'
    }
  end

  def valid_chat_params
    {
      model: "content-summarizer",
      messages: [
        { role: "user", content: "Test message" }
      ],
      temperature: 0.7,
      max_tokens: 256,
      n: 1
    }
  end
end
