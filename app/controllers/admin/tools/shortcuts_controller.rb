class Admin::Tools::ShortcutsController < Admin::BaseController
  before_action :set_shortcut, only: [:show, :edit, :update, :destroy, :toggle]
  
  # GET /admin/tools/shortcuts
  def index
    @shortcuts = Shortcut.order(:category, :position)
    
    respond_to do |format|
      format.html
      format.json {
        render json: @shortcuts.active.order(:category, :position).map { |s| shortcut_json(s) }
      }
    end
  end
  
  # GET /admin/tools/shortcuts/:id
  def show
  end
  
  # GET /admin/tools/shortcuts/new
  def new
    @shortcut = Shortcut.new
  end
  
  # GET /admin/tools/shortcuts/:id/edit
  def edit
  end
  
  # POST /admin/tools/shortcuts
  def create
    @shortcut = Shortcut.new(shortcut_params)
    
    if @shortcut.save
      redirect_to admin_tools_shortcuts_path, notice: 'Shortcut created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  # PATCH /admin/tools/shortcuts/:id
  def update
    if @shortcut.update(shortcut_params)
      redirect_to admin_tools_shortcuts_path, notice: 'Shortcut updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  # DELETE /admin/tools/shortcuts/:id
  def destroy
    @shortcut.destroy
    redirect_to admin_tools_shortcuts_path, notice: 'Shortcut deleted successfully.'
  end
  
  # PATCH /admin/tools/shortcuts/:id/toggle
  def toggle
    @shortcut.update(active: !@shortcut.active)
    redirect_to admin_tools_shortcuts_path, notice: "Shortcut #{@shortcut.active? ? 'enabled' : 'disabled'}."
  end
  
  # POST /admin/tools/shortcuts/reorder
  def reorder
    params[:order].each_with_index do |id, index|
      Shortcut.find(id).update(position: index)
    end
    
    head :ok
  end
  
  private
  
  def set_shortcut
    @shortcut = Shortcut.find(params[:id])
  end
  
  def shortcut_params
    params.require(:shortcut).permit(
      :name, :description, :action_type, :action_value,
      :icon, :category, :position, :active
    )
  end
  
  def shortcut_json(shortcut)
    {
      id: shortcut.id,
      name: shortcut.name,
      description: shortcut.description,
      action_type: shortcut.action_type,
      action_value: shortcut.action_value,
      icon: shortcut.icon,
      category: shortcut.category
    }
  end
end


