FactoryBot.define do
  factory :plugin_setting do
    plugin_name { "MyString" }
    key { "MyString" }
    value { "MyText" }
    setting_type { "MyString" }
  end
end
