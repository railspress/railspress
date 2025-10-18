FactoryBot.define do
  factory :term_relationship do
    association :term
    association :object, factory: :post
  end
end
