require "test_helper"

class AiServiceTest < ActiveSupport::TestCase
  setup do
    @ai_provider = AiProvider.create!(
      name: "Test Provider",
      provider_type: "openai",
      api_key: "sk-test-key-123456789",
      model_identifier: "gpt-4",
      max_tokens: 4000,
      temperature: 0.7
    )
    
    @ai_service = AiService.new(@ai_provider)
  end

  test "should initialize with provider" do
    assert_equal @ai_provider, @ai_service.provider
  end

  test "should generate content with OpenAI" do
    # Mock OpenAI API response
    mock_response = {
      "choices" => [
        {
          "message" => {
            "content" => "Generated content from OpenAI"
          }
        }
      ]
    }
    
    # Mock HTTP request
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .with(
        headers: {
          "Authorization" => "Bearer #{@ai_provider.api_key}",
          "Content-Type" => "application/json"
        },
        body: {
          model: @ai_provider.model_identifier,
          messages: [
            { role: "user", content: "Test prompt" }
          ],
          max_tokens: @ai_provider.max_tokens,
          temperature: @ai_provider.temperature
        }.to_json
      )
      .to_return(status: 200, body: mock_response.to_json)
    
    result = @ai_service.generate("Test prompt")
    
    assert_equal "Generated content from OpenAI", result
  end

  test "should generate content with Cohere" do
    cohere_provider = AiProvider.create!(
      name: "Cohere Provider",
      provider_type: "cohere",
      api_key: "cohere-test-key",
      model_identifier: "command",
      api_url: "https://api.cohere.ai/v1/generate"
    )
    
    ai_service = AiService.new(cohere_provider)
    
    # Mock Cohere API response
    mock_response = {
      "generations" => [
        {
          "text" => "Generated content from Cohere"
        }
      ]
    }
    
    # Mock HTTP request
    stub_request(:post, "https://api.cohere.ai/v1/generate")
      .with(
        headers: {
          "Authorization" => "Bearer #{cohere_provider.api_key}",
          "Content-Type" => "application/json"
        },
        body: {
          model: cohere_provider.model_identifier,
          prompt: "Test prompt",
          max_tokens: cohere_provider.max_tokens,
          temperature: cohere_provider.temperature
        }.to_json
      )
      .to_return(status: 200, body: mock_response.to_json)
    
    result = ai_service.generate("Test prompt")
    
    assert_equal "Generated content from Cohere", result
  end

  test "should generate content with Anthropic" do
    anthropic_provider = AiProvider.create!(
      name: "Anthropic Provider",
      provider_type: "anthropic",
      api_key: "anthropic-test-key",
      model_identifier: "claude-3-sonnet-20240229",
      api_url: "https://api.anthropic.com/v1/messages"
    )
    
    ai_service = AiService.new(anthropic_provider)
    
    # Mock Anthropic API response
    mock_response = {
      "content" => [
        {
          "text" => "Generated content from Anthropic"
        }
      ]
    }
    
    # Mock HTTP request
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .with(
        headers: {
          "x-api-key" => anthropic_provider.api_key,
          "Content-Type" => "application/json"
        },
        body: {
          model: anthropic_provider.model_identifier,
          max_tokens: anthropic_provider.max_tokens,
          messages: [
            { role: "user", content: "Test prompt" }
          ]
        }.to_json
      )
      .to_return(status: 200, body: mock_response.to_json)
    
    result = ai_service.generate("Test prompt")
    
    assert_equal "Generated content from Anthropic", result
  end

  test "should generate content with Google" do
    google_provider = AiProvider.create!(
      name: "Google Provider",
      provider_type: "google",
      api_key: "google-test-key",
      model_identifier: "gemini-pro",
      api_url: "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
    )
    
    ai_service = AiService.new(google_provider)
    
    # Mock Google API response
    mock_response = {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              {
                "text" => "Generated content from Google"
              }
            ]
          }
        }
      ]
    }
    
    # Mock HTTP request
    stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent")
      .with(
        query: { key: google_provider.api_key },
        headers: {
          "Content-Type" => "application/json"
        },
        body: {
          contents: [
            {
              parts: [
                { text: "Test prompt" }
              ]
            }
          ],
          generationConfig: {
            maxOutputTokens: google_provider.max_tokens,
            temperature: google_provider.temperature
          }
        }.to_json
      )
      .to_return(status: 200, body: mock_response.to_json)
    
    result = ai_service.generate("Test prompt")
    
    assert_equal "Generated content from Google", result
  end

  test "should handle API errors gracefully" do
    # Mock API error response
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 401, body: { error: { message: "Invalid API key" } }.to_json)
    
    assert_raises(StandardError, "API Error: Invalid API key") do
      @ai_service.generate("Test prompt")
    end
  end

  test "should handle network errors" do
    # Mock network error
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_raise(Net::TimeoutError.new("Request timeout"))
    
    assert_raises(StandardError, "Network Error: Request timeout") do
      @ai_service.generate("Test prompt")
    end
  end

  test "should handle invalid JSON response" do
    # Mock invalid JSON response
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 200, body: "invalid json")
    
    assert_raises(StandardError, "Invalid JSON response") do
      @ai_service.generate("Test prompt")
    end
  end

  test "should handle empty response" do
    # Mock empty response
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 200, body: { "choices" => [] }.to_json)
    
    assert_raises(StandardError, "No content generated") do
      @ai_service.generate("Test prompt")
    end
  end

  test "should validate provider type" do
    invalid_provider = AiProvider.create!(
      name: "Invalid Provider",
      provider_type: "invalid_type",
      api_key: "test-key",
      model_identifier: "test-model"
    )
    
    ai_service = AiService.new(invalid_provider)
    
    assert_raises(StandardError, "Unsupported provider type: invalid_type") do
      ai_service.generate("Test prompt")
    end
  end

  test "should handle rate limiting" do
    # Mock rate limit response
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 429, body: { error: { message: "Rate limit exceeded" } }.to_json)
    
    assert_raises(StandardError, "API Error: Rate limit exceeded") do
      @ai_service.generate("Test prompt")
    end
  end

  test "should handle quota exceeded" do
    # Mock quota exceeded response
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 402, body: { error: { message: "Quota exceeded" } }.to_json)
    
    assert_raises(StandardError, "API Error: Quota exceeded") do
      @ai_service.generate("Test prompt")
    end
  end

  test "should handle model not found" do
    # Mock model not found response
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 404, body: { error: { message: "Model not found" } }.to_json)
    
    assert_raises(StandardError, "API Error: Model not found") do
      @ai_service.generate("Test prompt")
    end
  end

  test "should handle server errors" do
    # Mock server error response
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 500, body: { error: { message: "Internal server error" } }.to_json)
    
    assert_raises(StandardError, "API Error: Internal server error") do
      @ai_service.generate("Test prompt")
    end
  end

  test "should handle timeout errors" do
    # Mock timeout error
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_timeout
    
    assert_raises(StandardError, "Network Error: execution expired") do
      @ai_service.generate("Test prompt")
    end
  end

  test "should handle connection errors" do
    # Mock connection error
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_raise(Errno::ECONNREFUSED.new("Connection refused"))
    
    assert_raises(StandardError, "Network Error: Connection refused") do
      @ai_service.generate("Test prompt")
    end
  end

  test "should handle SSL errors" do
    # Mock SSL error
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_raise(OpenSSL::SSL::SSLError.new("SSL error"))
    
    assert_raises(StandardError, "Network Error: SSL error") do
      @ai_service.generate("Test prompt")
    end
  end

  test "should handle malformed responses" do
    # Mock malformed response
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 200, body: { "choices" => [{ "message" => {} }] }.to_json)
    
    assert_raises(StandardError, "No content generated") do
      @ai_service.generate("Test prompt")
    end
  end

  test "should handle large responses" do
    # Mock large response
    large_content = "Generated content from OpenAI " * 1000
    mock_response = {
      "choices" => [
        {
          "message" => {
            "content" => large_content
          }
        }
      ]
    }
    
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 200, body: mock_response.to_json)
    
    result = @ai_service.generate("Test prompt")
    
    assert_equal large_content, result
    assert result.length > 10000
  end

  test "should handle special characters in prompt" do
    special_prompt = "Test prompt with special chars: !@#$%^&*()_+-=[]{}|;':\",./<>? and unicode: ñáéíóú"
    
    mock_response = {
      "choices" => [
        {
          "message" => {
            "content" => "Generated content with special chars"
          }
        }
      ]
    }
    
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 200, body: mock_response.to_json)
    
    result = @ai_service.generate(special_prompt)
    
    assert_equal "Generated content with special chars", result
  end

  test "should handle empty prompt" do
    mock_response = {
      "choices" => [
        {
          "message" => {
            "content" => "Generated content for empty prompt"
          }
        }
      ]
    }
    
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 200, body: mock_response.to_json)
    
    result = @ai_service.generate("")
    
    assert_equal "Generated content for empty prompt", result
  end

  test "should handle nil prompt" do
    mock_response = {
      "choices" => [
        {
          "message" => {
            "content" => "Generated content for nil prompt"
          }
        }
      ]
    }
    
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 200, body: mock_response.to_json)
    
    result = @ai_service.generate(nil)
    
    assert_equal "Generated content for nil prompt", result
  end

  test "should handle custom api_url" do
    custom_provider = AiProvider.create!(
      name: "Custom Provider",
      provider_type: "openai",
      api_key: "custom-key",
      model_identifier: "gpt-4",
      api_url: "https://custom-api.example.com/v1/chat/completions"
    )
    
    ai_service = AiService.new(custom_provider)
    
    mock_response = {
      "choices" => [
        {
          "message" => {
            "content" => "Generated content from custom API"
          }
        }
      ]
    }
    
    stub_request(:post, "https://custom-api.example.com/v1/chat/completions")
      .to_return(status: 200, body: mock_response.to_json)
    
    result = ai_service.generate("Test prompt")
    
    assert_equal "Generated content from custom API", result
  end
end



