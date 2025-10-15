# frozen_string_literal: true

module AnalyticsHelper
  # Render analytics tracking script
  # Automatically includes GDPR consent management
  #
  # @return [String] Rendered HTML
  def render_analytics_tracker
    return '' if admin_page?
    return '' unless analytics_enabled?
    
    content_tag(:div, '', 
      data: { 
        controller: 'analytics-tracker',
        turbo_permanent: true
      },
      class: 'analytics-tracker'
    )
  end
  
  # Check if analytics is enabled
  def analytics_enabled?
    SiteSetting.get('analytics_enabled', 'true') == 'true'
  rescue
    true
  end
  
  # Check if we're on an admin page
  def admin_page?
    controller_path.start_with?('admin/')
  end
  
  # Format large numbers
  def format_number(num)
    return '0' if num.nil? || num.zero?
    
    if num >= 1_000_000
      "#{(num / 1_000_000.0).round(1)}M"
    elsif num >= 1_000
      "#{(num / 1_000.0).round(1)}K"
    else
      num.to_s
    end
  end
  
  # Format percentage
  def format_percentage(num)
    return '0%' if num.nil?
    "#{num.round(1)}%"
  end
  
  # Get country flag emoji
  def country_flag(country_code)
    return '' unless country_code
    
    # Convert country code to flag emoji
    country_code.upcase.chars.map { |c| (c.ord + 127397).chr(Encoding::UTF_8) }.join
  rescue
    '🌍'
  end
  
  # Get device icon
  def device_icon(device)
    case device&.downcase
    when 'mobile'
      '<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M7 2a2 2 0 00-2 2v12a2 2 0 002 2h6a2 2 0 002-2V4a2 2 0 00-2-2H7zm3 14a1 1 0 100-2 1 1 0 000 2z" clip-rule="evenodd"/></svg>'
    when 'tablet'
      '<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M6 2a2 2 0 00-2 2v12a2 2 0 002 2h8a2 2 0 002-2V4a2 2 0 00-2-2H6zm4 14a1 1 0 100-2 1 1 0 000 2z" clip-rule="evenodd"/></svg>'
    else
      '<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M3 5a2 2 0 012-2h10a2 2 0 012 2v8a2 2 0 01-2 2h-2.22l.123.489.804.804A1 1 0 0113 18H7a1 1 0 01-.707-1.707l.804-.804L7.22 15H5a2 2 0 01-2-2V5zm5.771 7H5V5h10v7H8.771z" clip-rule="evenodd"/></svg>'
    end
  end
  
  # Get browser icon
  def browser_icon(browser)
    icons = {
      'chrome' => '🌐',
      'firefox' => '🦊',
      'safari' => '🧭',
      'edge' => '🔷',
      'opera' => '🅾️'
    }
    
    icons[browser&.downcase] || '🌍'
  end
end








