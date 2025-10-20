class Admin::ContentAnalyticsController < Admin::BaseController
  before_action :ensure_admin
  
  # GET /admin/analytics/posts/:id
  def post
    @post = Post.find(params[:id])
    @period = params[:period] || 'month'
    @analytics = ContentAnalyticsService.post_analytics(@post.id, period: @period.to_sym)
    
    # Chart data for views over time
    @views_chart_data = @analytics[:views_by_day].map do |date, count|
      { date: date, views: count }
    end
    
    # Chart data for views by hour
    @hourly_chart_data = @analytics[:views_by_hour].map do |hour, count|
      { hour: hour, views: count }
    end
    
    # Chart data for reader demographics
    @country_chart_data = @analytics[:readers_by_country].first(10).map do |country, count|
      { country: country, readers: count }
    end
    
    @device_chart_data = @analytics[:readers_by_device].map do |device, count|
      { device: device, readers: count }
    end
  end
  
  # GET /admin/analytics/pages/:id
  def page
    @page = Page.find(params[:id])
    @period = params[:period] || 'month'
    @analytics = ContentAnalyticsService.page_analytics(@page.id, period: @period.to_sym)
    
    # Chart data for views over time
    @views_chart_data = @analytics[:views_by_day].map do |date, count|
      { date: date, views: count }
    end
    
    # Chart data for views by hour
    @hourly_chart_data = @analytics[:views_by_hour].map do |hour, count|
      { hour: hour, views: count }
    end
    
    # Chart data for visitor demographics
    @country_chart_data = @analytics[:visitors_by_country].first(10).map do |country, count|
      { country: country, visitors: count }
    end
    
    @device_chart_data = @analytics[:visitors_by_device].map do |device, count|
      { device: device, visitors: count }
    end
  end
  
  # GET /admin/analytics/content/performance
  def performance
    @period = params[:period] || 'month'
    @limit = params[:limit]&.to_i || 10
    @performance_data = ContentAnalyticsService.top_performing_content(
      period: @period.to_sym, 
      limit: @limit
    )
  end
  
  # GET /admin/analytics/content/engagement
  def engagement
    @period = params[:period] || 'month'
    @engagement_data = ContentAnalyticsService.reader_engagement_insights(period: @period.to_sym)
    
    # Chart data for engagement levels
    @engagement_chart_data = [
      { level: 'Low', count: @engagement_data[:low_engagement] },
      { level: 'Medium', count: @engagement_data[:medium_engagement] },
      { level: 'High', count: @engagement_data[:high_engagement] }
    ]
    
    # Chart data for reader segments
    @reader_segments_chart_data = [
      { segment: 'Quick Readers', count: @engagement_data[:quick_readers] },
      { segment: 'Engaged Readers', count: @engagement_data[:engaged_readers] },
      { segment: 'Deep Readers', count: @engagement_data[:deep_readers] }
    ]
    
    # Chart data for scroll behavior
    @scroll_chart_data = [
      { milestone: '25%', count: @engagement_data[:readers_who_scrolled_25] },
      { milestone: '50%', count: @engagement_data[:readers_who_scrolled_50] },
      { milestone: '75%', count: @engagement_data[:readers_who_scrolled_75] },
      { milestone: '100%', count: @engagement_data[:readers_who_scrolled_100] }
    ]
  end
  
  # GET /admin/analytics/content/export
  def export
    @period = params[:period] || 'month'
    @content_type = params[:content_type] || 'all' # all, posts, pages
    
    case @content_type
    when 'posts'
      @content = Post.published.includes(:pageviews)
    when 'pages'
      @content = Page.published.includes(:pageviews)
    else
      @content = Post.published.includes(:pageviews) + Page.published.includes(:pageviews)
    end
    
    respond_to do |format|
      format.csv do
        send_data generate_csv(@content, @period), 
                  filename: "content-analytics-#{@content_type}-#{@period}-#{Date.today}.csv",
                  type: 'text/csv',
                  disposition: 'attachment'
      end
    end
  end
  
  private
  
  def generate_csv(content, period)
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      csv << [
        'Content Type', 'Title', 'Slug', 'Published Date', 'Total Views', 
        'Unique Readers', 'Avg Reading Time', 'Avg Completion Rate', 
        'Engagement Score', 'URL'
      ]
      
      content.each do |item|
        range = period_range(period)
        pageviews = item.pageviews.where(visited_at: range).non_bot.consented_only
        
        csv << [
          item.class.name,
          item.title,
          item.slug,
          item.published_at&.strftime('%Y-%m-%d'),
          pageviews.count,
          pageviews.distinct.count(:session_id),
          pageviews.where.not(reading_time: nil).average(:reading_time)&.to_i || 0,
          pageviews.where.not(completion_rate: nil).average(:completion_rate)&.to_f || 0.0,
          ContentAnalyticsService.calculate_engagement_score(pageviews),
          Rails.application.routes.url_helpers.url_for(item)
        ]
      end
    end
  end
  
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
end
