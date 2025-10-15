class DeliverWebhookJob < ApplicationJob
  queue_as :default
  
  # Retry with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 5
  
  def perform(webhook_delivery_id)
    delivery = WebhookDelivery.find(webhook_delivery_id)
    webhook = delivery.webhook
    
    # Skip if webhook is inactive
    return unless webhook.active?
    
    # Prepare request
    uri = URI(webhook.url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = webhook.timeout
    http.read_timeout = webhook.timeout
    
    # Create request
    request = Net::HTTP::Post.new(uri.path.empty? ? '/' : uri.path)
    
    # Set headers
    delivery.signed_headers.each do |key, value|
      request[key] = value
    end
    
    # Set body
    request.body = delivery.payload.to_json
    
    # Send request
    begin
      response = http.request(request)
      
      if response.code.to_i >= 200 && response.code.to_i < 300
        # Success
        delivery.mark_success!(response.code.to_i, response.body)
        
        Rails.logger.info "Webhook delivered successfully: #{webhook.name} (#{delivery.event_type})"
      else
        # HTTP error
        delivery.mark_failed!(
          "HTTP #{response.code}: #{response.message}",
          response.code.to_i,
          response.body
        )
        
        Rails.logger.warn "Webhook delivery failed: #{webhook.name} (HTTP #{response.code})"
      end
    rescue Timeout::Error => e
      delivery.mark_failed!("Request timeout after #{webhook.timeout}s")
      Rails.logger.error "Webhook timeout: #{webhook.name} - #{e.message}"
    rescue SocketError, Errno::ECONNREFUSED => e
      delivery.mark_failed!("Connection failed: #{e.message}")
      Rails.logger.error "Webhook connection failed: #{webhook.name} - #{e.message}"
    rescue => e
      delivery.mark_failed!("Unexpected error: #{e.message}")
      Rails.logger.error "Webhook error: #{webhook.name} - #{e.class}: #{e.message}"
    end
  end
end








