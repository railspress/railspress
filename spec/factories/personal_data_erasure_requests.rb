FactoryBot.define do
  factory :personal_data_erasure_request do
    user { nil }
    email { "MyString" }
    requested_by { 1 }
    confirmed_by { 1 }
    status { "MyString" }
    token { "MyString" }
    reason { "MyText" }
    confirmed_at { "2025-10-12 03:11:24" }
    completed_at { "2025-10-12 03:11:24" }
    metadata { "" }
    tenant { nil }
  end
end
