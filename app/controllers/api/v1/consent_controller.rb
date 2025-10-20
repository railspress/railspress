class Api::V1::ConsentController < Api::V1::BaseController
  before_action :authenticate_user!, only: [:create, :update, :withdraw]
  before_action :set_consent_configuration, only: [:configuration, :region]
  
  # GET /api/v1/consent/configuration
  def configuration
    render json: {
      consent_categories_with_defaults: @consent_config.consent_categories_with_defaults,
      banner_settings_with_defaults: @consent_config.banner_settings_with_defaults,
      geolocation_settings_with_defaults: @consent_config.geolocation_settings_with_defaults,
      pixel_consent_mapping_with_defaults: @consent_config.pixel_consent_mapping_with_defaults,
      version: @consent_config.version || '1.0'
    }
  end
  
  # GET /api/v1/consent/region
  def region
    user_ip = request.remote_ip || request.env['HTTP_X_FORWARDED_FOR']&.split(',')&.first
    
    begin
      detected_region = @consent_config.get_region_from_ip(user_ip)
      
      render json: {
        region: detected_region,
        ip: user_ip,
        timestamp: Time.current.iso8601
      }
    rescue => e
      Rails.logger.error "Region detection error: #{e.message}"
      render json: {
        region: 'unknown',
        ip: user_ip,
        timestamp: Time.current.iso8601,
        error: 'Region detection failed'
      }
    end
  end
  
  # POST /api/v1/consent
  def create
    consent_params = params.require(:consent).permit!
    region = params[:region]
    timestamp = params[:timestamp]
    
    begin
      # Save consent for each category
      saved_consents = []
      
      consent_params.each do |category, consent_data|
        next unless consent_data[:granted]
        
        # Find or create user consent
        user_consent = current_user.user_consents.find_or_initialize_by(
          consent_type: category
        )
        
        user_consent.assign_attributes(
          consent_text: consent_data[:consent_text],
          ip_address: consent_data[:ip_address],
          user_agent: consent_data[:user_agent],
          granted: true,
          granted_at: Time.parse(consent_data[:granted_at]),
          withdrawn_at: nil,
          details: {
            region: region,
            timestamp: timestamp,
            consent_version: @consent_config.version || '1.0'
          }
        )
        
        user_consent.save!
        saved_consents << user_consent
      end
      
      # Log consent event
      log_consent_event('consent_granted', {
        user_id: current_user.id,
        consents: saved_consents.map(&:consent_type),
        region: region,
        timestamp: timestamp
      })
      
      render json: {
        success: true,
        message: 'Consent saved successfully',
        consents: saved_consents.map do |consent|
          {
            type: consent.consent_type,
            granted: consent.granted,
            granted_at: consent.granted_at
          }
        end
      }
      
    rescue => e
      Rails.logger.error "Consent save error: #{e.message}"
      render json: {
        success: false,
        error: 'Failed to save consent'
      }, status: :unprocessable_entity
    end
  end
  
  # PATCH /api/v1/consent
  def update
    consent_params = params.require(:consent).permit!
    region = params[:region]
    timestamp = params[:timestamp]
    
    begin
      # Update existing consents
      updated_consents = []
      
      consent_params.each do |category, consent_data|
        user_consent = current_user.user_consents.find_by(consent_type: category)
        next unless user_consent
        
        if consent_data[:granted]
          user_consent.update!(
            granted: true,
            granted_at: Time.parse(consent_data[:granted_at]),
            withdrawn_at: nil,
            details: user_consent.details.merge({
              region: region,
              timestamp: timestamp,
              consent_version: @consent_config.version || '1.0'
            })
          )
        else
          user_consent.withdraw!
        end
        
        updated_consents << user_consent
      end
      
      # Log consent update event
      log_consent_event('consent_updated', {
        user_id: current_user.id,
        consents: updated_consents.map(&:consent_type),
        region: region,
        timestamp: timestamp
      })
      
      render json: {
        success: true,
        message: 'Consent updated successfully',
        consents: updated_consents.map do |consent|
          {
            type: consent.consent_type,
            granted: consent.granted,
            granted_at: consent.granted_at,
            withdrawn_at: consent.withdrawn_at
          }
        end
      }
      
    rescue => e
      Rails.logger.error "Consent update error: #{e.message}"
      render json: {
        success: false,
        error: 'Failed to update consent'
      }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/consent/:consent_type
  def withdraw
    consent_type = params[:consent_type]
    
    begin
      user_consent = current_user.user_consents.find_by(consent_type: consent_type)
      
      if user_consent
        user_consent.withdraw!
        
        # Log consent withdrawal event
        log_consent_event('consent_withdrawn', {
          user_id: current_user.id,
          consent_type: consent_type,
          timestamp: Time.current.iso8601
        })
        
        render json: {
          success: true,
          message: 'Consent withdrawn successfully'
        }
      else
        render json: {
          success: false,
          error: 'Consent not found'
        }, status: :not_found
      end
      
    rescue => e
      Rails.logger.error "Consent withdrawal error: #{e.message}"
      render json: {
        success: false,
        error: 'Failed to withdraw consent'
      }, status: :unprocessable_entity
    end
  end
  
  # GET /api/v1/consent/status
  def status
    if user_signed_in?
      consents = current_user.user_consents.includes(:user)
      
      render json: {
        user_id: current_user.id,
        consents: consents.map do |consent|
          {
            type: consent.consent_type,
            granted: consent.granted?,
            granted_at: consent.granted_at,
            withdrawn_at: consent.withdrawn_at,
            details: consent.details
          }
        end,
        timestamp: Time.current.iso8601
      }
    else
      render json: {
        user_id: nil,
        consents: [],
        timestamp: Time.current.iso8601
      }
    end
  end
  
  # GET /api/v1/consent/pixels
  def pixels
    # Get all active pixels with consent requirements
    pixels = Pixel.active.includes(:tenant)
    
    pixel_data = pixels.map do |pixel|
      required_consent = @consent_config.get_consent_categories_for_pixel(pixel.pixel_type)
      
      {
        id: pixel.id,
        name: pixel.name,
        pixel_type: pixel.pixel_type,
        pixel_id: pixel.pixel_id,
        position: pixel.position,
        required_consent: required_consent,
        consent_required: @consent_config.is_pixel_consent_required?(pixel.pixel_type)
      }
    end
    
    render json: {
      pixels: pixel_data,
      timestamp: Time.current.iso8601
    }
  end
  
  private
  
  def set_consent_configuration
    @consent_config = ConsentConfiguration.active.first
    
    unless @consent_config
      render json: {
        error: 'No active consent configuration found'
      }, status: :not_found
    end
  end
  
  def log_consent_event(event_type, data)
    # Log to analytics if available
    if defined?(AnalyticsEvent)
      AnalyticsEvent.create!(
        event_type: event_type,
        user_id: data[:user_id],
        properties: data,
        timestamp: Time.current
      )
    end
    
    # Log to Rails logger
    Rails.logger.info "Consent Event: #{event_type} - #{data}"
  end
end
