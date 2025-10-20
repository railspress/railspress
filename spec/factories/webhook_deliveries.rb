FactoryBot.define do
  factory :webhook_delivery do
    association :webhook
    event_type { "post.created" }
    payload { { "id" => 1, "title" => "Test Post" } }
    status { "pending" }
    response_code { nil }
    response_body { nil }
    error_message { nil }
    delivered_at { nil }
    retry_count { 0 }
    request_id { SecureRandom.uuid }
    
    trait :successful do
      status { "success" }
      response_code { 200 }
      response_body { "OK" }
      delivered_at { Time.current }
    end
    
    trait :failed do
      status { "failed" }
      error_message { "Connection timeout" }
      retry_count { 1 }
    end
  end
end
