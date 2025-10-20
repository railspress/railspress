# frozen_string_literal: true

class GdprComplianceService
  include ActiveSupport::Benchmarkable
  
  # Data subject rights under GDPR
  DATA_SUBJECT_RIGHTS = %w[
    right_to_be_informed
    right_of_access
    right_to_rectification
    right_to_erasure
    right_to_restrict_processing
    right_to_data_portability
    right_to_object
    rights_related_to_automated_decision_making
  ].freeze
  
  # Legal basis for processing under GDPR
  LEGAL_BASIS = %w[
    consent
    contract
    legal_obligation
    vital_interests
    public_task
    legitimate_interests
  ].freeze
  
  # Data categories we collect
  DATA_CATEGORIES = %w[
    identity_data
    contact_data
    technical_data
    usage_data
    marketing_data
    analytics_data
    geolocation_data
  ].freeze
  
  class << self
    # Check if GDPR applies to this request
    def gdpr_applies?(request)
      # GDPR applies to EU residents and EU data subjects
      eu_countries = %w[AT BE BG HR CY CZ DK EE FI FR DE GR HU IE IT LV LT LU MT NL PL PT RO SK SI ES SE]
      
      # Check if user is in EU based on IP geolocation
      country_code = get_country_from_request(request)
      eu_countries.include?(country_code)
    rescue
      # If we can't determine location, assume GDPR applies for safety
      true
    end
    
    # Get country code from request
    def get_country_from_request(request)
      # Try to get country from analytics data first
      session_id = request.session[:analytics_session_id]
      if session_id
        recent_pageview = Pageview.where(session_id: session_id)
                                 .where('visited_at >= ?', 1.hour.ago)
                                 .where.not(country_code: nil)
                                 .first
        return recent_pageview.country_code if recent_pageview
      end
      
      # Fallback to IP geolocation
      GeolocationService.lookup_ip(request.ip)&.dig(:country_code)
    rescue
      nil
    end
    
    # Check if user has given valid consent
    def has_valid_consent?(session_id, consent_type = 'analytics')
      return true unless SiteSetting.get('analytics_require_consent', true)
      
      # Check if consent is stored in session
      consent_key = "analytics_consent_#{consent_type}"
      Rails.cache.read("consent:#{session_id}:#{consent_key}") == true
    rescue
      false
    end
    
    # Store user consent
    def store_consent(session_id, consent_data)
      consent_data.each do |consent_type, granted|
        consent_key = "analytics_consent_#{consent_type}"
        Rails.cache.write("consent:#{session_id}:#{consent_key}", granted, expires_in: 1.year)
      end
      
      # Log consent for audit trail
      log_consent_event(session_id, consent_data)
    rescue => e
      Rails.logger.error "Failed to store consent: #{e.message}"
    end
    
    # Log consent event for audit trail
    def log_consent_event(session_id, consent_data)
      AnalyticsEvent.create!(
        event_name: 'gdpr_consent_updated',
        properties: {
          consent_data: consent_data,
          legal_basis: 'consent',
          data_categories: DATA_CATEGORIES,
          gdpr_compliant: true
        },
        session_id: session_id,
        tenant: ActsAsTenant.current_tenant || Tenant.first
      )
    rescue => e
      Rails.logger.error "Failed to log consent event: #{e.message}"
    end
    
    # Handle data subject access request
    def handle_data_access_request(session_id, request_data = {})
      # Collect all data related to this session/user
      data = {
        pageviews: collect_pageview_data(session_id),
        events: collect_event_data(session_id),
        consent_history: collect_consent_history(session_id),
        metadata: {
          request_date: Time.current,
          data_categories: DATA_CATEGORIES,
          retention_period: SiteSetting.get('analytics_data_retention_days', 365),
          legal_basis: 'consent'
        }
      }
      
      # Log the access request
      log_data_subject_request(session_id, 'access', request_data)
      
      data
    rescue => e
      Rails.logger.error "Failed to handle data access request: #{e.message}"
      { error: e.message }
    end
    
    # Handle data deletion request
    def handle_data_deletion_request(session_id, request_data = {})
      deleted_count = 0
      
      # Delete pageviews
      pageview_count = Pageview.where(session_id: session_id).count
      Pageview.where(session_id: session_id).delete_all
      deleted_count += pageview_count
      
      # Delete analytics events
      event_count = AnalyticsEvent.where(session_id: session_id).count
      AnalyticsEvent.where(session_id: session_id).delete_all
      deleted_count += event_count
      
      # Clear consent data
      clear_consent_data(session_id)
      
      # Log the deletion request
      log_data_subject_request(session_id, 'deletion', request_data.merge(deleted_records: deleted_count))
      
      { deleted_records: deleted_count, success: true }
    rescue => e
      Rails.logger.error "Failed to handle data deletion request: #{e.message}"
      { error: e.message }
    end
    
    # Handle data portability request
    def handle_data_portability_request(session_id, request_data = {})
      # Collect data in portable format
      data = handle_data_access_request(session_id, request_data)
      
      # Convert to JSON format for portability
      portable_data = {
        export_date: Time.current.iso8601,
        data_subject_id: session_id,
        data_categories: DATA_CATEGORIES,
        legal_basis: 'consent',
        data: data
      }
      
      # Log the portability request
      log_data_subject_request(session_id, 'portability', request_data)
      
      portable_data
    rescue => e
      Rails.logger.error "Failed to handle data portability request: #{e.message}"
      { error: e.message }
    end
    
    # Collect pageview data for data subject
    def collect_pageview_data(session_id)
      Pageview.where(session_id: session_id).map do |pageview|
        {
          id: pageview.id,
          path: pageview.path,
          title: pageview.title,
          visited_at: pageview.visited_at.iso8601,
          referrer: pageview.referrer,
          user_agent: pageview.user_agent,
          country: pageview.country_name,
          city: pageview.city,
          device: pageview.device,
          browser: pageview.browser,
          reading_time: pageview.reading_time,
          engagement_score: pageview.engagement_score,
          is_reader: pageview.is_reader
        }
      end
    end
    
    # Collect event data for data subject
    def collect_event_data(session_id)
      AnalyticsEvent.where(session_id: session_id).map do |event|
        {
          id: event.id,
          event_name: event.event_name,
          properties: event.properties,
          created_at: event.created_at.iso8601
        }
      end
    end
    
    # Collect consent history for data subject
    def collect_consent_history(session_id)
      # Get consent events from analytics
      consent_events = AnalyticsEvent.where(session_id: session_id)
                                   .where(event_name: 'gdpr_arnalytics_consent_updated')
                                   .order(:created_at)
      
      consent_events.map do |event|
        {
          event_id: event.id,
          consent_data: event.properties['consent_data'],
          timestamp: event.created_at.iso8601,
          legal_basis: event.properties['legal_basis']
        }
      end
    end
    
    # Clear consent data for data subject
    def clear_consent_data(session_id)
      # Clear all consent cache entries
      consent_types = %w[analytics marketing essential]
      consent_types.each do |consent_type|
        consent_key = "analytics_consent_#{consent_type}"
        Rails.cache.delete("consent:#{session_id}:#{consent_key}")
      end
    end
    
    # Log data subject request for audit trail
    def log_data_subject_request(session_id, request_type, request_data)
      AnalyticsEvent.create!(
        event_name: "gdpr_data_subject_request_#{request_type}",
        properties: {
          request_type: request_type,
          request_data: request_data,
          legal_basis: 'legal_obligation',
          gdpr_compliant: true,
          data_categories: DATA_CATEGORIES
        },
        session_id: session_id,
        tenant: ActsAsTenant.current_tenant
      )
    rescue => e
      Rails.logger.error "Failed to log data subject request: #{e.message}"
    end
    
    # Check if data processing is lawful
    def is_processing_lawful?(purpose, legal_basis, consent_given = false)
      case legal_basis
      when 'consent'
        consent_given
      when 'legitimate_interests'
        legitimate_interests_assessment(purpose)
      when 'contract'
        contract_processing_assessment(purpose)
      when 'legal_obligation'
        legal_obligation_assessment(purpose)
      else
        false
      end
    end
    
    # Assess legitimate interests
    def legitimate_interests_assessment(purpose)
      legitimate_purposes = %w[
        analytics
        security
        fraud_prevention
        service_improvement
        performance_monitoring
      ]
      
      legitimate_purposes.include?(purpose)
    end
    
    # Assess contract processing
    def contract_processing_assessment(purpose)
      contract_purposes = %w[
        user_authentication
        service_delivery
        payment_processing
        account_management
      ]
      
      contract_purposes.include?(purpose)
    end
    
    # Assess legal obligation
    def legal_obligation_assessment(purpose)
      legal_purposes = %w[
        tax_compliance
        audit_requirements
        regulatory_reporting
        law_enforcement
      ]
      
      legal_purposes.include?(purpose)
    end
    
    # Get privacy policy information
    def get_privacy_policy_info
      {
        data_controller: SiteSetting.get('data_controller_name', 'RailsPress'),
        data_controller_email: SiteSetting.get('data_controller_email', 'privacy@railspress.com'),
        dpo_email: SiteSetting.get('dpo_email', 'dpo@railspress.com'),
        data_categories: DATA_CATEGORIES,
        legal_basis: 'consent',
        retention_period: SiteSetting.get('analytics_data_retention_days', 365),
        data_subject_rights: DATA_SUBJECT_RIGHTS,
        third_party_sharing: get_third_party_sharing_info,
        data_transfers: get_data_transfer_info
      }
    rescue => e
      Rails.logger.error "Failed to get privacy policy info: #{e.message}"
      {
        data_controller: 'RailsPress',
        data_controller_email: 'privacy@railspress.com',
        dpo_email: 'dpo@railspress.com',
        data_categories: DATA_CATEGORIES,
        legal_basis: 'consent',
        retention_period: 365,
        data_subject_rights: DATA_SUBJECT_RIGHTS,
        third_party_sharing: {},
        data_transfers: {}
      }
    end
    
    # Get third party sharing information
    def get_third_party_sharing_info
      {
        google_analytics: {
          purpose: 'analytics',
          data_categories: %w[usage_data technical_data],
          legal_basis: 'consent',
          retention_period: 26 # months
        },
        maxmind: {
          purpose: 'geolocation',
          data_categories: %w[technical_data geolocation_data],
          legal_basis: 'legitimate_interests',
          retention_period: 365 # days
        }
      }
    end
    
    # Get data transfer information
    def get_data_transfer_info
      {
        adequacy_decision: false,
        safeguards: %w[standard_contractual_clauses],
        transfers_to: %w[United_States],
        transfer_purpose: 'analytics_and_geolocation'
      }
    end
    
    # Perform data protection impact assessment
    def perform_dpia(processing_activity)
      {
        processing_activity: processing_activity,
        risk_level: assess_risk_level(processing_activity),
        mitigation_measures: get_mitigation_measures(processing_activity),
        assessment_date: Time.current,
        assessor: 'RailsPress DPO'
      }
    end
    
    # Assess risk level
    def assess_risk_level(processing_activity)
      high_risk_activities = %w[
        large_scale_processing
        systematic_monitoring
        special_category_data
        automated_decision_making
      ]
      
      if high_risk_activities.any? { |activity| processing_activity.include?(activity) }
        'high'
      else
        'medium'
      end
    end
    
    # Get mitigation measures
    def get_mitigation_measures(processing_activity)
      measures = [
        'data_minimization',
        'purpose_limitation',
        'storage_limitation',
        'technical_and_organizational_measures',
        'privacy_by_design',
        'data_protection_by_default'
      ]
      
      if processing_activity.include?('large_scale_processing')
        measures += ['data_protection_impact_assessment', 'prior_consultation']
      end
      
      measures
    end
    
    # Check if processing is necessary and proportionate
    def is_processing_necessary_and_proportionate?(purpose, data_categories, legal_basis)
      # Check necessity
      necessary = is_processing_necessary?(purpose, data_categories)
      
      # Check proportionality
      proportionate = is_processing_proportionate?(purpose, data_categories, legal_basis)
      
      necessary && proportionate
    end
    
    # Check if processing is necessary
    def is_processing_necessary?(purpose, data_categories)
      case purpose
      when 'analytics'
        data_categories.include?('usage_data') && data_categories.include?('technical_data')
      when 'geolocation'
        data_categories.include?('geolocation_data')
      when 'security'
        data_categories.include?('technical_data')
      else
        false
      end
    end
    
    # Check if processing is proportionate
    def is_processing_proportionate?(purpose, data_categories, legal_basis)
      # Check if we're collecting only what's needed
      case purpose
      when 'analytics'
        data_categories.size <= 3 && legal_basis == 'consent'
      when 'geolocation'
        data_categories.size <= 2 && legal_basis == 'legitimate_interests'
      else
        data_categories.size <= 1
      end
    end
  end
end
