FactoryBot.define do
  factory :channel do
    name { Faker::Company.name }
    slug { name.parameterize }
    domain { Faker::Internet.domain_name }
    locale { 'en' }
    metadata { {} }
    settings { {} }

    trait :web do
      name { 'Web' }
      slug { 'web' }
      domain { 'www.example.com' }
    end

    trait :mobile do
      name { 'Mobile' }
      slug { 'mobile' }
      domain { 'm.example.com' }
    end

    trait :newsletter do
      name { 'Newsletter' }
      slug { 'newsletter' }
      domain { 'newsletter.example.com' }
    end

    trait :smart_tv do
      name { 'Smart TV' }
      slug { 'smarttv' }
      domain { 'tv.example.com' }
    end
  end
end