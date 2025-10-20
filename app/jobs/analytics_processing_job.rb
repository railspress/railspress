class AnalyticsProcessingJob < ApplicationJob
  queue_as :analytics
  
  def perform(pageview_data)
    # Process pageview data in background for better performance
    begin
      # Batch process multiple pageviews if data is an array
      if pageview_data.is_a?(Array)
        process_batch(pageview_data)
      else
        process_single(pageview_data)
      end
    rescue => e
      Rails.logger.error "Analytics processing failed: #{e.message}"
      # Don't retry to avoid infinite loops
    end
  end
  
  private
  
  def process_single(data)
    # Create pageview with error handling
    Pageview.create!(data)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Invalid pageview data: #{e.message}"
  end
  
  def process_batch(pageview_data_array)
    # Batch insert for better performance
    Pageview.insert_all(pageview_data_array, on_duplicate: :ignore)
  rescue => e
    Rails.logger.error "Batch analytics processing failed: #{e.message}"
  end
end
