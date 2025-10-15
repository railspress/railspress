class EmailLog < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant)
  
  # Serialize metadata as JSON
  serialize :metadata, coder: JSON, type: Hash
  
  # Enums
  enum status: {
    pending: 'pending',
    sent: 'sent',
    failed: 'failed',
    bounced: 'bounced'
  }, _prefix: true
  
  enum provider: {
    smtp: 'smtp',
    resend: 'resend',
    test: 'test'
  }, _prefix: true
  
  # Validations
  validates :from_address, :to_address, :subject, presence: true
  validates :status, presence: true
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where('created_at >= ?', Time.current.beginning_of_day) }
  scope :this_week, -> { where('created_at >= ?', Time.current.beginning_of_week) }
  scope :this_month, -> { where('created_at >= ?', Time.current.beginning_of_month) }
  
  # Class methods
  def self.log_email(from:, to:, subject:, body:, provider:, status: 'pending', error: nil, metadata: {})
    create!(
      from_address: from,
      to_address: to,
      subject: subject,
      body: body,
      provider: provider,
      status: status,
      error_message: error,
      metadata: metadata,
      sent_at: status == 'sent' ? Time.current : nil
    )
  end
  
  def self.stats
    {
      total: count,
      sent: status_sent.count,
      failed: status_failed.count,
      pending: status_pending.count,
      today: today.count,
      this_week: this_week.count,
      this_month: this_month.count
    }
  end
  
  # Instance methods
  def success?
    status_sent?
  end
  
  def failed?
    status_failed? || status_bounced?
  end
  
  def truncated_body(length = 200)
    return '' if body.blank?
    body.truncate(length)
  end
end
