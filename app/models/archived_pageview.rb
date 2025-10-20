class ArchivedPageview < ApplicationRecord
  # Archived pageview data for long-term storage
  # This model stores historical analytics data that has been archived
  
  acts_as_tenant(:tenant, optional: true)
  
  belongs_to :tenant, optional: true
  
  # Serialize metadata as JSON
  serialize :metadata, JSON
  
  # Scopes for filtering archived data
  scope :by_date_range, ->(start_date, end_date) { where(visited_at: start_date..end_date) }
  scope :by_country, ->(country_code) { where(country_code: country_code) }
  scope :by_device, ->(device) { where(device: device) }
  scope :by_browser, ->(browser) { where(browser: browser) }
  scope :unique_visitors, -> { where(unique_visitor: true) }
  scope :returning_visitors, -> { where(returning_visitor: true) }
  scope :bots, -> { where(bot: true) }
  scope :consented, -> { where(consented: true) }
  
  # Statistics methods for archived data
  def self.stats_by_date_range(start_date, end_date)
    data = by_date_range(start_date, end_date)
    
    {
      total_pageviews: data.count,
      unique_visitors: data.unique_visitors.count,
      returning_visitors: data.returning_visitors.count,
      bots: data.bots.count,
      consented_views: data.consented.count,
      average_reading_time: data.average(:reading_time),
      average_scroll_depth: data.average(:scroll_depth),
      average_completion_rate: data.average(:completion_rate),
      top_countries: data.group(:country_name).count.sort_by { |_, count| -count }.first(10),
      top_devices: data.group(:device).count.sort_by { |_, count| -count }.first(10),
      top_browsers: data.group(:browser).count.sort_by { |_, count| -count }.first(10),
      top_pages: data.group(:path).count.sort_by { |_, count| -count }.first(20)
    }
  end
  
  def self.export_for_analysis(start_date, end_date)
    by_date_range(start_date, end_date).map do |pv|
      {
        date: pv.visited_at.strftime('%Y-%m-%d'),
        hour: pv.visited_at.hour,
        path: pv.path,
        title: pv.title,
        country: pv.country_name,
        device: pv.device,
        browser: pv.browser,
        unique_visitor: pv.unique_visitor,
        reading_time: pv.reading_time,
        scroll_depth: pv.scroll_depth,
        completion_rate: pv.completion_rate
      }
    end
  end
end
