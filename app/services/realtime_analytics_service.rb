class RealtimeAnalyticsService
  def self.broadcast_new_pageview(pageview)
    data = {
      type: 'new_pageview',
      pageview: {
        id: pageview.id,
        path: pageview.path,
        title: pageview.title,
        country: pageview.country_name,
        browser: pageview.browser,
        device: pageview.device,
        created_at: pageview.created_at.iso8601
      },
      stats: {
        active_users: Pageview.where(created_at: 10.minutes.ago..Time.current).count,
        current_pageviews: Pageview.where(created_at: 10.minutes.ago..Time.current).count,
        unique_sessions: Pageview.where(created_at: 10.minutes.ago..Time.current).distinct.count(:session_id),
        active_countries: Pageview.where(created_at: 10.minutes.ago..Time.current).where.not(country_name: [nil, '']).distinct.count(:country_name)
      },
      timestamp: Time.current.iso8601
    }

    ActionCable.server.broadcast('realtime_analytics', data)
  end

  def self.broadcast_stats_update
    data = {
      type: 'stats_update',
      stats: {
        active_users: Pageview.where(created_at: 10.minutes.ago..Time.current).count,
        current_pageviews: Pageview.where(created_at: 10.minutes.ago..Time.current).count,
        unique_sessions: Pageview.where(created_at: 10.minutes.ago..Time.current).distinct.count(:session_id),
        active_countries: Pageview.where(created_at: 10.minutes.ago..Time.current).where.not(country_name: [nil, '']).distinct.count(:country_name)
      },
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

    ActionCable.server.broadcast('realtime_analytics', data)
  end
end
