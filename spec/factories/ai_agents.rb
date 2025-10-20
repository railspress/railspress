FactoryBot.define do
  factory :ai_agent do
    name { "Content Summarizer" }
    description { "Summarizes content" }
    agent_type { "content_summarizer" }
    prompt { "Summarize the following content:" }
    content { "Content guidelines" }
    guidelines { "Guidelines for summarization" }
    rules { "Rules for summarization" }
    tasks { "Tasks for summarization" }
    master_prompt { "Master prompt" }
    association :ai_provider
    active { true }
    position { 1 }
  end
end
