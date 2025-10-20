FactoryBot.define do
  factory :analytics_event do
    event_name { "MyString" }
    properties { "MyText" }
    session_id { "MyString" }
    user_id { 1 }
    path { "MyString" }
    tenant { nil }
  end
end
