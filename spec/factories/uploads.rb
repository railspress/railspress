FactoryBot.define do
  factory :upload do
    user { nil }
    title { "MyString" }
    description { "MyText" }
    alt_text { "MyString" }
    tenant { nil }
  end
end
