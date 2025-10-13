FactoryBot.define do
  factory :user_notification do
    plugin { "MyString" }
    user { nil }
    message { "MyText" }
    notification_type { "MyString" }
    metadata { "" }
    read { false }
  end
end
