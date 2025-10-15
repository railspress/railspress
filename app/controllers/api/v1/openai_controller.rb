class Api::V1::OpenaiController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_api_key
  before_action :set_agent, only: [:chat_completions]
  before_action :validate_request, only: [:chat_completions]
  
  # POST /v1/chat/completions
  def chat_completions
    start_time = Time.current
    
    begin
      # Execute the agent
      result = @agent.execute(user_message, build_context, @api_user)
      
      # Calculate tokens (rough estimation)
      prompt_tokens = calculate_tokens(full_prompt)
      completion_tokens = calculate_tokens(result.to_s)
      total_tokens = prompt_tokens + completion_tokens
      
      response_time = Time.current - start_time
      
      # Create usage log
      @agent.ai_usages.create!(
        user: @api_user,
        prompt: full_prompt,
        response: result.to_s,
        tokens_used: total_tokens,
        cost: calculate_cost(prompt_tokens, completion_tokens),
        response_time: response_time,
        success: true,
        metadata: {
          api_request: true,
          model: params[:model],
          messages: params[:messages],
          temperature: params[:temperature],
          max_tokens: params[:max_tokens]
        }
      )
      
      render json: {
        id: generate_chat_id,
        object: "chat.completion",
        created: Time.current.to_i,
        model: params[:model],
        choices: [
          {
            index: 0,
            message: {
              role: "assistant",
              content: result.to_s
            },
            finish_reason: "stop"
          }
        ],
        usage: {
          prompt_tokens: prompt_tokens,
          completion_tokens: completion_tokens,
          total_tokens: total_tokens
        }
      }
      
    rescue => e
      response_time = Time.current - start_time
      
      # Log failed usage
      @agent.ai_usages.create!(
        user: @api_user,
        prompt: full_prompt,
        response: nil,
        tokens_used: calculate_tokens(full_prompt),
        cost: 0.0,
        response_time: response_time,
        success: false,
        error_message: e.message,
        metadata: {
          api_request: true,
          model: params[:model],
          messages: params[:messages],
          error_class: e.class.name
        }
      )
      
      render json: {
        error: {
          message: e.message,
          type: "server_error",
          code: "internal_error"
        }
      }, status: :internal_server_error
    end
  end
  
  # GET /v1/models
  def models
    models_data = AiAgent.active.includes(:ai_provider).map do |agent|
      {
        id: agent.name.parameterize,
        object: "model",
        created: agent.created_at.to_i,
        owned_by: "railspress",
        permission: [],
        root: agent.name.parameterize,
        parent: nil
      }
    end
    
    render json: {
      object: "list",
      data: models_data
    }
  end
  
  # GET /v1/models/{id}
  def model
    agent = AiAgent.active.find_by("LOWER(REPLACE(name, ' ', '-')) = ?", params[:id].downcase)
    
    if agent
      render json: {
        id: params[:id],
        object: "model",
        created: agent.created_at.to_i,
        owned_by: "railspress",
        permission: [],
        root: params[:id],
        parent: nil
      }
    else
      render json: {
        error: {
          message: "The model '#{params[:id]}' does not exist",
          type: "invalid_request_error",
          code: "model_not_found"
        }
      }, status: :not_found
    end
  end
  
  private
  
  def authenticate_api_key
    auth_header = request.headers['Authorization']
    
    unless auth_header&.start_with?('Bearer ')
      render json: {
        error: {
          message: "Invalid API key provided",
          type: "invalid_request_error",
          code: "invalid_api_key"
        }
      }, status: :unauthorized
      return
    end
    
    api_key = auth_header.sub('Bearer ', '')
    
    # Find user by API key (assuming we have an api_key field on User model)
    @api_user = User.find_by(api_key: api_key)
    
    unless @api_user
      render json: {
        error: {
          message: "Invalid API key provided",
          type: "invalid_request_error",
          code: "invalid_api_key"
        }
      }, status: :unauthorized
    end
  end
  
  def set_agent
    model_name = params[:model]
    
    # Find agent by model name (parameterized)
    @agent = AiAgent.active.find_by("LOWER(REPLACE(name, ' ', '-')) = ?", model_name.downcase)
    
    unless @agent
      render json: {
        error: {
          message: "The model '#{model_name}' does not exist or is not available",
          type: "invalid_request_error",
          code: "model_not_found"
        }
      }, status: :not_found
    end
  end
  
  def validate_request
    unless params[:messages].is_a?(Array) && params[:messages].any?
      render json: {
        error: {
          message: "messages is required",
          type: "invalid_request_error",
          code: "missing_messages"
        }
      }, status: :bad_request
      return
    end
    
    # Validate message format
    params[:messages].each do |message|
      unless message['role'] && message['content']
        render json: {
          error: {
            message: "Each message must have 'role' and 'content'",
            type: "invalid_request_error",
            code: "invalid_message_format"
          }
        }, status: :bad_request
        return
      end
    end
  end
  
  def user_message
    # Get the last user message
    user_messages = params[:messages].select { |m| m['role'] == 'user' }
    user_messages.last&.dig('content') || ""
  end
  
  def system_message
    # Get the system message if present
    system_messages = params[:messages].select { |m| m['role'] == 'system' }
    system_messages.first&.dig('content') || ""
  end
  
  def full_prompt
    # Combine system message with agent prompt
    parts = []
    parts << system_message if system_message.present?
    parts << @agent.prompt if @agent.prompt.present?
    parts << "User Input: #{user_message}"
    parts.join("\n\n")
  end
  
  def build_context
    {
      temperature: params[:temperature] || @agent.ai_provider.temperature,
      max_tokens: params[:max_tokens] || @agent.ai_provider.max_tokens,
      model: params[:model],
      api_request: true
    }
  end
  
  def calculate_tokens(text)
    # Simple token estimation: ~4 characters per token
    (text.to_s.length / 4.0).ceil
  end
  
  def calculate_cost(prompt_tokens, completion_tokens)
    # Simple cost calculation based on provider
    total_tokens = prompt_tokens + completion_tokens
    case @agent.ai_provider.provider_type
    when 'openai'
      total_tokens * 0.00002
    when 'anthropic'
      total_tokens * 0.000015
    else
      total_tokens * 0.00001
    end
  end
  
  def generate_chat_id
    "chatcmpl_#{SecureRandom.hex(12)}"
  end
end
