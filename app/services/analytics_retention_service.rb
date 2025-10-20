class AnalyticsRetentionService
  # Clean up old analytics data to prevent database bloat
  def self.cleanup_old_data
    retention_days = SiteSetting.get('analytics_data_retention_days', 365)
    cutoff_date = retention_days.days.ago
    
    # Archive old pageviews before deletion
    archive_old_pageviews(cutoff_date)
    
    # Delete old analytics events
    old_events_count = AnalyticsEvent.where('created_at < ?', cutoff_date).count
    AnalyticsEvent.where('created_at < ?', cutoff_date).delete_all
    
    # Delete old pageviews (keep only essential data)
    old_pageviews_count = Pageview.where('visited_at < ?', cutoff_date).count
    Pageview.where('visited_at < ?', cutoff_date).delete_all
    
    Rails.logger.info "Analytics cleanup completed: #{old_pageviews_count} pageviews and #{old_events_count} events removed"
    
    { 
      pageviews_deleted: old_pageviews_count,
      events_deleted: old_events_count,
      cutoff_date: cutoff_date
    }
  end
  
  # Archive old pageviews to compressed files
  def self.archive_old_pageviews(cutoff_date)
    return unless SiteSetting.get('analytics_archive_enabled', true)
    
    # Create archive directory
    archive_dir = Rails.root.join('storage', 'analytics_archive')
    FileUtils.mkdir_p(archive_dir)
    
    # Get old pageviews in batches
    batch_size = 10000
    total_archived = 0
    
    Pageview.where('visited_at < ?', cutoff_date).find_in_batches(batch_size: batch_size) do |batch|
      archive_data = batch.map do |pv|
        {
          path: pv.path,
          title: pv.title,
          visited_at: pv.visited_at,
          session_id: pv.session_id,
          is_reader: pv.is_reader,
          engagement_score: pv.engagement_score,
          reading_time: pv.reading_time,
          country_code: pv.country_code
        }
      end
      
      # Write to compressed archive file
      archive_filename = "pageviews_#{cutoff_date.strftime('%Y%m')}.json.gz"
      archive_path = archive_dir.join(archive_filename)
      
      File.open(archive_path, 'a') do |file|
        file.write(Zlib::Deflate.deflate(JSON.dump(archive_data)))
      end
      
      total_archived += batch.size
    end
    
    Rails.logger.info "Archived #{total_archived} pageviews to #{archive_dir}"
    total_archived
  end
  
  # Get analytics summary for archived data
  def self.archived_summary(year, month)
    archive_dir = Rails.root.join('storage', 'analytics_archive')
    archive_filename = "pageviews_#{year}#{month.to_s.rjust(2, '0')}.json.gz"
    archive_path = archive_dir.join(archive_filename)
    
    return {} unless File.exist?(archive_path)
    
    archived_data = JSON.parse(Zlib::Inflate.inflate(File.read(archive_path)))
    
    {
      total_pageviews: archived_data.size,
      unique_readers: archived_data.count { |pv| pv['is_reader'] },
      avg_engagement: archived_data.sum { |pv| pv['engagement_score'] || 0 } / archived_data.size.to_f,
      top_pages: archived_data.group_by { |pv| pv['path'] }
                             .transform_values(&:size)
                             .sort_by { |_, count| -count }
                             .first(10)
                             .to_h
    }
  end
end
