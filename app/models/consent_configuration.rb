class ConsentConfiguration < ApplicationRecord
  acts_as_tenant(:tenant)
  
  # Serialization
  serialize :consent_categories, coder: JSON, type: Hash
  serialize :pixel_consent_mapping, coder: JSON, type: Hash
  serialize :banner_settings, coder: JSON, type: Hash
  serialize :geolocation_settings, coder: JSON, type: Hash
  
  # Validations
  validates :name, presence: true
  validates :banner_type, inclusion: { in: %w[bottom_banner modal overlay] }
  validates :consent_mode, inclusion: { in: %w[opt_in opt_out implied] }
  
  # Default consent categories
  DEFAULT_CONSENT_CATEGORIES = {
    'necessary' => {
      'name' => 'Necessary Cookies',
      'description' => 'These cookies are essential for the website to function and cannot be switched off.',
      'required' => true,
      'default_enabled' => true,
      'pixels' => []
    },
    'analytics' => {
      'name' => 'Analytics Cookies',
      'description' => 'These cookies help us understand how visitors interact with our website.',
      'required' => false,
      'default_enabled' => false,
      'pixels' => ['google_analytics', 'google_tag_manager', 'clarity', 'hotjar']
    },
    'marketing' => {
      'name' => 'Marketing Cookies',
      'description' => 'These cookies are used to track visitors across websites for advertising purposes.',
      'required' => false,
      'default_enabled' => false,
      'pixels' => ['facebook_pixel', 'tiktok_pixel', 'linkedin_insight', 'twitter_pixel', 'pinterest_tag', 'snapchat_pixel', 'reddit_pixel']
    },
    'functional' => {
      'name' => 'Functional Cookies',
      'description' => 'These cookies enable enhanced functionality and personalization.',
      'required' => false,
      'default_enabled' => false,
      'pixels' => ['mixpanel', 'segment', 'heap']
    }
  }.freeze
  
  # Default banner settings
  DEFAULT_BANNER_SETTINGS = {
    'enabled' => true,
    'position' => 'bottom',
    'theme' => 'dark',
    'show_manage_preferences' => true,
    'show_reject_all' => true,
    'show_accept_all' => true,
    'show_necessary_only' => true,
    'auto_hide_after_accept' => true,
    'auto_hide_delay' => 3000,
    'animation_duration' => 300,
    'custom_css' => '',
    'text' => {
      'title' => 'We use cookies to enhance your experience',
      'description' => 'We use cookies and similar technologies to provide, protect, and improve our services and to show you relevant content and ads.',
      'accept_all' => 'Accept All',
      'reject_all' => 'Reject All',
      'necessary_only' => 'Necessary Only',
      'manage_preferences' => 'Manage Preferences',
      'save_preferences' => 'Save Preferences',
      'close' => 'Close'
    },
    'colors' => {
      'primary' => '#3b82f6',
      'secondary' => '#6b7280',
      'background' => '#1f2937',
      'text' => '#ffffff',
      'button_accept' => '#10b981',
      'button_reject' => '#ef4444',
      'button_neutral' => '#6b7280'
    },
    'fonts' => {
      'family' => 'system-ui, -apple-system, sans-serif',
      'size_title' => '18px',
      'size_description' => '14px',
      'size_button' => '14px'
    }
  }.freeze
  
  # Default geolocation settings
  DEFAULT_GEOLOCATION_SETTINGS = {
    'enabled' => true,
    'eu_countries' => %w[AT BE BG HR CY CZ DK EE FI FR DE GR HU IE IT LV LT LU MT NL PL PT RO SK SI ES SE],
    'us_states' => %w[CA CO CT DE HI IL IA ME MD MA MI MN NH NJ NM NY OR PA RI TX UT VT VA WA],
    'uk_countries' => %w[GB],
    'canada_provinces' => %w[AB BC MB NB NL NS NT NU ON PE QC SK YT],
    'auto_detect' => true,
    'fallback_consent_mode' => 'opt_in',
    'region_specific_settings' => {
      'eu' => {
        'consent_mode' => 'opt_in',
        'show_detailed_preferences' => true,
        'require_explicit_consent' => true
      },
      'us' => {
        'consent_mode' => 'opt_out',
        'show_detailed_preferences' => false,
        'require_explicit_consent' => false
      },
      'uk' => {
        'consent_mode' => 'opt_in',
        'show_detailed_preferences' => true,
        'require_explicit_consent' => true
      },
      'ca' => {
        'consent_mode' => 'opt_in',
        'show_detailed_preferences' => true,
        'require_explicit_consent' => true
      }
    }
  }.freeze
  
  # Callbacks
  after_initialize :set_defaults, if: :new_record?
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_banner_type, ->(type) { where(banner_type: type) }
  scope :ordered, -> { order(:name) }
  
  # Instance methods
  
  def consent_categories_with_defaults
    DEFAULT_CONSENT_CATEGORIES.merge(consent_categories || {})
  end
  
  def banner_settings_with_defaults
    DEFAULT_BANNER_SETTINGS.merge(banner_settings || {})
  end
  
  def geolocation_settings_with_defaults
    DEFAULT_GEOLOCATION_SETTINGS.merge(geolocation_settings || {})
  end
  
  def pixel_consent_mapping_with_defaults
    mapping = {}
    consent_categories_with_defaults.each do |category, settings|
      mapping[category] = settings['pixels'] || []
    end
    mapping.merge(pixel_consent_mapping || {})
  end
  
  def get_pixels_for_consent_category(category)
    pixel_consent_mapping_with_defaults[category] || []
  end
  
  def get_consent_categories_for_pixel(pixel_type)
    categories = []
    pixel_consent_mapping_with_defaults.each do |category, pixels|
      categories << category if pixels.include?(pixel_type)
    end
    categories
  end
  
  def is_pixel_consent_required?(pixel_type)
    get_consent_categories_for_pixel(pixel_type).any? do |category|
      settings = consent_categories_with_defaults[category]
      settings && !settings['required'] && !settings['default_enabled']
    end
  end
  
  def get_region_from_ip(ip_address)
    return 'unknown' unless geolocation_settings_with_defaults['enabled']
    
    begin
      # Use MaxMind GeoIP or similar service
      result = Geocoder.search(ip_address).first
      return 'unknown' unless result
      
      country_code = result.country_code&.upcase
      return 'unknown' unless country_code
      
      # Check EU countries
      if geolocation_settings_with_defaults['eu_countries'].include?(country_code)
        return 'eu'
      end
      
      # Check UK
      if geolocation_settings_with_defaults['uk_countries'].include?(country_code)
        return 'uk'
      end
      
      # Check Canada
      if country_code == 'CA'
        return 'ca'
      end
      
      # Check US
      if country_code == 'US'
        return 'us'
      end
      
      'other'
    rescue => e
      Rails.logger.error "Geolocation error: #{e.message}"
      'unknown'
    end
  end
  
  def get_consent_mode_for_region(region)
    region_settings = geolocation_settings_with_defaults['region_specific_settings']
    region_settings[region]&.dig('consent_mode') || geolocation_settings_with_defaults['fallback_consent_mode']
  end
  
  def should_show_banner?(region = nil, user_consent = nil)
    return false unless banner_settings_with_defaults['enabled']
    return false if user_consent&.any? { |consent| consent['consent_type'] == 'necessary' && consent['granted'] }
    
    # Check if user has given any consent
    if user_consent&.any? { |consent| consent['granted'] }
      return false
    end
    
    # Region-specific logic
    if region && region != 'unknown'
      region_settings = geolocation_settings_with_defaults['region_specific_settings'][region]
      return region_settings&.dig('require_explicit_consent') == true if region_settings
    end
    
    true
  end
  
  def generate_banner_html(region = nil, user_consent = nil)
    return '' unless should_show_banner?(region, user_consent)
    
    settings = banner_settings_with_defaults
    categories = consent_categories_with_defaults
    
    # Generate the banner HTML
    <<~HTML
      <div id="consent-banner" class="consent-banner" style="display: none;">
        <div class="consent-banner-content">
          <div class="consent-banner-header">
            <h3 class="consent-banner-title">#{settings['text']['title']}</h3>
            <button class="consent-banner-close" onclick="ConsentManager.hideBanner()">
              <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
              </svg>
            </button>
          </div>
          <div class="consent-banner-body">
            <p class="consent-banner-description">#{settings['text']['description']}</p>
          </div>
          <div class="consent-banner-actions">
            #{generate_banner_buttons(settings)}
          </div>
        </div>
      </div>
      <div id="consent-preferences-modal" class="consent-preferences-modal" style="display: none;">
        <div class="consent-modal-content">
          <div class="consent-modal-header">
            <h3 class="consent-modal-title">Cookie Preferences</h3>
            <button class="consent-modal-close" onclick="ConsentManager.hidePreferencesModal()">
              <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414 1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
              </svg>
            </button>
          </div>
          <div class="consent-modal-body">
            #{generate_preferences_form(categories)}
          </div>
          <div class="consent-modal-actions">
            <button class="consent-btn consent-btn-secondary" onclick="ConsentManager.hidePreferencesModal()">
              #{settings['text']['close']}
            </button>
            <button class="consent-btn consent-btn-primary" onclick="ConsentManager.savePreferences()">
              #{settings['text']['save_preferences']}
            </button>
          </div>
        </div>
      </div>
    HTML
  end
  
  def generate_banner_css
    settings = banner_settings_with_defaults
    colors = settings['colors']
    fonts = settings['fonts']
    
    <<~CSS
      .consent-banner {
        position: fixed;
        bottom: 0;
        left: 0;
        right: 0;
        background: #{colors['background']};
        color: #{colors['text']};
        padding: 20px;
        box-shadow: 0 -4px 6px -1px rgba(0, 0, 0, 0.1);
        z-index: 9999;
        font-family: #{fonts['family']};
        transform: translateY(100%);
        transition: transform #{settings['animation_duration']}ms ease-in-out;
      }
      
      .consent-banner.show {
        transform: translateY(0);
      }
      
      .consent-banner-content {
        max-width: 1200px;
        margin: 0 auto;
        display: flex;
        flex-direction: column;
        gap: 16px;
      }
      
      .consent-banner-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
      
      .consent-banner-title {
        font-size: #{fonts['size_title']};
        font-weight: 600;
        margin: 0;
        color: #{colors['text']};
      }
      
      .consent-banner-close {
        background: none;
        border: none;
        color: #{colors['text']};
        cursor: pointer;
        padding: 4px;
        border-radius: 4px;
        transition: background-color 0.2s;
      }
      
      .consent-banner-close:hover {
        background-color: rgba(255, 255, 255, 0.1);
      }
      
      .consent-banner-description {
        font-size: #{fonts['size_description']};
        margin: 0;
        line-height: 1.5;
        color: #{colors['text']};
      }
      
      .consent-banner-actions {
        display: flex;
        gap: 12px;
        flex-wrap: wrap;
      }
      
      .consent-btn {
        padding: 10px 20px;
        border: none;
        border-radius: 6px;
        font-size: #{fonts['size_button']};
        font-weight: 500;
        cursor: pointer;
        transition: all 0.2s;
        font-family: #{fonts['family']};
      }
      
      .consent-btn-primary {
        background-color: #{colors['button_accept']};
        color: white;
      }
      
      .consent-btn-primary:hover {
        opacity: 0.9;
        transform: translateY(-1px);
      }
      
      .consent-btn-secondary {
        background-color: #{colors['button_reject']};
        color: white;
      }
      
      .consent-btn-secondary:hover {
        opacity: 0.9;
        transform: translateY(-1px);
      }
      
      .consent-btn-neutral {
        background-color: #{colors['button_neutral']};
        color: white;
      }
      
      .consent-btn-neutral:hover {
        opacity: 0.9;
        transform: translateY(-1px);
      }
      
      .consent-preferences-modal {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background-color: rgba(0, 0, 0, 0.5);
        z-index: 10000;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 20px;
      }
      
      .consent-modal-content {
        background: white;
        border-radius: 8px;
        max-width: 600px;
        width: 100%;
        max-height: 80vh;
        overflow-y: auto;
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
      }
      
      .consent-modal-header {
        padding: 20px;
        border-bottom: 1px solid #e5e7eb;
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
      
      .consent-modal-title {
        font-size: 18px;
        font-weight: 600;
        margin: 0;
        color: #111827;
      }
      
      .consent-modal-close {
        background: none;
        border: none;
        color: #6b7280;
        cursor: pointer;
        padding: 4px;
        border-radius: 4px;
        transition: background-color 0.2s;
      }
      
      .consent-modal-close:hover {
        background-color: #f3f4f6;
      }
      
      .consent-modal-body {
        padding: 20px;
      }
      
      .consent-modal-actions {
        padding: 20px;
        border-top: 1px solid #e5e7eb;
        display: flex;
        justify-content: flex-end;
        gap: 12px;
      }
      
      .consent-category {
        margin-bottom: 20px;
        padding: 16px;
        border: 1px solid #e5e7eb;
        border-radius: 6px;
      }
      
      .consent-category-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 8px;
      }
      
      .consent-category-title {
        font-size: 16px;
        font-weight: 500;
        margin: 0;
        color: #111827;
      }
      
      .consent-category-description {
        font-size: 14px;
        color: #6b7280;
        margin: 0;
        line-height: 1.5;
      }
      
      .consent-toggle {
        position: relative;
        display: inline-block;
        width: 44px;
        height: 24px;
      }
      
      .consent-toggle input {
        opacity: 0;
        width: 0;
        height: 0;
      }
      
      .consent-slider {
        position: absolute;
        cursor: pointer;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background-color: #ccc;
        transition: 0.4s;
        border-radius: 24px;
      }
      
      .consent-slider:before {
        position: absolute;
        content: "";
        height: 18px;
        width: 18px;
        left: 3px;
        bottom: 3px;
        background-color: white;
        transition: 0.4s;
        border-radius: 50%;
      }
      
      .consent-toggle input:checked + .consent-slider {
        background-color: #{colors['button_accept']};
      }
      
      .consent-toggle input:checked + .consent-slider:before {
        transform: translateX(20px);
      }
      
      .consent-toggle input:disabled + .consent-slider {
        background-color: #{colors['button_neutral']};
        cursor: not-allowed;
      }
      
      @media (max-width: 768px) {
        .consent-banner-actions {
          flex-direction: column;
        }
        
        .consent-btn {
          width: 100%;
        }
        
        .consent-modal-content {
          margin: 10px;
        }
      }
      
      #{settings['custom_css']}
    CSS
  end
  
  def generate_preferences_form(categories)
    form_html = ''
    
    categories.each do |category, settings|
      required_class = settings['required'] ? 'required' : ''
      disabled_attr = settings['required'] ? 'disabled' : ''
      checked_attr = settings['default_enabled'] ? 'checked' : ''
      
      form_html += <<~HTML
        <div class="consent-category #{required_class}">
          <div class="consent-category-header">
            <h4 class="consent-category-title">#{settings['name']}</h4>
            <label class="consent-toggle">
              <input type="checkbox" #{checked_attr} #{disabled_attr} data-category="#{category}">
              <span class="consent-slider"></span>
            </label>
          </div>
          <p class="consent-category-description">#{settings['description']}</p>
        </div>
      HTML
    end
    
    form_html
  end
  
  private
  
  def set_defaults
    self.consent_categories ||= DEFAULT_CONSENT_CATEGORIES
    self.banner_settings ||= DEFAULT_BANNER_SETTINGS
    self.geolocation_settings ||= DEFAULT_GEOLOCATION_SETTINGS
    self.active ||= true
  end
  
  def generate_banner_buttons(settings)
    buttons = []
    
    if settings['show_accept_all']
      buttons << "<button class=\"consent-btn consent-btn-primary\" onclick=\"ConsentManager.acceptAll()\">#{settings['text']['accept_all']}</button>"
    end
    
    if settings['show_reject_all']
      buttons << "<button class=\"consent-btn consent-btn-secondary\" onclick=\"ConsentManager.rejectAll()\">#{settings['text']['reject_all']}</button>"
    end
    
    if settings['show_necessary_only']
      buttons << "<button class=\"consent-btn consent-btn-neutral\" onclick=\"ConsentManager.acceptNecessary()\">#{settings['text']['necessary_only']}</button>"
    end
    
    if settings['show_manage_preferences']
      buttons << "<button class=\"consent-btn consent-btn-neutral\" onclick=\"ConsentManager.showPreferencesModal()\">#{settings['text']['manage_preferences']}</button>"
    end
    
    buttons.join('')
  end
end
