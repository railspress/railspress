FactoryBot.define do
  factory :redirect do
    from_path { "MyString" }
    to_path { "MyString" }
    redirect_type { 1 }
    status_code { 1 }
    hits_count { 1 }
    active { false }
    notes { "MyText" }
    tenant_id { 1 }
  end
end
