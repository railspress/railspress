class Pageview < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant)
  
  # Associations
  belongs_to :user, optional: true
  belongs_to :post, optional: true
  belongs_to :page, optional: true
  
  # Serialization
  serialize :metadata, coder: JSON, type: Hash
  
  # Validations
  validates :path, presence: true
  validates :visited_at, presence: true
  
  # Scopes
  scope :consented_only, -> { where(consented: true) }
  scope :non_bot, -> { where(bot: false) }
  scope :unique_visitors, -> { where(unique_visitor: true) }
  scope :returning_visitors, -> { where(returning_visitor: true) }
  scope :today, -> { where('visited_at >= ?', Time.current.beginning_of_day) }
  scope :this_week, -> { where('visited_at >= ?', 1.week.ago) }
  scope :this_month, -> { where('visited_at >= ?', 1.month.ago) }
  scope :by_country, ->(code) { where(country_code: code) }
  scope :by_browser, ->(browser) { where(browser: browser) }
  scope :by_device, ->(device) { where(device: device) }
  scope :for_post, ->(post_id) { where(post_id: post_id) }
  scope :for_page, ->(page_id) { where(page_id: page_id) }
  scope :recent, -> { order(visited_at: :desc) }
  
  # Class methods for statistics
  
  # Get overview statistics
  def self.stats(period: :month)
    range = case period.to_sym
            when :today
              Time.current.beginning_of_day..Time.current.end_of_day
            when :week
              1.week.ago..Time.current
            when :month
              1.month.ago..Time.current
            when :year
              1.year.ago..Time.current
            else
              1.month.ago..Time.current
            end
    
    views = where(visited_at: range).non_bot
    consented_views = views.consented_only
    
    {
      total_pageviews: views.count,
      consented_pageviews: consented_views.count,
      unique_visitors: views.where(unique_visitor: true).count,
      returning_visitors: views.where(returning_visitor: true).count,
      avg_duration: views.average(:duration)&.to_i || 0,
      bounce_rate: calculate_bounce_rate(views),
      top_pages: top_pages(consented_views, 10),
      top_posts: top_posts(consented_views, 10),
      top_countries: top_countries(consented_views, 10),
      top_browsers: top_browsers(consented_views, 5),
      top_devices: top_devices(consented_views, 5),
      top_referrers: top_referrers(consented_views, 10),
      hourly_distribution: hourly_distribution(consented_views),
      daily_trend: daily_trend(consented_views, 30)
    }
  end
  
  # Top pages by views
  def self.top_pages(scope = all, limit = 10)
    scope.group(:path, :title)
         .order('count_id DESC')
         .limit(limit)
         .count(:id)
         .map { |k, v| { path: k[0], title: k[1], views: v } }
  end
  
  # Top posts by views
  def self.top_posts(scope = all, limit = 10)
    scope.where.not(post_id: nil)
         .group(:post_id)
         .order('count_id DESC')
         .limit(limit)
         .count(:id)
         .map do |post_id, count|
      post = Post.find_by(id: post_id)
      { post_id: post_id, title: post&.title, views: count }
    end
  end
  
  # Top countries by visitors
  def self.top_countries(scope = all, limit = 10)
    scope.where.not(country_code: nil)
         .group(:country_code)
         .order('count_id DESC')
         .limit(limit)
         .count(:id)
         .map { |code, count| { country_code: code, count: count } }
  end
  
  # Top browsers
  def self.top_browsers(scope = all, limit = 5)
    scope.where.not(browser: nil)
         .group(:browser)
         .order('count_id DESC')
         .limit(limit)
         .count(:id)
  end
  
  # Top devices
  def self.top_devices(scope = all, limit = 5)
    scope.where.not(device: nil)
         .group(:device)
         .order('count_id DESC')
         .limit(limit)
         .count(:id)
  end
  
  # Top referrers
  def self.top_referrers(scope = all, limit = 10)
    scope.where.not(referrer: [nil, ''])
         .group(:referrer)
         .order('count_id DESC')
         .limit(limit)
         .count(:id)
         .map { |ref, count| { referrer: ref, count: count } }
  end
  
  # Hourly distribution (0-23)
  def self.hourly_distribution(scope = all)
    distribution = scope.group("CAST(strftime('%H', visited_at) AS INTEGER)")
                        .count
    
    (0..23).map { |hour| distribution[hour] || 0 }
  end
  
  # Daily trend (last N days)
  def self.daily_trend(scope = all, days = 30)
    scope.where('visited_at >= ?', days.days.ago)
         .group("DATE(visited_at)")
         .order("DATE(visited_at)")
         .count
         .map { |date, count| { date: date, count: count } }
  end
  
  # Calculate bounce rate (single-page sessions)
  def self.calculate_bounce_rate(scope = all)
    total_sessions = scope.distinct.count(:session_id)
    return 0 if total_sessions.zero?
    
    single_page_sessions = scope.group(:session_id)
                                .having('COUNT(*) = 1')
                                .count
                                .size
    
    ((single_page_sessions.to_f / total_sessions) * 100).round(1)
  end
  
  # Get real-time active users (last 5 minutes)
  def self.active_now
    where('visited_at >= ?', 5.minutes.ago)
      .non_bot
      .distinct
      .count(:session_id)
  end
  
  # Track a pageview (called from middleware)
  def self.track(request, options = {})
    # Skip if bot and not tracking bots
    return if is_bot?(request.user_agent) && !options[:track_bots]
    
    # Parse user agent
    ua_data = parse_user_agent(request.user_agent)
    
    # Get or create session
    session_id = options[:session_id] || generate_session_id(request)
    
    # Check if unique visitor
    is_unique = !exists?(session_id: session_id)
    is_returning = exists?(ip_hash: hash_ip(request.ip)) && !is_unique
    
    # Get content IDs
    content_ids = extract_content_ids(request.path)
    
    # Create pageview
    create!(
      path: request.path,
      title: options[:title],
      referrer: request.referer,
      user_agent: request.user_agent,
      browser: ua_data[:browser],
      device: ua_data[:device],
      os: ua_data[:os],
      ip_hash: hash_ip(request.ip),
      session_id: session_id,
      user_id: options[:user_id],
      post_id: content_ids[:post_id],
      page_id: content_ids[:page_id],
      unique_visitor: is_unique,
      returning_visitor: is_returning,
      bot: is_bot?(request.user_agent),
      consented: options[:consented] || false,
      visited_at: Time.current,
      metadata: options[:metadata] || {}
    )
  rescue => e
    Rails.logger.error "Failed to track pageview: #{e.message}"
    nil
  end
  
  # GDPR: Anonymize old data
  def self.anonymize_old_data(days_old = 90)
    where('created_at < ?', days_old.days.ago).update_all(
      ip_hash: nil,
      session_id: nil,
      city: nil,
      region: nil,
      metadata: {}
    )
  end
  
  # GDPR: Delete non-consented data
  def self.purge_non_consented(days_old = 30)
    where(consented: false)
      .where('created_at < ?', days_old.days.ago)
      .delete_all
  end
  
  private
  
  # Hash IP address for privacy
  def self.hash_ip(ip)
    return nil unless ip
    Digest::SHA256.hexdigest("#{ip}-#{Rails.application.secret_key_base}")[0..15]
  end
  
  # Generate session ID
  def self.generate_session_id(request)
    data = "#{request.ip}-#{request.user_agent}-#{Date.today}"
    Digest::SHA256.hexdigest(data)[0..31]
  end
  
  # Check if bot
  def self.is_bot?(user_agent)
    return true if user_agent.blank?
    
    bot_patterns = [
      /bot/i, /crawl/i, /spider/i, /slurp/i,
      /googlebot/i, /bingbot/i, /yandex/i,
      /facebookexternalhit/i, /twitterbot/i,
      /whatsapp/i, /telegram/i
    ]
    
    bot_patterns.any? { |pattern| user_agent.match?(pattern) }
  end
  
  # Parse user agent
  def self.parse_user_agent(ua)
    return { browser: 'Unknown', device: 'Unknown', os: 'Unknown' } if ua.blank?
    
    # Simple parsing (you can use a gem like browser for more accurate parsing)
    browser = case ua
              when /Chrome/i then 'Chrome'
              when /Firefox/i then 'Firefox'
              when /Safari/i then 'Safari'
              when /Edge/i then 'Edge'
              when /Opera/i then 'Opera'
              else 'Other'
              end
    
    device = case ua
             when /Mobile|Android|iPhone|iPad/i then 'Mobile'
             when /Tablet/i then 'Tablet'
             else 'Desktop'
             end
    
    os = case ua
         when /Windows/i then 'Windows'
         when /Mac OS X/i then 'macOS'
         when /Linux/i then 'Linux'
         when /Android/i then 'Android'
         when /iOS|iPhone|iPad/i then 'iOS'
         else 'Other'
         end
    
    { browser: browser, device: device, os: os }
  end
  
  # Extract post/page IDs from path
  def self.extract_content_ids(path)
    ids = { post_id: nil, page_id: nil }
    
    # Try to match blog post pattern
    if path.match?(/\/blog\/(.+)/)
      slug = path.split('/').last
      post = Post.find_by(slug: slug)
      ids[:post_id] = post&.id
    end
    
    # Try to match page pattern
    unless ids[:post_id]
      slug = path.split('/').reject(&:blank?).last
      page_obj = Page.find_by(slug: slug) if slug
      ids[:page_id] = page_obj&.id
    end
    
    ids
  end
end
