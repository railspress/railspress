FactoryBot.define do
  factory :theme do
    name { "Test Theme" }
    slug { "test-theme" }
    version { "1.0.0" }
    description { "A test theme" }
    author { "Test Author" }
    active { false }
    config { {} }
    association :tenant
  end

  trait :active do
    active { true }
  end

  trait :with_config do
    config { { "colors" => { "primary" => "#007cba" }, "fonts" => { "heading" => "Arial" } } }
  end
end
