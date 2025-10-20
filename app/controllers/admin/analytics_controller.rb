class Admin::AnalyticsController < Admin::BaseController
  def index
    @period = params[:period] || 'month'
    range = period_range(@period)
    
    # Core metrics
    @total_pageviews = Pageview.where(created_at: range).count
    @unique_visitors = Pageview.where(created_at: range).distinct.count(:session_id)
    @avg_session_duration = calculate_avg_session_duration(range)
    @bounce_rate = calculate_bounce_rate(range)
    @pages_per_session = calculate_pages_per_session(range)
    @current_pageviews = Pageview.where(created_at: 1.hour.ago..Time.current).count
    
    # Country data
    @country_data = Pageview.where(created_at: range)
                           .where.not(country_name: [nil, ''])
                           .group(:country_name)
                           .count
                           .map { |name, count| { name: name, count: count } }
                           .sort_by { |item| -item[:count] }
                           .first(10)
    
    # Device data
    @device_data = Pageview.where(created_at: range)
                          .where.not(device: [nil, ''])
                          .group(:device)
                          .count
                          .map { |type, count| { type: type, count: count } }
                          .sort_by { |item| -item[:count] }
                          .first(10)
    
    # Top referrers
    @top_referrers = Pageview.where(visited_at: range)
                            .where.not(referrer: [nil, ''])
                            .group(:referrer)
                            .count
                            .map { |referrer, count| { referrer: referrer, count: count } }
                            .sort_by { |item| -item[:count] }
                            .first(10)
    
    # Traffic data for charts
    @traffic_data = Pageview.where(created_at: range)
                           .group("DATE(created_at)")
                           .count
                           .map { |date, count| { date: date.to_s, count: count } }
    
    # Top pages
    @top_pages = Pageview.where(created_at: range)
                        .where.not(path: [nil, ''])
                        .group(:path)
                        .count
                        .map { |path, count| { path: path, count: count } }
                        .sort_by { |item| -item[:count] }
                        .first(10)
    
    # Browser and device stats
    @browser_stats = Pageview.where(created_at: range)
                            .where.not(browser: [nil, ''])
                            .group(:browser)
                            .count
    
    @device_stats = Pageview.where(created_at: range)
                           .where.not(device: [nil, ''])
                           .group(:device)
                           .count
    
    @os_stats = Pageview.where(created_at: range)
                       .where.not(os: [nil, ''])
                       .group(:os)
                       .count
    
    # Set audience insights
    @audience_insights = AnalyticsService.audience_insights(period: @period)
    @operating_systems = @audience_insights[:operating_systems] || []
  end
  
  
  # GET /admin/analytics/realtime
  def realtime
    # REAL-TIME: Last 10 minutes only
    @current_pageviews = Pageview.where(created_at: 10.minutes.ago..Time.current).count
    @recent_pageviews = Pageview.where(created_at: 10.minutes.ago..Time.current)
                               .order(created_at: :desc)
                               .limit(50)
  end
  
  # GET /admin/analytics/insights
  def insights
    @period = params[:period] || 'month'
    insights = AnalyticsService.generate_insights(period: @period)
    
    render json: insights
  end
  
  # GET /admin/analytics/posts
  def posts
    @period = params[:period] || 'month'
    range = period_range(@period)
    
    @top_posts = Pageview.consented_only
                         .non_bot
                         .where(visited_at: range)
                         .where.not(post_id: nil)
                         .group(:post_id)
                         .order('count_id DESC')
                         .limit(50)
                         .count(:id)
                         .map do |post_id, count|
      post = Post.find_by(id: post_id)
      {
        post: post,
        post_id: post_id,
        title: post&.title || "Deleted Post ##{post_id}",
        views: count,
        unique: Pageview.consented_only.non_bot.where(post_id: post_id, visited_at: range, unique_visitor: true).count
      }
    end
  end
  
  # GET /admin/analytics/pages
  def pages
    @period = params[:period] || 'month'
    range = period_range(@period)
    
    @top_pages = Pageview.consented_only
                         .non_bot
                         .where(visited_at: range)
                         .where.not(page_id: nil)
                         .group(:page_id)
                         .order('count_id DESC')
                         .limit(50)
                         .count(:id)
                         .map do |page_id, count|
      page_obj = Page.find_by(id: page_id)
      {
        page: page_obj,
        views: count,
        unique: Pageview.consented_only.non_bot.where(page_id: page_id, visited_at: range, unique_visitor: true).count
      }
    end
  end
  
  # GET /admin/analytics/countries
  def countries
    @period = params[:period] || 'month'
    range = period_range(@period)
    
    @country_stats = Pageview.consented_only
                             .non_bot
                             .where(visited_at: range)
                             .where.not(country_code: nil)
                             .group(:country_code)
                             .order('count_id DESC')
                             .count(:id)
                             .map { |code, count| { code: code, name: country_name(code), count: count } }
  end
  
  # GET /admin/analytics/browsers
  def browsers
    @period = params[:period] || 'month'
    range = period_range(@period)
    
    @browser_stats = Pageview.consented_only.non_bot.where(visited_at: range).group(:browser).count
    @device_stats = Pageview.consented_only.non_bot.where(visited_at: range).group(:device).count
    @os_stats = Pageview.consented_only.non_bot.where(visited_at: range).group(:os).count
  end
  
  # GET /admin/analytics/referrers
  def referrers
    @period = params[:period] || 'month'
    range = period_range(@period)
    
    @referrer_stats = Pageview.consented_only
                              .non_bot
                              .where(visited_at: range)
                              .where.not(referrer: [nil, ''])
                              .group(:referrer)
                              .order('count_id DESC')
                              .limit(50)
                              .count(:id)
  end
  
  # GET /admin/analytics/export
  def export
    @period = params[:period] || 'month'
    range = period_range(@period)
    
    pageviews = Pageview.consented_only
                        .where(visited_at: range)
                        .order(visited_at: :desc)
    
    csv_data = generate_csv(pageviews)
    
    send_data csv_data,
              filename: "analytics-#{@period}-#{Date.today}.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end
  
  # POST /admin/analytics/purge
  def purge
    days = params[:days]&.to_i || 90
    
    case params[:purge_type]
    when 'anonymize'
      Pageview.anonymize_old_data(days)
      message = "Data older than #{days} days has been anonymized."
    when 'delete_non_consented'
      count = Pageview.purge_non_consented(days)
      message = "Deleted #{count} non-consented pageviews older than #{days} days."
    when 'delete_all'
      count = Pageview.where('created_at < ?', days.days.ago).delete_all
      message = "Deleted #{count} pageviews older than #{days} days."
    else
      message = "Invalid purge type."
    end
    
    redirect_to admin_analytics_path, notice: message
  end
  
  # POST /analytics/events (for custom event tracking)
  def track_event
    return head :unauthorized unless request.xhr? || request.content_type&.include?('application/json')
    
    begin
      event_data = JSON.parse(request.body.read)
      
      # Create analytics event
      event = AnalyticsEvent.create!(
        event_name: event_data['event_name'],
        properties: event_data['properties'] || {},
        session_id: event_data['properties']&.dig('session_id') || generate_session_id,
        user_id: current_user&.id,
        path: event_data['properties']&.dig('path') || request.path,
        tenant: ActsAsTenant.current_tenant
      )
      
      render json: { success: true, event_id: event.id }
    rescue => e
      Rails.logger.error "Failed to track custom event: #{e.message}"
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end
  end
  
  private
  
  def period_range(period)
    case period.to_sym
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
  end
  
  def calculate_consent_rate
    total = Pageview.count
    return 0 if total.zero?
    
    consented = Pageview.consented_only.count
    ((consented.to_f / total) * 100).round(1)
  end
  
  def country_name(code)
    # Simple country code to name mapping
    countries = {
      'US' => 'United States',
      'GB' => 'United Kingdom',
      'CA' => 'Canada',
      'DE' => 'Germany',
      'FR' => 'France',
      'ES' => 'Spain',
      'IT' => 'Italy',
      'BR' => 'Brazil',
      'JP' => 'Japan',
      'CN' => 'China',
      'IN' => 'India',
      'AU' => 'Australia',
      'MX' => 'Mexico',
      'NL' => 'Netherlands'
    }
    
    countries[code] || code
  end
  
  def pageview_json(pageview)
    {
      id: pageview.id,
      path: pageview.path,
      title: pageview.title,
      browser: pageview.browser,
      device: pageview.device,
      country: pageview.country_code,
      visited_at: pageview.visited_at.strftime('%Y-%m-%d %H:%M:%S')
    }
  end
  
  def generate_csv(pageviews)
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      csv << ['Date', 'Time', 'Path', 'Title', 'Referrer', 'Country', 'Browser', 'Device', 'OS', 'Duration']
      
      pageviews.each do |pv|
        csv << [
          pv.visited_at.strftime('%Y-%m-%d'),
          pv.visited_at.strftime('%H:%M:%S'),
          pv.path,
          pv.title,
          pv.referrer,
          pv.country_code,
          pv.browser,
          pv.device,
          pv.os,
          pv.duration
        ]
      end
    end
  end
  
  def calculate_engagement_levels(range)
    pageviews = Pageview.consented_only.non_bot.where(visited_at: range)
    
    high_engagement = pageviews.where('time_on_page > ? AND scroll_depth > ?', 60, 75).count
    medium_engagement = pageviews.where('time_on_page BETWEEN ? AND ? AND scroll_depth BETWEEN ? AND ?', 30, 60, 25, 75).count
    low_engagement = pageviews.where('time_on_page < ? OR scroll_depth < ?', 30, 25).count
    
    [
      { level: 'high', count: high_engagement },
      { level: 'medium', count: medium_engagement },
      { level: 'low', count: low_engagement }
    ]
  end
  
  def calculate_device_breakdown(range)
    Pageview.consented_only
            .non_bot
            .where(visited_at: range)
            .where.not(device: nil)
            .group(:device)
            .count(:id)
            .sort_by { |_, count| -count }
            .first(10)
            .map { |device, count| { device: device, count: count } }
  end
  
  def calculate_country_breakdown(range)
    Pageview.consented_only
            .non_bot
            .where(visited_at: range)
            .where.not(country_code: nil)
            .group(:country_code)
            .count(:id)
            .sort_by { |_, count| -count }
            .first(10)
            .map { |country, count| { country: country, count: count } }
  end
  
  def calculate_performance_metrics(range)
    pageviews = Pageview.consented_only.non_bot.where(visited_at: range)
    
    {
      page_load_time: 85, # This would come from performance monitoring
      time_to_interactive: 78,
      first_contentful_paint: 92,
      largest_contentful_paint: 88
    }
  end
  
  def calculate_conversion_funnel(range)
    pageviews = Pageview.consented_only.non_bot.where(visited_at: range)
    
    visitors = pageviews.distinct.count(:session_id)
    page_views = pageviews.count
    engaged_users = pageviews.where('time_on_page > ?', 30).distinct.count(:session_id)
    readers = pageviews.where(is_reader: true).distinct.count(:session_id)
    conversions = AnalyticsEvent.where(created_at: range, event_name: 'conversion').distinct.count(:session_id)
    
    [
      { stage: 'Visitors', count: visitors },
      { stage: 'Page Views', count: page_views },
      { stage: 'Engaged Users', count: engaged_users },
      { stage: 'Readers', count: readers },
      { stage: 'Conversions', count: conversions }
    ]
  end
  
  # Advanced GA4/Matomo-level analytics methods
  def calculate_traffic_sources(range)
    pageviews = Pageview.consented_only.non_bot.where(visited_at: range)
    
    sources = pageviews.where.not(referrer: [nil, '']).group(:referrer).count(:id)
    direct = pageviews.where(referrer: [nil, '']).count
    
    {
      organic: sources.select { |k, _| k.include?('google') || k.include?('bing') }.sum { |_, v| v },
      social: sources.select { |k, _| k.include?('facebook') || k.include?('twitter') || k.include?('linkedin') }.sum { |_, v| v },
      direct: direct,
      referral: sources.reject { |k, _| k.include?('google') || k.include?('bing') || k.include?('facebook') || k.include?('twitter') || k.include?('linkedin') }.sum { |_, v| v }
    }
  end
  
  def calculate_user_flow(range)
    pageviews = Pageview.consented_only.non_bot.where(visited_at: range)
    
    # Calculate user flow through the site
    entry_pages = pageviews.group(:session_id).minimum(:visited_at)
    exit_pages = pageviews.group(:session_id).maximum(:visited_at)
    
    {
      entry_pages: entry_pages.values.group_by { |pv| Pageview.find(pv.id).path }.transform_values(&:count),
      exit_pages: exit_pages.values.group_by { |pv| Pageview.find(pv.id).path }.transform_values(&:count),
      avg_pages_per_session: pageviews.group(:session_id).count.values.mean || 0
    }
  end
  
  def calculate_cohort_analysis(range)
    # Simple cohort analysis by month
    cohorts = {}
    (0..12).each do |i|
      month_start = i.months.ago.beginning_of_month
      month_end = month_start.end_of_month
      
      cohort_users = Pageview.where(visited_at: month_start..month_end).distinct.pluck(:session_id)
      cohorts[month_start.strftime('%Y-%m')] = {
        users: cohort_users.count,
        retention: calculate_cohort_retention(cohort_users, month_start)
      }
    end
    
    cohorts
  end
  
  def calculate_attribution_data(range)
    # Multi-touch attribution analysis
    sessions = Pageview.where(visited_at: range).distinct.pluck(:session_id)
    
    {
      first_touch: calculate_first_touch_attribution(sessions),
      last_touch: calculate_last_touch_attribution(sessions),
      linear: calculate_linear_attribution(sessions)
    }
  end
  
  def calculate_bounce_rate(range)
    pageviews = Pageview.consented_only.non_bot.where(visited_at: range)
    total_sessions = pageviews.distinct.count(:session_id)
    return 0 if total_sessions.zero?
    
    single_page_sessions_count = pageviews.group(:session_id).having('COUNT(*) = 1').count.size
    (single_page_sessions_count.to_f / total_sessions * 100).round(2)
  end
  
  def calculate_avg_session_duration(range)
    pageviews = Pageview.consented_only.non_bot.where(visited_at: range)
    sessions = pageviews.group(:session_id).sum(:time_on_page)
    
    return 0 if sessions.empty?
    (sessions.values.sum / sessions.count).round(2)
  end
  
  def calculate_pages_per_session(range)
    pageviews = Pageview.consented_only.non_bot.where(visited_at: range)
    pages_per_session = pageviews.group(:session_id).count
    
    return 0 if pages_per_session.empty?
    (pages_per_session.values.sum / pages_per_session.count.to_f).round(2)
  end
  
  def calculate_conversion_rate(range)
    total_sessions = Pageview.consented_only.non_bot.where(visited_at: range).distinct.count(:session_id)
    conversions = AnalyticsEvent.where(created_at: range, event_name: 'conversion').distinct.count(:session_id)
    
    return 0 if total_sessions.zero?
    (conversions.to_f / total_sessions * 100).round(2)
  end
  
  def get_top_posts(range)
    Pageview.consented_only
            .non_bot
            .where(visited_at: range)
            .where.not(post_id: nil)
            .group(:post_id)
            .count(:id)
            .sort_by { |_, count| -count }
            .first(10)
            .map do |post_id, count|
      post = Post.find_by(id: post_id)
      {
        post: post,
        post_id: post_id,
        title: post&.title || "Deleted Post ##{post_id}",
        views: count,
        unique_readers: Pageview.consented_only.non_bot.where(post_id: post_id, visited_at: range, is_reader: true).count
      }
    end
  end
  
  def get_top_pages(range)
    Pageview.consented_only
            .non_bot
            .where(visited_at: range)
            .where.not(page_id: nil)
            .group(:page_id)
            .count(:id)
            .sort_by { |_, count| -count }
            .first(10)
            .map do |page_id, count|
      page = Page.find_by(id: page_id)
      {
        page: page,
        page_id: page_id,
        title: page&.title || "Deleted Page ##{page_id}",
        views: count,
        unique_readers: Pageview.consented_only.non_bot.where(page_id: page_id, visited_at: range, is_reader: true).count
      }
    end
  end
  
  def calculate_content_engagement(range)
    pageviews = Pageview.consented_only.non_bot.where(visited_at: range)
    
    {
      avg_reading_time: pageviews.average(:reading_time)&.round(2) || 0,
      avg_scroll_depth: pageviews.average(:scroll_depth)&.round(2) || 0,
      avg_completion_rate: pageviews.average(:completion_rate)&.round(2) || 0,
      readers_count: pageviews.where(is_reader: true).count,
      high_engagement_readers: pageviews.where(is_reader: true, engagement_score: 80..100).count
    }
  end
  
  def calculate_geographic_insights(range)
    pageviews = Pageview.consented_only.non_bot.where(visited_at: range)
    
    {
      top_countries: pageviews.where.not(country_code: nil).group(:country_code).count.sort_by { |_, v| -v }.first(10),
      top_cities: pageviews.where.not(city: nil).group(:city).count.sort_by { |_, v| -v }.first(10),
      top_regions: pageviews.where.not(region: nil).group(:region).count.sort_by { |_, v| -v }.first(10)
    }
  end
  
  def calculate_technology_insights(range)
    pageviews = Pageview.consented_only.non_bot.where(visited_at: range)
    
    {
      browsers: pageviews.where.not(browser: nil).group(:browser).count.sort_by { |_, v| -v },
      devices: pageviews.where.not(device: nil).group(:device).count.sort_by { |_, v| -v },
      operating_systems: pageviews.where.not(os: nil).group(:os).count.sort_by { |_, v| -v }
    }
  end
  
  def calculate_time_insights(range)
    pageviews = Pageview.consented_only.non_bot.where(visited_at: range)
    
    {
      hourly_distribution: pageviews.group_by_hour(:visited_at).count,
      daily_distribution: pageviews.group_by_day(:visited_at).count,
      weekly_distribution: pageviews.group_by_day_of_week(:visited_at).count,
      monthly_distribution: pageviews.group_by_month(:visited_at).count
    }
  end
  
  def calculate_cohort_retention(cohort_users, cohort_month)
    # Calculate how many users from this cohort returned in subsequent months
    returning_users = 0
    (1..12).each do |i|
      next_month = cohort_month + i.months
      if next_month <= Time.current
        next_month_users = Pageview.where(visited_at: next_month.beginning_of_month..next_month.end_of_month)
                                  .where(session_id: cohort_users)
                                  .distinct
                                  .pluck(:session_id)
        returning_users += next_month_users.count
      end
    end
    
    cohort_users.empty? ? 0 : (returning_users.to_f / cohort_users.count * 100).round(2)
  end
  
  def calculate_first_touch_attribution(sessions)
    # Calculate first-touch attribution
    first_touches = {}
    sessions.each do |session_id|
      first_pageview = Pageview.where(session_id: session_id).order(:visited_at).first
      next unless first_pageview&.referrer.present?
      
      source = categorize_traffic_source(first_pageview.referrer)
      first_touches[source] = (first_touches[source] || 0) + 1
    end
    first_touches
  end
  
  def calculate_last_touch_attribution(sessions)
    # Calculate last-touch attribution
    last_touches = {}
    sessions.each do |session_id|
      last_pageview = Pageview.where(session_id: session_id).order(:visited_at).last
      next unless last_pageview&.referrer.present?
      
      source = categorize_traffic_source(last_pageview.referrer)
      last_touches[source] = (last_touches[source] || 0) + 1
    end
    last_touches
  end
  
  def calculate_linear_attribution(sessions)
    # Calculate linear attribution (equal weight to all touchpoints)
    linear_attribution = {}
    sessions.each do |session_id|
      pageviews = Pageview.where(session_id: session_id).where.not(referrer: [nil, ''])
      next if pageviews.empty?
      
      weight = 1.0 / pageviews.count
      pageviews.each do |pv|
        source = categorize_traffic_source(pv.referrer)
        linear_attribution[source] = (linear_attribution[source] || 0) + weight
      end
    end
    linear_attribution
  end
  
  def categorize_traffic_source(referrer)
    return 'Direct' if referrer.blank?
    
    if referrer.include?('google') || referrer.include?('bing') || referrer.include?('yahoo')
      'Organic Search'
    elsif referrer.include?('facebook') || referrer.include?('twitter') || referrer.include?('linkedin') || referrer.include?('instagram')
      'Social Media'
    elsif referrer.include?('mail') || referrer.include?('email')
      'Email'
    else
      'Referral'
    end
  end
end








