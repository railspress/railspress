FactoryBot.define do
  factory :theme_version_file do
    theme_version { nil }
    file_path { "MyString" }
    file_type { "MyString" }
    content { "MyText" }
    file_size { 1 }
  end
end
