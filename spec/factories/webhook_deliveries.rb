FactoryBot.define do
  factory :webhook_delivery do
    webhook { nil }
    event_type { "MyString" }
    payload { "" }
    status { "MyString" }
    response_code { 1 }
    response_body { "MyText" }
    error_message { "MyText" }
    delivered_at { "2025-10-11 21:49:53" }
    retry_count { 1 }
  end
end
