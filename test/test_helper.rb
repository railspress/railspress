require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order
  fixtures :all

  # Add more helper methods to be used by all tests here...
  
  def sign_in(user)
    post user_session_url, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end

  def sign_out(user)
    delete destroy_user_session_url
  end

  def json_response
    JSON.parse(response.body)
  end

  def assert_json_response(expected_status, expected_keys = [])
    assert_response expected_status
    assert_equal "application/json", response.content_type
    
    data = json_response
    expected_keys.each do |key|
      assert data.key?(key.to_s), "Expected response to include key: #{key}"
    end
  end

  def assert_error_response(message)
    data = json_response
    assert_equal "error", data["status"]
    assert_includes data["message"], message
  end

  def assert_success_response
    data = json_response
    assert_equal "success", data["status"]
  end

  def create_test_file(filename, content)
    file = Tempfile.new([filename, File.extname(filename)])
    file.write(content)
    file.rewind
    file
  end

  def with_timeout(seconds)
    Timeout::timeout(seconds) { yield }
  end

  def mock_api_request(url, response_body, status = 200)
    stub_request(:post, url)
      .to_return(status: status, body: response_body.to_json)
  end

  def mock_ai_service_response(content)
    {
      "choices" => [
        {
          "message" => {
            "content" => content
          }
        }
      ]
    }
  end

  def create_test_ai_provider(provider_type = "openai")
    AiProvider.create!(
      name: "Test #{provider_type.titleize} Provider",
      provider_type: provider_type,
      api_key: "sk-test-key-123456789",
      model_identifier: case provider_type
                       when "openai" then "gpt-4"
                       when "cohere" then "command"
                       when "anthropic" then "claude-3-sonnet-20240229"
                       when "google" then "gemini-pro"
                       else "test-model"
                       end,
      max_tokens: 4000,
      temperature: 0.7,
      active: true
    )
  end

  def create_test_ai_agent(agent_type = "content_summarizer", provider = nil)
    provider ||= create_test_ai_provider
    
    AiAgent.create!(
      name: "Test #{agent_type.titleize} Agent",
      agent_type: agent_type,
      prompt: "You are a #{agent_type} agent. Process the following:",
      ai_provider: provider,
      active: true
    )
  end
end


