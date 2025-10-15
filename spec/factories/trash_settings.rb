FactoryBot.define do
  factory :trash_setting do
    auto_cleanup_enabled { false }
    cleanup_after_days { 1 }
    tenant { nil }
  end
end
