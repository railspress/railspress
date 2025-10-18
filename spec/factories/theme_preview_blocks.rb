FactoryBot.define do
  factory :theme_preview_block do
    theme_preview_section { nil }
    block_type { "MyString" }
    block_id { "MyString" }
    settings { "MyText" }
    position { 1 }
  end
end
