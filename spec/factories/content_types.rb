FactoryBot.define do
  factory :content_type do
    ident { Faker::Lorem.word.downcase.gsub(/\s+/, '-') }
    label { Faker::Lorem.word.capitalize }
    singular { label }
    plural { label.pluralize }
    description { Faker::Lorem.sentence }
    icon { 'document-text' }
    public { true }
    hierarchical { false }
    has_archive { true }
    menu_position { 1 }
    supports { ['title', 'editor', 'excerpt', 'thumbnail', 'comments'] }
    capabilities { {} }
    rest_base { ident.pluralize }
    active { true }
    
    trait :post do
      ident { 'post' }
      label { 'Post' }
      singular { 'Post' }
      plural { 'Posts' }
    end
    
    trait :page do
      ident { 'page' }
      label { 'Page' }
      singular { 'Page' }
      plural { 'Pages' }
    end
    
    trait :portfolio do
      ident { 'portfolio' }
      label { 'Portfolio' }
      singular { 'Portfolio Item' }
      plural { 'Portfolio Items' }
      supports { ['title', 'editor', 'thumbnail', 'custom_fields'] }
    end
  end
end
