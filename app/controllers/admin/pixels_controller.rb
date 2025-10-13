class Admin::PixelsController < Admin::BaseController
  before_action :set_pixel, only: [:edit, :update, :destroy, :toggle, :test]
  
  # GET /admin/pixels
  def index
    @pixels = Pixel.includes(:versions).ordered
    
    # Filter by status
    @pixels = @pixels.active if params[:status] == 'active'
    @pixels = @pixels.inactive if params[:status] == 'inactive'
    
    # Filter by provider
    @pixels = @pixels.by_provider(params[:provider]) if params[:provider].present?
    
    # Filter by position
    @pixels = @pixels.by_position(params[:position]) if params[:position].present?
    
    # Stats
    @stats = {
      total: Pixel.count,
      active: Pixel.active.count,
      inactive: Pixel.inactive.count,
      providers: Pixel.group(:provider).count.keys.compact.count
    }
  end
  
  # GET /admin/pixels/new
  def new
    @pixel = Pixel.new
  end
  
  # GET /admin/pixels/:id/edit
  def edit
  end
  
  # POST /admin/pixels
  def create
    @pixel = Pixel.new(pixel_params)
    
    if @pixel.save
      redirect_to admin_pixels_path, notice: 'Pixel added successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /admin/pixels/:id
  def update
    if @pixel.update(pixel_params)
      redirect_to admin_pixels_path, notice: 'Pixel updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  # DELETE /admin/pixels/:id
  def destroy
    @pixel.destroy
    redirect_to admin_pixels_path, notice: 'Pixel deleted successfully.'
  end
  
  # PATCH /admin/pixels/:id/toggle
  def toggle
    @pixel.update(active: !@pixel.active)
    redirect_to admin_pixels_path, notice: "Pixel #{@pixel.active? ? 'activated' : 'deactivated'}."
  end
  
  # GET /admin/pixels/:id/test
  def test
    @pixel_code = @pixel.render_code
    render layout: false
  end
  
  # POST /admin/pixels/bulk_action
  def bulk_action
    pixel_ids = params[:pixel_ids] || []
    action = params[:bulk_action]
    
    case action
    when 'activate'
      Pixel.where(id: pixel_ids).update_all(active: true)
      message = "#{pixel_ids.count} pixels activated."
    when 'deactivate'
      Pixel.where(id: pixel_ids).update_all(active: false)
      message = "#{pixel_ids.count} pixels deactivated."
    when 'delete'
      Pixel.where(id: pixel_ids).destroy_all
      message = "#{pixel_ids.count} pixels deleted."
    else
      message = "Invalid action."
    end
    
    redirect_to admin_pixels_path, notice: message
  end
  
  private
  
  def set_pixel
    @pixel = Pixel.find(params[:id])
  end
  
  def pixel_params
    params.require(:pixel).permit(
      :name,
      :pixel_type,
      :provider,
      :pixel_id,
      :custom_code,
      :position,
      :active,
      :notes
    )
  end
end






