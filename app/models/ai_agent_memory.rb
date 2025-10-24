class AiAgentMemory < ApplicationRecord
  belongs_to :ai_agent, optional: true
  belongs_to :user, optional: true

  validates :key, presence: true

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :by_type, ->(type) { where(memory_type: type) }
  scope :for_agent, ->(agent) { where(ai_agent: agent) }
  scope :for_user, ->(user) { where(user: user) }

  # Semantic search (requires pgvector)
  def self.semantic_search(query_embedding, limit: 5)
    where.not(embedding: nil)
      .order(Arel.sql("embedding <=> '#{query_embedding}'"))
      .limit(limit)
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end
end

