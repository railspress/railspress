class GeolocationService
  include Singleton

  PROVIDERS = {
    'maxmind' => 'MaxMind GeoLite2 Database',
    'ipapi' => 'IP-API.com (Free)',
    'ipinfo' => 'IPInfo.io (Free tier)',
    'ipgeolocation' => 'IP Geolocation API',
    'abstract' => 'Abstract API'
  }.freeze

  def initialize
    @provider = SiteSetting.get('geolocation_provider', 'maxmind')
    @maxmind_db_path = Rails.root.join('db', 'maxmind', 'GeoLite2-Country.mmdb')
    @maxmind_city_db_path = Rails.root.join('db', 'maxmind', 'GeoLite2-City.mmdb')
  end

  def lookup_ip(ip_address)
    return nil if ip_address.blank? || private_ip?(ip_address)
    
    # Check if geolocation is enabled (disabled by default for GDPR compliance)
    return nil unless SiteSetting.get('geolocation_enabled', false)
    
    # Check if user has consented (if consent is required)
    if SiteSetting.get('geolocation_require_consent', true)
      # This would need to be implemented based on your consent system
      # For now, we'll assume consent is given if geolocation is enabled
    end
    
    # Anonymize IP if required
    processed_ip = ip_address
    if SiteSetting.get('geolocation_anonymize_ip', true) && !SiteSetting.get('geolocation_full_power_mode', false)
      processed_ip = anonymize_ip(ip_address)
    end
    
    case @provider
    when 'maxmind'
      maxmind_lookup(processed_ip)
    when 'ipapi'
      ipapi_lookup(processed_ip)
    when 'ipinfo'
      ipinfo_lookup(processed_ip)
    when 'ipgeolocation'
      ipgeolocation_lookup(processed_ip)
    when 'abstract'
      abstract_lookup(processed_ip)
    else
      maxmind_lookup(processed_ip) # fallback to MaxMind
    end
  rescue => e
    Rails.logger.error "Geolocation lookup failed for #{ip_address}: #{e.message}"
    nil
  end

  def maxmind_lookup(ip_address)
    return nil unless maxmind_available?
    
    begin
      # Try City database first for more detailed info
      if File.exist?(@maxmind_city_db_path)
        db = MaxMindDB.new(@maxmind_city_db_path.to_s)
        result = db.lookup(ip_address)
        
        if result.found?
          city_record = result.record
          return {
            country_code: city_record.country.iso_code,
            country_name: city_record.country.names['en'],
            city: city_record.city.names['en'],
            region: city_record.subdivisions&.first&.names&.dig('en'),
            latitude: city_record.location.latitude,
            longitude: city_record.location.longitude,
            timezone: city_record.location.time_zone,
            accuracy_radius: city_record.location.accuracy_radius,
            provider: 'maxmind_city'
          }
        end
      end

      # Fallback to Country database
      if File.exist?(@maxmind_db_path)
        db = MaxMindDB.new(@maxmind_db_path.to_s)
        result = db.lookup(ip_address)
        
        if result.found?
          country_record = result.record
          return {
            country_code: country_record.country.iso_code,
            country_name: country_record.country.names['en'],
            provider: 'maxmind_country'
          }
        end
      end
    rescue => e
      Rails.logger.error "MaxMind lookup failed: #{e.message}"
    end
    
    nil
  end

  def ipapi_lookup(ip_address)
    return nil unless SiteSetting.get('geolocation_ipapi_enabled', false)
    
    begin
      response = HTTP.timeout(5).get("http://ip-api.com/json/#{ip_address}")
      data = JSON.parse(response.body.to_s)
      
      if data['status'] == 'success'
        {
          country_code: data['countryCode'],
          country_name: data['country'],
          city: data['city'],
          region: data['regionName'],
          latitude: data['lat'],
          longitude: data['lon'],
          timezone: data['timezone'],
          isp: data['isp'],
          org: data['org'],
          provider: 'ipapi'
        }
      end
    rescue => e
      Rails.logger.error "IP-API lookup failed: #{e.message}"
    end
    
    nil
  end

  def ipinfo_lookup(ip_address)
    return nil unless SiteSetting.get('geolocation_ipinfo_enabled', false)
    
    api_key = SiteSetting.get('geolocation_ipinfo_api_key', '')
    return nil if api_key.blank?
    
    begin
      url = "https://ipinfo.io/#{ip_address}/json"
      url += "?token=#{api_key}" if api_key.present?
      
      response = HTTP.timeout(5).get(url)
      data = JSON.parse(response.body.to_s)
      
      unless data['error']
        lat_lng = data['loc']&.split(',')
        {
          country_code: data['country'],
          country_name: country_name_from_code(data['country']),
          city: data['city'],
          region: data['region'],
          latitude: lat_lng&.first&.to_f,
          longitude: lat_lng&.last&.to_f,
          timezone: data['timezone'],
          isp: data['org'],
          provider: 'ipinfo'
        }
      end
    rescue => e
      Rails.logger.error "IPInfo lookup failed: #{e.message}"
    end
    
    nil
  end

  def ipgeolocation_lookup(ip_address)
    return nil unless SiteSetting.get('geolocation_ipgeolocation_enabled', false)
    
    api_key = SiteSetting.get('geolocation_ipgeolocation_api_key', '')
    return nil if api_key.blank?
    
    begin
      response = HTTP.timeout(5).get("https://api.ipgeolocation.io/ipgeo", params: {
        apiKey: api_key,
        ip: ip_address
      })
      data = JSON.parse(response.body.to_s)
      
      {
        country_code: data['country_code2'],
        country_name: data['country_name'],
        city: data['city'],
        region: data['state_prov'],
        latitude: data['latitude']&.to_f,
        longitude: data['longitude']&.to_f,
        timezone: data['time_zone']&.dig('name'),
        isp: data['isp'],
        provider: 'ipgeolocation'
      }
    rescue => e
      Rails.logger.error "IP Geolocation lookup failed: #{e.message}"
    end
    
    nil
  end

  def abstract_lookup(ip_address)
    return nil unless SiteSetting.get('geolocation_abstract_enabled', false)
    
    api_key = SiteSetting.get('geolocation_abstract_api_key', '')
    return nil if api_key.blank?
    
    begin
      response = HTTP.timeout(5).get("https://ipgeolocation.abstractapi.com/v1/", params: {
        api_key: api_key,
        ip_address: ip_address
      })
      data = JSON.parse(response.body.to_s)
      
      {
        country_code: data['country_code'],
        country_name: data['country'],
        city: data['city'],
        region: data['region'],
        latitude: data['latitude']&.to_f,
        longitude: data['longitude']&.to_f,
        timezone: data['timezone']&.dig('name'),
        provider: 'abstract'
      }
    rescue => e
      Rails.logger.error "Abstract API lookup failed: #{e.message}"
    end
    
    nil
  end

  def maxmind_available?
    File.exist?(@maxmind_db_path) || File.exist?(@maxmind_city_db_path)
  end

  def maxmind_database_info
    info = {}
    
    if File.exist?(@maxmind_db_path)
      stat = File.stat(@maxmind_db_path)
      info[:country_db] = {
        path: @maxmind_db_path,
        size: stat.size,
        modified: stat.mtime,
        available: true
      }
    end
    
    if File.exist?(@maxmind_city_db_path)
      stat = File.stat(@maxmind_city_db_path)
      info[:city_db] = {
        path: @maxmind_city_db_path,
        size: stat.size,
        modified: stat.mtime,
        available: true
      }
    end
    
    info
  end

  def test_lookup(ip_address = '8.8.8.8')
    result = lookup_ip(ip_address)
    
    if result
      {
        success: true,
        data: result,
        provider: result[:provider],
        message: "Successfully resolved #{ip_address}"
      }
    else
      {
        success: false,
        message: "Failed to resolve #{ip_address} with provider #{@provider}"
      }
    end
  end

  private

  def private_ip?(ip_address)
    ip = IPAddr.new(ip_address)
    ip.private? || ip.loopback? || ip.link_local?
  rescue
    true # treat invalid IPs as private
  end

  def anonymize_ip(ip_address)
    # Anonymize IP by zeroing out the last octet for IPv4 or last 80 bits for IPv6
    begin
      ip = IPAddr.new(ip_address)
      if ip.ipv4?
        # Zero out the last octet for IPv4
        parts = ip_address.split('.')
        parts[3] = '0'
        parts.join('.')
      elsif ip.ipv6?
        # Zero out the last 80 bits for IPv6 (last 10 hex characters)
        ip_str = ip.to_s
        if ip_str.include?('::')
          # Handle compressed IPv6 addresses
          ip_str.gsub(/::[^:]*$/, '::')
        else
          # Handle full IPv6 addresses
          parts = ip_str.split(':')
          parts[-1] = '0000'
          parts.join(':')
        end
      else
        ip_address
      end
    rescue
      ip_address # return original if anonymization fails
    end
  end

  def filter_geolocation_data(data)
    # Filter data based on GDPR settings
    filtered_data = {}
    
    # Always include country if enabled
    if SiteSetting.get('geolocation_collect_country', true) && data[:country_code]
      filtered_data[:country_code] = data[:country_code]
      filtered_data[:country_name] = data[:country_name]
    end
    
    # Include region if enabled
    if SiteSetting.get('geolocation_collect_region', false) && data[:region]
      filtered_data[:region] = data[:region]
    end
    
    # Include city if enabled
    if SiteSetting.get('geolocation_collect_city', false) && data[:city]
      filtered_data[:city] = data[:city]
    end
    
    # Include coordinates if enabled
    if SiteSetting.get('geolocation_collect_coordinates', false) && data[:latitude] && data[:longitude]
      filtered_data[:latitude] = data[:latitude]
      filtered_data[:longitude] = data[:longitude]
    end
    
    # Include timezone if available
    filtered_data[:timezone] = data[:timezone] if data[:timezone]
    
    filtered_data
  end

  def country_name_from_code(code)
    # Simple country code to name mapping
    country_names = {
      'US' => 'United States',
      'GB' => 'United Kingdom',
      'CA' => 'Canada',
      'DE' => 'Germany',
      'FR' => 'France',
      'IT' => 'Italy',
      'ES' => 'Spain',
      'NL' => 'Netherlands',
      'AU' => 'Australia',
      'JP' => 'Japan',
      'CN' => 'China',
      'IN' => 'India',
      'BR' => 'Brazil',
      'RU' => 'Russia',
      'MX' => 'Mexico'
    }
    
    country_names[code] || code
  end
end
