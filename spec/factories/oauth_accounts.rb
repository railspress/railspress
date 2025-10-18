FactoryBot.define do
  factory :oauth_account do
    association :user
    association :tenant
    provider { 'google_oauth2' }
    uid { SecureRandom.hex(8) }
    email { Faker::Internet.email }
    name { Faker::Name.name }
    avatar_url { Faker::Avatar.image }

    trait :google do
      provider { 'google_oauth2' }
      uid { "google_#{SecureRandom.hex(8)}" }
    end

    trait :github do
      provider { 'github' }
      uid { "github_#{SecureRandom.hex(8)}" }
    end

    trait :facebook do
      provider { 'facebook' }
      uid { "facebook_#{SecureRandom.hex(8)}" }
    end

    trait :twitter do
      provider { 'twitter' }
      uid { "twitter_#{SecureRandom.hex(8)}" }
    end

    trait :without_avatar do
      avatar_url { nil }
    end

    trait :with_custom_email do
      email { 'custom@example.com' }
    end

    trait :with_custom_name do
      name { 'Custom OAuth User' }
    end
  end
end
