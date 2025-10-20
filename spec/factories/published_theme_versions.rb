FactoryBot.define do
  factory :published_theme_version do
    version_number { 1 }
    published_at { Time.current }
    association :published_by, factory: :user
    association :tenant
    association :theme
  end
end
