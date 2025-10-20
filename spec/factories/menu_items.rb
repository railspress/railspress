FactoryBot.define do
  factory :menu_item do
    label { "Home" }
    url { "/" }
    association :menu
    association :tenant
    
    # Ensure menu is associated before validation
    after(:build) do |menu_item|
      menu_item.position = nil if menu_item.position == 1
    end
  end

  trait :with_page do
    association :page
    url { nil }
  end

  trait :with_post do
    association :post
    url { nil }
  end

  trait :child do
    association :parent, factory: :menu_item
  end

  trait :external_link do
    url { "https://example.com" }
  end
end
