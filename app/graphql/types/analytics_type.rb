# frozen_string_literal: true

module Types
  class AnalyticsType < Types::BaseObject
    description "Analytics data for posts and pages"
    
    field :total_views, Integer, null: false, description: "Total number of page views"
    field :unique_readers, Integer, null: false, description: "Number of unique readers"
    field :medium_readers, Integer, null: false, description: "Number of Medium-like readers (30+ seconds)"
    field :reader_conversion_rate, Float, null: false, description: "Percentage of visitors who become readers"
    field :returning_readers, Integer, null: false, description: "Number of returning readers"
    field :avg_reading_time, Integer, null: false, description: "Average reading time in seconds"
    field :avg_engagement_score, Float, null: false, description: "Average engagement score (0-100)"
    field :avg_scroll_depth, Integer, null: false, description: "Average scroll depth percentage"
    field :avg_completion_rate, Float, null: false, description: "Average completion rate percentage"
    field :avg_time_on_page, Integer, null: false, description: "Average time on page in seconds"
    field :readers_who_scrolled_to_bottom, Integer, null: false, description: "Readers who scrolled to bottom"
    field :readers_who_spent_time, Integer, null: false, description: "Readers who spent significant time"
    field :readers_with_exit_intent, Integer, null: false, description: "Readers who showed exit intent"
    field :readers_by_country, [Types::CountryAnalyticsType], null: false, description: "Reader demographics by country"
    field :readers_by_device, [Types::DeviceAnalyticsType], null: false, description: "Reader demographics by device"
    field :readers_by_browser, [Types::BrowserAnalyticsType], null: false, description: "Reader demographics by browser"
    field :traffic_sources, [Types::TrafficSourceType], null: false, description: "Traffic sources analysis"
    field :direct_traffic, Integer, null: false, description: "Direct traffic count"
    field :organic_traffic, Integer, null: false, description: "Organic search traffic count"
    field :social_traffic, Integer, null: false, description: "Social media traffic count"
  end
  
  class CountryAnalyticsType < Types::BaseObject
    description "Analytics data by country"
    
    field :country_code, String, null: false, description: "Country code (ISO 3166-1 alpha-2)"
    field :country_name, String, null: false, description: "Full country name"
    field :count, Integer, null: false, description: "Number of readers from this country"
    field :percentage, Float, null: false, description: "Percentage of total readers"
  end
  
  class DeviceAnalyticsType < Types::BaseObject
    description "Analytics data by device type"
    
    field :device, String, null: false, description: "Device type"
    field :count, Integer, null: false, description: "Number of readers using this device"
    field :percentage, Float, null: false, description: "Percentage of total readers"
  end
  
  class BrowserAnalyticsType < Types::BaseObject
    description "Analytics data by browser"
    
    field :browser, String, null: false, description: "Browser name"
    field :count, Integer, null: false, description: "Number of readers using this browser"
    field :percentage, Float, null: false, description: "Percentage of total readers"
  end
  
  class TrafficSourceType < Types::BaseObject
    description "Traffic source information"
    
    field :referrer, String, null: false, description: "Referrer URL or source name"
    field :count, Integer, null: false, description: "Number of visits from this source"
    field :percentage, Float, null: false, description: "Percentage of total traffic"
  end
  
  class RealtimeAnalyticsType < Types::BaseObject
    description "Real-time analytics data"
    
    field :active_users, Integer, null: false, description: "Currently active users"
    field :current_pageviews, Integer, null: false, description: "Current pageviews count"
    field :top_pages_now, [Types::PageAnalyticsType], null: false, description: "Top pages being viewed now"
    field :active_countries, [Types::CountryAnalyticsType], null: false, description: "Active countries"
    field :timestamp, GraphQL::Types::ISO8601DateTime, null: false, description: "Data timestamp"
  end
  
  class PageAnalyticsType < Types::BaseObject
    description "Page analytics summary"
    
    field :path, String, null: false, description: "Page path"
    field :title, String, null: true, description: "Page title"
    field :views, Integer, null: false, description: "Number of views"
  end
  
  class AnalyticsOverviewType < Types::BaseObject
    description "Complete analytics overview"
    
    field :total_pageviews, Integer, null: false, description: "Total pageviews for period"
    field :unique_visitors, Integer, null: false, description: "Unique visitors for period"
    field :top_posts, [Types::ContentAnalyticsType], null: false, description: "Top performing posts"
    field :top_pages, [Types::ContentAnalyticsType], null: false, description: "Top performing pages"
    field :traffic_sources, [Types::TrafficSourceType], null: false, description: "Traffic sources"
    field :audience_insights, Types::AudienceInsightsType, null: false, description: "Audience insights"
    field :period, String, null: false, description: "Analytics period"
    field :generated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "Data generation timestamp"
  end
  
  class ContentAnalyticsType < Types::BaseObject
    description "Content analytics summary"
    
    field :id, ID, null: false, description: "Content ID"
    field :title, String, null: false, description: "Content title"
    field :slug, String, null: false, description: "Content slug"
    field :views, Integer, null: false, description: "Number of views"
    field :unique_readers, Integer, null: false, description: "Number of unique readers"
    field :medium_readers, Integer, null: false, description: "Number of Medium-like readers"
    field :avg_engagement_score, Float, null: false, description: "Average engagement score"
    field :avg_reading_time, Integer, null: false, description: "Average reading time"
    field :published_at, GraphQL::Types::ISO8601DateTime, null: true, description: "Publication date"
  end
  
  class AudienceInsightsType < Types::BaseObject
    description "Audience insights data"
    
    field :top_countries, [Types::CountryAnalyticsType], null: false, description: "Top countries by traffic"
    field :browsers, [Types::BrowserAnalyticsType], null: false, description: "Browser distribution"
    field :devices, [Types::DeviceAnalyticsType], null: false, description: "Device distribution"
    field :operating_systems, [Types::OperatingSystemAnalyticsType], null: false, description: "OS distribution"
    field :avg_session_duration, Integer, null: false, description: "Average session duration in seconds"
    field :bounce_rate, Float, null: false, description: "Bounce rate percentage"
    field :pages_per_session, Float, null: false, description: "Average pages per session"
  end
  
  class OperatingSystemAnalyticsType < Types::BaseObject
    description "Analytics data by operating system"
    
    field :os, String, null: false, description: "Operating system name"
    field :count, Integer, null: false, description: "Number of readers using this OS"
    field :percentage, Float, null: false, description: "Percentage of total readers"
  end
end
