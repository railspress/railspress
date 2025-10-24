class AiProvider < ApplicationRecord
  has_many :ai_agents, dependent: :destroy
  
  PROVIDER_TYPES = %w[openai cohere anthropic google].freeze
  
  validates :name, presence: true
  validates :provider_type, presence: true, inclusion: { in: PROVIDER_TYPES }
  validates :api_key, presence: true
  validates :model_identifier, presence: true
  validates :max_tokens, presence: true, numericality: { greater_than: 0 }
  validates :temperature, presence: true, numericality: { in: 0.0..2.0 }
  validates :system_default, inclusion: { in: [true, false] }
  validate :only_one_system_default, if: :system_default?
  
  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(provider_type: type) }
  scope :ordered, -> { order(:position, :name) }
  scope :system_default, -> { where(system_default: true).first }
  
  after_initialize :set_defaults, if: :new_record?
  before_save :unset_other_system_defaults, if: :system_default?
  
  def display_name
    "#{name} (#{provider_type.titleize})"
  end
  
  def latest_model_for_type
    case provider_type
    when 'openai'
      'gpt-4o'
    when 'cohere'
      'command-r-plus'
    when 'anthropic'
      'claude-3-5-sonnet-20241022'
    when 'google'
      'gemini-1.5-pro'
    else
      model_identifier
    end
  end
  
  private
  
  def set_defaults
    self.active = true if active.nil?
    self.temperature = 0.7 if temperature.nil?
    self.max_tokens = 4000 if max_tokens.nil?
    self.position = 0 if position.nil?
  end
  
  def only_one_system_default
    if system_default? && AiProvider.where(system_default: true).where.not(id: id).exists?
      errors.add(:system_default, "can only be set for one provider at a time")
    end
  end
  
  def unset_other_system_defaults
    AiProvider.where(system_default: true).where.not(id: id).update_all(system_default: false)
  end
end
