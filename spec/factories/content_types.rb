FactoryBot.define do
  factory :content_type do
    label { "Article" }
    ident { "article" }
    singular { "Article" }
    plural { "Articles" }
    description { "A custom article type" }
    active { true }
    public { true }
    association :tenant
  end

  trait :content_type_post do
    label { "Post" }
    ident { "post" }
    singular { "Post" }
    plural { "Posts" }
  end

  trait :content_type_page do
    label { "Page" }
    ident { "page" }
    singular { "Page" }
    plural { "Pages" }
  end
end