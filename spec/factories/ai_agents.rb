FactoryBot.define do
  factory :ai_agent do
    name { "MyString" }
    description { "MyText" }
    agent_type { "MyString" }
    prompt { "MyText" }
    content { "MyText" }
    guidelines { "MyText" }
    rules { "MyText" }
    tasks { "MyText" }
    master_prompt { "MyText" }
    ai_provider { nil }
    active { false }
    position { 1 }
  end
end
