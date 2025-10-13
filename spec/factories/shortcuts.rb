FactoryBot.define do
  factory :shortcut do
    name { "MyString" }
    description { "MyText" }
    keybinding { "MyString" }
    action_type { "MyString" }
    action_value { "MyString" }
    icon { "MyString" }
    category { "MyString" }
    position { 1 }
    active { false }
    tenant { nil }
  end
end
