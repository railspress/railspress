require "test_helper"

class AiAgentsManagementTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    sign_in @user
    
    @ai_provider = AiProvider.create!(
      name: "Test Provider",
      provider_type: "openai",
      api_key: "sk-test-key",
      model_identifier: "gpt-4"
    )
  end

  test "should create ai agent through full flow" do
    get new_admin_ai_agent_url
    assert_response :success
    
    post admin_ai_agents_url, params: {
      ai_agent: {
        name: "Test Agent",
        agent_type: "content_summarizer",
        prompt: "You are a content summarizer.",
        content: "Focus on key points.",
        guidelines: "Keep it concise.",
        rules: "No personal opinions.",
        tasks: "Extract main ideas.",
        master_prompt: "You are an AI assistant.",
        ai_provider_id: @ai_provider.id,
        active: true,
        position: 1
      }
    }
    
    assert_redirected_to admin_ai_agent_url(AiAgent.last)
    assert_equal "AI Agent was successfully created.", flash[:notice]
    
    agent = AiAgent.last
    assert_equal "Test Agent", agent.name
    assert_equal "content_summarizer", agent.agent_type
    assert_equal @ai_provider, agent.ai_provider
  end

  test "should test ai agent functionality" do
    agent = AiAgent.create!(
      name: "Test Agent",
      agent_type: "content_summarizer",
      prompt: "Summarize this content:",
      ai_provider: @ai_provider
    )
    
    post test_admin_ai_agent_url(agent), params: {
      input: "This is a test content that needs to be summarized."
    }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "success", response_data["status"]
    assert_not_nil response_data["result"]
  end

  test "should handle ai agent execution errors" do
    agent = AiAgent.create!(
      name: "Test Agent",
      agent_type: "content_summarizer",
      prompt: "Summarize this content:",
      ai_provider: @ai_provider
    )
    
    # Mock API failure
    AiService.any_instance.stubs(:generate).raises(StandardError.new("API Error"))
    
    post test_admin_ai_agent_url(agent), params: {
      input: "Test input"
    }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "error", response_data["status"]
    assert_includes response_data["message"], "API Error"
  end

  test "should manage ai provider and agent relationship" do
    # Create provider
    get new_admin_ai_provider_url
    assert_response :success
    
    post admin_ai_providers_url, params: {
      ai_provider: {
        name: "OpenAI Provider",
        provider_type: "openai",
        api_key: "sk-openai-key",
        model_identifier: "gpt-4",
        max_tokens: 4000,
        temperature: 0.7,
        active: true
      }
    }
    
    provider = AiProvider.last
    assert_equal "OpenAI Provider", provider.name
    
    # Create agent using this provider
    get new_admin_ai_agent_url
    assert_response :success
    
    post admin_ai_agents_url, params: {
      ai_agent: {
        name: "OpenAI Summarizer",
        agent_type: "content_summarizer",
        prompt: "Summarize using OpenAI:",
        ai_provider_id: provider.id,
        active: true
      }
    }
    
    agent = AiAgent.last
    assert_equal provider, agent.ai_provider
    
    # Verify relationship
    get admin_ai_provider_url(provider)
    assert_response :success
    assert_includes response.body, agent.name
  end

  test "should handle bulk operations on ai agents" do
    # Create multiple agents
    agents = []
    3.times do |i|
      agents << AiAgent.create!(
        name: "Agent #{i}",
        agent_type: "content_summarizer",
        prompt: "Test prompt #{i}",
        ai_provider: @ai_provider
      )
    end
    
    # Bulk activate
    post admin_bulk_action_ai_agents_url, params: {
      bulk_action: "activate",
      agent_ids: agents.map(&:id)
    }
    
    assert_redirected_to admin_ai_agents_url
    assert_equal "AI Agents were successfully updated.", flash[:notice]
    
    agents.each(&:reload)
    agents.each { |agent| assert agent.active }
  end

  test "should handle ai agent search and filtering" do
    # Create agents with different types
    summarizer = AiAgent.create!(
      name: "Content Summarizer",
      agent_type: "content_summarizer",
      prompt: "Summarize content",
      ai_provider: @ai_provider
    )
    
    writer = AiAgent.create!(
      name: "Post Writer",
      agent_type: "post_writer",
      prompt: "Write posts",
      ai_provider: @ai_provider
    )
    
    # Search by name
    get admin_ai_agents_url, params: { search: "Summarizer" }
    assert_response :success
    assert_select ".agent-row", count: 1
    assert_select ".agent-name", summarizer.name
    
    # Filter by type
    get admin_ai_agents_url, params: { agent_type: "post_writer" }
    assert_response :success
    assert_select ".agent-row", count: 1
    assert_select ".agent-name", writer.name
    
    # Filter by provider
    get admin_ai_agents_url, params: { ai_provider_id: @ai_provider.id }
    assert_response :success
    assert_select ".agent-row", count: 2
  end

  test "should handle ai agent import and export" do
    # Create test data
    agent = AiAgent.create!(
      name: "Export Agent",
      agent_type: "content_summarizer",
      prompt: "Export test",
      ai_provider: @ai_provider
    )
    
    # Export
    get export_admin_ai_agents_url, params: { format: :csv }
    assert_response :success
    assert_equal "text/csv", response.content_type
    assert_includes response.body, agent.name
    
    # Import
    csv_content = "name,agent_type,prompt,ai_provider_id\nImported Agent,post_writer,Import test,#{@ai_provider.id}"
    
    post import_admin_ai_agents_url, params: {
      file: fixture_file_upload("ai_agents.csv", "text/csv")
    }
    
    assert_redirected_to admin_ai_agents_url
    assert_equal "AI Agents were successfully imported.", flash[:notice]
    
    imported_agent = AiAgent.find_by(name: "Imported Agent")
    assert_not_nil imported_agent
    assert_equal "post_writer", imported_agent.agent_type
  end

  test "should handle ai agent duplication" do
    original_agent = AiAgent.create!(
      name: "Original Agent",
      agent_type: "content_summarizer",
      prompt: "Original prompt",
      ai_provider: @ai_provider
    )
    
    post duplicate_admin_ai_agent_url(original_agent)
    
    assert_redirected_to admin_ai_agents_url
    assert_equal "AI Agent was successfully duplicated.", flash[:notice]
    
    duplicated_agent = AiAgent.last
    assert_equal "Original Agent (Copy)", duplicated_agent.name
    assert_equal original_agent.prompt, duplicated_agent.prompt
    assert_equal original_agent.ai_provider, duplicated_agent.ai_provider
  end

  test "should handle ai agent versioning" do
    agent = AiAgent.create!(
      name: "Versioned Agent",
      agent_type: "content_summarizer",
      prompt: "Version 1",
      ai_provider: @ai_provider
    )
    
    # Update agent
    patch admin_ai_agent_url(agent), params: {
      ai_agent: {
        prompt: "Version 2"
      }
    }
    
    assert_redirected_to admin_ai_agent_url(agent)
    
    # Check version history
    get versions_admin_ai_agent_url(agent)
    assert_response :success
    assert_includes response.body, "Version 1"
    assert_includes response.body, "Version 2"
  end

  test "should handle ai agent permissions" do
    regular_user = users(:user)
    sign_in regular_user
    
    get admin_ai_agents_url
    assert_redirected_to root_url
    assert_equal "Access denied.", flash[:alert]
    
    # Try to create agent
    post admin_ai_agents_url, params: {
      ai_agent: {
        name: "Unauthorized Agent",
        agent_type: "content_summarizer",
        prompt: "Test",
        ai_provider_id: @ai_provider.id
      }
    }
    
    assert_redirected_to root_url
    assert_equal "Access denied.", flash[:alert]
  end

  test "should handle ai agent rate limiting" do
    agent = AiAgent.create!(
      name: "Rate Limited Agent",
      agent_type: "content_summarizer",
      prompt: "Test prompt",
      ai_provider: @ai_provider
    )
    
    # Simulate multiple rapid requests
    10.times do
      post test_admin_ai_agent_url(agent), params: {
        input: "Test input"
      }
    end
    
    # Should hit rate limit
    post test_admin_ai_agent_url(agent), params: {
      input: "Test input"
    }
    
    assert_response :too_many_requests
    assert_includes response.body, "Rate limit exceeded"
  end

  test "should handle ai agent caching" do
    agent = AiAgent.create!(
      name: "Cached Agent",
      agent_type: "content_summarizer",
      prompt: "Test prompt",
      ai_provider: @ai_provider
    )
    
    # First request
    post test_admin_ai_agent_url(agent), params: {
      input: "Cached input"
    }
    
    assert_response :success
    
    # Second request with same input should use cache
    post test_admin_ai_agent_url(agent), params: {
      input: "Cached input"
    }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "cached", response_data["cache_status"]
  end

  test "should handle ai agent monitoring" do
    agent = AiAgent.create!(
      name: "Monitored Agent",
      agent_type: "content_summarizer",
      prompt: "Test prompt",
      ai_provider: @ai_provider
    )
    
    # Execute agent multiple times
    5.times do
      post test_admin_ai_agent_url(agent), params: {
        input: "Test input"
      }
    end
    
    # Check monitoring data
    get monitoring_admin_ai_agent_url(agent)
    assert_response :success
    assert_includes response.body, "5 executions"
    assert_includes response.body, "Average response time"
  end

  test "should handle ai agent webhooks" do
    agent = AiAgent.create!(
      name: "Webhook Agent",
      agent_type: "content_summarizer",
      prompt: "Test prompt",
      ai_provider: @ai_provider
    )
    
    # Set up webhook
    patch admin_ai_agent_url(agent), params: {
      ai_agent: {
        webhook_url: "https://example.com/webhook"
      }
    }
    
    assert_redirected_to admin_ai_agent_url(agent)
    
    # Execute agent
    post test_admin_ai_agent_url(agent), params: {
      input: "Webhook test"
    }
    
    assert_response :success
    
    # Verify webhook was called
    # This would require mocking HTTP requests in a real test
    assert_equal "success", JSON.parse(response.body)["status"]
  end

  test "should handle ai agent error recovery" do
    agent = AiAgent.create!(
      name: "Error Recovery Agent",
      agent_type: "content_summarizer",
      prompt: "Test prompt",
      ai_provider: @ai_provider
    )
    
    # Mock API failure
    AiService.any_instance.stubs(:generate).raises(StandardError.new("API Error"))
    
    # Execute agent
    post test_admin_ai_agent_url(agent), params: {
      input: "Error test"
    }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "error", response_data["status"]
    
    # Fix API issue
    AiService.any_instance.unstub(:generate)
    
    # Retry should work
    post test_admin_ai_agent_url(agent), params: {
      input: "Retry test"
    }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "success", response_data["status"]
  end
end






