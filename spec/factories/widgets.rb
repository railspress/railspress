FactoryBot.define do
  factory :widget do
    name { "Test Widget" }
    title { "Test Widget Title" }
    content { "Test widget content" }
    widget_type { "text" }
    active { true }
    position { 0 }
    association :tenant
  end

  trait :widget_html do
    widget_type { "html" }
    content { "<p>HTML content</p>" }
  end

  trait :widget_text do
    widget_type { "text" }
    content { "Plain text content" }
  end

  trait :widget_disabled do
    active { false }
  end

  trait :widget_sidebar do
    name { "Sidebar Widget" }
    position { 1 }
  end

  trait :widget_footer do
    name { "Footer Widget" }
    position { 2 }
  end
end
