class Webhook < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  # Associations
  has_many :webhook_deliveries, dependent: :destroy
  
  # Serialization
  serialize :events, coder: JSON, type: Array
  
  # Validations
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :secret_key, presence: true
  validates :name, presence: true
  validates :events, presence: true
  validates :retry_limit, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }
  validates :timeout, numericality: { greater_than: 0, less_than_or_equal_to: 120 }
  
  # Callbacks
  before_validation :generate_secret_key, on: :create
  before_validation :set_defaults
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :for_event, ->(event_type) { where("events LIKE ?", "%#{event_type}%") }
  
  # Available webhook events
  AVAILABLE_EVENTS = [
    'post.created',
    'post.updated',
    'post.published',
    'post.deleted',
    'page.created',
    'page.updated',
    'page.published',
    'page.deleted',
    'comment.created',
    'comment.approved',
    'comment.spam',
    'user.created',
    'user.updated',
    'media.uploaded'
  ].freeze
  
  # Check if webhook is subscribed to an event
  def subscribed_to?(event_type)
    events.include?(event_type)
  end
  
  # Deliver a webhook
  def deliver(event_type, payload)
    return unless active? && subscribed_to?(event_type)
    
    delivery = webhook_deliveries.create!(
      event_type: event_type,
      payload: payload,
      status: 'pending',
      request_id: SecureRandom.uuid
    )
    
    # Enqueue for delivery
    DeliverWebhookJob.perform_later(delivery.id)
    
    delivery
  end
  
  # Generate HMAC signature for payload
  def sign_payload(payload_json)
    OpenSSL::HMAC.hexdigest('SHA256', secret_key, payload_json)
  end
  
  # Update delivery statistics
  def record_delivery(success:)
    increment!(:total_deliveries)
    increment!(:failed_deliveries) unless success
    touch(:last_delivered_at) if success
  end
  
  # Check if webhook is healthy
  def healthy?
    return true if total_deliveries.zero?
    
    failure_rate = failed_deliveries.to_f / total_deliveries
    failure_rate < 0.5  # Less than 50% failure rate
  end
  
  private
  
  def generate_secret_key
    self.secret_key ||= SecureRandom.hex(32)
  end
  
  def set_defaults
    self.retry_limit ||= 3
    self.timeout ||= 30
    self.total_deliveries ||= 0
    self.failed_deliveries ||= 0
  end
end
