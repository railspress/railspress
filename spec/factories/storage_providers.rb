FactoryBot.define do
  factory :storage_provider do
    name { "MyString" }
    provider_type { "MyString" }
    config { "MyText" }
    active { false }
    position { 1 }
    tenant { nil }
  end
end
