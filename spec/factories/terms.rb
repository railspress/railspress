FactoryBot.define do
  factory :term do
    name { Faker::Lorem.word.capitalize }
    slug { name.downcase.gsub(/\s+/, '-') }
    description { Faker::Lorem.sentence }
    count { 0 }
    metadata { {} }
    association :taxonomy
    
    trait :category do
      association :taxonomy, factory: [:taxonomy, :category]
      name { 'Uncategorized' }
      slug { 'uncategorized' }
    end
    
    trait :tag do
      association :taxonomy, factory: [:taxonomy, :post_tag]
      name { Faker::Lorem.word.capitalize }
      slug { name.downcase.gsub(/\s+/, '-') }
    end
    
    trait :with_parent do
      association :parent, factory: :term
    end
  end
end
