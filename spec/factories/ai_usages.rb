FactoryBot.define do
  factory :ai_usage do
    ai_agent { nil }
    user { nil }
    prompt { "MyText" }
    response { "MyText" }
    tokens_used { 1 }
    cost { "9.99" }
    response_time { "9.99" }
    success { false }
    error_message { "MyText" }
    metadata { "" }
  end
end
