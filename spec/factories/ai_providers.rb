FactoryBot.define do
  factory :ai_provider do
    name { "OpenAI Provider" }
    provider_type { "openai" }
    api_key { "sk-test-key" }
    api_url { "https://api.openai.com/v1" }
    model_identifier { "gpt-4o" }
    max_tokens { 4000 }
    temperature { 0.7 }
    active { true }
    position { 1 }
  end
end
