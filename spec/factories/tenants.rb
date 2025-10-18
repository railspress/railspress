FactoryBot.define do
  factory :tenant do
    name { Faker::Company.name }
    subdomain { name.parameterize }
    domain { nil }
    theme { 'nordic' }
    storage_type { 'local' }
    active { true }
    locales { 'en' }
    
    trait :with_domain do
      domain { "#{name.parameterize}.com" }
      subdomain { nil }
    end
    
    trait :with_s3_storage do
      storage_type { 's3' }
    end
    
    trait :inactive do
      active { false }
    end
    
    trait :multi_locale do
      locales { 'en,es,fr' }
    end
  end
end
