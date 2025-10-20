# frozen_string_literal: true

class ContentAnalyticsUpdateJob < ApplicationJob
  queue_as :analytics
  
  def perform(content_id, content_type, engagement_data)
    return unless content_id.present? && content_type.present?
    
    begin
      # Update content analytics in the database
      update_content_metrics(content_id, content_type, engagement_data)
      
      # Update real-time analytics cache
      update_realtime_cache(content_id, content_type, engagement_data)
      
      # Trigger advanced analytics processing
      trigger_advanced_processing(content_id, content_type, engagement_data)
      
    rescue => e
      Rails.logger.error "Content analytics update failed: #{e.message}"
      raise e
    end
  end
  
  private
  
  def update_content_metrics(content_id, content_type, engagement_data)
    # Update aggregated metrics for content
    case content_type
    when 'Post'
      update_post_metrics(content_id, engagement_data)
    when 'Page'
      update_page_metrics(content_id, engagement_data)
    end
  end
  
  def update_post_metrics(post_id, engagement_data)
    post = Post.find_by(id: post_id)
    return unless post
    
    # Update post engagement metrics
    post_analytics = ContentAnalyticsService.post_analytics(post_id, period: :month)
    
    # Cache the updated analytics
    Rails.cache.write("post_analytics:#{post_id}:month", post_analytics, expires_in: 1.hour)
  end
  
  def update_page_metrics(page_id, engagement_data)
    page = Page.find_by(id: page_id)
    return unless page
    
    # Update page engagement metrics
    page_analytics = ContentAnalyticsService.page_analytics(page_id, period: :month)
    
    # Cache the updated analytics
    Rails.cache.write("page_analytics:#{page_id}:month", page_analytics, expires_in: 1.hour)
  end
  
  def update_realtime_cache(content_id, content_type, engagement_data)
    # Update real-time engagement cache
    cache_key = "realtime_engagement:#{content_type.downcase}:#{content_id}"
    
    current_data = Rails.cache.read(cache_key) || {}
    updated_data = current_data.merge(engagement_data)
    
    Rails.cache.write(cache_key, updated_data, expires_in: 5.minutes)
  end
  
  def trigger_advanced_processing(content_id, content_type, engagement_data)
    # Trigger advanced analytics processing if engagement is significant
    if significant_engagement?(engagement_data)
      AdvancedAnalyticsProcessingJob.perform_later(content_id, content_type, engagement_data)
    end
  end
  
  def significant_engagement?(engagement_data)
    # Consider engagement significant if:
    # - Reading time > 30 seconds
    # - Scroll depth > 50%
    # - Multiple interactions
    
    reading_time = engagement_data[:reading_time]&.to_i || 0
    scroll_depth = engagement_data[:scroll_depth]&.to_i || 0
    interactions = engagement_data[:interactions]&.length || 0
    
    reading_time > 30 || scroll_depth > 50 || interactions > 3
  end
end
