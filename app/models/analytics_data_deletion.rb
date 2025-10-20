# frozen_string_literal: true

class AnalyticsDataDeletion < ApplicationRecord
  acts_as_tenant(:tenant, optional: true)
  
  belongs_to :user, optional: true
  belongs_to :admin_user, class_name: 'User', optional: true
  
  validates :data_types, presence: true
  validates :timestamp, presence: true
  
  scope :recent, -> { where('timestamp > ?', 1.year.ago) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_admin, ->(admin_id) { where(admin_user_id: admin_id) }
  
  def self.log_deletion(user_id, data_types, admin_user = nil)
    create!(
      user_id: user_id,
      data_types: data_types,
      admin_user: admin_user,
      timestamp: Time.current
    )
  end
  
  def data_types_array
    case data_types
    when String
      JSON.parse(data_types) rescue [data_types]
    when Array
      data_types
    else
      [data_types]
    end
  end
end
