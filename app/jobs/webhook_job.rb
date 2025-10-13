class WebhookJob < ApplicationJob
  queue_as :default
  
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  
  def perform(webhook_config, data)
    webhook = webhook_config.with_indifferent_access
    
    uri = URI(webhook[:url])
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.read_timeout = webhook[:timeout] || 30
    
    request_class = case webhook[:method]&.upcase
                   when 'GET'
                     Net::HTTP::Get
                   when 'PUT'
                     Net::HTTP::Put
                   when 'PATCH'
                     Net::HTTP::Patch
                   when 'DELETE'
                     Net::HTTP::Delete
                   else
                     Net::HTTP::Post
                   end
    
    request = request_class.new(uri)
    request['Content-Type'] = 'application/json'
    request['User-Agent'] = 'RailsPress-Plugin-Webhook/1.0'
    
    # Add custom headers
    webhook[:headers]&.each do |key, value|
      request[key] = value
    end
    
    # Add webhook signature if secret is provided
    if webhook[:secret]
      payload = data.to_json
      signature = OpenSSL::HMAC.hexdigest('SHA256', webhook[:secret], payload)
      request['X-Webhook-Signature'] = "sha256=#{signature}"
    end
    
    # Prepare payload
    payload = data.to_json
    request.body = payload
    
    # Send request
    response = http.request(request)
    
    Rails.logger.info "Webhook sent to #{webhook[:url]}: #{response.code} #{response.message}"
    
    # Raise error for non-success responses to trigger retry
    unless response.is_a?(Net::HTTPSuccess)
      raise "Webhook failed with status #{response.code}: #{response.message}"
    end
    
  rescue => e
    Rails.logger.error "Webhook delivery failed: #{e.message}"
    raise e # Re-raise to trigger retry mechanism
  end
end
