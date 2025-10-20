class AnalyticsEvent < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  # Associations
  belongs_to :user, optional: true
  belongs_to :tenant, optional: true
  
  # Serialization
  serialize :properties, coder: JSON, type: Hash
  
  # Validations
  validates :event_name, presence: true
  validates :session_id, presence: true
  
  # Scopes
  scope :by_event_name, ->(name) { where(event_name: name) }
  scope :by_session, ->(session_id) { where(session_id: session_id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where('created_at >= ?', Time.current.beginning_of_day) }
  scope :this_week, -> { where('created_at >= ?', 1.week.ago) }
  scope :this_month, -> { where('created_at >= ?', 1.month.ago) }
  
  # Class methods for event analytics
  
  def self.event_stats(period: :month)
    range = case period.to_sym
            when :today
              Time.current.beginning_of_day..Time.current.end_of_day
            when :week
              1.week.ago..Time.current
            when :month
              1.month.ago..Time.current
            when :year
              1.year.ago..Time.current
            else
              1.month.ago..Time.current
            end
    
    events = where(created_at: range)
    
    {
      total_events: events.count,
      unique_sessions: events.distinct.count(:session_id),
      top_events: events.group(:event_name).order('count_id DESC').limit(10).count(:id),
      events_per_session: events.count.to_f / events.distinct.count(:session_id),
      conversion_events: events.where(event_name: ['purchase', 'signup', 'download', 'contact']).count
    }
  end
  
  def self.track_conversion(event_name, properties = {})
    # Track conversion events with enhanced properties
    create!(
      event_name: event_name,
      properties: properties.merge({
        conversion: true,
        timestamp: Time.current.iso8601,
        user_agent: properties[:user_agent],
        referrer: properties[:referrer]
      }),
      session_id: properties[:session_id] || SecureRandom.hex(16),
      user_id: properties[:user_id],
      path: properties[:path] || '/',
      tenant: properties[:tenant] || ActsAsTenant.current_tenant
    )
  rescue => e
    Rails.logger.error "Failed to track conversion event: #{e.message}"
    nil
  end
end
