require 'test_helper'

class AiAgentTest < ActiveSupport::TestCase
  setup do
    @ai_provider = ai_providers(:cohere)
    @ai_agent = ai_agents(:content_summarizer)
    @user = users(:admin)
  end

  test "should be valid" do
    assert @ai_agent.valid?
  end

  test "name should be present" do
    agent = AiAgent.new
    agent.name = nil
    assert_not agent.valid?
    assert_includes agent.errors[:name], "can't be blank"
  end

  test "agent_type should be present" do
    agent = AiAgent.new
    agent.agent_type = nil
    assert_not agent.valid?
    assert_includes agent.errors[:agent_type], "can't be blank"
  end

  test "agent_type should be in allowed list" do
    agent = AiAgent.new
    agent.agent_type = "invalid_type"
    assert_not agent.valid?
    assert_includes agent.errors[:agent_type], "is not included in the list"
  end

  test "ai_provider should be present" do
    @ai_agent.ai_provider = nil
    assert_not @ai_agent.valid?
    assert_includes @ai_agent.errors[:ai_provider], "must exist"
  end

  test "should belong to ai_provider" do
    assert_equal @ai_provider, @ai_agent.ai_provider
  end

  test "should have many ai_usages" do
    assert_respond_to @ai_agent, :ai_usages
  end

  test "should execute with valid input" do
    # Skip this test if we don't have a real AI API key configured
    skip "Requires real AI API configuration" unless @ai_provider.api_key.present?
    
    result = @ai_agent.execute("Test input", {}, @user)
    
    assert result.present?
    assert_equal 1, @ai_agent.ai_usages.count
    
    usage = @ai_agent.ai_usages.last
    assert_equal @user, usage.user
    assert usage.success
    assert usage.tokens_used > 0
    assert usage.response_time > 0
    assert usage.prompt.present?
    assert usage.response.present?
  end

  test "should handle AI service errors" do
    # Skip this test as it requires mocking
    skip "Requires AI service mocking"
  end

  test "should build full prompt correctly" do
    user_input = "Test input"
    context = { temperature: 0.7 }
    
    full_prompt = @ai_agent.full_prompt(user_input, context)
    
    assert_includes full_prompt, @ai_agent.prompt
    assert_includes full_prompt, user_input
  end

  test "should calculate usage statistics correctly" do
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
      success: false
    )
    
    assert_equal 3, @ai_agent.total_requests
    assert_equal 300, @ai_agent.total_tokens
    assert_equal 0.003, @ai_agent.total_cost
    assert_equal 66.7, @ai_agent.success_rate.round(1)
    assert_equal 1.5, @ai_agent.average_response_time
  end

  test "should scope active agents" do
    active_agent = ai_agents(:content_summarizer)
    inactive_agent = AiAgent.create!(
      name: "Inactive Agent",
      description: "Test agent",
      agent_type: "content_summarizer", # Use valid agent type
      prompt: "Test prompt",
      ai_provider: @ai_provider,
      active: false
    )
    
    active_agents = AiAgent.active
    
    assert_includes active_agents, active_agent
    assert_not_includes active_agents, inactive_agent
  end

  test "should calculate tokens correctly" do
    prompt = "This is a test message with multiple words."
    response = "This is a response."
    tokens = @ai_agent.send(:calculate_tokens, prompt, response)
    
    # Simple estimation: ~4 characters per token
    total_text = prompt + response
    expected_tokens = (total_text.length / 4.0).ceil
    assert_equal expected_tokens, tokens
  end

  test "should calculate cost correctly" do
    prompt = "This is a test prompt with multiple words to calculate tokens."
    response = "This is a test response with multiple words."
    
    # Test with Cohere provider (should use default estimate)
    cost = @ai_agent.send(:calculate_cost, prompt, response)
    
    # The method calculates tokens from the text and then applies cost
    expected_tokens = @ai_agent.send(:calculate_tokens, prompt, response)
    expected_cost = expected_tokens * 0.00001 # Default estimate for non-OpenAI providers
    
    assert_equal expected_cost, cost
  end

  test "should handle user fallback in execute" do
    # Skip this test if we don't have a real AI API key configured
    skip "Requires real AI API configuration" unless @ai_provider.api_key.present?
    
    result = @ai_agent.execute("Test input")
    
    assert result.present?
    usage = @ai_agent.ai_usages.last
    assert_equal User.first, usage.user # Should fallback to first user
  end
end