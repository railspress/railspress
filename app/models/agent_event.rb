class AgentEvent < ApplicationRecord
  belongs_to :agent_session
  belongs_to :target_event, class_name: "AgentEvent", optional: true
  has_many :related_events, class_name: "AgentEvent", foreign_key: :target_event_id

  EVENT_TYPES = %w[intent action observation response feedback].freeze

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }

  scope :messages, -> { where(event_type: %w[intent response]) }
  scope :feedbacks, -> { where(event_type: "feedback") }
  scope :by_type, ->(type) { where(event_type: type) }

  def user_message?
    event_type == "intent"
  end

  def assistant_message?
    event_type == "response"
  end

  def feedback?
    event_type == "feedback"
  end
end

