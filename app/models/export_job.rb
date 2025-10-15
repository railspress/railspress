class ExportJob < ApplicationRecord
  acts_as_tenant(:tenant)
  
  belongs_to :user
  
  validates :export_type, presence: true
  validates :status, presence: true
  
  enum status: {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }, _suffix: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where(status: ['pending', 'processing']) }
end
