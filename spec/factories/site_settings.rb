FactoryBot.define do
  factory :site_setting do
    key { Faker::Lorem.word }
    value { Faker::Lorem.sentence }
    
    trait :site_title do
      key { 'site_title' }
      value { 'RailsPress Test Site' }
    end
    
    trait :site_description do
      key { 'site_description' }
      value { 'A test RailsPress site for testing feeds' }
    end
  end
end
