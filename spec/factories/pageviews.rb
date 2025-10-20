FactoryBot.define do
  factory :pageview do
    path { "/test-page" }
    title { "Test Page" }
    referrer { "https://google.com" }
    user_agent { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" }
    browser { "Chrome" }
    device { "Desktop" }
    os { "macOS" }
    country_code { "US" }
    city { "San Francisco" }
    region { "California" }
    ip_hash { "abc123def456" }
    session_id { "session123" }
    user { nil }
    post { nil }
    page { nil }
    duration { 30 }
    unique_visitor { true }
    returning_visitor { false }
    bot { false }
    consented { true }
    metadata { {} }
    tenant { nil } # Optional tenant
    visited_at { Time.current }
  end
end
