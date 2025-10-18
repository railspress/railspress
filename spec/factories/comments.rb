FactoryBot.define do
  factory :comment do
    content { Faker::Lorem.paragraph }
    status { :approved }
    association :user
    association :tenant
    
    trait :pending do
      status { :pending }
    end
    
    trait :approved do
      status { :approved }
    end
    
    trait :spam do
      status { :spam }
    end
    
    trait :trash do
      status { :trash }
    end
    
    trait :on_post do
      association :commentable, factory: :post
    end
    
    trait :on_page do
      association :commentable, factory: :page
    end
  end
end