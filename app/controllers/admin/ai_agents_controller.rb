class Admin::AiAgentsController < Admin::BaseController
  before_action :set_ai_agent, only: [:show, :edit, :update, :destroy, :toggle, :test]
  
  # GET /admin/ai_agents
  def index
    @ai_agents = AiAgent.includes(:ai_provider).ordered
    
    respond_to do |format|
      format.html
      format.json do
        render json: @ai_agents.active.map { |agent|
          {
            id: agent.id,
            name: agent.name,
            slug: agent.slug,
            description: agent.description
          }
        }
      end
    end
  end
  
  # GET /admin/ai_agents/usage
  def usage
    @ai_agents = AiAgent.includes(:ai_provider).ordered
    
    # Calculate usage statistics for all agents
    @total_usage = calculate_total_usage
    
    # Calculate usage statistics for each agent
    @agent_usage = @ai_agents.map do |agent|
      {
        agent: agent,
        usage_stats: calculate_agent_usage(agent)
      }
    end
  end
  
  # GET /admin/ai_agents/:id
  def show
  end
  
  # GET /admin/ai_agents/new
  def new
    @ai_agent = AiAgent.new
    @ai_providers = AiProvider.active.ordered
  end
  
  # POST /admin/ai_agents
  def create
    @ai_agent = AiAgent.new(ai_agent_params)
    @ai_providers = AiProvider.active.ordered
    
    if @ai_agent.save
      redirect_to admin_ai_agents_path, notice: 'AI Agent created successfully.'
    else
      render :new, status: :unprocessable_content
    end
  end
  
  # GET /admin/ai_agents/:id/edit
  def edit
    if @ai_agent.system_required?
      redirect_to admin_ai_agents_path, alert: 'Cannot edit system-required agent.'
      return
    end
    @ai_providers = AiProvider.active.ordered
  end
  
  # PATCH/PUT /admin/ai_agents/:id
  def update
    if @ai_agent.system_required?
      redirect_to admin_ai_agents_path, alert: 'Cannot update system-required agent.'
      return
    end
    
    @ai_providers = AiProvider.active.ordered
    
    if @ai_agent.update(ai_agent_params)
      redirect_to admin_ai_agents_path, notice: 'AI Agent updated successfully.'
    else
      render :edit, status: :unprocessable_content
    end
  end
  
  # DELETE /admin/ai_agents/:id
  def destroy
    if @ai_agent.system_required?
      redirect_to admin_ai_agents_path, alert: 'Cannot delete system-required agent.'
      return
    end
    
    if @ai_agent.destroy
      redirect_to admin_ai_agents_path, notice: 'AI Agent deleted successfully.'
    else
      redirect_to admin_ai_agents_path, alert: @ai_agent.errors.full_messages.join(', ')
    end
  end
  
  # PATCH /admin/ai_agents/:id/toggle
  def toggle
    @ai_agent.update(active: !@ai_agent.active)
    redirect_to admin_ai_agents_path, notice: "AI Agent #{@ai_agent.active? ? 'activated' : 'deactivated'}."
  end
  
  # POST /admin/ai_agents/:id/test
  def test
    user_input = params[:user_input] || "Test input"
    context = params[:context] || {}
    
    begin
      result = @ai_agent.execute(user_input, context, current_user)
      
      respond_to do |format|
        format.json { render json: { success: true, result: result } }
        format.html { redirect_to admin_ai_agent_path(@ai_agent), notice: "Test completed successfully." }
      end
    rescue => e
      Rails.logger.error "AI Agent test failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      respond_to do |format|
        format.json { render json: { success: false, error: e.message }, status: :unprocessable_content }
        format.html { redirect_to admin_ai_agent_path(@ai_agent), alert: "Test failed: #{e.message}" }
      end
    end
  end
  
  private
  
  def set_ai_agent
    @ai_agent = AiAgent.find(params[:id])
  end
  
  def ai_agent_params
    params.require(:ai_agent).permit(
      :name, :description, :agent_type, :prompt, :content, :guidelines,
      :rules, :tasks, :master_prompt, :ai_provider_id, :active, :position
    )
  end
  
  def calculate_total_usage
    # Calculate total usage across all agents from real data
    {
      total_requests: AiUsage.count,
      total_tokens: AiUsage.sum(:tokens_used),
      total_cost: AiUsage.sum(:cost),
      requests_today: AiUsage.today.count,
      requests_this_month: AiUsage.this_month.count,
      average_response_time: AiUsage.average(:response_time)&.round(2) || 0
    }
  end
  
  def calculate_agent_usage(agent)
    # Calculate usage statistics for a specific agent from real data
    {
      total_requests: agent.total_requests,
      total_tokens: agent.total_tokens,
      total_cost: agent.total_cost,
      requests_today: agent.requests_today,
      requests_this_month: agent.requests_this_month,
      average_response_time: agent.average_response_time,
      last_used: agent.last_used,
      success_rate: agent.success_rate
    }
  end
end
