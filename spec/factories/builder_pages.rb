FactoryBot.define do
  factory :builder_page do
    template_name { "home" }
    page_title { "Home Page" }
    position { 0 }
    published { false }
    settings { {} }
    sections { {} }
    association :builder_theme
    association :tenant
  end

  trait :page_published do
    published { true }
  end

  trait :page_with_sections do
    sections { { "header" => {}, "content" => {}, "footer" => {} } }
  end

  trait :page_with_settings do
    settings { { "color" => "blue", "layout" => "wide" } }
  end
end
