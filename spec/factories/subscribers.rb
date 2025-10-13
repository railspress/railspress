FactoryBot.define do
  factory :subscriber do
    email { "MyString" }
    name { "MyString" }
    status { "MyString" }
    source { "MyString" }
    confirmed_at { "2025-10-12 00:36:07" }
    unsubscribed_at { "2025-10-12 00:36:07" }
    unsubscribe_token { "MyString" }
    ip_address { "MyString" }
    user_agent { "MyString" }
    metadata { "MyText" }
    tags { "MyText" }
    lists { "MyText" }
    tenant_id { 1 }
  end
end
