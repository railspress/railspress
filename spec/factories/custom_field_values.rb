FactoryBot.define do
  factory :custom_field_value do
    field_id { 1 }
    post_id { 1 }
    page_id { 1 }
    value { "MyText" }
    meta_key { "MyString" }
    meta_value { "MyText" }
    tenant_id { 1 }
  end
end
