class AiAgent < ApplicationRecord
  belongs_to :ai_provider
  
  AGENT_TYPES = %w[content_summarizer post_writer comments_analyzer seo_analyzer].freeze
  
  validates :name, presence: true
  validates :agent_type, presence: true, inclusion: { in: AGENT_TYPES }
  validates :ai_provider, presence: true
  
  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(agent_type: type) }
  scope :ordered, -> { order(:position, :name) }
  
  after_initialize :set_defaults, if: :new_record?
  
  def full_prompt(user_input = "", context = {})
    parts = []
    
    # Master prompt (highest priority)
    parts << master_prompt if master_prompt.present?
    
    # Agent prompt
    parts << prompt if prompt.present?
    
    # Content guidelines
    parts << "Content Guidelines:\n#{content}" if content.present?
    
    # Guidelines
    parts << "Guidelines:\n#{guidelines}" if guidelines.present?
    
    # Rules
    parts << "Rules:\n#{rules}" if rules.present?
    
    # Tasks
    parts << "Tasks:\n#{tasks}" if tasks.present?
    
    # User input
    parts << "User Input: #{user_input}" if user_input.present?
    
    # Context
    if context.present?
      context_str = context.map { |k, v| "#{k}: #{v}" }.join("\n")
      parts << "Context:\n#{context_str}"
    end
    
    parts.join("\n\n")
  end
  
  def execute(user_input = "", context = {})
    AiService.new(ai_provider).generate(full_prompt(user_input, context))
  end
  
  private
  
  def set_defaults
    self.active = true if active.nil?
    self.position = 0 if position.nil?
  end
end
