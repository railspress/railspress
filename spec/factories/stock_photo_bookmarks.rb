FactoryBot.define do
  factory :stock_photo_bookmark do
    user { nil }
    tenant { nil }
    provider { "MyString" }
    provider_photo_id { "MyString" }
    thumbnail_url { "MyString" }
    preview_url { "MyString" }
    download_url { "MyString" }
    width { 1 }
    height { 1 }
    photographer { "MyString" }
    photographer_url { "MyString" }
    source_url { "MyString" }
    alt_description { "MyString" }
    title { "MyString" }
    photo_data { "MyText" }
  end
end
