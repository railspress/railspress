class Api::V1::AiAgentsController < ApplicationController
  before_action :authenticate_api_user!
  before_action :set_agent, only: [:execute, :show, :update, :destroy]
  
  # GET /api/v1/ai_agents
  def index
    agents = AiAgent.active.ordered.includes(:ai_provider)
    
    render json: {
      success: true,
      agents: agents.map { |agent| agent_json(agent) },
      total: agents.count
    }
  end
  
  # GET /api/v1/ai_agents/:id
  def show
    render json: {
      success: true,
      agent: agent_json(@agent, detailed: true)
    }
  end
  
  # POST /api/v1/ai_agents
  def create
    provider = AiProvider.find(params[:ai_provider_id])
    
    agent = AiAgent.new(agent_params.merge(ai_provider: provider))
    
    if agent.save
      render json: {
        success: true,
        agent: agent_json(agent, detailed: true),
        message: 'AI Agent created successfully'
      }, status: :created
    else
      render json: {
        success: false,
        errors: agent.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /api/v1/ai_agents/:id
  def update
    if @agent.update(agent_params)
      render json: {
        success: true,
        agent: agent_json(@agent, detailed: true),
        message: 'AI Agent updated successfully'
      }
    else
      render json: {
        success: false,
        errors: @agent.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/ai_agents/:id
  def destroy
    if @agent.destroy
      render json: {
        success: true,
        message: 'AI Agent deleted successfully'
      }
    else
      render json: {
        success: false,
        error: 'Failed to delete agent'
      }, status: :unprocessable_entity
    end
  end
  
  # POST /api/v1/ai_agents/execute
  def execute
    user_input = params[:user_input] || ""
    context = params[:context] || {}
    
    begin
      result = @agent.execute(user_input, context)
      
      render json: {
        success: true,
        result: result,
        agent: {
          id: @agent.id,
          name: @agent.name,
          type: @agent.agent_type
        }
      }
    rescue => e
      render json: {
        success: false,
        error: e.message
      }, status: :unprocessable_entity
    end
  end
  
  # POST /api/v1/ai_agents/execute/:agent_type
  def execute_by_type
    agent_type = params[:agent_type]
    user_input = params[:user_input] || ""
    context = params[:context] || {}
    
    agent = AiAgent.active.find_by(agent_type: agent_type)
    
    unless agent
      render json: {
        success: false,
        error: "No active agent found for type: #{agent_type}"
      }, status: :not_found
      return
    end
    
    begin
      result = agent.execute(user_input, context)
      
      render json: {
        success: true,
        result: result,
        agent: {
          id: agent.id,
          name: agent.name,
          type: agent.agent_type
        }
      }
    rescue => e
      render json: {
        success: false,
        error: e.message
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_agent
    @agent = AiAgent.active.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: "Agent not found or inactive"
    }, status: :not_found
  end
  
  def agent_params
    params.require(:ai_agent).permit(
      :name,
      :agent_type,
      :prompt,
      :content,
      :guidelines,
      :rules,
      :tasks,
      :master_prompt,
      :active,
      :position
    )
  end
  
  def agent_json(agent, detailed: false)
    json = {
      id: agent.id,
      name: agent.name,
      type: agent.agent_type,
      active: agent.active,
      provider: {
        id: agent.ai_provider_id,
        name: agent.ai_provider.name,
        type: agent.ai_provider.provider_type
      }
    }
    
    if detailed
      json.merge!({
        prompt: agent.prompt,
        content: agent.content,
        guidelines: agent.guidelines,
        rules: agent.rules,
        tasks: agent.tasks,
        master_prompt: agent.master_prompt,
        position: agent.position,
        created_at: agent.created_at,
        updated_at: agent.updated_at
      })
    end
    
    json
  end
  
  def authenticate_api_user!
    # For now, we'll allow any authenticated user
    # You can add more specific authentication logic here
    unless current_user
      render json: {
        success: false,
        error: "Authentication required"
      }, status: :unauthorized
    end
  end
end
