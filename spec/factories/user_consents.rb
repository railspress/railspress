FactoryBot.define do
  factory :user_consent do
    user
    tenant { user.tenant }
    consent_type { 'data_processing' }
    consent_text { 'I agree to the processing of my personal data' }
    granted { true }
    granted_at { Time.current }
    withdrawn_at { nil }
    ip_address { '127.0.0.1' }
    user_agent { 'Mozilla/5.0 (Test Browser)' }
    
    trait :withdrawn do
      granted { false }
      granted_at { 1.day.ago }
      withdrawn_at { Time.current }
    end
    
    trait :marketing do
      consent_type { 'marketing' }
      consent_text { 'I agree to receive marketing communications' }
    end
    
    trait :analytics do
      consent_type { 'analytics' }
      consent_text { 'I agree to analytics tracking' }
    end
    
    trait :cookies do
      consent_type { 'cookies' }
      consent_text { 'I agree to the use of cookies' }
    end
    
    trait :newsletter do
      consent_type { 'newsletter' }
      consent_text { 'I agree to receive newsletter emails' }
    end
    
    trait :third_party_sharing do
      consent_type { 'third_party_sharing' }
      consent_text { 'I agree to sharing my data with third parties' }
    end
  end
end
