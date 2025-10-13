FactoryBot.define do
  factory :ai_provider do
    name { "MyString" }
    provider_type { "MyString" }
    api_key { "MyString" }
    api_url { "MyString" }
    model_identifier { "MyString" }
    max_tokens { 1 }
    temperature { "9.99" }
    active { false }
    position { 1 }
  end
end
