FactoryBot.define do
  factory :api_token do
    name { "MyString" }
    token { "MyString" }
    user { nil }
    role { "MyString" }
    permissions { "" }
    expires_at { "2025-10-12 08:48:16" }
    last_used_at { "2025-10-12 08:48:16" }
    active { false }
  end
end
