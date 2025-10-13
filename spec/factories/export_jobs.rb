FactoryBot.define do
  factory :export_job do
    export_type { "MyString" }
    file_path { "MyString" }
    file_name { "MyString" }
    content_type { "MyString" }
    user { nil }
    status { "MyString" }
    progress { 1 }
    total_items { 1 }
    exported_items { 1 }
    options { "" }
    metadata { "" }
    tenant { nil }
  end
end
