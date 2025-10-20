FactoryBot.define do
  factory :builder_theme do
    theme_name { "test-theme" }
    label { "Test Version" }
    summary { "Test builder theme version" }
    published { false }
    association :tenant
    association :user
  end

  trait :published do
    published { true }
    published_at { Time.current }
  end

  trait :with_settings do
    after(:create) do |builder_theme|
      builder_theme.instance_variable_set(:@settings_data, { "colors" => { "primary" => "#007cba" }, "layout" => { "width" => "1200px" } })
    end
  end

  trait :with_parent do
    association :parent_version, factory: :builder_theme
  end
end
