class Api::V1::AiProvidersController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin!, except: [:index, :show]
  before_action :set_provider, only: [:show, :update, :destroy, :toggle]
  
  # GET /api/v1/ai_providers
  def index
    providers = AiProvider.ordered.all
    
    render json: {
      success: true,
      providers: providers.map { |p| provider_json(p) },
      total: providers.count
    }
  end
  
  # GET /api/v1/ai_providers/:id
  def show
    render json: {
      success: true,
      provider: provider_json(@provider, detailed: true)
    }
  end
  
  # POST /api/v1/ai_providers
  def create
    provider = AiProvider.new(provider_params)
    
    if provider.save
      render json: {
        success: true,
        provider: provider_json(provider, detailed: true),
        message: 'AI Provider created successfully'
      }, status: :created
    else
      render json: {
        success: false,
        errors: provider.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /api/v1/ai_providers/:id
  def update
    if @provider.update(provider_params)
      render json: {
        success: true,
        provider: provider_json(@provider, detailed: true),
        message: 'AI Provider updated successfully'
      }
    else
      render json: {
        success: false,
        errors: @provider.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/ai_providers/:id
  def destroy
    if @provider.ai_agents.any?
      render json: {
        success: false,
        error: 'Cannot delete provider with active agents'
      }, status: :unprocessable_entity
      return
    end
    
    if @provider.destroy
      render json: {
        success: true,
        message: 'AI Provider deleted successfully'
      }
    else
      render json: {
        success: false,
        error: 'Failed to delete provider'
      }, status: :unprocessable_entity
    end
  end
  
  # PATCH /api/v1/ai_providers/:id/toggle
  def toggle
    @provider.update!(active: !@provider.active)
    
    render json: {
      success: true,
      provider: provider_json(@provider),
      message: "Provider #{@provider.active ? 'activated' : 'deactivated'}"
    }
  end
  
  private
  
  def set_provider
    @provider = AiProvider.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: "Provider not found"
    }, status: :not_found
  end
  
  def provider_params
    params.require(:ai_provider).permit(
      :name,
      :provider_type,
      :api_key,
      :api_url,
      :model_identifier,
      :max_tokens,
      :temperature,
      :active,
      :position
    )
  end
  
  def provider_json(provider, detailed: false)
    json = {
      id: provider.id,
      name: provider.name,
      type: provider.provider_type,
      model: provider.model_identifier,
      active: provider.active
    }
    
    if detailed
      json.merge!({
        api_url: provider.api_url,
        max_tokens: provider.max_tokens,
        temperature: provider.temperature,
        position: provider.position,
        agents_count: provider.ai_agents.count,
        created_at: provider.created_at,
        updated_at: provider.updated_at
      })
    end
    
    json
  end
  
  def authenticate_api_user!
    unless current_user
      render json: {
        success: false,
        error: "Authentication required"
      }, status: :unauthorized
    end
  end
  
  def require_admin!
    unless current_user&.administrator?
      render json: {
        success: false,
        error: "Admin access required"
      }, status: :forbidden
    end
  end
end



