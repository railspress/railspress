class PersonalDataExportRequest < ApplicationRecord
  acts_as_tenant(:tenant, optional: true)
  
  belongs_to :user
  
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :status, presence: true
  
  enum status: {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }, _suffix: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :pending_expiry, -> { where('completed_at < ?', 7.days.ago) }
  
  after_create :generate_token
  
  private
  
  def generate_token
    self.token ||= SecureRandom.hex(32)
  end
end
