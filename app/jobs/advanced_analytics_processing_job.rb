# frozen_string_literal: true

class AdvancedAnalyticsProcessingJob < ApplicationJob
  queue_as :analytics
  
  def perform(content_id, content_type, engagement_data)
    return unless content_id.present? && content_type.present?
    
    begin
      # Process advanced analytics
      process_user_behavior_analysis(content_id, content_type, engagement_data)
      process_content_performance_analysis(content_id, content_type, engagement_data)
      process_engagement_patterns(content_id, content_type, engagement_data)
      process_predictive_insights(content_id, content_type, engagement_data)
      
    rescue => e
      Rails.logger.error "Advanced analytics processing failed: #{e.message}"
      raise e
    end
  end
  
  private
  
  def process_user_behavior_analysis(content_id, content_type, engagement_data)
    # Analyze user behavior patterns
    user_id = engagement_data[:user_id]
    return unless user_id.present?
    
    # Update user behavior profile
    behavior_data = {
      content_id: content_id,
      content_type: content_type,
      engagement_level: calculate_engagement_level(engagement_data),
      reading_pattern: analyze_reading_pattern(engagement_data),
      interaction_pattern: analyze_interaction_pattern(engagement_data),
      timestamp: Time.current
    }
    
    # Store behavior analysis
    Rails.cache.write("user_behavior:#{user_id}:latest", behavior_data, expires_in: 1.day)
    
    # Update user cohort if applicable
    update_user_cohort(user_id, behavior_data)
  end
  
  def process_content_performance_analysis(content_id, content_type, engagement_data)
    # Analyze content performance
    performance_data = {
      engagement_score: calculate_content_engagement_score(engagement_data),
      readability_score: calculate_readability_score(engagement_data),
      retention_rate: calculate_retention_rate(content_id, content_type),
      bounce_rate: calculate_bounce_rate(content_id, content_type),
      conversion_potential: calculate_conversion_potential(engagement_data)
    }
    
    # Store performance analysis
    cache_key = "content_performance:#{content_type.downcase}:#{content_id}"
    Rails.cache.write(cache_key, performance_data, expires_in: 1.hour)
  end
  
  def process_engagement_patterns(content_id, content_type, engagement_data)
    # Process engagement patterns for insights
    patterns = {
      time_patterns: analyze_time_patterns(engagement_data),
      device_patterns: analyze_device_patterns(engagement_data),
      geographic_patterns: analyze_geographic_patterns(engagement_data),
      content_patterns: analyze_content_patterns(content_id, content_type)
    }
    
    # Store engagement patterns
    Rails.cache.write("engagement_patterns:#{content_id}", patterns, expires_in: 6.hours)
  end
  
  def process_predictive_insights(content_id, content_type, engagement_data)
    # Generate predictive insights
    insights = {
      content_recommendation_score: calculate_recommendation_score(content_id, content_type),
      viral_potential: calculate_viral_potential(engagement_data),
      engagement_prediction: predict_future_engagement(content_id, content_type),
      user_retention_prediction: predict_user_retention(engagement_data)
    }
    
    # Store predictive insights
    Rails.cache.write("predictive_insights:#{content_id}", insights, expires_in: 1.day)
  end
  
  def calculate_engagement_level(engagement_data)
    score = 0
    
    # Reading time contribution (0-40 points)
    reading_time = engagement_data[:reading_time]&.to_i || 0
    score += [reading_time / 10, 40].min
    
    # Scroll depth contribution (0-30 points)
    scroll_depth = engagement_data[:scroll_depth]&.to_i || 0
    score += (scroll_depth * 0.3).round
    
    # Interaction contribution (0-30 points)
    interactions = engagement_data[:interactions]&.length || 0
    score += [interactions * 5, 30].min
    
    case score
    when 0..30
      'low'
    when 31..60
      'medium'
    else
      'high'
    end
  end
  
  def analyze_reading_pattern(engagement_data)
    reading_time = engagement_data[:reading_time]&.to_i || 0
    scroll_depth = engagement_data[:scroll_depth]&.to_i || 0
    
    if reading_time > 60 && scroll_depth > 80
      'deep_reader'
    elsif reading_time > 30 && scroll_depth > 50
      'engaged_reader'
    elsif reading_time > 10
      'casual_reader'
    else
      'browser'
    end
  end
  
  def analyze_interaction_pattern(engagement_data)
    interactions = engagement_data[:interactions] || []
    
    if interactions.length > 5
      'highly_interactive'
    elsif interactions.length > 2
      'moderately_interactive'
    elsif interactions.length > 0
      'slightly_interactive'
    else
      'passive'
    end
  end
  
  def update_user_cohort(user_id, behavior_data)
    # Update user cohort based on behavior
    cohort_type = determine_user_cohort(behavior_data)
    
    if cohort_type
      AdvancedAnalyticsService.track_user_cohort(user_id, cohort_type, behavior_data)
    end
  end
  
  def determine_user_cohort(behavior_data)
    engagement_level = behavior_data[:engagement_level]
    reading_pattern = behavior_data[:reading_pattern]
    
    case [engagement_level, reading_pattern]
    when ['high', 'deep_reader']
      'power_readers'
    when ['medium', 'engaged_reader']
      'engaged_readers'
    when ['low', 'casual_reader']
      'casual_readers'
    else
      'browsers'
    end
  end
  
  def calculate_content_engagement_score(engagement_data)
    # Calculate overall engagement score (0-100)
    score = 0
    
    # Reading time component (40%)
    reading_time = engagement_data[:reading_time]&.to_i || 0
    score += (reading_time / 2) * 0.4
    
    # Scroll depth component (30%)
    scroll_depth = engagement_data[:scroll_depth]&.to_i || 0
    score += scroll_depth * 0.3
    
    # Interaction component (30%)
    interactions = engagement_data[:interactions]&.length || 0
    score += [interactions * 10, 30].min * 0.3
    
    [score, 100].min.round(2)
  end
  
  def calculate_readability_score(engagement_data)
    # Calculate readability based on engagement metrics
    reading_time = engagement_data[:reading_time]&.to_i || 0
    scroll_depth = engagement_data[:scroll_depth]&.to_i || 0
    
    # Simple readability score based on engagement
    if reading_time > 60 && scroll_depth > 80
      90 # Very readable
    elsif reading_time > 30 && scroll_depth > 50
      70 # Readable
    elsif reading_time > 10 && scroll_depth > 20
      50 # Somewhat readable
    else
      30 # Difficult to read
    end
  end
  
  def calculate_retention_rate(content_id, content_type)
    # Calculate retention rate for content
    total_views = Pageview.where(path: get_content_path(content_id, content_type)).count
    return 0 if total_views.zero?
    
    retained_views = Pageview.where(
      path: get_content_path(content_id, content_type),
      time_on_page: 30..Float::INFINITY
    ).count
    
    (retained_views.to_f / total_views * 100).round(2)
  end
  
  def calculate_bounce_rate(content_id, content_type)
    # Calculate bounce rate for content
    content_path = get_content_path(content_id, content_type)
    total_sessions = Pageview.where(path: content_path).distinct.count(:session_id)
    return 0 if total_sessions.zero?
    
    single_page_sessions = Pageview.where(path: content_path)
                                   .group(:session_id)
                                   .having('COUNT(*) = 1')
                                   .count
    
    (single_page_sessions.to_f / total_sessions * 100).round(2)
  end
  
  def calculate_conversion_potential(engagement_data)
    # Calculate conversion potential based on engagement
    score = calculate_content_engagement_score(engagement_data)
    
    case score
    when 80..100
      'high'
    when 60..79
      'medium'
    when 40..59
      'low'
    else
      'very_low'
    end
  end
  
  def analyze_time_patterns(engagement_data)
    # Analyze time-based patterns
    timestamp = engagement_data[:timestamp] || Time.current
    
    {
      hour: timestamp.hour,
      day_of_week: timestamp.wday,
      is_weekend: timestamp.wday.in?([0, 6]),
      is_business_hours: timestamp.hour.between?(9, 17)
    }
  end
  
  def analyze_device_patterns(engagement_data)
    # Analyze device patterns
    user_agent = engagement_data[:user_agent] || ''
    
    {
      device_type: detect_device_type(user_agent),
      browser: detect_browser(user_agent),
      os: detect_operating_system(user_agent)
    }
  end
  
  def analyze_geographic_patterns(engagement_data)
    # Analyze geographic patterns
    {
      country: engagement_data[:country_code],
      region: engagement_data[:region],
      city: engagement_data[:city]
    }
  end
  
  def analyze_content_patterns(content_id, content_type)
    # Analyze content-specific patterns
    content = content_type.constantize.find_by(id: content_id)
    return {} unless content
    
    {
      content_length: content.content&.length || 0,
      has_images: content.content&.include?('<img') || false,
      has_videos: content.content&.include?('<video') || false,
      category: content.respond_to?(:category) ? content.category&.name : nil,
      tags: content.respond_to?(:tags) ? content.tags.pluck(:name) : []
    }
  end
  
  def calculate_recommendation_score(content_id, content_type)
    # Calculate content recommendation score
    performance_data = Rails.cache.read("content_performance:#{content_type.downcase}:#{content_id}")
    return 0 unless performance_data
    
    engagement_score = performance_data[:engagement_score] || 0
    retention_rate = performance_data[:retention_rate] || 0
    
    (engagement_score + retention_rate) / 2
  end
  
  def calculate_viral_potential(engagement_data)
    # Calculate viral potential based on engagement
    score = calculate_content_engagement_score(engagement_data)
    
    case score
    when 90..100
      'high'
    when 70..89
      'medium'
    when 50..69
      'low'
    else
      'very_low'
    end
  end
  
  def predict_future_engagement(content_id, content_type)
    # Predict future engagement based on current patterns
    current_performance = Rails.cache.read("content_performance:#{content_type.downcase}:#{content_id}")
    return 'unknown' unless current_performance
    
    engagement_score = current_performance[:engagement_score] || 0
    
    case engagement_score
    when 80..100
      'increasing'
    when 60..79
      'stable'
    when 40..59
      'decreasing'
    else
      'declining'
    end
  end
  
  def predict_user_retention(engagement_data)
    # Predict user retention based on engagement
    engagement_level = calculate_engagement_level(engagement_data)
    reading_pattern = analyze_reading_pattern(engagement_data)
    
    case [engagement_level, reading_pattern]
    when ['high', 'deep_reader']
      'high'
    when ['medium', 'engaged_reader']
      'medium'
    when ['low', 'casual_reader']
      'low'
    else
      'very_low'
    end
  end
  
  def get_content_path(content_id, content_type)
    # Get the path for content
    case content_type
    when 'Post'
      post = Post.find_by(id: content_id)
      post ? "/posts/#{post.slug}" : nil
    when 'Page'
      page = Page.find_by(id: content_id)
      page ? "/pages/#{page.slug}" : nil
    else
      nil
    end
  end
  
  def detect_device_type(user_agent)
    user_agent = user_agent.downcase
    
    if user_agent.include?('mobile') || user_agent.include?('android') || user_agent.include?('iphone')
      'mobile'
    elsif user_agent.include?('tablet') || user_agent.include?('ipad')
      'tablet'
    else
      'desktop'
    end
  end
  
  def detect_browser(user_agent)
    user_agent = user_agent.downcase
    
    if user_agent.include?('chrome')
      'Chrome'
    elsif user_agent.include?('firefox')
      'Firefox'
    elsif user_agent.include?('safari')
      'Safari'
    elsif user_agent.include?('edge')
      'Edge'
    else
      'Other'
    end
  end
  
  def detect_operating_system(user_agent)
    user_agent = user_agent.downcase
    
    if user_agent.include?('windows')
      'Windows'
    elsif user_agent.include?('mac')
      'macOS'
    elsif user_agent.include?('linux')
      'Linux'
    elsif user_agent.include?('android')
      'Android'
    elsif user_agent.include?('ios')
      'iOS'
    else
      'Other'
    end
  end
end
