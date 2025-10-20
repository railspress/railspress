# frozen_string_literal: true

class AnalyticsSecurityService
  # Advanced security measures for analytics data
  
  class << self
    # Encrypt sensitive analytics data
    def encrypt_sensitive_data(data, user_id = nil)
      return data unless data.is_a?(Hash)
      
      encrypted_data = data.dup
      
      # Encrypt PII fields
      sensitive_fields = %w[email phone name address ip_address user_agent]
      
      sensitive_fields.each do |field|
        if encrypted_data[field].present?
          encrypted_data[field] = encrypt_field(encrypted_data[field], user_id)
        end
      end
      
      # Encrypt nested PII
      if encrypted_data[:properties].is_a?(Hash)
        encrypted_data[:properties] = encrypt_sensitive_data(encrypted_data[:properties], user_id)
      end
      
      encrypted_data
    end
    
    # Decrypt sensitive analytics data (admin only)
    def decrypt_sensitive_data(encrypted_data, user_id = nil, admin_user = nil)
      return encrypted_data unless admin_user&.administrator?
      
      decrypted_data = encrypted_data.dup
      
      # Decrypt PII fields
      sensitive_fields = %w[email phone name address ip_address user_agent]
      
      sensitive_fields.each do |field|
        if decrypted_data[field].present? && is_encrypted?(decrypted_data[field])
          decrypted_data[field] = decrypt_field(decrypted_data[field], user_id)
        end
      end
      
      # Decrypt nested PII
      if decrypted_data[:properties].is_a?(Hash)
        decrypted_data[:properties] = decrypt_sensitive_data(decrypted_data[:properties], user_id, admin_user)
      end
      
      decrypted_data
    end
    
    # Anonymize IP addresses based on GDPR settings
    def anonymize_ip(ip_address, anonymization_level = :full)
      return nil if ip_address.blank?
      
      case anonymization_level
      when :full
        # Full anonymization - remove last octet
        parts = ip_address.split('.')
        parts[3] = '0' if parts.length == 4
        parts.join('.')
      when :partial
        # Partial anonymization - remove last two octets
        parts = ip_address.split('.')
        parts[2] = '0'
        parts[3] = '0' if parts.length == 4
        parts.join('.')
      when :none
        # No anonymization (only if GDPR consent given)
        ip_address
      else
        # Default to full anonymization
        anonymize_ip(ip_address, :full)
      end
    end
    
    # Hash user identifiers for privacy
    def hash_user_identifier(identifier, salt = nil)
      return nil if identifier.blank?
      
      salt ||= Rails.application.secrets.secret_key_base
      Digest::SHA256.hexdigest("#{identifier}#{salt}")
    end
    
    # Generate secure session IDs
    def generate_secure_session_id
      SecureRandom.hex(32)
    end
    
    # Validate analytics request authenticity
    def validate_request_authenticity(request)
      # Check for valid CSRF token
      return false unless valid_csrf_token?(request)
      
      # Check for suspicious patterns
      return false if suspicious_request?(request)
      
      # Check rate limiting
      return false if rate_limited?(request)
      
      true
    end
    
    # Implement data retention policies
    def apply_data_retention_policy(data_type, record_age)
      retention_days = get_retention_period(data_type)
      
      return false if retention_days.nil?
      
      record_age > retention_days.days
    end
    
    # Audit analytics data access
    def audit_data_access(user_id, data_type, action, admin_user = nil)
      audit_data = {
        user_id: user_id,
        data_type: data_type,
        action: action,
        admin_user_id: admin_user&.id,
        timestamp: Time.current,
        ip_address: anonymize_ip(get_current_ip),
        user_agent: get_current_user_agent
      }
      
      # Store audit log
      AnalyticsAuditLog.create!(audit_data)
      
      # Check for suspicious access patterns
      check_suspicious_access_patterns(user_id, data_type, action)
    end
    
    # Implement data masking for non-admin users
    def mask_sensitive_data(data, user_role = :user)
      return data if user_role == :admin
      
      masked_data = data.dup
      
      # Mask PII fields
      pii_fields = %w[email phone name address ip_address]
      pii_fields.each do |field|
        if masked_data[field].present?
          masked_data[field] = mask_field(masked_data[field])
        end
      end
      
      masked_data
    end
    
    # Implement data pseudonymization
    def pseudonymize_data(data, pseudonymization_key)
      return data unless data.is_a?(Hash)
      
      pseudonymized_data = data.dup
      
      # Pseudonymize identifiers
      identifier_fields = %w[user_id session_id device_id]
      identifier_fields.each do |field|
        if pseudonymized_data[field].present?
          pseudonymized_data[field] = hash_user_identifier(
            pseudonymized_data[field], 
            pseudonymization_key
          )
        end
      end
      
      pseudonymized_data
    end
    
    # Implement data minimization
    def minimize_data_collection(data, purpose)
      return data unless data.is_a?(Hash)
      
      # Define minimal data sets for different purposes
      minimal_sets = {
        analytics: %w[page_path timestamp device browser],
        marketing: %w[user_id preferences interests],
        security: %w[ip_address user_agent timestamp],
        performance: %w[page_load_time resource_metrics]
      }
      
      allowed_fields = minimal_sets[purpose.to_sym] || minimal_sets[:analytics]
      
      data.select { |key, _| allowed_fields.include?(key.to_s) }
    end
    
    # Implement consent management
    def manage_consent(user_id, consent_type, granted, purpose = nil)
      consent_data = {
        user_id: user_id,
        consent_type: consent_type,
        granted: granted,
        purpose: purpose,
        timestamp: Time.current,
        ip_address: anonymize_ip(get_current_ip),
        user_agent: get_current_user_agent
      }
      
      # Store consent record
      AnalyticsConsent.create!(consent_data)
      
      # Update user consent status
      update_user_consent_status(user_id, consent_type, granted)
      
      # Apply consent-based data processing
      apply_consent_based_processing(user_id, consent_type, granted)
    end
    
    # Implement data portability
    def export_user_data(user_id, format = :json)
      user_data = collect_user_data(user_id)
      
      case format
      when :json
        export_json_data(user_data)
      when :csv
        export_csv_data(user_data)
      when :xml
        export_xml_data(user_data)
      else
        export_json_data(user_data)
      end
    end
    
    # Implement right to be forgotten
    def delete_user_data(user_id, data_types = :all)
      deletion_log = {
        user_id: user_id,
        data_types: data_types,
        timestamp: Time.current,
        admin_user_id: get_current_admin_user&.id
      }
      
      case data_types
      when :all
        delete_all_user_data(user_id)
      when :analytics
        delete_analytics_data(user_id)
      when :personal
        delete_personal_data(user_id)
      else
        delete_specific_data_types(user_id, data_types)
      end
      
      # Log deletion
      AnalyticsDataDeletion.create!(deletion_log)
    end
    
    # Implement data breach detection
    def detect_data_breach(user_id = nil)
      breach_indicators = {
        unusual_access_patterns: detect_unusual_access_patterns(user_id),
        suspicious_requests: detect_suspicious_requests(user_id),
        data_exfiltration: detect_data_exfiltration(user_id),
        unauthorized_access: detect_unauthorized_access(user_id)
      }
      
      if breach_indicators.values.any?
        handle_potential_breach(user_id, breach_indicators)
      end
      
      breach_indicators
    end
    
    private
    
    def encrypt_field(value, user_id)
      return value if value.blank?
      
      key = generate_encryption_key(user_id)
      cipher = OpenSSL::Cipher.new('AES-256-GCM')
      cipher.encrypt
      cipher.key = key
      
      encrypted = cipher.update(value) + cipher.final
      "#{cipher.iv.unpack1('H*')}:#{encrypted.unpack1('H*')}"
    end
    
    def decrypt_field(encrypted_value, user_id)
      return encrypted_value unless is_encrypted?(encrypted_value)
      
      iv_hex, encrypted_hex = encrypted_value.split(':')
      return encrypted_value unless iv_hex && encrypted_hex
      
      key = generate_encryption_key(user_id)
      cipher = OpenSSL::Cipher.new('AES-256-GCM')
      cipher.decrypt
      cipher.key = key
      cipher.iv = [iv_hex].pack('H*')
      
      encrypted_data = [encrypted_hex].pack('H*')
      cipher.update(encrypted_data) + cipher.final
    rescue => e
      Rails.logger.error "Decryption failed: #{e.message}"
      encrypted_value
    end
    
    def is_encrypted?(value)
      value.is_a?(String) && value.include?(':') && value.length > 64
    end
    
    def generate_encryption_key(user_id)
      salt = Rails.application.secrets.secret_key_base
      Digest::SHA256.digest("#{user_id}#{salt}")
    end
    
    def valid_csrf_token?(request)
      # Implement CSRF validation
      true # Simplified for now
    end
    
    def suspicious_request?(request)
      # Check for suspicious patterns
      user_agent = request.user_agent.to_s.downcase
      
      # Block known bot patterns
      bot_patterns = %w[bot crawler spider scraper]
      return true if bot_patterns.any? { |pattern| user_agent.include?(pattern) }
      
      # Check for unusual request patterns
      ip_address = request.remote_ip
      request_count = Redis.current.get("request_count:#{ip_address}").to_i
      
      return true if request_count > 100 # Rate limit exceeded
      
      # Update request count
      Redis.current.incr("request_count:#{ip_address}")
      Redis.current.expire("request_count:#{ip_address}", 1.hour.to_i)
      
      false
    end
    
    def rate_limited?(request)
      ip_address = request.remote_ip
      key = "rate_limit:#{ip_address}:#{Time.current.to_i / 60}"
      
      current_count = Redis.current.get(key).to_i
      return true if current_count >= 60 # 60 requests per minute
      
      Redis.current.incr(key)
      Redis.current.expire(key, 1.minute.to_i)
      
      false
    end
    
    def get_retention_period(data_type)
      case data_type
      when :analytics
        SiteSetting.get('analytics_data_retention_days', 365).to_i
      when :personal
        SiteSetting.get('personal_data_retention_days', 30).to_i
      when :marketing
        SiteSetting.get('marketing_data_retention_days', 90).to_i
      else
        SiteSetting.get('default_data_retention_days', 365).to_i
      end
    end
    
    def get_current_ip
      # Get current request IP
      Thread.current[:current_request]&.remote_ip || '127.0.0.1'
    end
    
    def get_current_user_agent
      # Get current request user agent
      Thread.current[:current_request]&.user_agent || 'Unknown'
    end
    
    def get_current_admin_user
      # Get current admin user from thread
      Thread.current[:current_admin_user]
    end
    
    def mask_field(value)
      return value if value.blank?
      
      if value.include?('@')
        # Email masking
        parts = value.split('@')
        parts[0] = "#{parts[0][0]}***"
        parts.join('@')
      elsif value.match?(/^\d+$/)
        # Phone number masking
        "#{value[0..2]}***#{value[-2..-1]}"
      else
        # General masking
        "#{value[0..2]}***"
      end
    end
    
    def update_user_consent_status(user_id, consent_type, granted)
      # Update user consent status in Redis/database
      Redis.current.hset("user_consent:#{user_id}", consent_type, granted)
    end
    
    def apply_consent_based_processing(user_id, consent_type, granted)
      # Apply consent-based data processing rules
      case consent_type
      when :analytics
        if granted
          enable_analytics_tracking(user_id)
        else
          disable_analytics_tracking(user_id)
        end
      when :marketing
        if granted
          enable_marketing_tracking(user_id)
        else
          disable_marketing_tracking(user_id)
        end
      end
    end
    
    def enable_analytics_tracking(user_id)
      Redis.current.hset("user_tracking:#{user_id}", "analytics_enabled", true)
    end
    
    def disable_analytics_tracking(user_id)
      Redis.current.hset("user_tracking:#{user_id}", "analytics_enabled", false)
    end
    
    def enable_marketing_tracking(user_id)
      Redis.current.hset("user_tracking:#{user_id}", "marketing_enabled", true)
    end
    
    def disable_marketing_tracking(user_id)
      Redis.current.hset("user_tracking:#{user_id}", "marketing_enabled", false)
    end
    
    def collect_user_data(user_id)
      {
        pageviews: Pageview.where(user_id: user_id).limit(1000),
        events: AnalyticsEvent.where(user_id: user_id).limit(1000),
        consent_records: AnalyticsConsent.where(user_id: user_id),
        profile_data: get_user_profile_data(user_id)
      }
    end
    
    def export_json_data(data)
      data.to_json
    end
    
    def export_csv_data(data)
      # Convert to CSV format
      CSV.generate do |csv|
        data.each do |key, records|
          if records.is_a?(ActiveRecord::Relation)
            csv << [key.to_s]
            records.each { |record| csv << record.attributes.values }
          end
        end
      end
    end
    
    def export_xml_data(data)
      data.to_xml
    end
    
    def delete_all_user_data(user_id)
      Pageview.where(user_id: user_id).delete_all
      AnalyticsEvent.where(user_id: user_id).delete_all
      AnalyticsConsent.where(user_id: user_id).delete_all
      AnalyticsAuditLog.where(user_id: user_id).delete_all
    end
    
    def delete_analytics_data(user_id)
      Pageview.where(user_id: user_id).delete_all
      AnalyticsEvent.where(user_id: user_id).delete_all
    end
    
    def delete_personal_data(user_id)
      # Delete personal data while keeping analytics data anonymized
      AnalyticsEvent.where(user_id: user_id).update_all(user_id: nil)
      Pageview.where(user_id: user_id).update_all(user_id: nil)
    end
    
    def delete_specific_data_types(user_id, data_types)
      data_types.each do |data_type|
        case data_type
        when :pageviews
          Pageview.where(user_id: user_id).delete_all
        when :events
          AnalyticsEvent.where(user_id: user_id).delete_all
        when :consent
          AnalyticsConsent.where(user_id: user_id).delete_all
        end
      end
    end
    
    def detect_unusual_access_patterns(user_id)
      # Detect unusual access patterns
      false # Simplified for now
    end
    
    def detect_suspicious_requests(user_id)
      # Detect suspicious requests
      false # Simplified for now
    end
    
    def detect_data_exfiltration(user_id)
      # Detect data exfiltration attempts
      false # Simplified for now
    end
    
    def detect_unauthorized_access(user_id)
      # Detect unauthorized access
      false # Simplified for now
    end
    
    def handle_potential_breach(user_id, breach_indicators)
      # Handle potential data breach
      Rails.logger.warn "Potential data breach detected for user #{user_id}: #{breach_indicators}"
    end
    
    def check_suspicious_access_patterns(user_id, data_type, action)
      # Check for suspicious access patterns
      access_key = "access_pattern:#{user_id}:#{data_type}"
      access_count = Redis.current.incr(access_key)
      Redis.current.expire(access_key, 1.hour.to_i)
      
      if access_count > 50 # Suspicious if more than 50 accesses per hour
        handle_suspicious_access(user_id, data_type, action, access_count)
      end
    end
    
    def handle_suspicious_access(user_id, data_type, action, count)
      Rails.logger.warn "Suspicious access pattern: User #{user_id} accessed #{data_type} #{count} times in the last hour"
    end
    
    def get_user_profile_data(user_id)
      # Get user profile data
      User.find_by(id: user_id)&.attributes || {}
    end
  end
end
