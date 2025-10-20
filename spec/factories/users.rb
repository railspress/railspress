FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    name { Faker::Name.name }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { :subscriber }
    association :tenant
    
    trait :subscriber do
      role { :subscriber }
    end
    
    trait :contributor do
      role { :contributor }
    end
    
    trait :author do
      role { :author }
    end
    
    trait :editor do
      role { :editor }
    end
    
    trait :administrator do
      role { :administrator }
    end
    
    trait :admin do
      role { :administrator }
    end
    
    trait :with_avatar do
      after(:create) do |user|
        # Avatar attachment would be tested with actual file uploads
        # For now, we just ensure the association exists
      end
    end
    
    trait :with_oauth_accounts do
      after(:create) do |user|
        create(:oauth_account, user: user, provider: 'google_oauth2', tenant: user.tenant)
        create(:oauth_account, user: user, provider: 'github', tenant: user.tenant)
      end
    end
    
    trait :with_api_tokens do
      after(:create) do |user|
        create(:api_token, user: user, tenant: user.tenant)
      end
    end
    
    trait :with_custom_editor_preference do
      editor_preference { 'trix' }
    end
    
    trait :with_custom_monaco_theme do
      monaco_theme { 'dark' }
    end
  end
end
