FactoryBot.define do
  factory :admin_notification do
    plugin { "MyString" }
    message { "MyText" }
    notification_type { "MyString" }
    metadata { "" }
    read { false }
  end
end
