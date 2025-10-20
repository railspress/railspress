# Content Analytics Service - Medium-like analytics for posts and pages
class ContentAnalyticsService
  include AnalyticsHelper
  
  # Get comprehensive analytics for a specific post
  def self.post_analytics(post_id, period: :month)
    post = Post.find(post_id)
    range = period_range(period)
    pageviews = Pageview.where(visited_at: range, post_id: post_id).non_bot.consented_only
    
    readers = pageviews.where(is_reader: true) # Medium-like readers (30+ seconds)
    
    {
      # Basic metrics
      total_views: pageviews.count,
      unique_readers: pageviews.distinct.count(:session_id),
      medium_readers: readers.count, # Users who spent 30+ seconds (Medium definition)
      reader_conversion_rate: readers.count.to_f / [pageviews.count, 1].max * 100,
      returning_readers: pageviews.where(returning_visitor: true).distinct.count(:session_id),
      
      # Engagement metrics
      avg_reading_time: pageviews.where.not(reading_time: nil).average(:reading_time)&.to_i || 0,
      avg_engagement_score: pageviews.where.not(engagement_score: nil).average(:engagement_score)&.to_f || 0.0,
      avg_scroll_depth: pageviews.where.not(scroll_depth: nil).average(:scroll_depth)&.to_i || 0,
      avg_completion_rate: pageviews.where.not(completion_rate: nil).average(:completion_rate)&.to_f || 0.0,
      avg_time_on_page: pageviews.where.not(time_on_page: nil).average(:time_on_page)&.to_i || 0,
      
      # Reader behavior (Medium-like)
      readers_who_scrolled_to_bottom: readers.where(scroll_depth: 100).count,
      readers_who_spent_time: readers.where('time_on_page > ?', 30).count,
      readers_with_exit_intent: readers.where(exit_intent: true).count,
      
      # Demographics (focus on actual readers)
      readers_by_country: readers.where.not(country_code: nil)
                                .group(:country_code)
                                .count(:id)
                                .sort_by { |_, count| -count }
                                .first(10)
                                .to_h,
      
      readers_by_device: readers.group(:device).count(:id).sort_by { |_, count| -count }.to_h,
      readers_by_browser: readers.group(:browser).count(:id).sort_by { |_, count| -count }.to_h,
      
      # Traffic sources
      traffic_sources: pageviews.where.not(referrer: [nil, ''])
                                .group(:referrer)
                                .count(:id)
                                .sort_by { |_, count| -count }
                                .first(10)
                                .to_h,
      
      # Time-based analytics
      views_by_hour: pageviews.group("strftime('%H', visited_at)")
                              .count(:id)
                              .transform_keys(&:to_i)
                              .sort.to_h,
      
      views_by_day: pageviews.group("date(visited_at)")
                             .count(:id)
                             .sort_by { |date, _| Date.parse(date) }
                             .to_h,
      
      # Content performance
      reading_time_estimate: estimate_reading_time(post),
      engagement_score: calculate_engagement_score(pageviews),
      
      # Post metadata
      post: {
        id: post.id,
        title: post.title,
        slug: post.slug,
        published_at: post.published_at,
        word_count: post.word_count,
        reading_time: post.reading_time
      }
    }
  end
  
  # Get comprehensive analytics for a specific page
  def self.page_analytics(page_id, period: :month)
    page = Page.find(page_id)
    range = period_range(period)
    pageviews = Pageview.where(visited_at: range, page_id: page_id).non_bot.consented_only
    
    {
      # Basic metrics
      total_views: pageviews.count,
      unique_visitors: pageviews.distinct.count(:session_id),
      returning_visitors: pageviews.where(returning_visitor: true).distinct.count(:session_id),
      
      # Engagement metrics
      avg_reading_time: pageviews.where.not(reading_time: nil).average(:reading_time)&.to_i || 0,
      avg_scroll_depth: pageviews.where.not(scroll_depth: nil).average(:scroll_depth)&.to_i || 0,
      avg_completion_rate: pageviews.where.not(completion_rate: nil).average(:completion_rate)&.to_f || 0.0,
      avg_time_on_page: pageviews.where.not(time_on_page: nil).average(:time_on_page)&.to_i || 0,
      
      # Visitor behavior
      visitors_who_scrolled_to_bottom: pageviews.where(scroll_depth: 100).count,
      visitors_who_spent_time: pageviews.where('time_on_page > ?', 30).count,
      visitors_with_exit_intent: pageviews.where(exit_intent: true).count,
      
      # Demographics
      visitors_by_country: pageviews.where.not(country_code: nil)
                                   .group(:country_code)
                                   .count(:id)
                                   .sort_by { |_, count| -count }
                                   .first(10)
                                   .to_h,
      
      visitors_by_device: pageviews.group(:device).count(:id).sort_by { |_, count| -count }.to_h,
      visitors_by_browser: pageviews.group(:browser).count(:id).sort_by { |_, count| -count }.to_h,
      
      # Traffic sources
      traffic_sources: pageviews.where.not(referrer: [nil, ''])
                                .group(:referrer)
                                .count(:id)
                                .sort_by { |_, count| -count }
                                .first(10)
                                .to_h,
      
      # Time-based analytics
      views_by_hour: pageviews.group("strftime('%H', visited_at)")
                              .count(:id)
                              .transform_keys(&:to_i)
                              .sort.to_h,
      
      views_by_day: pageviews.group("date(visited_at)")
                             .count(:id)
                             .sort_by { |date, _| Date.parse(date) }
                             .to_h,
      
      # Content performance
      engagement_score: calculate_engagement_score(pageviews),
      
      # Page metadata
      page: {
        id: page.id,
        title: page.title,
        slug: page.slug,
        published_at: page.published_at,
        word_count: page.word_count
      }
    }
  end
  
  # Get top performing content
  def self.top_performing_content(period: :month, limit: 10)
    range = period_range(period)
    
    # Top posts
    top_posts = Pageview.where(visited_at: range)
                        .where.not(post_id: nil)
                        .non_bot
                        .consented_only
                        .group(:post_id)
                        .count(:id)
                        .sort_by { |_, count| -count }
                        .first(limit)
                        .map do |post_id, views|
      post = Post.find_by(id: post_id)
      next unless post
      
      post_pageviews = Pageview.where(visited_at: range, post_id: post_id).non_bot.consented_only
      
      {
        id: post.id,
        title: post.title,
        slug: post.slug,
        published_at: post.published_at,
        views: views,
        unique_readers: post_pageviews.distinct.count(:session_id),
        avg_reading_time: post_pageviews.where.not(reading_time: nil).average(:reading_time)&.to_i || 0,
        avg_completion_rate: post_pageviews.where.not(completion_rate: nil).average(:completion_rate)&.to_f || 0.0,
        engagement_score: calculate_engagement_score(post_pageviews),
        url: Rails.application.routes.url_helpers.post_path(post)
      }
    end.compact
    
    # Top pages
    top_pages = Pageview.where(visited_at: range)
                        .where.not(page_id: nil)
                        .non_bot
                        .consented_only
                        .group(:page_id)
                        .count(:id)
                        .sort_by { |_, count| -count }
                        .first(limit)
                        .map do |page_id, views|
      page = Page.find_by(id: page_id)
      next unless page
      
      page_pageviews = Pageview.where(visited_at: range, page_id: page_id).non_bot.consented_only
      
      {
        id: page.id,
        title: page.title,
        slug: page.slug,
        published_at: page.published_at,
        views: views,
        unique_visitors: page_pageviews.distinct.count(:session_id),
        avg_reading_time: page_pageviews.where.not(reading_time: nil).average(:reading_time)&.to_i || 0,
        avg_completion_rate: page_pageviews.where.not(completion_rate: nil).average(:completion_rate)&.to_f || 0.0,
        engagement_score: calculate_engagement_score(page_pageviews),
        url: Rails.application.routes.url_helpers.page_path(page)
      }
    end.compact
    
    {
      top_posts: top_posts,
      top_pages: top_pages,
      period: period,
      generated_at: Time.current
    }
  end
  
  # Get reader engagement insights
  def self.reader_engagement_insights(period: :month)
    range = period_range(period)
    pageviews = Pageview.where(visited_at: range).non_bot.consented_only
    
    {
      # Reading behavior
      avg_reading_time: pageviews.where.not(reading_time: nil).average(:reading_time)&.to_i || 0,
      avg_scroll_depth: pageviews.where.not(scroll_depth: nil).average(:scroll_depth)&.to_i || 0,
      avg_completion_rate: pageviews.where.not(completion_rate: nil).average(:completion_rate)&.to_f || 0.0,
      
      # Reader segments
      quick_readers: pageviews.where('reading_time < ?', 30).count,
      engaged_readers: pageviews.where('reading_time BETWEEN ? AND ?', 30, 300).count,
      deep_readers: pageviews.where('reading_time > ?', 300).count,
      
      # Engagement levels
      low_engagement: pageviews.where('completion_rate < ?', 0.25).count,
      medium_engagement: pageviews.where('completion_rate BETWEEN ? AND ?', 0.25, 0.75).count,
      high_engagement: pageviews.where('completion_rate > ?', 0.75).count,
      
      # Scroll behavior
      readers_who_scrolled_25: pageviews.where('scroll_depth >= ?', 25).count,
      readers_who_scrolled_50: pageviews.where('scroll_depth >= ?', 50).count,
      readers_who_scrolled_75: pageviews.where('scroll_depth >= ?', 75).count,
      readers_who_scrolled_100: pageviews.where('scroll_depth >= ?', 100).count,
      
      # Time patterns
      peak_reading_hours: pageviews.group("strftime('%H', visited_at)")
                                   .count(:id)
                                   .sort_by { |_, count| -count }
                                   .first(5)
                                   .to_h,
      
      # Content preferences
      preferred_content_length: analyze_content_length_preferences(pageviews),
      preferred_device_types: pageviews.group(:device).count(:id).sort_by { |_, count| -count }.to_h
    }
  end
  
  private
  
  def self.period_range(period)
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
  
  def self.estimate_reading_time(content)
    return 0 unless content.respond_to?(:content)
    
    # Estimate reading time based on word count (average 200 words per minute)
    word_count = content.content&.gsub(/<[^>]*>/, '')&.split&.count || 0
    (word_count / 200.0).ceil
  end
  
  def self.calculate_engagement_score(pageviews)
    return 0 if pageviews.empty?
    
    # Calculate engagement score based on multiple factors
    avg_completion = pageviews.where.not(completion_rate: nil).average(:completion_rate) || 0
    avg_scroll_depth = pageviews.where.not(scroll_depth: nil).average(:scroll_depth) || 0
    avg_time_on_page = pageviews.where.not(time_on_page: nil).average(:time_on_page) || 0
    
    # Weighted score: completion rate (40%), scroll depth (30%), time on page (30%)
    engagement_score = (avg_completion * 0.4) + (avg_scroll_depth / 100.0 * 0.3) + (avg_time_on_page / 300.0 * 0.3)
    
    # Normalize to 0-100 scale
    (engagement_score * 100).round(1)
  end
  
  def self.analyze_content_length_preferences(pageviews)
    # Analyze what content lengths perform best
    content_performance = {}
    
    pageviews.includes(:post, :page).each do |pageview|
      content = pageview.post || pageview.page
      next unless content
      
      word_count = content.content&.gsub(/<[^>]*>/, '')&.split&.count || 0
      length_category = case word_count
                       when 0..500 then 'short'
                       when 501..1500 then 'medium'
                       when 1501..3000 then 'long'
                       else 'very_long'
                       end
      
      content_performance[length_category] ||= { views: 0, engagement: 0 }
      content_performance[length_category][:views] += 1
      content_performance[length_category][:engagement] += pageview.completion_rate || 0
    end
    
    # Calculate average engagement per category
    content_performance.transform_values do |data|
      {
        views: data[:views],
        avg_engagement: data[:engagement] / data[:views].to_f
      }
    end
  end
end
