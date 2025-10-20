FactoryBot.define do
  factory :plugin do
    name { "test-plugin" }
    version { "1.0.0" }
    description { "A test plugin" }
    author { "Test Author" }
    active { false }
    settings { {} }
  end

  trait :plugin_active do
    active { true }
  end

  trait :plugin_with_settings do
    settings { { "option1" => "value1", "option2" => "value2" } }
  end
end
