class UserConsent < ApplicationRecord
  acts_as_tenant(:tenant)
  
  belongs_to :user
  
  validates :consent_type, presence: true, uniqueness: { scope: :user_id }
  validates :consent_text, presence: true
  validates :ip_address, presence: true
  validates :user_agent, presence: true
  
  # Consent types
  CONSENT_TYPES = %w[
    data_processing
    marketing
    analytics
    cookies
    newsletter
    third_party_sharing
  ].freeze
  
  validates :consent_type, inclusion: { in: CONSENT_TYPES }
  
  scope :granted, -> { where(granted: true) }
  scope :withdrawn, -> { where(granted: false) }
  scope :by_type, ->(type) { where(consent_type: type) }
  scope :recent, -> { order(granted_at: :desc) }
  
  # Callbacks
  before_validation :set_defaults, on: :create
  
  def granted?
    granted && granted_at.present? && withdrawn_at.nil?
  end
  
  def withdrawn?
    !granted || withdrawn_at.present?
  end
  
  def withdraw!
    update!(
      granted: false,
      withdrawn_at: Time.current
    )
  end
  
  def grant!
    update!(
      granted: true,
      granted_at: Time.current,
      withdrawn_at: nil
    )
  end
  
  private
  
  def set_defaults
    self.granted_at ||= Time.current if granted
  end
end
