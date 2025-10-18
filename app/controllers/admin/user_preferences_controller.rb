class Admin::UserPreferencesController < Admin::BaseController
  def show
    render json: { 
      sidebar_order: current_user.sidebar_order 
    }
  end

  def update
    if params[:sidebar_order].present?
      current_user.update!(sidebar_order: params[:sidebar_order])
      render json: { status: 'success' }
    else
      render json: { status: 'error', message: 'No sidebar order provided' }, status: :unprocessable_entity
    end
  end
end
