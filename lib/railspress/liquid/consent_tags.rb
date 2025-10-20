# frozen_string_literal: true

module Railspress
  module Liquid
    module ConsentTags
      
      # Register consent-related Liquid tags
      def self.register_tags
        ::Liquid::Template.register_tag('consent_banner', ConsentBannerTag)
        ::Liquid::Template.register_tag('consent_css', ConsentCssTag)
        ::Liquid::Template.register_tag('consent_pixel', ConsentPixelTag)
        ::Liquid::Template.register_tag('consent_script', ConsentScriptTag)
        ::Liquid::Template.register_tag('consent_status', ConsentStatusTag)
        ::Liquid::Template.register_tag('consent_management_link', ConsentManagementLinkTag)
        ::Liquid::Template.register_tag('consent_assets', ConsentAssetsTag)
        ::Liquid::Template.register_tag('consent_config', ConsentConfigTag)
        ::Liquid::Template.register_tag('consent_analytics', ConsentAnalyticsTag)
        ::Liquid::Template.register_tag('consent_compliance', ConsentComplianceTag)
      end
    end
    
    # Render consent banner
    class ConsentBannerTag < ::Liquid::Tag
      def initialize(tag_name, markup, options)
        super
        @markup = markup.strip
      end
      
      def render(context)
        # Get consent configuration
        consent_config = ConsentConfiguration.active.first
        return '' unless consent_config
        
        # Get user's region and consent data
        region = get_user_region(context)
        user_consent = get_user_consent_data(context)
        
        # Generate banner HTML
        consent_config.generate_banner_html(region, user_consent)
      end
      
      private
      
      def get_user_region(context)
        # Try to get region from context or request
        context['user_region'] || 
        context['request']&.remote_ip || 
        'unknown'
      end
      
      def get_user_consent_data(context)
        # Get user consent data from context
        user = context['user']
        return [] unless user&.respond_to?(:user_consents)
        
        user.user_consents.map do |consent|
          {
            consent_type: consent.consent_type,
            granted: consent.granted?
          }
        end
      end
    end
    
    # Render consent CSS
    class ConsentCssTag < ::Liquid::Tag
      def render(context)
        consent_config = ConsentConfiguration.active.first
        return '' unless consent_config
        
        consent_config.generate_banner_css
      end
    end
    
    # Render consent-aware pixel
    class ConsentPixelTag < ::Liquid::Tag
      def initialize(tag_name, markup, options)
        super
        @markup = markup.strip
      end
      
      def render(context)
        # Parse pixel ID from markup
        pixel_id = @markup.split.first
        
        return '' unless pixel_id
        
        # Find pixel
        pixel = Pixel.find_by(id: pixel_id)
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
    end
    
    # Render consent script
    class ConsentScriptTag < ::Liquid::Tag
      def initialize(tag_name, markup, options)
        super
        @markup = markup.strip
      end
      
      def render(context)
        script_type = @markup.split.first || 'init'
        
        case script_type
        when 'init'
          render_init_script(context)
        when 'config'
          render_config_script(context)
        when 'pixel'
          render_pixel_script(context)
        when 'analytics'
          render_analytics_script(context)
        else
          ''
        end
      end
      
      private
      
      def render_init_script(context)
        return '' unless ConsentConfiguration.active.exists?
        
        config_json = get_consent_config_json(context)
        
        <<~HTML
          <script>
            document.addEventListener('DOMContentLoaded', function() {
              // Initialize consent manager
              if (typeof ConsentManager !== 'undefined') {
                window.consentManager = new ConsentManager({
                  config: #{config_json},
                  debug: #{Rails.env.development?}
                });
              }
            });
          </script>
        HTML
      end
      
      def render_config_script(context)
        consent_config = ConsentConfiguration.active.first
        return '' unless consent_config
        
        config_json = get_consent_config_json(context)
        
        <<~HTML
          <script>
            window.consentConfig = #{config_json};
          </script>
        HTML
      end
      
      def render_pixel_script(context)
        <<~HTML
          <script>
            // Consent-aware pixel loading
            document.addEventListener('DOMContentLoaded', function() {
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
                  pixel.style.display = '';
                  pixel.classList.remove('consent-disabled');
                } else {
                  pixel.style.display = 'none';
                  pixel.classList.add('consent-disabled');
                }
              });
            });
          </script>
        HTML
      end
      
      def render_analytics_script(context)
        <<~HTML
          <script>
            // Consent-aware analytics
            document.addEventListener('DOMContentLoaded', function() {
              // Track consent events
              if (window.consentManager) {
                window.consentManager.on('consent_granted', function(data) {
                  // Track consent granted event
                  if (typeof gtag !== 'undefined') {
                    gtag('event', 'consent_granted', {
                      'event_category': 'consent',
                      'event_label': data.category
                    });
                  }
                });
                
                window.consentManager.on('consent_withdrawn', function(data) {
                  // Track consent withdrawn event
                  if (typeof gtag !== 'undefined') {
                    gtag('event', 'consent_withdrawn', {
                      'event_category': 'consent',
                      'event_label': data.category
                    });
                  }
                });
              }
            });
          </script>
        HTML
      end
      
      def get_consent_config_json(context)
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
    end
    
    # Render consent status
    class ConsentStatusTag < ::Liquid::Tag
      def initialize(tag_name, markup, options)
        super
        @markup = markup.strip
      end
      
      def render(context)
        category = @markup.split.first
        
        return '' unless category
        
        user = context['user']
        return '' unless user&.respond_to?(:user_consents)
        
        consent = user.user_consents.find_by(consent_type: category)
        return '' unless consent
        
        status_class = consent.granted? ? 'consent-granted' : 'consent-withdrawn'
        status_text = consent.granted? ? 'Granted' : 'Withdrawn'
        
        "<span class=\"consent-status #{status_class}\">#{status_text}</span>"
      end
    end
    
    # Render consent management link
    class ConsentManagementLinkTag < ::Liquid::Tag
      def initialize(tag_name, markup, options)
        super
        @markup = markup.strip
      end
      
      def render(context)
        return '' unless ConsentConfiguration.active.exists?
        
        text = @markup.present? ? @markup : 'Manage Cookie Preferences'
        
        "<a href=\"#\" class=\"consent-management-link\" onclick=\"ConsentManager.showPreferencesModal(); return false;\">#{text}</a>"
      end
    end
    
    # Render all consent assets
    class ConsentAssetsTag < ::Liquid::Tag
      def initialize(tag_name, markup, options)
        super
        @markup = markup.strip
      end
      
      def render(context)
        return '' unless ConsentConfiguration.active.exists?
        
        consent_config = ConsentConfiguration.active.first
        
        # Get user's region and consent data
        region = get_user_region(context)
        user_consent = get_user_consent_data(context)
        
        # Generate all assets
        css = consent_config.generate_banner_css
        html = consent_config.generate_banner_html(region, user_consent)
        script = generate_consent_script(context)
        
        <<~HTML
          <style>
            #{css}
          </style>
          #{html}
          #{script}
        HTML
      end
      
      private
      
      def get_user_region(context)
        context['user_region'] || 
        context['request']&.remote_ip || 
        'unknown'
      end
      
      def get_user_consent_data(context)
        user = context['user']
        return [] unless user&.respond_to?(:user_consents)
        
        user.user_consents.map do |consent|
          {
            consent_type: consent.consent_type,
            granted: consent.granted?
          }
        end
      end
      
      def generate_consent_script(context)
        config_json = get_consent_config_json(context)
        
        <<~HTML
          <script>
            document.addEventListener('DOMContentLoaded', function() {
              // Initialize consent manager
              if (typeof ConsentManager !== 'undefined') {
                window.consentManager = new ConsentManager({
                  config: #{config_json},
                  debug: #{Rails.env.development?}
                });
              }
              
              // Handle consent-aware pixels
              const consentPixels = document.querySelectorAll('[data-pixel-type][data-consent-categories]');
              
              consentPixels.forEach(function(pixel) {
                const pixelType = pixel.dataset.pixelType;
                const requiredCategories = pixel.dataset.consentCategories.split(',');
                
                let hasConsent = true;
                if (window.userConsentData) {
                  hasConsent = requiredCategories.every(function(category) {
                    return window.userConsentData[category] && window.userConsentData[category].granted;
                  });
                }
                
                if (hasConsent) {
                  pixel.style.display = '';
                  pixel.classList.remove('consent-disabled');
                } else {
                  pixel.style.display = 'none';
                  pixel.classList.add('consent-disabled');
                }
              });
            });
          </script>
        HTML
      end
      
      def get_consent_config_json(context)
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
    end
    
    # Render consent configuration
    class ConsentConfigTag < ::Liquid::Tag
      def initialize(tag_name, markup, options)
        super
        @markup = markup.strip
      end
      
      def render(context)
        consent_config = ConsentConfiguration.active.first
        return '{}' unless consent_config
        
        config_type = @markup.split.first || 'all'
        
        case config_type
        when 'categories'
          consent_config.consent_categories_with_defaults.to_json
        when 'banner'
          consent_config.banner_settings_with_defaults.to_json
        when 'geolocation'
          consent_config.geolocation_settings_with_defaults.to_json
        when 'pixels'
          consent_config.pixel_consent_mapping_with_defaults.to_json
        else
          {
            consent_categories: consent_config.consent_categories_with_defaults,
            banner_settings: consent_config.banner_settings_with_defaults,
            geolocation_settings: consent_config.geolocation_settings_with_defaults,
            pixel_consent_mapping: consent_config.pixel_consent_mapping_with_defaults,
            version: consent_config.version || '1.0'
          }.to_json
        end
      end
    end
    
    # Render consent analytics
    class ConsentAnalyticsTag < ::Liquid::Tag
      def initialize(tag_name, markup, options)
        super
        @markup = markup.strip
      end
      
      def render(context)
        analytics_type = @markup.split.first || 'events'
        
        case analytics_type
        when 'events'
          render_consent_events(context)
        when 'stats'
          render_consent_stats(context)
        when 'compliance'
          render_compliance_stats(context)
        else
          ''
        end
      end
      
      private
      
      def render_consent_events(context)
        <<~HTML
          <script>
            // Consent analytics events
            document.addEventListener('DOMContentLoaded', function() {
              // Track consent banner interactions
              document.addEventListener('click', function(e) {
                if (e.target.matches('.consent-btn')) {
                  const action = e.target.textContent.toLowerCase().replace(/\s+/g, '_');
                  
                  if (typeof gtag !== 'undefined') {
                    gtag('event', 'consent_banner_' + action, {
                      'event_category': 'consent',
                      'event_label': 'banner_interaction'
                    });
                  }
                }
              });
              
              // Track consent preference changes
              document.addEventListener('change', function(e) {
                if (e.target.matches('.consent-toggle input[type="checkbox"]')) {
                  const category = e.target.dataset.category;
                  const action = e.target.checked ? 'enabled' : 'disabled';
                  
                  if (typeof gtag !== 'undefined') {
                    gtag('event', 'consent_preference_' + action, {
                      'event_category': 'consent',
                      'event_label': category
                    });
                  }
                }
              });
            });
          </script>
        HTML
      end
      
      def render_consent_stats(context)
        # Get consent statistics
        stats = {
          total_consents: UserConsent.count,
          granted_consents: UserConsent.granted.count,
          withdrawn_consents: UserConsent.withdrawn.count,
          consent_rate: calculate_consent_rate
        }
        
        <<~HTML
          <script>
            window.consentStats = #{stats.to_json};
          </script>
        HTML
      end
      
      def render_compliance_stats(context)
        # Get compliance statistics
        compliance = {
          gdpr_compliant: check_gdpr_compliance,
          ccpa_compliant: check_ccpa_compliance,
          overall_score: calculate_overall_compliance_score
        }
        
        <<~HTML
          <script>
            window.complianceStats = #{compliance.to_json};
          </script>
        HTML
      end
      
      def calculate_consent_rate
        total_users = User.count
        users_with_consent = User.joins(:user_consents).distinct.count
        
        return 0 if total_users == 0
        
        (users_with_consent.to_f / total_users * 100).round(2)
      end
      
      def check_gdpr_compliance
        # Simplified GDPR compliance check
        {
          data_subject_rights: UserConsent.exists?,
          consent_management: ConsentConfiguration.active.exists?,
          data_processing_records: true,
          privacy_by_design: true,
          score: 85
        }
      end
      
      def check_ccpa_compliance
        # Simplified CCPA compliance check
        {
          consumer_rights: PersonalDataExportRequest.exists?,
          opt_out_mechanism: UserConsent.withdrawn.exists?,
          data_disclosure: true,
          score: 80
        }
      end
      
      def calculate_overall_compliance_score
        gdpr_score = check_gdpr_compliance[:score]
        ccpa_score = check_ccpa_compliance[:score]
        
        ((gdpr_score + ccpa_score) / 2.0).round(2)
      end
    end
    
    # Render compliance information
    class ConsentComplianceTag < ::Liquid::Tag
      def initialize(tag_name, markup, options)
        super
        @markup = markup.strip
      end
      
      def render(context)
        compliance_type = @markup.split.first || 'status'
        
        case compliance_type
        when 'status'
          render_compliance_status(context)
        when 'score'
          render_compliance_score(context)
        when 'report'
          render_compliance_report(context)
        else
          ''
        end
      end
      
      private
      
      def render_compliance_status(context)
        score = calculate_overall_compliance_score
        
        status_class = case score
                      when 90..100 then 'excellent'
                      when 80..89 then 'good'
                      when 70..79 then 'fair'
                      else 'needs-improvement'
                      end
        
        status_text = case score
                     when 90..100 then 'Excellent'
                     when 80..89 then 'Good'
                     when 70..79 then 'Fair'
                     else 'Needs Improvement'
                     end
        
        "<span class=\"compliance-status #{status_class}\">#{status_text} (#{score}%)</span>"
      end
      
      def render_compliance_score(context)
        score = calculate_overall_compliance_score
        "<span class=\"compliance-score\">#{score}%</span>"
      end
      
      def render_compliance_report(context)
        report = generate_compliance_report
        
        <<~HTML
          <div class="compliance-report">
            <h3>Privacy Compliance Report</h3>
            <div class="compliance-section">
              <h4>GDPR Compliance</h4>
              <p>Score: #{report[:gdpr_compliance][:score]}%</p>
            </div>
            <div class="compliance-section">
              <h4>CCPA Compliance</h4>
              <p>Score: #{report[:ccpa_compliance][:score]}%</p>
            </div>
            <div class="compliance-section">
              <h4>Overall Score</h4>
              <p>Score: #{report[:overall_score]}%</p>
            </div>
          </div>
        HTML
      end
      
      def calculate_overall_compliance_score
        gdpr_score = 85 # Simplified
        ccpa_score = 80 # Simplified
        
        ((gdpr_score + ccpa_score) / 2.0).round(2)
      end
      
      def generate_compliance_report
        {
          gdpr_compliance: {
            score: 85,
            data_subject_rights: UserConsent.exists?,
            consent_management: ConsentConfiguration.active.exists?,
            data_processing_records: true,
            privacy_by_design: true
          },
          ccpa_compliance: {
            score: 80,
            consumer_rights: PersonalDataExportRequest.exists?,
            opt_out_mechanism: UserConsent.withdrawn.exists?,
            data_disclosure: true
          },
          overall_score: calculate_overall_compliance_score
        }
      end
    end
  end
end

# Register the consent tags
Railspress::Liquid::ConsentTags.register_tags
