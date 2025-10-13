class Admin::AnalyticsController < Admin::BaseController
  # GET /admin/analytics
  def index
    @period = params[:period] || 'month'
    @stats = Pageview.stats(period: @period)
    
    # Real-time stats
    @active_now = Pageview.active_now
    @today_views = Pageview.today.non_bot.count
    @today_unique = Pageview.today.non_bot.unique_visitors.count
    
    # Compliance stats
    @consent_rate = calculate_consent_rate
    @total_tracked = Pageview.count
    @consented_tracked = Pageview.consented_only.count
  end
  
  # GET /admin/analytics/realtime
  def realtime
    @active_users = Pageview.where('visited_at >= ?', 5.minutes.ago)
                            .non_bot
                            .group(:path, :country_code)
                            .count
    
    @recent_pageviews = Pageview.recent
                               .non_bot
                               .limit(20)
                               .includes(:post, :page, :user)
    
    render json: {
      active_now: Pageview.active_now,
      active_users: @active_users,
      recent_views: @recent_pageviews.map { |pv| pageview_json(pv) }
    }
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
end





