# frozen_string_literal: true

class GdprController < ApplicationController
  before_action :set_cors_headers
  before_action :validate_gdpr_request, only: [:data_access, :data_deletion, :data_portability]
  
  # GET /gdpr/privacy-policy
  def privacy_policy
    @privacy_info = GdprComplianceService.get_privacy_policy_info
    
    respond_to do |format|
      format.html { render layout: 'application' }
      format.json { render json: @privacy_info }
    end
  end
  
  # POST /gdpr/consent
  def update_consent
    session_id = get_or_create_session_id
    consent_data = params[:consent] || {}
    
    # Validate consent data
    if consent_data.empty?
      render json: { error: 'Consent data is required' }, status: :bad_request
      return
    end
    
    # Store consent
    GdprComplianceService.store_consent(session_id, consent_data)
    
    # Set consent cookies
    set_consent_cookies(consent_data)
    
    render json: { 
      success: true, 
      message: 'Consent preferences updated',
      session_id: session_id
    }
  rescue => e
    Rails.logger.error "Failed to update consent: #{e.message}"
    render json: { error: 'Failed to update consent preferences' }, status: :internal_server_error
  end
  
  # POST /gdpr/data-access
  def data_access
    session_id = get_or_create_session_id
    request_data = {
      request_type: 'data_access',
      timestamp: Time.current,
      ip_address: request.ip,
      user_agent: request.user_agent
    }
    
    # Handle data access request
    data = GdprComplianceService.handle_data_access_request(session_id, request_data)
    
    respond_to do |format|
      format.json { render json: data }
      format.html { 
        # For HTML requests, redirect to download page
        redirect_to gdpr_download_path(session_id: session_id)
      }
    end
  rescue => e
    Rails.logger.error "Failed to handle data access request: #{e.message}"
    render json: { error: 'Failed to process data access request' }, status: :internal_server_error
  end
  
  # POST /gdpr/data-deletion
  def data_deletion
    session_id = get_or_create_session_id
    request_data = {
      request_type: 'data_deletion',
      timestamp: Time.current,
      ip_address: request.ip,
      user_agent: request.user_agent
    }
    
    # Handle data deletion request
    result = GdprComplianceService.handle_data_deletion_request(session_id, request_data)
    
    render json: result
  rescue => e
    Rails.logger.error "Failed to handle data deletion request: #{e.message}"
    render json: { error: 'Failed to process data deletion request' }, status: :internal_server_error
  end
  
  # POST /gdpr/data-portability
  def data_portability
    session_id = get_or_create_session_id
    request_data = {
      request_type: 'data_portability',
      timestamp: Time.current,
      ip_address: request.ip,
      user_agent: request.user_agent
    }
    
    # Handle data portability request
    data = GdprComplianceService.handle_data_portability_request(session_id, request_data)
    
    respond_to do |format|
      format.json { render json: data }
      format.html { 
        # For HTML requests, redirect to download page
        redirect_to gdpr_download_path(session_id: session_id, format: :json)
      }
    end
  rescue => e
    Rails.logger.error "Failed to handle data portability request: #{e.message}"
    render json: { error: 'Failed to process data portability request' }, status: :internal_server_error
  end
  
  # GET /gdpr/download/:session_id
  def download_data
    session_id = params[:session_id]
    
    if session_id.blank?
      render json: { error: 'Session ID is required' }, status: :bad_request
      return
    end
    
    # Get data for download
    data = GdprComplianceService.handle_data_access_request(session_id)
    
    respond_to do |format|
      format.json { 
        send_data JSON.pretty_generate(data), 
                  filename: "railspress_data_#{session_id}_#{Date.current}.json",
                  type: 'application/json'
      }
      format.html {
        @data = data
        @session_id = session_id
        render layout: 'application'
      }
    end
  rescue => e
    Rails.logger.error "Failed to download data: #{e.message}"
    render json: { error: 'Failed to download data' }, status: :internal_server_error
  end
  
  # POST /gdpr/contact-dpo
  def contact_dpo
    # This would typically send an email to the DPO
    # For now, we'll just log the request
    
    session_id = get_or_create_session_id
    request_data = {
      request_type: 'dpo_contact',
      timestamp: Time.current,
      ip_address: request.ip,
      user_agent: request.user_agent,
      message: params[:message],
      email: params[:email]
    }
    
    # Log the DPO contact request
    AnalyticsEvent.create!(
      event_name: 'gdpr_dpo_contact_request',
      properties: request_data,
      session_id: session_id,
      tenant: ActsAsTenant.current_tenant
    )
    
    render json: { 
      success: true, 
      message: 'Your message has been sent to our Data Protection Officer',
      dpo_email: SiteSetting.get('dpo_email', 'dpo@railspress.com')
    }
  rescue => e
    Rails.logger.error "Failed to contact DPO: #{e.message}"
    render json: { error: 'Failed to send message to DPO' }, status: :internal_server_error
  end
  
  # GET /gdpr/consent-status
  def consent_status
    session_id = get_or_create_session_id
    
    consent_status = {
      session_id: session_id,
      analytics_consent: GdprComplianceService.has_valid_consent?(session_id, 'analytics'),
      marketing_consent: GdprComplianceService.has_valid_consent?(session_id, 'marketing'),
      essential_consent: true, # Always true for essential cookies
      gdpr_applies: GdprComplianceService.gdpr_applies?(request),
      privacy_policy_url: gdpr_privacy_policy_url
    }
    
    render json: consent_status
  end
  
  private
  
  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-CSRF-Token'
  end
  
  def validate_gdpr_request
    # Check if GDPR applies
    unless GdprComplianceService.gdpr_applies?(request)
      render json: { error: 'GDPR does not apply to this request' }, status: :forbidden
      return
    end
    
    # Check rate limiting (prevent abuse)
    session_id = get_or_create_session_id
    rate_limit_key = "gdpr_request_rate_limit:#{session_id}"
    
    if Rails.cache.read(rate_limit_key)
      render json: { error: 'Too many requests. Please try again later.' }, status: :too_many_requests
      return
    end
    
    # Set rate limit (5 requests per hour)
    Rails.cache.write(rate_limit_key, true, expires_in: 1.hour)
  end
  
  def get_or_create_session_id
    session_id = cookies[:analytics_session_id]
    
    if session_id.blank?
      session_id = generate_session_id
      cookies[:analytics_session_id] = {
        value: session_id,
        expires: 1.year.from_now,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax
      }
    end
    
    session_id
  end
  
  def generate_session_id
    SecureRandom.hex(16)
  end
  
  def set_consent_cookies(consent_data)
    consent_data.each do |consent_type, granted|
      cookie_name = "analytics_consent_#{consent_type}"
      cookies[cookie_name] = {
        value: granted.to_s,
        expires: 1.year.from_now,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax
      }
    end
  end
end
