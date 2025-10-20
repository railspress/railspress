# Advanced Analytics Service - GA4-like features with GDPR compliance
class AnalyticsService
  include AnalyticsHelper
  
  # Real-time analytics
  def self.realtime_stats
    {
      active_users: Pageview.where('visited_at >= ?', 5.minutes.ago).non_bot.distinct.count(:session_id),
      current_pageviews: Pageview.where('visited_at >= ?', 1.minute.ago).count,
      top_pages_now: Pageview.where('visited_at >= ?', 5.minutes.ago)
                              .non_bot
                              .group(:path)
                              .count(:id)
                              .sort_by { |_, count| -count }
                              .first(5)
                              .to_h,
      active_countries: Pageview.where('visited_at >= ?', 5.minutes.ago)
                                 .non_bot
                                 .where.not(country_code: nil)
                                 .group(:country_code)
                                 .count(:id)
                                 .sort_by { |_, count| -count }
                                 .first(3)
                                 .to_h
    }
  end
  
  # Advanced audience insights
  def self.audience_insights(period: :month)
    range = period_range(period)
    pageviews = Pageview.where(visited_at: range).non_bot.consented_only
    
    {
      # Demographics
      top_countries: pageviews.where.not(country_code: nil)
                              .group(:country_code)
                              .count(:id)
                              .sort_by { |_, count| -count }
                              .first(10)
                              .to_h,
      
      # Technology
      browsers: pageviews.group(:browser).count(:id).sort_by { |_, count| -count }.to_h,
      devices: pageviews.group(:device).count(:id).sort_by { |_, count| -count }.to_h,
      operating_systems: pageviews.group(:os).count(:id).sort_by { |_, count| -count }.to_h,
      
      # Behavior
      avg_session_duration: pageviews.average(:duration)&.to_i || 0,
      bounce_rate: calculate_bounce_rate(pageviews),
      pages_per_session: calculate_pages_per_session(pageviews),
      
      # Acquisition
      traffic_sources: pageviews.where.not(referrer: [nil, ''])
                                .group(:referrer)
                                .count(:id)
                                .sort_by { |_, count| -count }
                                .first(10)
                                .to_h,
      
      # Engagement
      engagement_rate: calculate_engagement_rate(pageviews),
      return_visitors: pageviews.where(returning_visitor: true).count,
      new_visitors: pageviews.where(unique_visitor: true).count
    }
  end
  
  # Content performance
  def self.content_performance(period: :month)
    range = period_range(period)
    pageviews = Pageview.where(visited_at: range).non_bot.consented_only
    
    {
      top_posts: pageviews.where.not(post_id: nil)
                          .group(:post_id)
                          .count(:id)
                          .sort_by { |_, count| -count }
                          .first(10)
                          .map do |post_id, count|
        post = Post.find_by(id: post_id)
        {
          post: post,
          views: count,
          unique_views: pageviews.where(post_id: post_id, unique_visitor: true).count,
          avg_duration: pageviews.where(post_id: post_id).average(:duration)&.to_i || 0
        }
      end,
      
      top_pages: pageviews.where.not(page_id: nil)
                          .group(:page_id)
                          .count(:id)
                          .sort_by { |_, count| -count }
                          .first(10)
                          .map do |page_id, count|
        page_obj = Page.find_by(id: page_id)
        {
          page: page_obj,
          views: count,
          unique_views: pageviews.where(page_id: page_id, unique_visitor: true).count,
          avg_duration: pageviews.where(page_id: page_id).average(:duration)&.to_i || 0
        }
      end,
      
      top_paths: pageviews.group(:path)
                          .count(:id)
                          .sort_by { |_, count| -count }
                          .first(10)
                          .to_h
    }
  end
  
  # Conversion tracking (custom events)
  def self.track_event(event_name, properties = {})
    # Create a custom event record
    AnalyticsEvent.create!(
      event_name: event_name,
      properties: properties,
      session_id: properties[:session_id] || generate_session_id,
      user_id: properties[:user_id],
      path: properties[:path] || '/',
      tenant: properties[:tenant] || ActsAsTenant.current_tenant || Tenant.first
    )
  rescue => e
    Rails.logger.error "Failed to track event: #{e.message}"
    nil
  end
  
  # Advanced metrics methods
  def self.total_pageviews(period: :month)
    range = period_range(period)
    Pageview.where(visited_at: range).non_bot.consented_only.count
  end
  
  def self.unique_visitors(period: :month)
    range = period_range(period)
    Pageview.where(visited_at: range).non_bot.consented_only.distinct.count(:session_id)
  end
  
  def self.avg_session_duration(period: :month)
    range = period_range(period)
    avg_duration = Pageview.where(visited_at: range)
                          .non_bot
                          .consented_only
                          .average(:duration)
    avg_duration ? avg_duration.to_i : 0
  end
  
  def self.bounce_rate(period: :month)
    range = period_range(period)
    pageviews = Pageview.where(visited_at: range).non_bot.consented_only
    calculate_bounce_rate(pageviews)
  end
  
  def self.pages_per_session(period: :month)
    range = period_range(period)
    pageviews = Pageview.where(visited_at: range).non_bot.consented_only
    calculate_pages_per_session(pageviews)
  end
  
  def self.traffic_sources(period: :month)
    range = period_range(period)
    pageviews = Pageview.where(visited_at: range).non_bot.consented_only
    
    # Group by referrer and count
    referrers = pageviews.where.not(referrer: [nil, ''])
                        .group(:referrer)
                        .count(:id)
                        .sort_by { |_, count| -count }
                        .first(10)
    
    # Categorize traffic sources
    categorized_sources = {
      'Direct' => pageviews.where(referrer: [nil, '']).count,
      'Search' => 0,
      'Social' => 0,
      'Referral' => 0,
      'Email' => 0,
      'Other' => 0
    }
    
    referrers.each do |referrer, count|
      if referrer.include?('google') || referrer.include?('bing') || referrer.include?('yahoo')
        categorized_sources['Search'] += count
      elsif referrer.include?('facebook') || referrer.include?('twitter') || referrer.include?('linkedin') || referrer.include?('instagram')
        categorized_sources['Social'] += count
      elsif referrer.include?('mail') || referrer.include?('email')
        categorized_sources['Email'] += count
      else
        categorized_sources['Referral'] += count
      end
    end
    
    categorized_sources
  end
  
  private
  
  def self.generate_session_id
    SecureRandom.hex(16)
  end
  
  # Funnel analysis
  def self.funnel_analysis(funnel_steps, period: :month)
    range = period_range(period)
    results = {}
    
    funnel_steps.each_with_index do |step, index|
      if index == 0
        # First step - all visitors
        results[step] = Pageview.where(visited_at: range)
                                .non_bot
                                .consented_only
                                .distinct
                                .count(:session_id)
      else
        # Subsequent steps - visitors who completed previous step
        previous_step_sessions = results[funnel_steps[index - 1]]
        results[step] = Pageview.where(visited_at: range)
                                .non_bot
                                .consented_only
                                .where(session_id: previous_step_sessions)
                                .distinct
                                .count(:session_id)
      end
    end
    
    results
  end
  
  # Cohort analysis
  def self.cohort_analysis(period: :month)
    range = period_range(period)
    
    # Group users by their first visit week
    cohorts = Pageview.where(visited_at: range)
                      .non_bot
                      .consented_only
                      .group("DATE_TRUNC('week', visited_at)")
                      .count(:session_id)
    
    cohorts
  end
  
  # AI-powered automated insights
  def self.generate_insights(period: :month)
    range = period_range(period)
    pageviews = Pageview.where(visited_at: range).non_bot.consented_only
    
    insights = []
    
    # Advanced traffic growth analysis
    current_period_count = pageviews.count
    previous_period_count = Pageview.where(visited_at: previous_period_range(period)).non_bot.consented_only.count
    
    if current_period_count > previous_period_count && previous_period_count > 0
      growth_percentage = ((current_period_count - previous_period_count).to_f / previous_period_count * 100).round(1)
      if growth_percentage > 20
        insights << {
          type: 'growth',
          title: '🚀 Significant Traffic Growth',
          message: "Traffic increased by #{growth_percentage}% compared to the previous period",
          action: "Analyze your top-performing content and marketing channels to replicate this success",
          priority: 'high',
          impact: 'positive'
        }
      elsif growth_percentage > 5
        insights << {
          type: 'growth',
          title: '📈 Steady Growth',
          message: "Traffic increased by #{growth_percentage}% compared to the previous period",
          action: "Continue your current strategy while experimenting with new content formats",
          priority: 'medium',
          impact: 'positive'
        }
      end
    elsif current_period_count < previous_period_count && previous_period_count > 0
      decline_percentage = ((previous_period_count - current_period_count).to_f / previous_period_count * 100).round(1)
      insights << {
        type: 'decline',
        title: '📉 Traffic Decline Detected',
        message: "Traffic decreased by #{decline_percentage}% compared to the previous period",
        action: "Review your content strategy and check for technical issues affecting SEO",
        priority: 'high',
        impact: 'negative'
      }
    end
    
    # Engagement analysis
    avg_engagement = pageviews.where.not(engagement_score: nil).average(:engagement_score) || 0
    readers_count = pageviews.where(is_reader: true).count
    reader_rate = readers_count > 0 ? (readers_count.to_f / pageviews.count * 100).round(1) : 0
    
    if reader_rate > 40
      insights << {
        type: 'engagement',
        title: '⭐ High Reader Engagement',
        message: "#{reader_rate}% of your visitors qualify as readers (30+ seconds)",
        action: "Your content is highly engaging! Consider creating more in-depth content",
        priority: 'high',
        impact: 'positive'
      }
    elsif reader_rate < 20
      insights << {
        type: 'engagement',
        title: '⚠️ Low Reader Engagement',
        message: "Only #{reader_rate}% of visitors are reading your content",
        action: "Improve content quality, add visual elements, and optimize for readability",
        priority: 'high',
        impact: 'negative'
      }
    end
    
    # Content performance insights
    top_posts = pageviews.where.not(post_id: nil)
                        .group(:post_id)
                        .count(:id)
                        .sort_by { |_, count| -count }
                        .first(3)
    
    if top_posts.any?
      top_post = top_posts.first
      post = Post.find_by(id: top_post[0])
      if post
        insights << {
          type: 'content',
          title: '🏆 Top Performing Content',
          message: "#{post.title} is your best performer with #{top_post[1]} views",
          action: "Analyze what makes this content successful and create similar pieces",
          priority: 'medium',
          impact: 'positive'
        }
      end
    end
    
    # Geographic insights
    top_countries = pageviews.where.not(country_code: nil)
                            .group(:country_code)
                            .count(:id)
                            .sort_by { |_, count| -count }
                            .first(3)
    
    if top_countries.any?
      top_country = top_countries.first
      country_percentage = (top_country[1].to_f / pageviews.count * 100).round(1)
      if country_percentage > 40
        insights << {
          type: 'geography',
          title: '🌍 Geographic Concentration',
          message: "#{top_country[0]} represents #{country_percentage}% of your traffic",
          action: "Consider creating localized content or targeting expansion to new markets",
          priority: 'medium',
          impact: 'neutral'
        }
      end
    end
    
    # Device and technology insights
    mobile_count = pageviews.where(device: 'Mobile').count
    mobile_percentage = (mobile_count.to_f / pageviews.count * 100).round(1)
    
    if mobile_percentage > 70
      insights << {
        type: 'device',
        title: '📱 Mobile-First Audience',
        message: "#{mobile_percentage}% of your traffic is from mobile devices",
        action: "Ensure your site is fully optimized for mobile and consider mobile-specific content",
        priority: 'high',
        impact: 'positive'
      }
    elsif mobile_percentage < 30
      insights << {
        type: 'device',
        title: '💻 Desktop-Dominant Traffic',
        message: "Only #{mobile_percentage}% of traffic is mobile",
        action: "Consider mobile optimization to reach a broader audience",
        priority: 'medium',
        impact: 'neutral'
      }
    end
    
    # Traffic source insights
    direct_traffic = pageviews.where(referrer: [nil, '']).count
    direct_percentage = (direct_traffic.to_f / pageviews.count * 100).round(1)
    
    if direct_percentage > 60
      insights << {
        type: 'traffic',
        title: '🎯 Strong Brand Recognition',
        message: "#{direct_percentage}% of your traffic is direct visits",
        action: "Your brand awareness is strong! Consider expanding your content marketing",
        priority: 'high',
        impact: 'positive'
      }
    end
    
    # Performance insights
    slow_pages = pageviews.where('time_on_page < ?', 10).count
    slow_percentage = (slow_pages.to_f / pageviews.count * 100).round(1)
    
    if slow_percentage > 50
      insights << {
        type: 'performance',
        title: '⚡ Page Speed Issues',
        message: "#{slow_percentage}% of visitors spend less than 10 seconds on your pages",
        action: "Optimize page load times and improve content engagement",
        priority: 'high',
        impact: 'negative'
      }
    end
    
    # Conversion insights (if conversions are tracked)
    conversions = AnalyticsEvent.where(created_at: range, event_name: 'conversion').count
    if conversions > 0
      conversion_rate = (conversions.to_f / pageviews.count * 100).round(2)
      insights << {
        type: 'conversion',
        title: '💰 Conversion Performance',
        message: "#{conversions} conversions with a #{conversion_rate}% conversion rate",
        action: "Analyze your conversion funnel and optimize high-performing pages",
        priority: 'high',
        impact: 'positive'
      }
    end
    
    # Sort insights by priority and impact
    insights.sort_by do |insight|
      priority_score = case insight[:priority]
                      when 'high' then 3
                      when 'medium' then 2
                      when 'low' then 1
                      else 0
                      end
      
      impact_score = case insight[:impact]
                    when 'positive' then 1
                    when 'negative' then 2
                    when 'neutral' then 0
                    else 0
                    end
      
      -(priority_score + impact_score)
    end
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
  
  def self.previous_period_range(period)
    case period.to_sym
    when :today
      Time.current.beginning_of_day - 1.day..Time.current.end_of_day - 1.day
    when :week
      2.weeks.ago..1.week.ago
    when :month
      2.months.ago..1.month.ago
    when :year
      2.years.ago..1.year.ago
    else
      2.months.ago..1.month.ago
    end
  end
  
  def self.calculate_bounce_rate(pageviews)
    total_sessions = pageviews.distinct.count(:session_id)
    return 0 if total_sessions.zero?
    
    single_page_sessions = pageviews.group(:session_id)
                                    .having('COUNT(*) = 1')
                                    .count
                                    .size
    
    ((single_page_sessions.to_f / total_sessions) * 100).round(1)
  end
  
  def self.calculate_pages_per_session(pageviews)
    total_sessions = pageviews.distinct.count(:session_id)
    return 0 if total_sessions.zero?
    
    total_pageviews = pageviews.count
    (total_pageviews.to_f / total_sessions).round(2)
  end
  
  def self.calculate_engagement_rate(pageviews)
    total_pageviews = pageviews.count
    return 0 if total_pageviews.zero?
    
    engaged_sessions = pageviews.where('duration > ?', 30).count
    ((engaged_sessions.to_f / total_pageviews) * 100).round(1)
  end
end
