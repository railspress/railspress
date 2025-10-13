class Admin::AiProvidersController < Admin::BaseController
  before_action :set_ai_provider, only: [:show, :edit, :update, :destroy, :toggle]
  
  # GET /admin/ai_providers
  def index
    @ai_providers = AiProvider.ordered.includes(:ai_agents)
  end
  
  # GET /admin/ai_providers/:id
  def show
  end
  
  # GET /admin/ai_providers/new
  def new
    @ai_provider = AiProvider.new
  end
  
  # POST /admin/ai_providers
  def create
    @ai_provider = AiProvider.new(ai_provider_params)
    
    if @ai_provider.save
      redirect_to admin_ai_providers_path, notice: 'AI Provider created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  # GET /admin/ai_providers/:id/edit
  def edit
  end
  
  # PATCH/PUT /admin/ai_providers/:id
  def update
    if @ai_provider.update(ai_provider_params)
      redirect_to admin_ai_providers_path, notice: 'AI Provider updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  # DELETE /admin/ai_providers/:id
  def destroy
    if @ai_provider.ai_agents.any?
      redirect_to admin_ai_providers_path, alert: 'Cannot delete provider with active agents. Delete agents first.'
    else
      @ai_provider.destroy
      redirect_to admin_ai_providers_path, notice: 'AI Provider deleted successfully.'
    end
  end
  
  # PATCH /admin/ai_providers/:id/toggle
  def toggle
    @ai_provider.update(active: !@ai_provider.active)
    redirect_to admin_ai_providers_path, notice: "AI Provider #{@ai_provider.active? ? 'activated' : 'deactivated'}."
  end
  
  private
  
  def set_ai_provider
    @ai_provider = AiProvider.find(params[:id])
  end
  
  def ai_provider_params
    params.require(:ai_provider).permit(
      :name, :provider_type, :api_key, :api_url, :model_identifier,
      :max_tokens, :temperature, :active, :position
    )
  end
end
