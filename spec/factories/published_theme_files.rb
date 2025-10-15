FactoryBot.define do
  factory :published_theme_file do
    published_theme_version { nil }
    file_path { "MyString" }
    file_type { "MyString" }
    content { "MyText" }
    checksum { "MyString" }
  end
end
