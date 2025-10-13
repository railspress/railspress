FactoryBot.define do
  factory :custom_field do
    field_group_id { 1 }
    name { "MyString" }
    label { "MyString" }
    field_type { "MyString" }
    instructions { "MyText" }
    required { false }
    default_value { "MyText" }
    choices { "MyText" }
    conditional_logic { "MyText" }
    position { 1 }
    settings { "MyText" }
  end
end
