FactoryBot.define do
  factory :import_job do
    import_type { "MyString" }
    file_path { "MyString" }
    file_name { "MyString" }
    user { nil }
    status { "MyString" }
    progress { 1 }
    total_items { 1 }
    imported_items { 1 }
    failed_items { 1 }
    error_log { "MyText" }
    metadata { "" }
    tenant { nil }
  end
end
