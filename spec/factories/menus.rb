FactoryBot.define do
  factory :menu do
    name { "Main Menu" }
    location { "header" }
    association :tenant
  end

  trait :menu_footer do
    location { "footer" }
    name { "Footer Menu" }
  end

  trait :menu_sidebar do
    location { "sidebar" }
    name { "Sidebar Menu" }
  end
end
