require 'test_helper'

class AiWorkflowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    @user.regenerate_api_key! unless @user.api_key.present?
    @ai_provider = ai_providers(:cohere)
    @ai_agent = ai_agents(:content_summarizer)
  end

  test "complete AI workflow from API call to usage logging" do
    # Skip if no real API key configured
    skip "Requires real AI API configuration" unless @ai_provider.api_key.present? && @ai_provider.api_key != "test-api-key"
    
    initial_usage_count = AiUsage.count
    
    # Make API call
    post "/api/v1/chat/completions",
         params: {
           model: "content-summarizer",
           messages: [
             { role: "user", content: "Summarize this: RailsPress is a modern CMS built on Ruby on Rails." }
           ],
           temperature: 0.7,
           max_tokens: 100,
           n: 1
         }.to_json,
         headers: {
           'Authorization' => "Bearer #{@user.api_key}",
           'Content-Type' => 'application/json'
         }

    assert_response :success
    
    # Verify response format
    response_data = JSON.parse(response.body)
    assert_equal "chat.completion", response_data["object"]
    assert_equal "content-summarizer", response_data["model"]
    assert response_data["choices"].present?
    assert response_data["usage"].present?
    
    # Verify usage was logged
    assert_equal initial_usage_count + 1, AiUsage.count
    
    usage = AiUsage.last
    assert_equal @ai_agent, usage.ai_agent
    assert_equal @user, usage.user
    assert usage.success
    assert usage.tokens_used > 0
    assert usage.response_time > 0
    assert usage.prompt.present?
    assert usage.response.present?
    
    # Verify the response content is reasonable
    response_content = response_data["choices"][0]["message"]["content"]
    assert response_content.length > 10, "Response should be substantial"
    assert response_content.downcase.include?("rails"), "Response should mention Rails"
  end

  test "multiple agent types work correctly" do
    # Skip if no real API key configured
    skip "Requires real AI API configuration" unless @ai_provider.api_key.present? && @ai_provider.api_key != "test-api-key"
    
    agents_to_test = [
      { model: "content-summarizer", content: "RailsPress is a modern CMS built on Ruby on Rails." },
      { model: "post-writer", content: "Write a short blog post about the benefits of using RailsPress." },
      { model: "seo-analyzer", content: "Analyze this content for SEO: RailsPress is a modern Rails-based CMS." }
    ]
    
    agents_to_test.each do |agent_test|
      post "/api/v1/chat/completions",
           params: {
             model: agent_test[:model],
             messages: [
               { role: "user", content: agent_test[:content] }
             ],
             temperature: 0.7,
             max_tokens: 200,
             n: 1
           }.to_json,
           headers: {
             'Authorization' => "Bearer #{@user.api_key}",
             'Content-Type' => 'application/json'
           }

      assert_response :success, "Failed for model: #{agent_test[:model]}"
      
      response_data = JSON.parse(response.body)
      assert_equal agent_test[:model], response_data["model"]
      assert response_data["choices"][0]["message"]["content"].present?
    end
  end

  test "models endpoint returns all agents" do
    get "/api/v1/models",
        headers: {
          'Authorization' => "Bearer #{@user.api_key}",
          'Content-Type' => 'application/json'
        }

    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_equal "list", response_data["object"]
    assert response_data["data"].is_a?(Array)
    
    # Should have at least the seeded agents
    model_ids = response_data["data"].map { |model| model["id"] }
    assert_includes model_ids, "content-summarizer"
    assert_includes model_ids, "post-writer"
    assert_includes model_ids, "comments-analyzer"
    assert_includes model_ids, "seo-analyzer"
  end

  test "individual model endpoint works" do
    get "/api/v1/models/content-summarizer",
        headers: {
          'Authorization' => "Bearer #{@user.api_key}",
          'Content-Type' => 'application/json'
        }

    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_equal "content-summarizer", response_data["id"]
    assert_equal "model", response_data["object"]
    assert_equal "railspress", response_data["owned_by"]
  end

  test "authentication works correctly" do
    # Test with valid API key
    get "/api/v1/models",
        headers: {
          'Authorization' => "Bearer #{@user.api_key}",
          'Content-Type' => 'application/json'
        }
    assert_response :success
    
    # Test with invalid API key
    get "/api/v1/models",
        headers: {
          'Authorization' => "Bearer invalid-key",
          'Content-Type' => 'application/json'
        }
    assert_response :unauthorized
    
    # Test without API key
    get "/api/v1/models",
        headers: {
          'Content-Type' => 'application/json'
        }
    assert_response :unauthorized
  end

  test "error handling works correctly" do
    # Test with invalid model
    post "/api/v1/chat/completions",
         params: {
           model: "nonexistent-model",
           messages: [
             { role: "user", content: "Test message" }
           ]
         }.to_json,
         headers: {
           'Authorization' => "Bearer #{@user.api_key}",
           'Content-Type' => 'application/json'
         }

    assert_response :not_found
    response_data = JSON.parse(response.body)
    assert_equal "model_not_found", response_data["error"]["code"]
    
    # Test with missing messages
    post "/api/v1/chat/completions",
         params: {
           model: "content-summarizer"
         }.to_json,
         headers: {
           'Authorization' => "Bearer #{@user.api_key}",
           'Content-Type' => 'application/json'
         }

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_equal "missing_messages", response_data["error"]["code"]
  end

  test "usage statistics are calculated correctly" do
    # Skip if no real API key configured
    skip "Requires real AI API configuration" unless @ai_provider.api_key.present? && @ai_provider.api_key != "test-api-key"
    
    # Clear existing usages for clean test
    @ai_agent.ai_usages.destroy_all
    
    # Create some usage records
    @ai_agent.ai_usages.create!(
      user: @user,
      prompt: "Test prompt 1",
      response: "Test response 1",
      tokens_used: 100,
      cost: 0.001,
      response_time: 1.5,
      success: true
    )
    
    @ai_agent.ai_usages.create!(
      user: @user,
      prompt: "Test prompt 2",
      response: "Test response 2",
      tokens_used: 150,
      cost: 0.002,
      response_time: 2.0,
      success: true
    )
    
    @ai_agent.ai_usages.create!(
      user: @user,
      prompt: "Test prompt 3",
      response: nil,
      tokens_used: 50,
      cost: 0.0,
      response_time: 1.0,
      success: false,
      error_message: "Test error"
    )
    
    # Test statistics
    assert_equal 3, @ai_agent.total_requests
    assert_equal 300, @ai_agent.total_tokens
    assert_equal 0.003, @ai_agent.total_cost
    assert_equal 66.7, @ai_agent.success_rate.round(1)
    assert_equal 1.5, @ai_agent.average_response_time
  end
end

