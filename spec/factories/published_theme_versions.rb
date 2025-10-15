FactoryBot.define do
  factory :published_theme_version do
    theme_name { "MyString" }
    version_number { 1 }
    published_at { "2025-10-14 04:16:18" }
    published_by { nil }
    tenant { nil }
  end
end
