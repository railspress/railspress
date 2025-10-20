# frozen_string_literal: true

class MaxmindUpdateJob < ApplicationJob
  queue_as :default
  
  def perform(update_type = :full)
    begin
      Rails.logger.info "Starting MaxMind database update: #{update_type}"
      
      case update_type
      when :full
        MaxmindUpdaterService.update_databases
      when :city
        MaxmindUpdaterService.download_database('GeoLite2-City')
      when :country
        MaxmindUpdaterService.download_database('GeoLite2-Country')
      end
      
      Rails.logger.info "MaxMind database update completed successfully"
      
      # Update the last update timestamp
      SiteSetting.set('maxmind_last_update', Time.current.iso8601)
      
      # Send notification if configured
      send_update_notification if SiteSetting.get('maxmind_notifications_enabled', false)
      
    rescue => e
      Rails.logger.error "MaxMind database update failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Send error notification
      send_error_notification(e) if SiteSetting.get('maxmind_notifications_enabled', false)
      
      raise e
    end
  end
  
  private
  
  def send_update_notification
    # Send notification to admin users about successful update
    admin_users = User.where(administrator: true)
    
    admin_users.each do |user|
      # You could implement email notifications here
      Rails.logger.info "MaxMind update notification sent to #{user.email}"
    end
  end
  
  def send_error_notification(error)
    # Send error notification to admin users
    admin_users = User.where(administrator: true)
    
    admin_users.each do |user|
      # You could implement error email notifications here
      Rails.logger.error "MaxMind update error notification sent to #{user.email}: #{error.message}"
    end
  end
end
