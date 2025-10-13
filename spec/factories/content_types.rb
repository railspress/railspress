FactoryBot.define do
  factory :content_type do
    ident { "MyString" }
    label { "MyString" }
    singular { "MyString" }
    plural { "MyString" }
    description { "MyText" }
    icon { "MyString" }
    public { false }
    hierarchical { false }
    has_archive { false }
    menu_position { 1 }
    supports { "MyText" }
    capabilities { "MyText" }
    rest_base { "MyString" }
    active { false }
    tenant { nil }
  end
end
