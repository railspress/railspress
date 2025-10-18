FactoryBot.define do
  factory :field_group do
    name { Faker::Lorem.words(number: 2).join(' ').titleize }
    description { Faker::Lorem.sentence }
    active { true }
    order { 1 }
    association :tenant
    
    trait :inactive do
      active { false }
    end
    
    trait :for_posts do
      location { 'post' }
    end
    
    trait :for_pages do
      location { 'page' }
    end
    
    trait :for_users do
      location { 'user' }
    end
  end
end