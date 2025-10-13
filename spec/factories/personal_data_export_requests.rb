FactoryBot.define do
  factory :personal_data_export_request do
    user { nil }
    email { "MyString" }
    requested_by { 1 }
    status { "MyString" }
    token { "MyString" }
    file_path { "MyString" }
    metadata { "" }
    tenant { nil }
  end
end
