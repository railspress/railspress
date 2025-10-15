class AiUsage < ApplicationRecord
  belongs_to :ai_agent
  belongs_to :user
  
  validates :prompt, presence: true
  validates :tokens_used, presence: true, numericality: { greater_than: 0 }
  validates :cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :response_time, presence: true, numericality: { greater_than: 0 }
  validates :success, inclusion: { in: [true, false] }
  
  scope :successful, -> { where(success: true) }
  scope :failed, -> { where(success: false) }
  scope :today, -> { where(created_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_month, -> { where(created_at: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :by_agent, ->(agent) { where(ai_agent: agent) }
  
  def self.total_tokens_for_period(start_date, end_date)
    where(created_at: start_date..end_date).sum(:tokens_used)
  end
  
  def self.total_cost_for_period(start_date, end_date)
    where(created_at: start_date..end_date).sum(:cost)
  end
  
  def self.average_response_time_for_period(start_date, end_date)
    where(created_at: start_date..end_date).average(:response_time)&.round(2)
  end
  
  def self.success_rate_for_period(start_date, end_date)
    period_usages = where(created_at: start_date..end_date)
    return 0 if period_usages.empty?
    
    (period_usages.successful.count.to_f / period_usages.count * 100).round(1)
  end
end
