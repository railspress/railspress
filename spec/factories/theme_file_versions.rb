FactoryBot.define do
  factory :theme_file_version do
    theme_name { "MyString" }
    file_path { "MyString" }
    content { "MyText" }
    file_size { 1 }
    user { nil }
  end
end
