FactoryBot.define do
  factory :post do
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
      status { :private_post }
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
    
    trait :with_content_type do
      association :content_type
    end
    
    trait :with_categories do
      after(:create) do |post|
        category_taxonomy = Taxonomy.find_or_create_by(slug: 'category') do |tax|
          tax.name = 'Categories'
          tax.description = 'Post categories'
          tax.hierarchical = true
          tax.object_types = ['Post']
        end
        
        category = category_taxonomy.terms.find_or_create_by(slug: 'uncategorized') do |term|
          term.name = 'Uncategorized'
          term.description = 'Default category'
        end
        
        post.terms << category
      end
    end
    
    trait :with_tags do
      after(:create) do |post|
        tag_taxonomy = Taxonomy.find_or_create_by(slug: 'post_tag') do |tax|
          tax.name = 'Tags'
          tax.description = 'Post tags'
          tax.hierarchical = false
          tax.object_types = ['Post']
        end
        
        2.times do
          tag = tag_taxonomy.terms.create!(
            name: Faker::Lorem.word.capitalize,
            slug: Faker::Lorem.word.downcase,
            description: Faker::Lorem.sentence
          )
          post.terms << tag
        end
      end
    end
    
    trait :with_custom_fields do
      after(:create) do |post|
        field_group = FieldGroup.create!(
          name: 'Test Fields',
          active: true,
          tenant: post.tenant
        )
        
        custom_field = CustomField.create!(
          field_group: field_group,
          name: 'test_field',
          field_type: 'text',
          tenant: post.tenant
        )
        
        CustomFieldValue.create!(
          custom_field: custom_field,
          object: post,
          meta_key: 'test_field',
          typed_value: 'test_value',
          tenant: post.tenant
        )
      end
    end
  end
end
