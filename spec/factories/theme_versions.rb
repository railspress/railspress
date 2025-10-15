FactoryBot.define do
  factory :theme_version do
    theme_name { "MyString" }
    version { "MyString" }
    is_live { false }
    is_preview { false }
    user { nil }
    change_summary { "MyText" }
    published_at { "2025-10-13 20:15:15" }
  end
end
