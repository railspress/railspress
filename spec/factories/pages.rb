FactoryBot.define do
  factory :page do
    title { Faker::Lorem.sentence }
    slug { title.parameterize }
    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    excerpt { Faker::Lorem.paragraph }
    status { :published }
    published_at { Time.current }
    association :user
    association :tenant
    
    trait :draft do
      status { :draft }
      published_at { nil }
    end
    
    trait :scheduled do
      status { :scheduled }
      published_at { 1.hour.from_now }
    end
    
    trait :private do
      status { :private_page }
    end
    
    trait :pending_review do
      status { :pending_review }
    end
    
    trait :trash do
      status { :trash }
    end
    
    trait :with_password do
      password { 'secret123' }
    end
    
    trait :with_parent do
      association :parent, factory: :page
    end
    
    trait :with_page_template do
      association :page_template
    end
    
    trait :with_custom_fields do
      after(:create) do |page|
        field_group = FieldGroup.create!(
          name: 'Test Fields',
          active: true,
          tenant: page.tenant
        )
        
        custom_field = CustomField.create!(
          field_group: field_group,
          name: 'test_field',
          field_type: 'text',
          tenant: page.tenant
        )
        
        CustomFieldValue.create!(
          custom_field: custom_field,
          object: page,
          meta_key: 'test_field',
          typed_value: 'test_value',
          tenant: page.tenant
        )
      end
    end
  end
end
