class AnalyticsRetentionJob < ApplicationJob
  queue_as :low_priority
  
  def perform
    # Run analytics data retention cleanup
    AnalyticsRetentionService.cleanup_old_data
    
    # Schedule next cleanup (weekly)
    AnalyticsRetentionJob.set(wait: 1.week).perform_later
  rescue => e
    Rails.logger.error "Analytics retention job failed: #{e.message}"
  end
end
