FactoryBot.define do
  factory :custom_field_value do
    meta_key { Faker::Lorem.word }
    typed_value { Faker::Lorem.sentence }
    association :custom_field
    association :tenant
    
    trait :text_value do
      typed_value { Faker::Lorem.sentence }
    end
    
    trait :number_value do
      typed_value { Faker::Number.number(digits: 3) }
    end
    
    trait :boolean_value do
      typed_value { [true, false].sample }
    end
    
    trait :date_value do
      typed_value { Faker::Date.between(from: 1.year.ago, to: Date.current) }
    end
    
    trait :for_post do
      association :object, factory: :post
    end
    
    trait :for_page do
      association :object, factory: :page
    end
    
    trait :for_user do
      association :object, factory: :user
    end
  end
end