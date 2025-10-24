class AgentSession < ApplicationRecord
  belongs_to :ai_agent
  belongs_to :ai_provider, optional: true
  belongs_to :user, optional: true
  has_many :agent_events, dependent: :destroy

  before_create :generate_uuid
  before_create :set_default_provider

  scope :open, -> { where(status: "open") }
  scope :closed, -> { where(status: "closed") }
  scope :by_channel, ->(channel) { where(channel: channel) }

  validates :status, inclusion: { in: %w[open closed error] }

  def provider
    ai_provider || ai_agent.ai_provider
  end

  def log(event_type:, subtype: nil, summary: nil, payload: {}, target_event: nil)
    event = agent_events.create!(
      event_type: event_type,
      subtype: subtype,
      summary: summary,
      payload: payload,
      target_event_id: target_event&.id,
      sequence: event_count + 1
    )
    
    increment!(:event_count)
    touch(:last_event_at)
    
    event
  end

  def messages
    agent_events.where(event_type: %w[intent response])
  end

  def conversation_history
    messages.order(:created_at).map do |event|
      {
        role: event.user_message? ? "user" : "assistant",
        content: event.payload["text"] || event.summary,
        event_id: event.id # Include event ID for feedback
      }
    end
  end

  def close!(summary: nil)
    update!(status: "closed")
    log(event_type: "response", subtype: "session_summary", summary: summary) if summary
  end

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def set_default_provider
    self.ai_provider ||= ai_agent.ai_provider
  end
end

