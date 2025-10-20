# frozen_string_literal: true

class AnalyticsAuditLog < ApplicationRecord
  acts_as_tenant(:tenant, optional: true)
  
  belongs_to :user, optional: true
  belongs_to :admin_user, class_name: 'User', optional: true
  
  validates :data_type, presence: true
  validates :action, presence: true
  validates :timestamp, presence: true
  
  scope :recent, -> { where('timestamp > ?', 30.days.ago) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_data_type, ->(data_type) { where(data_type: data_type) }
  
  def self.log_access(user_id, data_type, action, admin_user = nil)
    create!(
      user_id: user_id,
      data_type: data_type,
      action: action,
      admin_user: admin_user,
      timestamp: Time.current,
      ip_address: AnalyticsSecurityService.anonymize_ip(get_current_ip),
      user_agent: get_current_user_agent
    )
  end
  
  private
  
  def self.get_current_ip
    Thread.current[:current_request]&.remote_ip || '127.0.0.1'
  end
  
  def self.get_current_user_agent
    Thread.current[:current_request]&.user_agent || 'Unknown'
  end
end
