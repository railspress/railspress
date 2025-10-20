module ConsentHelper
  # Render consent banner HTML
  def render_consent_banner
    consent_config = ConsentConfiguration.active.first
    return '' unless consent_config
    
    # Get user's region (simplified for Liquid templates)
    region = get_user_region
    user_consent = get_user_consent_data
    
    consent_config.generate_banner_html(region, user_consent)
  end
  
  # Render consent banner CSS
  def render_consent_css
    consent_config = ConsentConfiguration.active.first
    return '' unless consent_config
    
    consent_config.generate_banner_css
  end
  
  # Render consent-aware pixel code
  def render_pixel_with_consent(pixel)
    return '' unless pixel&.active?
    
    # Get consent configuration
    consent_config = ConsentConfiguration.active.first
    return pixel.render_code unless consent_config
    
    # Check if pixel requires consent
    required_consent = consent_config.get_consent_categories_for_pixel(pixel.pixel_type)
    
    if required_consent.any?
      # Pixel requires consent - wrap in consent-aware code
      consent_categories = required_consent.join(',')
      
      <<~HTML
        <div data-pixel-type="#{pixel.pixel_type}" data-consent-categories="#{consent_categories}" class="consent-pixel" style="display: none;">
          #{pixel.render_code}
        </div>
      HTML
    else
      # Pixel doesn't require consent - render normally
      pixel.render_code
    end
  end
  
  # Render all pixels with consent awareness
  def render_all_pixels_with_consent(position = nil)
    pixels = Pixel.active
    pixels = pixels.by_position(position) if position
    
    pixels.map { |pixel| render_pixel_with_consent(pixel) }.join.html_safe
  end
  
  # Check if user has given consent for a specific category
  def user_has_consent?(category)
    return false unless user_signed_in?
    
    current_user.user_consents.find_by(consent_type: category)&.granted? || false
  end
  
  # Check if user has given consent for a pixel type
  def user_has_pixel_consent?(pixel_type)
    consent_config = ConsentConfiguration.active.first
    return true unless consent_config # If no consent config, allow all
    
    required_categories = consent_config.get_consent_categories_for_pixel(pixel_type)
    return true if required_categories.empty? # No consent required
    
    required_categories.all? { |category| user_has_consent?(category) }
  end
  
  # Get consent status for current user
  def user_consent_status
    return {} unless user_signed_in?
    
    current_user.user_consents.index_by(&:consent_type).transform_values do |consent|
      {
        granted: consent.granted?,
        granted_at: consent.granted_at,
        withdrawn_at: consent.withdrawn_at
      }
    end
  end
  
  # Render consent management link
  def consent_management_link(text = 'Manage Cookie Preferences', css_class = '')
    return '' unless ConsentConfiguration.active.exists?
    
    link_to text, '#', 
            class: "consent-management-link #{css_class}",
            onclick: 'ConsentManager.showPreferencesModal(); return false;'
  end
  
  # Render consent status indicator
  def consent_status_indicator(category)
    return '' unless user_signed_in?
    
    consent = current_user.user_consents.find_by(consent_type: category)
    return '' unless consent
    
    status_class = consent.granted? ? 'consent-granted' : 'consent-withdrawn'
    status_text = consent.granted? ? 'Granted' : 'Withdrawn'
    
    content_tag :span, status_text, class: "consent-status #{status_class}"
  end
  
  # Render consent banner for specific region
  def render_region_specific_banner(region)
    consent_config = ConsentConfiguration.active.first
    return '' unless consent_config
    
    # Check if banner should be shown for this region
    return '' unless consent_config.should_show_banner?(region)
    
    consent_config.generate_banner_html(region)
  end
  
  # Get consent configuration for JavaScript
  def consent_config_json
    consent_config = ConsentConfiguration.active.first
    return '{}' unless consent_config
    
    {
      consent_categories: consent_config.consent_categories_with_defaults,
      banner_settings: consent_config.banner_settings_with_defaults,
      geolocation_settings: consent_config.geolocation_settings_with_defaults,
      pixel_consent_mapping: consent_config.pixel_consent_mapping_with_defaults,
      version: consent_config.version || '1.0'
    }.to_json
  end
  
  # Render consent banner initialization script
  def consent_banner_script
    return '' unless ConsentConfiguration.active.exists?
    
    <<~HTML
      <script>
        document.addEventListener('DOMContentLoaded', function() {
          // Initialize consent manager with configuration
          if (typeof ConsentManager !== 'undefined') {
            window.consentManager = new ConsentManager({
              config: #{consent_config_json},
              debug: #{Rails.env.development?}
            });
          }
        });
      </script>
    HTML
  end
  
  # Render consent banner CSS and HTML
  def consent_banner_assets
    return '' unless ConsentConfiguration.active.exists?
    
    css = render_consent_css
    html = render_consent_banner
    script = consent_banner_script
    
    <<~HTML
      <style>
        #{css}
      </style>
      #{html}
      #{script}
    HTML
  end
  
  # Check if consent banner should be shown
  def should_show_consent_banner?
    consent_config = ConsentConfiguration.active.first
    return false unless consent_config
    
    # Check if user has already given consent
    return false if user_signed_in? && current_user.user_consents.granted.exists?
    
    # Check if banner is enabled
    consent_config.banner_settings_with_defaults['enabled']
  end
  
  # Render consent banner only if needed
  def render_consent_banner_if_needed
    return '' unless should_show_consent_banner?
    
    consent_banner_assets
  end
  
  # Get user's consent data for JavaScript
  def user_consent_json
    return '{}' unless user_signed_in?
    
    user_consent_status.to_json
  end
  
  # Render user consent data script
  def user_consent_script
    return '' unless user_signed_in?
    
    <<~HTML
      <script>
        window.userConsentData = #{user_consent_json};
      </script>
    HTML
  end
  
  # Render consent-aware pixel loading script
  def consent_pixel_script
    return '' unless ConsentConfiguration.active.exists?
    
    <<~HTML
      <script>
        // Override pixel loading to respect consent
        document.addEventListener('DOMContentLoaded', function() {
          // Find all consent-aware pixels
          const consentPixels = document.querySelectorAll('[data-pixel-type][data-consent-categories]');
          
          consentPixels.forEach(function(pixel) {
            const pixelType = pixel.dataset.pixelType;
            const requiredCategories = pixel.dataset.consentCategories.split(',');
            
            // Check if user has required consent
            let hasConsent = true;
            if (window.userConsentData) {
              hasConsent = requiredCategories.every(function(category) {
                return window.userConsentData[category] && window.userConsentData[category].granted;
              });
            }
            
            if (hasConsent) {
              // Load the pixel
              pixel.style.display = '';
              pixel.classList.remove('consent-disabled');
            } else {
              // Keep pixel hidden
              pixel.style.display = 'none';
              pixel.classList.add('consent-disabled');
            }
          });
        });
      </script>
    HTML
  end
  
  private
  
  def get_user_region
    # Simplified region detection for Liquid templates
    # In a real implementation, this would use the same logic as the API
    request.remote_ip || 'unknown'
  end
  
  def get_user_consent_data
    return [] unless user_signed_in?
    
    current_user.user_consents.map do |consent|
      {
        consent_type: consent.consent_type,
        granted: consent.granted?
      }
    end
  end
end
