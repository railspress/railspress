FactoryBot.define do
  factory :webhook do
    url { "MyString" }
    events { "MyText" }
    active { false }
    secret_key { "MyString" }
  end
end
