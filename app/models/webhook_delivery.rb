class WebhookDelivery < ApplicationRecord
  # Associations
  belongs_to :webhook
  
  # Validations
  validates :event_type, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending success failed] }
  
  # Enums
  enum status: {
    pending: 'pending',
    success: 'success',
    failed: 'failed'
  }, _suffix: true
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :failed, -> { where(status: 'failed') }
  scope :successful, -> { where(status: 'success') }
  scope :pending_retry, -> { where('status = ? AND retry_count < ? AND next_retry_at <= ?', 'failed', 3, Time.current) }
  
  # Callbacks
  after_create :schedule_delivery
  
  # Check if delivery can be retried
  def can_retry?
    failed_status? && retry_count < webhook.retry_limit
  end
  
  # Mark as successful
  def mark_success!(response_code, response_body)
    update!(
      status: 'success',
      response_code: response_code,
      response_body: response_body.to_s.truncate(5000),
      delivered_at: Time.current
    )
    
    webhook.record_delivery(success: true)
  end
  
  # Mark as failed
  def mark_failed!(error_message, response_code = nil, response_body = nil)
    update!(
      status: 'failed',
      error_message: error_message.to_s.truncate(1000),
      response_code: response_code,
      response_body: response_body.to_s.truncate(5000)
    )
    
    webhook.record_delivery(success: false)
    
    # Schedule retry if allowed
    schedule_retry if can_retry?
  end
  
  # Schedule retry with exponential backoff
  def schedule_retry
    increment!(:retry_count)
    
    # Exponential backoff: 1min, 5min, 15min
    delay = case retry_count
            when 1 then 1.minute
            when 2 then 5.minutes
            else 15.minutes
            end
    
    update!(next_retry_at: delay.from_now)
    
    # Schedule the retry job
    DeliverWebhookJob.set(wait: delay).perform_later(id)
  end
  
  # Get signed headers for delivery
  def signed_headers
    payload_json = payload.to_json
    signature = webhook.sign_payload(payload_json)
    
    {
      'Content-Type' => 'application/json',
      'User-Agent' => 'RailsPress-Webhooks/1.0',
      'X-RailsPress-Event' => event_type,
      'X-RailsPress-Delivery' => request_id,
      'X-RailsPress-Signature' => signature,
      'X-RailsPress-Signature-256' => "sha256=#{signature}"
    }
  end
  
  private
  
  def schedule_delivery
    DeliverWebhookJob.perform_later(id) if pending_status?
  end
end
