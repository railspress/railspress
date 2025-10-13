require "test_helper"

class Api::V1::AiAgentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    @api_key = @user.api_keys.create!(name: "Test API Key")
    
    @ai_provider = ai_providers(:one)
    @ai_agent = AiAgent.create!(
      name: "Test Agent",
      agent_type: "content_summarizer",
      prompt: "Summarize this content:",
      ai_provider: @ai_provider
    )
  end

  test "should execute agent by ID" do
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { input: "This is test content to summarize." },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "success", response_data["status"]
    assert_not_nil response_data["result"]
  end

  test "should execute agent by type" do
    post execute_by_type_api_v1_ai_agents_url("content_summarizer"), 
         params: { input: "This is test content to summarize." },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "success", response_data["status"]
    assert_not_nil response_data["result"]
  end

  test "should require authentication" do
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { input: "Test input" }
    
    assert_response :unauthorized
    response_data = JSON.parse(response.body)
    assert_equal "error", response_data["status"]
    assert_includes response_data["message"], "Invalid API key"
  end

  test "should handle invalid API key" do
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { input: "Test input" },
         headers: { "Authorization" => "Bearer invalid_token" }
    
    assert_response :unauthorized
    response_data = JSON.parse(response.body)
    assert_equal "error", response_data["status"]
    assert_includes response_data["message"], "Invalid API key"
  end

  test "should handle expired API key" do
    expired_key = @user.api_keys.create!(name: "Expired Key", expires_at: 1.day.ago)
    
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { input: "Test input" },
         headers: { "Authorization" => "Bearer #{expired_key.token}" }
    
    assert_response :unauthorized
    response_data = JSON.parse(response.body)
    assert_equal "error", response_data["status"]
    assert_includes response_data["message"], "API key has expired"
  end

  test "should handle agent not found" do
    post execute_api_v1_ai_agent_url(999999), 
         params: { input: "Test input" },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :not_found
    response_data = JSON.parse(response.body)
    assert_equal "error", response_data["status"]
    assert_includes response_data["message"], "Agent not found"
  end

  test "should handle inactive agent" do
    @ai_agent.update!(active: false)
    
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { input: "Test input" },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :unprocessable_entity
    response_data = JSON.parse(response.body)
    assert_equal "error", response_data["status"]
    assert_includes response_data["message"], "Agent is not active"
  end

  test "should handle agent type not found" do
    post execute_by_type_api_v1_ai_agents_url("non_existent_type"), 
         params: { input: "Test input" },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :not_found
    response_data = JSON.parse(response.body)
    assert_equal "error", response_data["status"]
    assert_includes response_data["message"], "No active agent found for type"
  end

  test "should handle missing input" do
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: {},
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :unprocessable_entity
    response_data = JSON.parse(response.body)
    assert_equal "error", response_data["status"]
    assert_includes response_data["message"], "Input is required"
  end

  test "should handle empty input" do
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { input: "" },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :unprocessable_entity
    response_data = JSON.parse(response.body)
    assert_equal "error", response_data["status"]
    assert_includes response_data["message"], "Input cannot be empty"
  end

  test "should handle AI service errors" do
    # Mock AI service error
    AiService.any_instance.stubs(:generate).raises(StandardError.new("AI Service Error"))
    
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { input: "Test input" },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :unprocessable_entity
    response_data = JSON.parse(response.body)
    assert_equal "error", response_data["status"]
    assert_includes response_data["message"], "AI Service Error"
  end

  test "should handle rate limiting" do
    # Mock rate limiting
    ApiRateLimit.any_instance.stubs(:exceeded?).returns(true)
    
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { input: "Test input" },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :too_many_requests
    response_data = JSON.parse(response.body)
    assert_equal "error", response_data["status"]
    assert_includes response_data["message"], "Rate limit exceeded"
  end

  test "should handle large input" do
    large_input = "Test input " * 10000
    
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { input: large_input },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "success", response_data["status"]
  end

  test "should handle special characters in input" do
    special_input = "Test input with special chars: !@#$%^&*()_+-=[]{}|;':\",./<>? and unicode: ñáéíóú"
    
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { input: special_input },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "success", response_data["status"]
  end

  test "should handle JSON input" do
    json_input = { "content" => "Test content", "type" => "article" }.to_json
    
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { input: json_input },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "success", response_data["status"]
  end

  test "should handle XML input" do
    xml_input = "<content>Test content</content>"
    
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { input: xml_input },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "success", response_data["status"]
  end

  test "should handle HTML input" do
    html_input = "<p>Test content with <strong>HTML</strong> tags</p>"
    
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { input: html_input },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "success", response_data["status"]
  end

  test "should handle markdown input" do
    markdown_input = "# Test Content\n\nThis is **bold** and *italic* text."
    
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { input: markdown_input },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "success", response_data["status"]
  end

  test "should handle multiple agents of same type" do
    # Create another agent of the same type
    another_agent = AiAgent.create!(
      name: "Another Summarizer",
      agent_type: "content_summarizer",
      prompt: "Another summarize prompt:",
      ai_provider: @ai_provider,
      position: 2
    )
    
    post execute_by_type_api_v1_ai_agents_url("content_summarizer"), 
         params: { input: "Test input" },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "success", response_data["status"]
    
    # Should use the first agent (lowest position)
    assert_equal @ai_agent.id, response_data["agent_id"]
  end

  test "should handle agent with custom parameters" do
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { 
           input: "Test input",
           max_tokens: 1000,
           temperature: 0.5
         },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "success", response_data["status"]
  end

  test "should handle agent with streaming response" do
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { 
           input: "Test input",
           stream: true
         },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :success
    assert_equal "text/event-stream", response.content_type
  end

  test "should handle agent with callback URL" do
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { 
           input: "Test input",
           callback_url: "https://example.com/callback"
         },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :accepted
    response_data = JSON.parse(response.body)
    assert_equal "success", response_data["status"]
    assert_includes response_data["message"], "Processing in background"
  end

  test "should handle agent execution logging" do
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { input: "Test input" },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :success
    
    # Check that execution was logged
    execution_log = AiAgentExecutionLog.last
    assert_not_nil execution_log
    assert_equal @ai_agent.id, execution_log.ai_agent_id
    assert_equal @user.id, execution_log.user_id
    assert_equal "Test input", execution_log.input
  end

  test "should handle agent execution metrics" do
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { input: "Test input" },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :success
    
    # Check that metrics were updated
    @ai_agent.reload
    assert @ai_agent.execution_count > 0
    assert_not_nil @ai_agent.last_executed_at
  end

  test "should handle agent execution caching" do
    # First execution
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { input: "Cached input" },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :success
    
    # Second execution with same input should use cache
    post execute_api_v1_ai_agent_url(@ai_agent), 
         params: { input: "Cached input" },
         headers: { "Authorization" => "Bearer #{@api_key.token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "cached", response_data["cache_status"]
  end
end




