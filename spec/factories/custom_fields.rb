FactoryBot.define do
  factory :custom_field do
    name { Faker::Lorem.word }
    label { name.humanize }
    field_type { 'text' }
    required { false }
    order { 1 }
    association :field_group
    association :tenant
    
    trait :required do
      required { true }
    end
    
    trait :text_field do
      field_type { 'text' }
    end
    
    trait :textarea_field do
      field_type { 'textarea' }
    end
    
    trait :select_field do
      field_type { 'select' }
      options { ['Option 1', 'Option 2', 'Option 3'] }
    end
    
    trait :checkbox_field do
      field_type { 'checkbox' }
    end
    
    trait :radio_field do
      field_type { 'radio' }
      options { ['Yes', 'No'] }
    end
    
    trait :date_field do
      field_type { 'date' }
    end
    
    trait :number_field do
      field_type { 'number' }
    end
  end
end