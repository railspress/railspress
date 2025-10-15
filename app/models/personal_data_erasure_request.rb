class PersonalDataErasureRequest < ApplicationRecord
  acts_as_tenant(:tenant)
  
  belongs_to :user
  
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :status, presence: true
  
  enum status: {
    pending_confirmation: 'pending_confirmation',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed',
    cancelled: 'cancelled'
  }, _suffix: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :awaiting_confirmation, -> { where(status: 'pending_confirmation') }
  
  after_create :generate_token
  
  private
  
  def generate_token
    self.token ||= SecureRandom.hex(32)
  end
end
