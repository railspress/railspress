require 'rails_helper'

RSpec.describe AiService, type: :service do
  let(:openai_provider) { create(:ai_provider, provider_type: 'openai', api_key: 'sk-test-key') }
  let(:cohere_provider) { create(:ai_provider, provider_type: 'cohere', api_key: 'cohere-test-key') }
  let(:anthropic_provider) { create(:ai_provider, provider_type: 'anthropic', api_key: 'anthropic-test-key') }
  let(:google_provider) { create(:ai_provider, provider_type: 'google', api_key: 'google-test-key') }

  describe '#initialize' do
    it 'sets the provider' do
      service = AiService.new(openai_provider)
      expect(service.instance_variable_get(:@provider)).to eq(openai_provider)
    end
  end

  describe '#generate' do
    context 'with OpenAI provider' do
      let(:service) { AiService.new(openai_provider) }

      it 'calls OpenAI API successfully' do
        mock_response = {
          'choices' => [
            {
              'message' => {
                'content' => 'Generated content from OpenAI'
              }
            }
          ]
        }

        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .with(
            headers: {
              'Authorization' => "Bearer #{openai_provider.api_key}",
              'Content-Type' => 'application/json'
            },
            body: {
              model: openai_provider.model_identifier,
              messages: [{ role: 'user', content: 'Test prompt' }],
              max_tokens: openai_provider.max_tokens,
              temperature: openai_provider.temperature
            }.to_json
          )
          .to_return(status: 200, body: mock_response.to_json)

        result = service.generate('Test prompt')
        expect(result).to eq('Generated content from OpenAI')
      end

      it 'handles API errors' do
        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .to_return(status: 401, body: { error: { message: 'Invalid API key' } }.to_json)

        expect { service.generate('Test prompt') }.to raise_error(StandardError)
      end

      it 'handles network errors' do
        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .to_raise(Timeout::Error.new('Request timeout'))

        expect { service.generate('Test prompt') }.to raise_error(Timeout::Error)
      end
    end

    context 'with Cohere provider' do
      let(:service) { AiService.new(cohere_provider) }

      it 'calls Cohere API successfully' do
        mock_response = {
          'text' => 'Generated content from Cohere'
        }

        stub_request(:post, 'https://api.cohere.ai/v1/chat')
          .with(
            headers: {
              'Authorization' => "Bearer #{cohere_provider.api_key}",
              'Content-Type' => 'application/json'
            },
            body: {
              model: cohere_provider.model_identifier,
              message: 'Test prompt',
              max_tokens: cohere_provider.max_tokens.to_i,
              temperature: cohere_provider.temperature.to_f,
              stream: false
            }.to_json
          )
          .to_return(status: 200, body: mock_response.to_json)

        result = service.generate('Test prompt')
        expect(result).to eq('Generated content from Cohere')
      end

      it 'handles API errors' do
        stub_request(:post, 'https://api.cohere.ai/v1/chat')
          .to_return(status: 400, body: { error: { message: 'Bad request' } }.to_json)

        expect { service.generate('Test prompt') }.to raise_error(StandardError)
      end
    end

    context 'with Anthropic provider' do
      let(:service) { AiService.new(anthropic_provider) }

      it 'calls Anthropic API successfully' do
        mock_response = {
          'content' => [
            {
              'text' => 'Generated content from Anthropic'
            }
          ]
        }

        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .with(
            headers: {
              'x-api-key' => anthropic_provider.api_key,
              'Content-Type' => 'application/json',
              'anthropic-version' => '2023-06-01'
            },
            body: {
              model: anthropic_provider.model_identifier,
              max_tokens: anthropic_provider.max_tokens,
              temperature: anthropic_provider.temperature,
              messages: [{ role: 'user', content: 'Test prompt' }]
            }.to_json
          )
          .to_return(status: 200, body: mock_response.to_json)

        result = service.generate('Test prompt')
        expect(result).to eq('Generated content from Anthropic')
      end

      it 'handles API errors' do
        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 401, body: { error: { message: 'Invalid API key' } }.to_json)

        expect { service.generate('Test prompt') }.to raise_error(StandardError)
      end
    end

    context 'with Google provider' do
      let(:service) { AiService.new(google_provider) }

      it 'calls Google API successfully' do
        mock_response = {
          'candidates' => [
            {
              'content' => {
                'parts' => [
                  {
                    'text' => 'Generated content from Google'
                  }
                ]
              }
            }
          ]
        }

        stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/#{google_provider.model_identifier}:generateContent")
          .with(
            query: { key: google_provider.api_key },
            headers: {
              'Content-Type' => 'application/json'
            },
            body: {
              contents: [
                {
                  parts: [
                    { text: 'Test prompt' }
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

        result = service.generate('Test prompt')
        expect(result).to eq('Generated content from Google')
      end

      it 'handles API errors' do
        stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/#{google_provider.model_identifier}:generateContent")
          .with(query: { key: google_provider.api_key })
          .to_return(status: 400, body: { error: { message: 'Bad request' } }.to_json)

        expect { service.generate('Test prompt') }.to raise_error(StandardError)
      end
    end

    context 'with unsupported provider' do
      let(:invalid_provider) { build(:ai_provider, provider_type: 'invalid').tap { |p| p.save!(validate: false) } }
      let(:service) { AiService.new(invalid_provider) }

      it 'raises error for unsupported provider' do
        expect { service.generate('Test prompt') }.to raise_error(StandardError, 'Unsupported provider type: invalid')
      end
    end

    context 'edge cases' do
      let(:service) { AiService.new(openai_provider) }

      it 'handles empty prompt' do
        mock_response = {
          'choices' => [
            {
              'message' => {
                'content' => 'Response to empty prompt'
              }
            }
          ]
        }

        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .to_return(status: 200, body: mock_response.to_json)

        result = service.generate('')
        expect(result).to eq('Response to empty prompt')
      end

      it 'handles nil prompt' do
        mock_response = {
          'choices' => [
            {
              'message' => {
                'content' => 'Response to nil prompt'
              }
            }
          ]
        }

        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .to_return(status: 200, body: mock_response.to_json)

        result = service.generate(nil)
        expect(result).to eq('Response to nil prompt')
      end

      it 'handles special characters in prompt' do
        special_prompt = "Test prompt with special chars: !@#$%^&*()_+-=[]{}|;':\",./<>? and unicode: ñáéíóú"
        
        mock_response = {
          'choices' => [
            {
              'message' => {
                'content' => 'Response with special chars'
              }
            }
          ]
        }

        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .to_return(status: 200, body: mock_response.to_json)

        result = service.generate(special_prompt)
        expect(result).to eq('Response with special chars')
      end

      it 'handles large responses' do
        large_content = 'Generated content ' * 1000
        mock_response = {
          'choices' => [
            {
              'message' => {
                'content' => large_content
              }
            }
          ]
        }

        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .to_return(status: 200, body: mock_response.to_json)

        result = service.generate('Test prompt')
        expect(result).to eq(large_content)
        expect(result.length).to be > 10000
      end
    end
  end

  describe 'error handling' do
    let(:service) { AiService.new(openai_provider) }

    it 'handles rate limiting' do
      stub_request(:post, 'https://api.openai.com/v1/chat/completions')
        .to_return(status: 429, body: { error: { message: 'Rate limit exceeded' } }.to_json)

      expect { service.generate('Test prompt') }.to raise_error(StandardError)
    end

    it 'handles quota exceeded' do
      stub_request(:post, 'https://api.openai.com/v1/chat/completions')
        .to_return(status: 402, body: { error: { message: 'Quota exceeded' } }.to_json)

      expect { service.generate('Test prompt') }.to raise_error(StandardError)
    end

    it 'handles model not found' do
      stub_request(:post, 'https://api.openai.com/v1/chat/completions')
        .to_return(status: 404, body: { error: { message: 'Model not found' } }.to_json)

      expect { service.generate('Test prompt') }.to raise_error(StandardError)
    end

    it 'handles server errors' do
      stub_request(:post, 'https://api.openai.com/v1/chat/completions')
        .to_return(status: 500, body: { error: { message: 'Internal server error' } }.to_json)

      expect { service.generate('Test prompt') }.to raise_error(StandardError)
    end

    it 'handles timeout errors' do
      stub_request(:post, 'https://api.openai.com/v1/chat/completions')
        .to_timeout

      expect { service.generate('Test prompt') }.to raise_error(StandardError)
    end

    it 'handles connection errors' do
      stub_request(:post, 'https://api.openai.com/v1/chat/completions')
        .to_raise(Errno::ECONNREFUSED.new('Connection refused'))

      expect { service.generate('Test prompt') }.to raise_error(StandardError)
    end

    it 'handles SSL errors' do
      stub_request(:post, 'https://api.openai.com/v1/chat/completions')
        .to_raise(OpenSSL::SSL::SSLError.new('SSL error'))

      expect { service.generate('Test prompt') }.to raise_error(StandardError)
    end

    it 'handles malformed responses' do
      stub_request(:post, 'https://api.openai.com/v1/chat/completions')
        .to_return(status: 200, body: { 'choices' => [{ 'message' => {} }] }.to_json)

      expect { service.generate('Test prompt') }.to raise_error(StandardError)
    end

    it 'handles invalid JSON response' do
      stub_request(:post, 'https://api.openai.com/v1/chat/completions')
        .to_return(status: 200, body: 'invalid json')

      expect { service.generate('Test prompt') }.to raise_error(StandardError)
    end

    it 'handles empty response' do
      stub_request(:post, 'https://api.openai.com/v1/chat/completions')
        .to_return(status: 200, body: { 'choices' => [] }.to_json)

      expect { service.generate('Test prompt') }.to raise_error(StandardError)
    end
  end
end
