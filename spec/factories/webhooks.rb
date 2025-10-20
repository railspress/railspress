FactoryBot.define do
  factory :webhook do
    name { "Test Webhook" }
    description { "A test webhook for testing purposes" }
    url { "https://example.com/webhook" }
    events { ["post.created", "post.updated"] }
    active { true }
    secret_key { SecureRandom.hex(32) }
    retry_limit { 3 }
    timeout { 30 }
    total_deliveries { 0 }
    failed_deliveries { 0 }
    
    trait :inactive do
      active { false }
    end
    
    trait :with_deliveries do
      after(:create) do |webhook|
        create_list(:webhook_delivery, 3, webhook: webhook, trait: :successful)
        create_list(:webhook_delivery, 1, webhook: webhook, trait: :failed)
        webhook.update!(
          total_deliveries: 4,
          failed_deliveries: 1
        )
      end
    end
  end
end
