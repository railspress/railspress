class ArchivedAnalyticsEvent < ApplicationRecord
  # Archived analytics events for long-term storage
  # This model stores historical event data that has been archived
  
  acts_as_tenant(:tenant, optional: true)
  
  belongs_to :tenant, optional: true
  belongs_to :user, optional: true
  
  # Serialize properties as JSON
  serialize :properties, JSON
  
  # Scopes for filtering archived events
  scope :by_event_name, ->(event_name) { where(event_name: event_name) }
  scope :by_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }
  scope :by_session, ->(session_id) { where(session_id: session_id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where(created_at: Date.current.all_day) }
  scope :this_week, -> { where(created_at: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :this_month, -> { where(created_at: Date.current.beginning_of_month..Date.current.end_of_month) }
  
  # Event statistics for archived data
  def self.event_stats_by_date_range(start_date, end_date)
    data = by_date_range(start_date, end_date)
    
    {
      total_events: data.count,
      unique_events: data.distinct.count(:event_name),
      top_events: data.group(:event_name).count.sort_by { |_, count| -count }.first(20),
      events_by_hour: data.group("strftime('%H', created_at)").count,
      events_by_day: data.group("date(created_at)").count,
      conversion_events: data.where(event_name: ['conversion', 'purchase', 'signup', 'download']).count
    }
  end
  
  def self.export_for_analysis(start_date, end_date)
    by_date_range(start_date, end_date).map do |event|
      {
        date: event.created_at.strftime('%Y-%m-%d'),
        hour: event.created_at.hour,
        event_name: event.event_name,
        properties: event.properties,
        session_id: event.session_id,
        user_id: event.user_id
      }
    end
  end
end
