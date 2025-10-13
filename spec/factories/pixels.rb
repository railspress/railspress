FactoryBot.define do
  factory :pixel do
    name { "MyString" }
    pixel_type { "MyString" }
    provider { "MyString" }
    pixel_id { "MyString" }
    custom_code { "MyText" }
    position { "MyString" }
    active { false }
    notes { "MyText" }
    tenant_id { 1 }
  end
end
