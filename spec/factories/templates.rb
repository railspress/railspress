FactoryBot.define do
  factory :template do
    name { "Test Template" }
    template_type { "homepage" }
    html_content { "<div>Test content</div>" }
    css_content { "body { color: black; }" }
    js_content { "console.log('test');" }
    active { true }
    association :theme
    association :tenant
  end

  trait :blog_index do
    template_type { "blog_index" }
    name { "Blog Index" }
  end

  trait :page_default do
    template_type { "page_default" }
    name { "Page Default" }
  end

  trait :template_disabled do
    active { false }
  end
end
