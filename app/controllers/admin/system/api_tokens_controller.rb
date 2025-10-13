class Admin::System::ApiTokensController < Admin::BaseController
  before_action :set_api_token, only: [:show, :edit, :update, :destroy, :toggle, :regenerate]
  
  def index
    @api_tokens = current_user.administrator? ? ApiToken.all.includes(:user) : current_user.api_tokens
    @api_tokens = @api_tokens.recent.page(params[:page]).per(20)
  end
  
  def show
  end
  
  def new
    @api_token = current_user.api_tokens.build(role: 'public')
  end
  
  def create
    @api_token = current_user.api_tokens.build(api_token_params)
    
    if @api_token.save
      flash[:notice] = "API Token created successfully. Token: #{@api_token.token}"
      redirect_to admin_system_api_token_path(@api_token)
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @api_token.update(api_token_params)
      flash[:notice] = "API Token updated successfully."
      redirect_to admin_system_api_token_path(@api_token)
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @api_token.destroy
    flash[:notice] = "API Token deleted successfully."
    redirect_to admin_system_api_tokens_path
  end
  
  def toggle
    @api_token.update!(active: !@api_token.active)
    flash[:notice] = "API Token #{@api_token.active ? 'activated' : 'deactivated'}."
    redirect_to admin_system_api_tokens_path
  end
  
  def regenerate
    new_token = SecureRandom.base58(32)
    @api_token.update!(token: new_token)
    flash[:notice] = "API Token regenerated. New token: #{new_token}"
    redirect_to admin_system_api_token_path(@api_token)
  end
  
  private
  
  def set_api_token
    @api_token = if current_user.administrator?
      ApiToken.find(params[:id])
    else
      current_user.api_tokens.find(params[:id])
    end
  end
  
  def api_token_params
    permitted = [:name, :role, :expires_at, :active]
    
    # Only admins can set custom permissions
    permitted << :permissions if current_user.administrator?
    
    params.require(:api_token).permit(permitted)
  end
end

