FactoryBot.define do
  factory :custom_font do
    name { "MyString" }
    family { "MyString" }
    source { "MyString" }
    url { "MyString" }
    weights { "MyText" }
    styles { "MyText" }
    fallback { "MyString" }
    active { false }
    tenant_id { 1 }
  end
end
