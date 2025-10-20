class AnalyticsArchiveService
  include Singleton

  def initialize
    @default_retention_days = SiteSetting.get('analytics_data_retention_days', 365).to_i
    @archive_enabled = SiteSetting.get('analytics_archive_enabled', true)
    @export_format = SiteSetting.get('analytics_export_format', 'json') # json, csv, parquet
  end

  # Archive old analytics data
  def archive_old_data
    return unless @archive_enabled
    
    cutoff_date = @default_retention_days.days.ago
    
    Rails.logger.info "Starting analytics data archival for data older than #{cutoff_date}"
    
    archived_count = 0
    
    # Archive old pageviews
    archived_count += archive_pageviews(cutoff_date)
    
    # Archive old analytics events
    archived_count += archive_analytics_events(cutoff_date)
    
    Rails.logger.info "Archived #{archived_count} analytics records"
    
    # Clean up archived data if configured
    if SiteSetting.get('analytics_auto_delete_archived', false)
      cleanup_archived_data
    end
    
    archived_count
  end

  # Export analytics data for specific date range
  def export_data(start_date, end_date, format: @export_format, include_events: true)
    Rails.logger.info "Exporting analytics data from #{start_date} to #{end_date} in #{format} format"
    
    export_data = {
      metadata: {
        export_date: Time.current,
        date_range: { start: start_date, end: end_date },
        format: format,
        version: '1.0'
      },
      pageviews: export_pageviews(start_date, end_date),
      events: include_events ? export_analytics_events(start_date, end_date) : []
    }
    
    case format
    when 'json'
      export_data.to_json
    when 'csv'
      convert_to_csv(export_data)
    when 'parquet'
      convert_to_parquet(export_data)
    else
      export_data.to_json
    end
  end

  # Get archive statistics
  def archive_stats
    {
      total_pageviews: Pageview.count,
      total_events: AnalyticsEvent.count,
      archived_pageviews: ArchivedPageview.count,
      archived_events: ArchivedAnalyticsEvent.count,
      oldest_data: oldest_data_date,
      retention_policy: {
        days: @default_retention_days,
        enabled: @archive_enabled,
        auto_delete: SiteSetting.get('analytics_auto_delete_archived', false)
      }
    }
  end

  # Schedule automatic archiving
  def schedule_auto_archive
    return unless @archive_enabled
    
    frequency = SiteSetting.get('analytics_archive_frequency', 'daily') # daily, weekly, monthly
    
    case frequency
    when 'daily'
      AnalyticsArchiveJob.perform_in(1.day)
    when 'weekly'
      AnalyticsArchiveJob.perform_in(1.week)
    when 'monthly'
      AnalyticsArchiveJob.perform_in(1.month)
    end
  end

  private

  def archive_pageviews(cutoff_date)
    old_pageviews = Pageview.where('visited_at < ?', cutoff_date)
    count = old_pageviews.count
    
    return 0 if count == 0
    
    # Archive in batches to avoid memory issues
    old_pageviews.find_in_batches(batch_size: 1000) do |batch|
      archived_data = batch.map do |pv|
        {
          id: pv.id,
          path: pv.path,
          title: pv.title,
          referrer: pv.referrer,
          user_agent: pv.user_agent,
          browser: pv.browser,
          device: pv.device,
          os: pv.os,
          ip_hash: pv.ip_hash,
          session_id: pv.session_id,
          user_id: pv.user_id,
          post_id: pv.post_id,
          page_id: pv.page_id,
          unique_visitor: pv.unique_visitor,
          returning_visitor: pv.returning_visitor,
          bot: pv.bot,
          consented: pv.consented,
          visited_at: pv.visited_at,
          metadata: pv.metadata,
          tenant_id: pv.tenant_id,
          reading_time: pv.reading_time,
          scroll_depth: pv.scroll_depth,
          completion_rate: pv.completion_rate,
          time_on_page: pv.time_on_page,
          exit_intent: pv.exit_intent,
          country_code: pv.country_code,
          country_name: pv.country_name,
          city: pv.city,
          region: pv.region,
          latitude: pv.latitude,
          longitude: pv.longitude,
          timezone: pv.timezone,
          archived_at: Time.current
        }
      end
      
      ArchivedPageview.insert_all(archived_data)
    end
    
    # Delete original records
    old_pageviews.delete_all
    
    count
  end

  def archive_analytics_events(cutoff_date)
    old_events = AnalyticsEvent.where('created_at < ?', cutoff_date)
    count = old_events.count
    
    return 0 if count == 0
    
    # Archive in batches
    old_events.find_in_batches(batch_size: 1000) do |batch|
      archived_data = batch.map do |event|
        {
          id: event.id,
          event_name: event.event_name,
          properties: event.properties,
          session_id: event.session_id,
          user_id: event.user_id,
          tenant_id: event.tenant_id,
          created_at: event.created_at,
          archived_at: Time.current
        }
      end
      
      ArchivedAnalyticsEvent.insert_all(archived_data)
    end
    
    # Delete original records
    old_events.delete_all
    
    count
  end

  def export_pageviews(start_date, end_date)
    Pageview.where(visited_at: start_date..end_date)
            .includes(:tenant)
            .map do |pv|
      {
        id: pv.id,
        path: pv.path,
        title: pv.title,
        referrer: pv.referrer,
        browser: pv.browser,
        device: pv.device,
        os: pv.os,
        unique_visitor: pv.unique_visitor,
        returning_visitor: pv.returning_visitor,
        bot: pv.bot,
        consented: pv.consented,
        visited_at: pv.visited_at,
        reading_time: pv.reading_time,
        scroll_depth: pv.scroll_depth,
        completion_rate: pv.completion_rate,
        time_on_page: pv.time_on_page,
        country_code: pv.country_code,
        country_name: pv.country_name,
        city: pv.city,
        region: pv.region,
        tenant_name: pv.tenant&.name
      }
    end
  end

  def export_analytics_events(start_date, end_date)
    AnalyticsEvent.where(created_at: start_date..end_date)
                  .includes(:tenant)
                  .map do |event|
      {
        id: event.id,
        event_name: event.event_name,
        properties: event.properties,
        session_id: event.session_id,
        user_id: event.user_id,
        created_at: event.created_at,
        tenant_name: event.tenant&.name
      }
    end
  end

  def convert_to_csv(data)
    require 'csv'
    
    csv_string = CSV.generate do |csv|
      # Header
      csv << ['Type', 'ID', 'Date', 'Path', 'Event', 'Properties', 'Country', 'Device', 'Browser', 'Tenant']
      
      # Pageviews
      data[:pageviews].each do |pv|
        csv << [
          'pageview',
          pv[:id],
          pv[:visited_at],
          pv[:path],
          nil,
          nil,
          pv[:country_name],
          pv[:device],
          pv[:browser],
          pv[:tenant_name]
        ]
      end
      
      # Events
      data[:events].each do |event|
        csv << [
          'event',
          event[:id],
          event[:created_at],
          nil,
          event[:event_name],
          event[:properties].to_json,
          nil,
          nil,
          nil,
          event[:tenant_name]
        ]
      end
    end
    
    csv_string
  end

  def convert_to_parquet(data)
    # For now, return JSON - could implement Parquet export with ruby-parquet gem
    data.to_json
  end

  def cleanup_archived_data_details
    cutoff_date = (@default_retention_days * 2).days.ago # Keep archived data for 2x retention period
    
    ArchivedPageview.where('archived_at < ?', cutoff_date).delete_all
    ArchivedAnalyticsEvent.where('archived_at < ?', cutoff_date).delete_all
  end

  def oldest_data_date
    [
      Pageview.minimum(:visited_at),
      AnalyticsEvent.minimum(:created_at),
      ArchivedPageview.minimum(:visited_at),
      ArchivedAnalyticsEvent.minimum(:created_at)
    ].compact.min
  end
end
