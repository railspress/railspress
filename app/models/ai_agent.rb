class AiAgent < ApplicationRecord
  belongs_to :ai_provider
  has_many :ai_usages, dependent: :destroy
  
  # Meta fields for plugin extensibility
  has_many :meta_fields, as: :metable, dependent: :destroy
  include Metable
  
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
      # Convert ActionController::Parameters to hash if needed
      context_hash = context.respond_to?(:to_unsafe_h) ? context.to_unsafe_h : context.to_h
      context_str = context_hash.map { |k, v| "#{k}: #{v}" }.join("\n")
      parts << "Context:\n#{context_str}"
    end
    
    parts.join("\n\n")
  end
  
  def execute(user_input = "", context = {}, user = nil)
    start_time = Time.current
    prompt_text = full_prompt(user_input, context)
    executing_user = user || User.first # Fallback to first user if no user provided
    
    begin
      result = AiService.new(ai_provider).generate(prompt_text)
      response_time = Time.current - start_time
      
      # Log successful usage
      ai_usages.create!(
        user: executing_user,
        prompt: prompt_text,
        response: result.to_s,
        tokens_used: calculate_tokens(prompt_text, result),
        cost: calculate_cost(prompt_text, result),
        response_time: response_time,
        success: true,
        metadata: {
          user_input: user_input,
          context: context,
          agent_type: agent_type
        }
      )
      
      result
    rescue => e
      response_time = Time.current - start_time
      
      # Log failed usage
      ai_usages.create!(
        user: executing_user,
        prompt: prompt_text,
        response: nil,
        tokens_used: calculate_tokens(prompt_text, ""),
        cost: 0.0,
        response_time: response_time,
        success: false,
        error_message: e.message,
        metadata: {
          user_input: user_input,
          context: context,
          agent_type: agent_type,
          error_class: e.class.name
        }
      )
      
      raise e
    end
  end
  
  # Usage statistics methods
  def total_requests
    ai_usages.count
  end
  
  def total_tokens
    ai_usages.sum(:tokens_used)
  end
  
  def total_cost
    ai_usages.sum(:cost)
  end
  
  def requests_today
    ai_usages.today.count
  end
  
  def requests_this_month
    ai_usages.this_month.count
  end
  
  def average_response_time
    ai_usages.average(:response_time)&.round(2) || 0
  end
  
  def success_rate
    return 0 if ai_usages.empty?
    (ai_usages.successful.count.to_f / ai_usages.count * 100).round(1)
  end
  
  def last_used
    ai_usages.order(:created_at).last&.created_at
  end

  private
  
  def set_defaults
    self.active = true if active.nil?
    self.position = 0 if position.nil?
  end
  
  def calculate_tokens(prompt, response)
    # Simple token estimation: ~4 characters per token
    # This is a rough approximation, real implementations would use tokenizers
    total_text = prompt.to_s + response.to_s
    (total_text.length / 4.0).ceil
  end
  
  def calculate_cost(prompt, response)
    # Simple cost calculation based on tokens
    # This should be replaced with actual pricing from the AI provider
    tokens = calculate_tokens(prompt, response)
    case ai_provider.provider_type
    when 'openai'
      tokens * 0.00002 # Rough estimate for GPT-3.5
    when 'anthropic'
      tokens * 0.000015 # Rough estimate for Claude
    else
      tokens * 0.00001 # Default estimate
    end
  end
end
