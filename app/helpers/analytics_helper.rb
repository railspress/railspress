# frozen_string_literal: true

module AnalyticsHelper
  # Render analytics tracking script with comprehensive GDPR compliance
  # Automatically includes GDPR consent management, privacy controls, and data subject rights
  #
  # @return [String] Rendered HTML
  def render_analytics_tracker
    return '' if admin_page?
    return '' unless analytics_enabled?
    
    # Base analytics tracker
    tracker = content_tag(:div, '', 
      data: { 
        controller: 'ga4-analytics',
        'ga4-analytics-consent-required-value': analytics_require_consent?,
        'ga4-analytics-anonymize-ip-value': analytics_anonymize_ip?,
        'ga4-analytics-debug-value': Rails.env.development?,
        'ga4-analytics-gdpr-enabled-value': gdpr_compliance_enabled?,
        'ga4-analytics-data-retention-days-value': analytics_data_retention_days,
        turbo_permanent: true
      },
      class: 'analytics-tracker'
    )
    
    # GDPR consent banner (if consent required)
    consent_banner = ''
    if analytics_require_consent?
      consent_banner = content_tag(:div, '', 
        data: { 'ga4-analytics-target': 'consentBanner' },
        class: 'fixed bottom-4 right-4 bg-indigo-600 text-white p-4 rounded-lg shadow-lg max-w-md hidden z-50'
      ) do
        content_tag(:div, class: 'flex items-start space-x-3') do
          content_tag(:div, class: 'flex-shrink-0') do
            content_tag(:svg, class: 'w-6 h-6', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24') do
              content_tag(:path, '', stroke_linecap: 'round', stroke_linejoin: 'round', stroke_width: '2', d: 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z')
            end
          end +
          content_tag(:div, class: 'flex-1') do
            content_tag(:h3, 'Privacy & Analytics', class: 'text-sm font-medium mb-2') +
            content_tag(:p, analytics_consent_message, class: 'text-xs text-indigo-100 mb-3') +
            content_tag(:div, class: 'flex flex-col space-y-2') do
              content_tag(:div, class: 'flex space-x-2') do
                content_tag(:button, 'Accept All', 
                  data: { action: 'click->ga4-analytics#acceptAllConsent' },
                  class: 'bg-white text-indigo-600 px-3 py-1 rounded text-xs font-medium hover:bg-indigo-50 transition'
                ) +
                content_tag(:button, 'Reject All', 
                  data: { action: 'click->ga4-analytics#rejectAllConsent' },
                  class: 'bg-indigo-500 text-white px-3 py-1 rounded text-xs font-medium hover:bg-indigo-400 transition'
                )
              end +
              content_tag(:button, 'Manage Preferences', 
                data: { action: 'click->ga4-analytics#showConsentPreferences' },
                class: 'text-xs text-indigo-200 underline hover:text-white transition'
              )
            end
          end
        end
      end
    end
    
    # Privacy controls panel (hidden by default)
    privacy_controls = content_tag(:div, '', 
      data: { 'ga4-analytics-target': 'privacyControls' },
      class: 'fixed inset-0 bg-black bg-opacity-50 hidden z-50'
    ) do
      content_tag(:div, class: 'flex items-center justify-center min-h-screen p-4') do
        content_tag(:div, class: 'bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-screen overflow-y-auto') do
          content_tag(:div, class: 'p-6') do
            content_tag(:div, class: 'flex items-center justify-between mb-6') do
              content_tag(:h2, 'Privacy Preferences', class: 'text-xl font-semibold text-gray-900') +
              content_tag(:button, '×', 
                data: { action: 'click->ga4-analytics#hideConsentPreferences' },
                class: 'text-gray-400 hover:text-gray-600 text-2xl font-bold'
              )
            end +
            content_tag(:div, class: 'space-y-6') do
              # Essential cookies (always required)
              content_tag(:div) do
                content_tag(:h3, 'Essential Cookies', class: 'text-lg font-medium text-gray-900 mb-2') +
                content_tag(:p, 'These cookies are necessary for the website to function and cannot be switched off.', class: 'text-sm text-gray-600 mb-4') +
                content_tag(:div, class: 'flex items-center justify-between') do
                  content_tag(:span, 'Always Active', class: 'text-sm font-medium text-green-600') +
                  content_tag(:div, class: 'w-12 h-6 bg-green-500 rounded-full flex items-center justify-end px-1') do
                    content_tag(:div, '', class: 'w-4 h-4 bg-white rounded-full')
                  end
                end
              end +
              
              # Analytics cookies
              content_tag(:div) do
                content_tag(:h3, 'Analytics Cookies', class: 'text-lg font-medium text-gray-900 mb-2') +
                content_tag(:p, 'These cookies help us understand how visitors interact with our website by collecting and reporting information anonymously.', class: 'text-sm text-gray-600 mb-4') +
                content_tag(:div, class: 'flex items-center justify-between') do
                  content_tag(:span, 'Analytics Tracking', class: 'text-sm font-medium text-gray-700') +
                  content_tag(:button, '', 
                    data: { action: 'click->ga4-analytics#toggleAnalyticsConsent' },
                    class: 'w-12 h-6 bg-gray-300 rounded-full flex items-center px-1 transition-colors'
                  ) do
                    content_tag(:div, '', class: 'w-4 h-4 bg-white rounded-full shadow-md transition-transform')
                  end
                end
              end +
              
              # Marketing cookies
              content_tag(:div) do
                content_tag(:h3, 'Marketing Cookies', class: 'text-lg font-medium text-gray-900 mb-2') +
                content_tag(:p, 'These cookies are used to track visitors across websites to display relevant and engaging advertisements.', class: 'text-sm text-gray-600 mb-4') +
                content_tag(:div, class: 'flex items-center justify-between') do
                  content_tag(:span, 'Marketing Tracking', class: 'text-sm font-medium text-gray-700') +
                  content_tag(:button, '', 
                    data: { action: 'click->ga4-analytics#toggleMarketingConsent' },
                    class: 'w-12 h-6 bg-gray-300 rounded-full flex items-center px-1 transition-colors'
                  ) do
                    content_tag(:div, '', class: 'w-4 h-4 bg-white rounded-full shadow-md transition-transform')
                  end
                end
              end +
              
              # Data subject rights
              content_tag(:div, class: 'border-t pt-6') do
                content_tag(:h3, 'Your Rights', class: 'text-lg font-medium text-gray-900 mb-4') +
                content_tag(:div, class: 'grid grid-cols-1 md:grid-cols-2 gap-4') do
                  content_tag(:button, 'Access My Data', 
                    data: { action: 'click->ga4-analytics#requestDataAccess' },
                    class: 'text-left p-3 border border-gray-200 rounded-lg hover:bg-gray-50 transition'
                  ) do
                    content_tag(:div, class: 'font-medium text-gray-900') { 'Access My Data' } +
                    content_tag(:div, class: 'text-sm text-gray-600') { 'Download a copy of your personal data' }
                  end +
                  content_tag(:button, 'Delete My Data', 
                    data: { action: 'click->ga4-analytics#requestDataDeletion' },
                    class: 'text-left p-3 border border-gray-200 rounded-lg hover:bg-gray-50 transition'
                  ) do
                    content_tag(:div, class: 'font-medium text-gray-900') { 'Delete My Data' } +
                    content_tag(:div, class: 'text-sm text-gray-600') { 'Request deletion of your personal data' }
                  end +
                  content_tag(:button, 'Data Portability', 
                    data: { action: 'click->ga4-analytics#requestDataPortability' },
                    class: 'text-left p-3 border border-gray-200 rounded-lg hover:bg-gray-50 transition'
                  ) do
                    content_tag(:div, class: 'font-medium text-gray-900') { 'Data Portability' } +
                    content_tag(:div, class: 'text-sm text-gray-600') { 'Export your data in a portable format' }
                  end +
                  content_tag(:button, 'Contact DPO', 
                    data: { action: 'click->ga4-analytics#contactDPO' },
                    class: 'text-left p-3 border border-gray-200 rounded-lg hover:bg-gray-50 transition'
                  ) do
                    content_tag(:div, class: 'font-medium text-gray-900') { 'Contact DPO' } +
                    content_tag(:div, class: 'text-sm text-gray-600') { 'Contact our Data Protection Officer' }
                  end
                end
              end +
              
              # Action buttons
              content_tag(:div, class: 'flex space-x-3 pt-6 border-t') do
                content_tag(:button, 'Save Preferences', 
                  data: { action: 'click->ga4-analytics#saveConsentPreferences' },
                  class: 'flex-1 bg-indigo-600 text-white px-4 py-2 rounded-lg font-medium hover:bg-indigo-700 transition'
                ) +
                content_tag(:button, 'Accept All', 
                  data: { action: 'click->ga4-analytics#acceptAllConsent' },
                  class: 'flex-1 bg-green-600 text-white px-4 py-2 rounded-lg font-medium hover:bg-green-700 transition'
                )
              end
            end
          end
        end
      end
    end
    
    tracker + consent_banner + privacy_controls
  end
  
  # Check if analytics is enabled
  def analytics_enabled?
    SiteSetting.get('analytics_enabled', 'true') == 'true'
  rescue
    true
  end
  
  # Check if GDPR compliance is enabled
  def gdpr_compliance_enabled?
    SiteSetting.get('gdpr_compliance_enabled', 'true') == 'true'
  rescue
    true
  end
  
  # Check if analytics requires consent
  def analytics_require_consent?
    SiteSetting.get('analytics_require_consent', 'true') == 'true'
  rescue
    true
  end
  
  # Get analytics consent message
  def analytics_consent_message
    SiteSetting.get('analytics_consent_message', 'We use privacy-friendly analytics to understand how you use our site. No personal data is collected.')
  rescue
    'We use privacy-friendly analytics to understand how you use our site. No personal data is collected.'
  end
  
  # Check if IP anonymization is enabled
  def analytics_anonymize_ip?
    SiteSetting.get('analytics_anonymize_ip', 'true') == 'true'
  rescue
    true
  end
  
  # Check if bot tracking is enabled
  def analytics_track_bots?
    SiteSetting.get('analytics_track_bots', 'false') == 'true'
  rescue
    false
  end
  
  # Get data retention period
  def analytics_data_retention_days
    SiteSetting.get('analytics_data_retention_days', 365).to_i
  rescue
    365
  end
  
  # Helper methods for content analytics views
  
  def flag_for_country(country_code)
    # Return flag emoji for country code
    case country_code&.upcase
    when 'US' then '🇺🇸'
    when 'GB' then '🇬🇧'
    when 'CA' then '🇨🇦'
    when 'AU' then '🇦🇺'
    when 'DE' then '🇩🇪'
    when 'FR' then '🇫🇷'
    when 'IT' then '🇮🇹'
    when 'ES' then '🇪🇸'
    when 'NL' then '🇳🇱'
    when 'SE' then '🇸🇪'
    when 'NO' then '🇳🇴'
    when 'DK' then '🇩🇰'
    when 'FI' then '🇫🇮'
    when 'JP' then '🇯🇵'
    when 'CN' then '🇨🇳'
    when 'IN' then '🇮🇳'
    when 'BR' then '🇧🇷'
    when 'MX' then '🇲🇽'
    when 'AR' then '🇦🇷'
    when 'CL' then '🇨🇱'
    when 'CO' then '🇨🇴'
    when 'PE' then '🇵🇪'
    when 'VE' then '🇻🇪'
    when 'RU' then '🇷🇺'
    when 'KR' then '🇰🇷'
    when 'TH' then '🇹🇭'
    when 'SG' then '🇸🇬'
    when 'MY' then '🇲🇾'
    when 'ID' then '🇮🇩'
    when 'PH' then '🇵🇭'
    when 'VN' then '🇻🇳'
    when 'ZA' then '🇿🇦'
    when 'EG' then '🇪🇬'
    when 'NG' then '🇳🇬'
    when 'KE' then '🇰🇪'
    when 'MA' then '🇲🇦'
    when 'TN' then '🇹🇳'
    when 'DZ' then '🇩🇿'
    when 'TR' then '🇹🇷'
    when 'SA' then '🇸🇦'
    when 'AE' then '🇦🇪'
    when 'IL' then '🇮🇱'
    when 'IR' then '🇮🇷'
    when 'IQ' then '🇮🇶'
    when 'PK' then '🇵🇰'
    when 'BD' then '🇧🇩'
    when 'LK' then '🇱🇰'
    when 'NP' then '🇳🇵'
    when 'BT' then '🇧🇹'
    when 'MV' then '🇲🇻'
    when 'AF' then '🇦🇫'
    when 'UZ' then '🇺🇿'
    when 'KZ' then '🇰🇿'
    when 'KG' then '🇰🇬'
    when 'TJ' then '🇹🇯'
    when 'TM' then '🇹🇲'
    when 'MN' then '🇲🇳'
    when 'MM' then '🇲🇲'
    when 'LA' then '🇱🇦'
    when 'KH' then '🇰🇭'
    when 'BN' then '🇧🇳'
    when 'TL' then '🇹🇱'
    when 'FJ' then '🇫🇯'
    when 'PG' then '🇵🇬'
    when 'SB' then '🇸🇧'
    when 'VU' then '🇻🇺'
    when 'NC' then '🇳🇨'
    when 'PF' then '🇵🇫'
    when 'WS' then '🇼🇸'
    when 'TO' then '🇹🇴'
    when 'KI' then '🇰🇮'
    when 'TV' then '🇹🇻'
    when 'NR' then '🇳🇷'
    when 'PW' then '🇵🇼'
    when 'FM' then '🇫🇲'
    when 'MH' then '🇲🇭'
    when 'CK' then '🇨🇰'
    when 'NU' then '🇳🇺'
    when 'TK' then '🇹🇰'
    when 'AS' then '🇦🇸'
    when 'GU' then '🇬🇺'
    when 'MP' then '🇲🇵'
    when 'VI' then '🇻🇮'
    when 'PR' then '🇵🇷'
    when 'DO' then '🇩🇴'
    when 'HT' then '🇭🇹'
    when 'CU' then '🇨🇺'
    when 'JM' then '🇯🇲'
    when 'BB' then '🇧🇧'
    when 'TT' then '🇹🇹'
    when 'GY' then '🇬🇾'
    when 'SR' then '🇸🇷'
    when 'GF' then '🇬🇫'
    when 'UY' then '🇺🇾'
    when 'PY' then '🇵🇾'
    when 'BO' then '🇧🇴'
    when 'EC' then '🇪🇨'
    when 'PA' then '🇵🇦'
    when 'CR' then '🇨🇷'
    when 'NI' then '🇳🇮'
    when 'HN' then '🇭🇳'
    when 'SV' then '🇸🇻'
    when 'GT' then '🇬🇹'
    when 'BZ' then '🇧🇿'
    when 'GY' then '🇬🇾'
    when 'SR' then '🇸🇷'
    when 'GF' then '🇬🇫'
    when 'UY' then '🇺🇾'
    when 'PY' then '🇵🇾'
    when 'BO' then '🇧🇴'
    when 'EC' then '🇪🇨'
    when 'PA' then '🇵🇦'
    when 'CR' then '🇨🇷'
    when 'NI' then '🇳🇮'
    when 'HN' then '🇭🇳'
    when 'SV' then '🇸🇻'
    when 'GT' then '🇬🇹'
    when 'BZ' then '🇧🇿'
    else '🌍'
    end
  end
  
  def country_name(country_code)
    # Return full country name for country code
    case country_code&.upcase
    when 'US' then 'United States'
    when 'GB' then 'United Kingdom'
    when 'CA' then 'Canada'
    when 'AU' then 'Australia'
    when 'DE' then 'Germany'
    when 'FR' then 'France'
    when 'IT' then 'Italy'
    when 'ES' then 'Spain'
    when 'NL' then 'Netherlands'
    when 'SE' then 'Sweden'
    when 'NO' then 'Norway'
    when 'DK' then 'Denmark'
    when 'FI' then 'Finland'
    when 'JP' then 'Japan'
    when 'CN' then 'China'
    when 'IN' then 'India'
    when 'BR' then 'Brazil'
    when 'MX' then 'Mexico'
    when 'AR' then 'Argentina'
    when 'CL' then 'Chile'
    when 'CO' then 'Colombia'
    when 'PE' then 'Peru'
    when 'VE' then 'Venezuela'
    when 'RU' then 'Russia'
    when 'KR' then 'South Korea'
    when 'TH' then 'Thailand'
    when 'SG' then 'Singapore'
    when 'MY' then 'Malaysia'
    when 'ID' then 'Indonesia'
    when 'PH' then 'Philippines'
    when 'VN' then 'Vietnam'
    when 'ZA' then 'South Africa'
    when 'EG' then 'Egypt'
    when 'NG' then 'Nigeria'
    when 'KE' then 'Kenya'
    when 'MA' then 'Morocco'
    when 'TN' then 'Tunisia'
    when 'DZ' then 'Algeria'
    when 'TR' then 'Turkey'
    when 'SA' then 'Saudi Arabia'
    when 'AE' then 'United Arab Emirates'
    when 'IL' then 'Israel'
    when 'IR' then 'Iran'
    when 'IQ' then 'Iraq'
    when 'PK' then 'Pakistan'
    when 'BD' then 'Bangladesh'
    when 'LK' then 'Sri Lanka'
    when 'NP' then 'Nepal'
    when 'BT' then 'Bhutan'
    when 'MV' then 'Maldives'
    when 'AF' then 'Afghanistan'
    when 'UZ' then 'Uzbekistan'
    when 'KZ' then 'Kazakhstan'
    when 'KG' then 'Kyrgyzstan'
    when 'TJ' then 'Tajikistan'
    when 'TM' then 'Turkmenistan'
    when 'MN' then 'Mongolia'
    when 'MM' then 'Myanmar'
    when 'LA' then 'Laos'
    when 'KH' then 'Cambodia'
    when 'BN' then 'Brunei'
    when 'TL' then 'Timor-Leste'
    when 'FJ' then 'Fiji'
    when 'PG' then 'Papua New Guinea'
    when 'SB' then 'Solomon Islands'
    when 'VU' then 'Vanuatu'
    when 'NC' then 'New Caledonia'
    when 'PF' then 'French Polynesia'
    when 'WS' then 'Samoa'
    when 'TO' then 'Tonga'
    when 'KI' then 'Kiribati'
    when 'TV' then 'Tuvalu'
    when 'NR' then 'Nauru'
    when 'PW' then 'Palau'
    when 'FM' then 'Micronesia'
    when 'MH' then 'Marshall Islands'
    when 'CK' then 'Cook Islands'
    when 'NU' then 'Niue'
    when 'TK' then 'Tokelau'
    when 'AS' then 'American Samoa'
    when 'GU' then 'Guam'
    when 'MP' then 'Northern Mariana Islands'
    when 'VI' then 'U.S. Virgin Islands'
    when 'PR' then 'Puerto Rico'
    when 'DO' then 'Dominican Republic'
    when 'HT' then 'Haiti'
    when 'CU' then 'Cuba'
    when 'JM' then 'Jamaica'
    when 'BB' then 'Barbados'
    when 'TT' then 'Trinidad and Tobago'
    when 'GY' then 'Guyana'
    when 'SR' then 'Suriname'
    when 'GF' then 'French Guiana'
    when 'UY' then 'Uruguay'
    when 'PY' then 'Paraguay'
    when 'BO' then 'Bolivia'
    when 'EC' then 'Ecuador'
    when 'PA' then 'Panama'
    when 'CR' then 'Costa Rica'
    when 'NI' then 'Nicaragua'
    when 'HN' then 'Honduras'
    when 'SV' then 'El Salvador'
    when 'GT' then 'Guatemala'
    when 'BZ' then 'Belize'
    else country_code
    end
  end
  
  def device_icon(device)
    case device&.downcase
    when 'desktop' then '🖥️'
    when 'mobile' then '📱'
    when 'tablet' then '📱'
    when 'phone' then '📱'
    else '💻'
    end
  end
  
  def source_domain(referrer)
    return 'Direct' if referrer.blank?
    
    begin
      uri = URI.parse(referrer)
      domain = uri.host
      
      case domain
      when /google\./ then 'Google'
      when /bing\./ then 'Bing'
      when /yahoo\./ then 'Yahoo'
      when /duckduckgo\./ then 'DuckDuckGo'
      when /facebook\./ then 'Facebook'
      when /twitter\./ then 'Twitter'
      when /linkedin\./ then 'LinkedIn'
      when /instagram\./ then 'Instagram'
      when /youtube\./ then 'YouTube'
      when /reddit\./ then 'Reddit'
      when /pinterest\./ then 'Pinterest'
      when /tumblr\./ then 'Tumblr'
      when /medium\./ then 'Medium'
      when /dev\./ then 'Dev.to'
      when /hashnode\./ then 'Hashnode'
      when /hackernews\./ then 'Hacker News'
      when /github\./ then 'GitHub'
      when /stackoverflow\./ then 'Stack Overflow'
      else domain
      end
    rescue
      referrer
    end
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








