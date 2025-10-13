require "test_helper"

class AiProviderTest < ActiveSupport::TestCase
  def setup
    @ai_provider = AiProvider.new(
      name: "OpenAI GPT-4",
      provider_type: "openai",
      api_key: "sk-test-key-123456789",
      api_url: "https://api.openai.com/v1/chat/completions",
      model_identifier: "gpt-4",
      max_tokens: 4000,
      temperature: 0.7,
      active: true,
      position: 1
    )
  end

  test "should be valid with valid attributes" do
    assert @ai_provider.valid?
  end

  test "should require name" do
    @ai_provider.name = nil
    assert_not @ai_provider.valid?
    assert_includes @ai_provider.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    @ai_provider.save!
    duplicate_provider = AiProvider.new(
      name: "OpenAI GPT-4",
      provider_type: "openai",
      api_key: "sk-different-key",
      model_identifier: "gpt-3.5-turbo"
    )
    assert_not duplicate_provider.valid?
    assert_includes duplicate_provider.errors[:name], "has already been taken"
  end

  test "should require provider_type" do
    @ai_provider.provider_type = nil
    assert_not @ai_provider.valid?
    assert_includes @ai_provider.errors[:provider_type], "can't be blank"
  end

  test "should accept valid provider types" do
    valid_types = %w[openai cohere anthropic google]
    valid_types.each do |type|
      @ai_provider.provider_type = type
      assert @ai_provider.valid?, "#{type} should be valid"
    end
  end

  test "should reject invalid provider types" do
    @ai_provider.provider_type = "invalid_provider"
    assert_not @ai_provider.valid?
    assert_includes @ai_provider.errors[:provider_type], "is not included in the list"
  end

  test "should require api_key" do
    @ai_provider.api_key = nil
    assert_not @ai_provider.valid?
    assert_includes @ai_provider.errors[:api_key], "can't be blank"
  end

  test "should require model_identifier" do
    @ai_provider.model_identifier = nil
    assert_not @ai_provider.valid?
    assert_includes @ai_provider.errors[:model_identifier], "can't be blank"
  end

  test "should have default values" do
    provider = AiProvider.new(
      name: "Test Provider",
      provider_type: "openai",
      api_key: "test-key",
      model_identifier: "test-model"
    )
    assert_equal 4000, provider.max_tokens
    assert_equal 0.7, provider.temperature
    assert_equal true, provider.active
    assert_equal 0, provider.position
  end

  test "should validate max_tokens range" do
    @ai_provider.max_tokens = -1
    assert_not @ai_provider.valid?
    
    @ai_provider.max_tokens = 0
    assert_not @ai_provider.valid?
    
    @ai_provider.max_tokens = 1
    assert @ai_provider.valid?
    
    @ai_provider.max_tokens = 100000
    assert @ai_provider.valid?
  end

  test "should validate temperature range" do
    @ai_provider.temperature = -0.1
    assert_not @ai_provider.valid?
    
    @ai_provider.temperature = 0.0
    assert @ai_provider.valid?
    
    @ai_provider.temperature = 1.0
    assert @ai_provider.valid?
    
    @ai_provider.temperature = 2.1
    assert_not @ai_provider.valid?
  end

  test "should have ai_agents association" do
    @ai_provider.save!
    agent = @ai_provider.ai_agents.create!(
      name: "Test Agent",
      agent_type: "content_summarizer",
      prompt: "Test prompt"
    )
    assert_includes @ai_provider.ai_agents, agent
  end

  test "should scope active providers" do
    active_provider = AiProvider.create!(
      name: "Active Provider",
      provider_type: "openai",
      api_key: "active-key",
      model_identifier: "gpt-4",
      active: true
    )
    inactive_provider = AiProvider.create!(
      name: "Inactive Provider",
      provider_type: "openai",
      api_key: "inactive-key",
      model_identifier: "gpt-3.5",
      active: false
    )
    
    active_providers = AiProvider.active
    assert_includes active_providers, active_provider
    assert_not_includes active_providers, inactive_provider
  end

  test "should scope by provider type" do
    openai_provider = AiProvider.create!(
      name: "OpenAI Provider",
      provider_type: "openai",
      api_key: "openai-key",
      model_identifier: "gpt-4"
    )
    cohere_provider = AiProvider.create!(
      name: "Cohere Provider",
      provider_type: "cohere",
      api_key: "cohere-key",
      model_identifier: "command"
    )
    
    openai_providers = AiProvider.by_type("openai")
    assert_includes openai_providers, openai_provider
    assert_not_includes openai_providers, cohere_provider
  end

  test "should scope ordered by position" do
    provider1 = AiProvider.create!(
      name: "Provider 1",
      provider_type: "openai",
      api_key: "key1",
      model_identifier: "model1",
      position: 2
    )
    provider2 = AiProvider.create!(
      name: "Provider 2",
      provider_type: "openai",
      api_key: "key2",
      model_identifier: "model2",
      position: 1
    )
    
    ordered_providers = AiProvider.ordered
    assert_equal provider2, ordered_providers.first
    assert_equal provider1, ordered_providers.second
  end

  test "should have display_name method" do
    assert_equal "OpenAI GPT-4", @ai_provider.display_name
    
    @ai_provider.name = "Custom Provider Name"
    assert_equal "Custom Provider Name", @ai_provider.display_name
  end

  test "should have latest_model_for_type class method" do
    AiProvider.create!(
      name: "OpenAI GPT-4",
      provider_type: "openai",
      api_key: "key1",
      model_identifier: "gpt-4",
      position: 1
    )
    AiProvider.create!(
      name: "OpenAI GPT-3.5",
      provider_type: "openai",
      api_key: "key2",
      model_identifier: "gpt-3.5-turbo",
      position: 2
    )
    
    latest = AiProvider.latest_model_for_type("openai")
    assert_equal "gpt-3.5-turbo", latest.model_identifier
  end

  test "should set defaults on creation" do
    provider = AiProvider.create!(
      name: "Test Provider",
      provider_type: "openai",
      api_key: "test-key",
      model_identifier: "test-model"
    )
    
    assert_equal 4000, provider.max_tokens
    assert_equal 0.7, provider.temperature
    assert_equal true, provider.active
    assert_equal 0, provider.position
  end

  test "should handle provider types correctly" do
    AiProvider::PROVIDER_TYPES.each do |type|
      provider = AiProvider.new(
        name: "Test #{type}",
        provider_type: type,
        api_key: "test-key",
        model_identifier: "test-model"
      )
      assert provider.valid?, "#{type} provider should be valid"
    end
  end

  test "should prevent deletion if has active agents" do
    @ai_provider.save!
    @ai_provider.ai_agents.create!(
      name: "Test Agent",
      agent_type: "content_summarizer",
      prompt: "Test prompt"
    )
    
    assert_not @ai_provider.destroy
    assert_includes @ai_provider.errors[:base], "Cannot delete provider with active agents"
  end

  test "should allow deletion if no agents" do
    @ai_provider.save!
    assert @ai_provider.destroy
  end

  test "should validate api_url format" do
    @ai_provider.api_url = "invalid-url"
    assert_not @ai_provider.valid?
    
    @ai_provider.api_url = "https://api.example.com/v1"
    assert @ai_provider.valid?
    
    @ai_provider.api_url = "http://api.example.com/v1"
    assert @ai_provider.valid?
  end

  test "should handle nil api_url" do
    @ai_provider.api_url = nil
    assert @ai_provider.valid? # api_url is optional
  end

  test "should have proper string representation" do
    @ai_provider.save!
    assert_equal "OpenAI GPT-4", @ai_provider.to_s
  end
end



