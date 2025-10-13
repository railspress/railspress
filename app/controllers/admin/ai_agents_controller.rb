class Admin::AiAgentsController < Admin::BaseController
  before_action :set_ai_agent, only: [:show, :edit, :update, :destroy, :toggle, :test]
  
  # GET /admin/ai_agents
  def index
    @ai_agents = AiAgent.includes(:ai_provider).ordered
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
      render :new, status: :unprocessable_entity
    end
  end
  
  # GET /admin/ai_agents/:id/edit
  def edit
    @ai_providers = AiProvider.active.ordered
  end
  
  # PATCH/PUT /admin/ai_agents/:id
  def update
    @ai_providers = AiProvider.active.ordered
    
    if @ai_agent.update(ai_agent_params)
      redirect_to admin_ai_agents_path, notice: 'AI Agent updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  # DELETE /admin/ai_agents/:id
  def destroy
    @ai_agent.destroy
    redirect_to admin_ai_agents_path, notice: 'AI Agent deleted successfully.'
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
      result = @ai_agent.execute(user_input, context)
      render json: { success: true, result: result }
    rescue => e
      render json: { success: false, error: e.message }
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
end
