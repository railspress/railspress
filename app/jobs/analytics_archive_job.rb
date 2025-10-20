class AnalyticsArchiveJob < ApplicationJob
  queue_as :default
  
  def perform
    Rails.logger.info "Starting analytics archive job"
    
    begin
      archived_count = AnalyticsArchiveService.instance.archive_old_data
      
      Rails.logger.info "Analytics archive job completed successfully. Archived #{archived_count} records."
      
      # Schedule next archive job
      AnalyticsArchiveService.instance.schedule_auto_archive
      
    rescue => e
      Rails.logger.error "Analytics archive job failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Retry the job with exponential backoff
      raise e
    end
  end
end
