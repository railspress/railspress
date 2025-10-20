# frozen_string_literal: true

class AnalyticsConsent < ApplicationRecord
  acts_as_tenant(:tenant, optional: true)
  
  belongs_to :user, optional: true
  
  validates :consent_type, presence: true
  validates :granted, inclusion: { in: [true, false] }
  validates :timestamp, presence: true
  
  scope :granted, -> { where(granted: true) }
  scope :denied, -> { where(granted: false) }
  scope :by_type, ->(type) { where(consent_type: type) }
  scope :recent, -> { where('timestamp > ?', 1.year.ago) }
  scope :by_purpose, ->(purpose) { where(purpose: purpose) }
  
  def self.get_user_consent(user_id, consent_type)
    recent
      .where(user_id: user_id, consent_type: consent_type)
      .order(timestamp: :desc)
      .first
  end
  
  def self.user_has_consent?(user_id, consent_type)
    consent = get_user_consent(user_id, consent_type)
    consent&.granted || false
  end
  
  def self.consent_rate(consent_type, period = 30.days)
    total_consents = where(consent_type: consent_type, timestamp: period.ago..Time.current).count
    granted_consents = where(consent_type: consent_type, granted: true, timestamp: period.ago..Time.current).count
    
    return 0 if total_consents.zero?
    (granted_consents.to_f / total_consents * 100).round(2)
  end
end
