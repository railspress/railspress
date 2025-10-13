FactoryBot.define do
  factory :pageview do
    path { "MyString" }
    title { "MyString" }
    referrer { "MyString" }
    user_agent { "MyString" }
    browser { "MyString" }
    device { "MyString" }
    os { "MyString" }
    country_code { "MyString" }
    city { "MyString" }
    region { "MyString" }
    ip_hash { "MyString" }
    session_id { "MyString" }
    user_id { 1 }
    post_id { 1 }
    page_id { 1 }
    duration { 1 }
    unique_visitor { false }
    returning_visitor { false }
    bot { false }
    consented { false }
    metadata { "MyText" }
    tenant_id { 1 }
    visited_at { "2025-10-12 00:56:15" }
  end
end
