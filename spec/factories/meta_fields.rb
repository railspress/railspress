FactoryBot.define do
  factory :meta_field do
    metable { nil }
    key { "MyString" }
    value { "MyText" }
    immutable { false }
  end
end
