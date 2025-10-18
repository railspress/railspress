FactoryBot.define do
  factory :taxonomy do
    name { Faker::Lorem.word.capitalize }
    slug { name.downcase.gsub(/\s+/, '-') }
    description { Faker::Lorem.sentence }
    hierarchical { false }
    object_types { ['Post'] }
    settings { {} }
    
    trait :category do
      name { 'Categories' }
      slug { 'category' }
      description { 'Post categories' }
      hierarchical { true }
      object_types { ['Post'] }
    end
    
    trait :post_tag do
      name { 'Tags' }
      slug { 'post_tag' }
      description { 'Post tags' }
      hierarchical { false }
      object_types { ['Post'] }
    end
    
    trait :hierarchical do
      hierarchical { true }
    end
    
    trait :flat do
      hierarchical { false }
    end
  end
end
