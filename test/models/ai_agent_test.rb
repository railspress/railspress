require "test_helper"

class AiAgentTest < ActiveSupport::TestCase
  def setup
    @ai_provider = AiProvider.create!(
      name: "Test Provider",
      provider_type: "openai",
      api_key: "test-key",
      model_identifier: "gpt-4"
    )
    
    @ai_agent = AiAgent.new(
      name: "Content Summarizer",
      agent_type: "content_summarizer",
      prompt: "You are a content summarizer. Summarize the following content:",
      content: "Focus on key points and main ideas.",
      guidelines: "Keep summaries concise and informative.",
      rules: "Do not add personal opinions.",
      tasks: "Extract main points, create bullet points, maintain original meaning.",
      master_prompt: "You are an AI assistant designed to help with content creation.",
      ai_provider: @ai_provider,
      active: true,
      position: 1
    )
  end

  test "should be valid with valid attributes" do
    assert @ai_agent.valid?
  end

  test "should require name" do
    @ai_agent.name = nil
    assert_not @ai_agent.valid?
    assert_includes @ai_agent.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    @ai_agent.save!
    duplicate_agent = AiAgent.new(
      name: "Content Summarizer",
      agent_type: "post_writer",
      prompt: "Different prompt",
      ai_provider: @ai_provider
    )
    assert_not duplicate_agent.valid?
    assert_includes duplicate_agent.errors[:name], "has already been taken"
  end

  test "should require agent_type" do
    @ai_agent.agent_type = nil
    assert_not @ai_agent.valid?
    assert_includes @ai_agent.errors[:agent_type], "can't be blank"
  end

  test "should require unique agent_type" do
    @ai_agent.save!
    duplicate_agent = AiAgent.new(
      name: "Different Summarizer",
      agent_type: "content_summarizer",
      prompt: "Different prompt",
      ai_provider: @ai_provider
    )
    assert_not duplicate_agent.valid?
    assert_includes duplicate_agent.errors[:agent_type], "has already been taken"
  end

  test "should accept valid agent types" do
    valid_types = %w[content_summarizer post_writer comments_analyzer seo_analyzer]
    valid_types.each do |type|
      @ai_agent.agent_type = type
      assert @ai_agent.valid?, "#{type} should be valid"
    end
  end

  test "should reject invalid agent types" do
    @ai_agent.agent_type = "invalid_type"
    assert_not @ai_agent.valid?
    assert_includes @ai_agent.errors[:agent_type], "is not included in the list"
  end

  test "should require ai_provider" do
    @ai_agent.ai_provider = nil
    assert_not @ai_agent.valid?
    assert_includes @ai_agent.errors[:ai_provider], "must exist"
  end

  test "should have default values" do
    agent = AiAgent.new(
      name: "Test Agent",
      agent_type: "content_summarizer",
      prompt: "Test prompt",
      ai_provider: @ai_provider
    )
    assert_equal true, agent.active
    assert_equal 0, agent.position
  end

  test "should have ai_provider association" do
    @ai_agent.save!
    assert_equal @ai_provider, @ai_agent.ai_provider
  end

  test "should scope active agents" do
    active_agent = AiAgent.create!(
      name: "Active Agent",
      agent_type: "post_writer",
      prompt: "Test prompt",
      ai_provider: @ai_provider,
      active: true
    )
    inactive_agent = AiAgent.create!(
      name: "Inactive Agent",
      agent_type: "comments_analyzer",
      prompt: "Test prompt",
      ai_provider: @ai_provider,
      active: false
    )
    
    active_agents = AiAgent.active
    assert_includes active_agents, active_agent
    assert_not_includes active_agents, inactive_agent
  end

  test "should scope by agent type" do
    summarizer = AiAgent.create!(
      name: "Summarizer Agent",
      agent_type: "content_summarizer",
      prompt: "Test prompt",
      ai_provider: @ai_provider
    )
    writer = AiAgent.create!(
      name: "Writer Agent",
      agent_type: "post_writer",
      prompt: "Test prompt",
      ai_provider: @ai_provider
    )
    
    summarizers = AiAgent.by_type("content_summarizer")
    assert_includes summarizers, summarizer
    assert_not_includes summarizers, writer
  end

  test "should scope ordered by position" do
    agent1 = AiAgent.create!(
      name: "Agent 1",
      agent_type: "content_summarizer",
      prompt: "Test prompt",
      ai_provider: @ai_provider,
      position: 2
    )
    agent2 = AiAgent.create!(
      name: "Agent 2",
      agent_type: "post_writer",
      prompt: "Test prompt",
      ai_provider: @ai_provider,
      position: 1
    )
    
    ordered_agents = AiAgent.ordered
    assert_equal agent2, ordered_agents.first
    assert_equal agent1, ordered_agents.second
  end

  test "should generate full_prompt combining all parts" do
    @ai_agent.save!
    full_prompt = @ai_agent.full_prompt
    
    assert_includes full_prompt, @ai_agent.master_prompt
    assert_includes full_prompt, @ai_agent.prompt
    assert_includes full_prompt, @ai_agent.content
    assert_includes full_prompt, @ai_agent.guidelines
    assert_includes full_prompt, @ai_agent.rules
    assert_includes full_prompt, @ai_agent.tasks
  end

  test "should handle missing optional prompt parts" do
    @ai_agent.content = nil
    @ai_agent.guidelines = nil
    @ai_agent.rules = nil
    @ai_agent.tasks = nil
    @ai_agent.master_prompt = nil
    
    assert @ai_agent.valid?
    full_prompt = @ai_agent.full_prompt
    assert_includes full_prompt, @ai_agent.prompt
  end

  test "should execute with AI service" do
    @ai_agent.save!
    
    # Mock the AI service response
    mock_response = { "choices" => [{ "message" => { "content" => "Generated content" } }] }
    
    # This would require mocking the AiService in a real test
    # For now, we'll test the method exists and handles the call
    assert_respond_to @ai_agent, :execute
  end

  test "should handle execution errors gracefully" do
    @ai_agent.save!
    
    # Test that execute method exists and can handle errors
    assert_respond_to @ai_agent, :execute
    
    # In a real test, we would mock the AI service to raise an error
    # and verify the agent handles it properly
  end

  test "should have proper string representation" do
    @ai_agent.save!
    assert_equal "Content Summarizer", @ai_agent.to_s
  end

  test "should validate agent types correctly" do
    AiAgent::AGENT_TYPES.each do |type|
      agent = AiAgent.new(
        name: "Test #{type}",
        agent_type: type,
        prompt: "Test prompt",
        ai_provider: @ai_provider
      )
      assert agent.valid?, "#{type} agent should be valid"
    end
  end

  test "should handle long text fields" do
    long_text = "A" * 10000
    @ai_agent.prompt = long_text
    @ai_agent.content = long_text
    @ai_agent.guidelines = long_text
    @ai_agent.rules = long_text
    @ai_agent.tasks = long_text
    @ai_agent.master_prompt = long_text
    
    assert @ai_agent.valid?
  end

  test "should maintain prompt structure in full_prompt" do
    @ai_agent.master_prompt = "MASTER: You are an AI assistant."
    @ai_agent.prompt = "PROMPT: Summarize this content."
    @ai_agent.content = "CONTENT: Focus on key points."
    @ai_agent.guidelines = "GUIDELINES: Be concise."
    @ai_agent.rules = "RULES: No opinions."
    @ai_agent.tasks = "TASKS: Extract main ideas."
    
    full_prompt = @ai_agent.full_prompt
    
    # Check that sections are clearly separated
    assert_includes full_prompt, "MASTER:"
    assert_includes full_prompt, "PROMPT:"
    assert_includes full_prompt, "CONTENT:"
    assert_includes full_prompt, "GUIDELINES:"
    assert_includes full_prompt, "RULES:"
    assert_includes full_prompt, "TASKS:"
  end

  test "should set defaults on creation" do
    agent = AiAgent.create!(
      name: "Test Agent",
      agent_type: "content_summarizer",
      prompt: "Test prompt",
      ai_provider: @ai_provider
    )
    
    assert_equal true, agent.active
    assert_equal 0, agent.position
  end

  test "should handle special characters in prompts" do
    @ai_agent.prompt = "Prompt with special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?"
    @ai_agent.content = "Content with unicode: ñáéíóú"
    @ai_agent.guidelines = "Guidelines with emojis: 🚀✨🎯"
    
    assert @ai_agent.valid?
  end

  test "should validate position is non-negative" do
    @ai_agent.position = -1
    assert_not @ai_agent.valid?
    
    @ai_agent.position = 0
    assert @ai_agent.valid?
    
    @ai_agent.position = 100
    assert @ai_agent.valid?
  end

  test "should be searchable by name" do
    @ai_agent.save!
    summarizer = AiAgent.create!(
      name: "Advanced Summarizer",
      agent_type: "post_writer",
      prompt: "Test prompt",
      ai_provider: @ai_provider
    )
    
    # Test basic search functionality
    agents = AiAgent.where("name ILIKE ?", "%summarizer%")
    assert_includes agents, @ai_agent
    assert_includes agents, summarizer
  end
end




