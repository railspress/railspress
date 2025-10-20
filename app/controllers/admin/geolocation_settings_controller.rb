class Admin::GeolocationSettingsController < Admin::BaseController
  before_action :load_geolocation_settings

  def show
    @geolocation_service = GeolocationService.instance
    @maxmind_updater = MaxmindUpdaterService.instance
    @database_info = @maxmind_updater.database_info
    @pronviders = GeolocationService::PROVIDERS
  end

  def update
    begin
      # Update geolocation settings
      geolocation_params.each do |key, value|
        SiteSetting.set(key, value)
      end

      # Handle MaxMind database updates
      if params[:update_databases].present?
        results = @maxmind_updater.update_all_databases
        flash[:notice] = "Geolocation settings updated. Database update results: #{format_update_results(results)}"
      else
        flash[:notice] = "Geolocation settings updated successfully"
      end

      redirect_to admin_geolocation_settings_path
    rescue => e
      flash[:alert] = "Failed to update settings: #{e.message}"
      redirect_to admin_geolocation_settings_path
    end
  end

  def test_lookup
    ip_address = params[:test_ip] || '8.8.8.8'
    result = @geolocation_service.test_lookup(ip_address)
    
    render json: result
  end

  def update_maxmind
    type = params[:type] || 'country'
    result = @maxmind_updater.update_database(type)
    
    render json: result
  end

  def test_connection
    result = @maxmind_updater.test_connection
    render json: result
  end

  def schedule_auto_update
    result = @maxmind_updater.schedule_auto_update
    render json: result
  end

  private

  def load_geolocation_settings
    @settings = {
      # Geolocation provider settings
      geolocation_provider: SiteSetting.get('geolocation_provider', 'maxmind'),
      geolocation_enabled: SiteSetting.get('geolocation_enabled', false),
      
      # MaxMind settings
      maxmind_license_key: SiteSetting.get('maxmind_license_key', ''),
      maxmind_auto_update: SiteSetting.get('maxmind_auto_update', false),
      maxmind_auto_update_frequency: SiteSetting.get('maxmind_auto_update_frequency', 'weekly'),
      
      # IP-API settings
      geolocation_ipapi_enabled: SiteSetting.get('geolocation_ipapi_enabled', false),
      
      # IPInfo settings
      geolocation_ipinfo_enabled: SiteSetting.get('geolocation_ipinfo_enabled', false),
      geolocation_ipinfo_api_key: SiteSetting.get('geolocation_ipinfo_api_key', ''),
      
      # IP Geolocation settings
      geolocation_ipgeolocation_enabled: SiteSetting.get('geolocation_ipgeolocation_enabled', false),
      geolocation_ipgeolocation_api_key: SiteSetting.get('geolocation_ipgeolocation_api_key', ''),
      
      # Abstract API settings
      geolocation_abstract_enabled: SiteSetting.get('geolocation_abstract_enabled', false),
      geolocation_abstract_api_key: SiteSetting.get('geolocation_abstract_api_key', ''),
      
      # Privacy settings (GDPR-friendly defaults)
      geolocation_anonymize_ip: SiteSetting.get('geolocation_anonymize_ip', true),
      geolocation_store_full_ip: SiteSetting.get('geolocation_store_full_ip', false),
      geolocation_require_consent: SiteSetting.get('geolocation_require_consent', true),
      geolocation_consent_message: SiteSetting.get('geolocation_consent_message', ''),
      geolocation_legal_basis: SiteSetting.get('geolocation_legal_basis', 'consent'),
      geolocation_data_retention_days: SiteSetting.get('geolocation_data_retention_days', 90),
      geolocation_auto_delete: SiteSetting.get('geolocation_auto_delete', true),
      
      # Data collection controls (GDPR-friendly defaults)
      geolocation_collect_country: SiteSetting.get('geolocation_collect_country', true),
      geolocation_collect_region: SiteSetting.get('geolocation_collect_region', false),
      geolocation_collect_city: SiteSetting.get('geolocation_collect_city', false),
      geolocation_collect_coordinates: SiteSetting.get('geolocation_collect_coordinates', false),
      
      # Power user settings (disabled by default)
      geolocation_full_power_mode: SiteSetting.get('geolocation_full_power_mode', false),
      geolocation_debug_mode: SiteSetting.get('geolocation_debug_mode', false),
      geolocation_precision_mode: SiteSetting.get('geolocation_precision_mode', false),
      
      # Fallback settings
      geolocation_fallback_enabled: SiteSetting.get('geolocation_fallback_enabled', true),
      geolocation_cache_duration: SiteSetting.get('geolocation_cache_duration', 24) # hours
    }
  end

  def geolocation_params
    params.require(:settings).permit(
      :geolocation_provider,
      :geolocation_enabled,
      :maxmind_license_key,
      :maxmind_auto_update,
      :maxmind_auto_update_frequency,
      :geolocation_ipapi_enabled,
      :geolocation_ipinfo_enabled,
      :geolocation_ipinfo_api_key,
      :geolocation_ipgeolocation_enabled,
      :geolocation_ipgeolocation_api_key,
      :geolocation_abstract_enabled,
      :geolocation_abstract_api_key,
      :geolocation_anonymize_ip,
      :geolocation_store_full_ip,
      :geolocation_require_consent,
      :geolocation_consent_message,
      :geolocation_legal_basis,
      :geolocation_data_retention_days,
      :geolocation_auto_delete,
      :geolocation_collect_country,
      :geolocation_collect_region,
      :geolocation_collect_city,
      :geolocation_collect_coordinates,
      :geolocation_full_power_mode,
      :geolocation_debug_mode,
      :geolocation_precision_mode,
      :geolocation_fallback_enabled,
      :geolocation_cache_duration
    )
  end

  def format_update_results(results)
    messages = []
    results.each do |type, result|
      status = result[:success] ? '✓' : '✗'
      messages << "#{status} #{type.capitalize}: #{result[:message]}"
    end
    messages.join(', ')
  end
  
  # POST /admin/settings/geolocation/schedule_auto_update
  def schedule_auto_update
    frequency = params[:frequency] || 'weekly'
    
    begin
      MaxmindUpdaterService.schedule_auto_update(frequency)
      redirect_to admin_geolocation_settings_path, notice: "MaxMind auto-update scheduled for #{frequency} updates."
    rescue => e
      redirect_to admin_geolocation_settings_path, alert: "Failed to schedule auto-update: #{e.message}"
    end
  end
  
  # DELETE /admin/settings/geolocation/disable_auto_update
  def disable_auto_update
    begin
      MaxmindUpdaterService.disable_auto_update
      redirect_to admin_geolocation_settings_path, notice: "MaxMind auto-update disabled."
    rescue => e
      redirect_to admin_geolocation_settings_path, alert: "Failed to disable auto-update: #{e.message}"
    end
  end
  
  # GET /admin/settings/geolocation/schedule_status
  def schedule_status
    schedule_info = MaxmindUpdaterService.get_update_schedule_info
    
    render json: {
      enabled: schedule_info[:enabled],
      frequency: schedule_info[:frequency],
      next_run: schedule_info[:next_run]&.strftime('%Y-%m-%d %H:%M:%S'),
      last_run: schedule_info[:last_run]&.strftime('%Y-%m-%d %H:%M:%S'),
      cron_schedule: schedule_info[:cron_schedule]
    }
  end
end
