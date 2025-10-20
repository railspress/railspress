class RealtimeAnalyticsChannel < ApplicationCable::Channel
  def subscribed
    # Subscribe to real-time analytics updates
    stream_from "realtime_analytics"
    
    # Send initial data
    send_realtime_data
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private

  def send_realtime_data
    data = {
      active_users: Pageview.where(created_at: 10.minutes.ago..Time.current).count,
      current_pageviews: Pageview.where(created_at: 10.minutes.ago..Time.current).count,
      unique_sessions: Pageview.where(created_at: 10.minutes.ago..Time.current).distinct.count(:session_id),
      active_countries: Pageview.where(created_at: 10.minutes.ago..Time.current).where.not(country_name: [nil, '']).distinct.count(:country_name),
      recent_views: Pageview.where(created_at: 10.minutes.ago..Time.current)
                           .order(created_at: :desc)
                           .limit(10)
                           .map do |pv|
        {
          path: pv.path,
          country: pv.country_name,
          browser: pv.browser,
          device: pv.device,
          created_at: pv.created_at.iso8601
        }
      end,
      timestamp: Time.current.iso8601
    }

    transmit(data)
  end
end