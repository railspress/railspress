FactoryBot.define do
  factory :channel_override do
    association :channel
    resource_type { 'Post' }
    resource_id { 1 }
    kind { 'override' }
    path { 'title' }
    data { { 'title' => 'Overridden Title' } }
    enabled { true }

    trait :exclusion do
      kind { 'exclude' }
      path { 'exclude' }
      data { {} }
    end

    trait :disabled do
      enabled { false }
    end

    trait :for_page do
      resource_type { 'Page' }
    end

    trait :for_medium do
      resource_type { 'Medium' }
    end

    trait :for_setting do
      resource_type { 'Setting' }
    end
  end
end