FactoryBot.define do
  factory :field_group do
    name { "MyString" }
    slug { "MyString" }
    description { "MyText" }
    position { 1 }
    active { false }
    location_rules { "MyText" }
    tenant_id { 1 }
  end
end
