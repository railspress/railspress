class Admin::FieldGroupsController < Admin::BaseController
  before_action :set_field_group, only: [:show, :edit, :update, :destroy, :toggle, :duplicate]
  
  # GET /admin/field_groups
  def index
    @field_groups = FieldGroup.ordered
                              .includes(:custom_fields)
    
    @field_groups = @field_groups.where(active: true) if params[:filter] == 'active'
    @field_groups = @field_groups.where(active: false) if params[:filter] == 'inactive'
    
    respond_to do |format|
      format.html
      format.json {
        render json: @field_groups.map { |fg| field_group_json(fg) }
      }
    end
  end
  
  # GET /admin/field_groups/:id
  def show
    @fields = @field_group.custom_fields.ordered
  end
  
  # GET /admin/field_groups/new
  def new
    @field_group = FieldGroup.new
    @field_group.custom_fields.build  # Start with one field
  end
  
  # GET /admin/field_groups/:id/edit
  def edit
    @field_group.custom_fields.build if @field_group.custom_fields.empty?
  end
  
  # POST /admin/field_groups
  def create
    @field_group = FieldGroup.new(field_group_params)
    
    if @field_group.save
      redirect_to edit_admin_field_group_path(@field_group), 
                  notice: 'Field group created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /admin/field_groups/:id
  def update
    if @field_group.update(field_group_params)
      redirect_to edit_admin_field_group_path(@field_group),
                  notice: 'Field group updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  # DELETE /admin/field_groups/:id
  def destroy
    @field_group.destroy
    redirect_to admin_field_groups_path, notice: 'Field group deleted successfully.'
  end
  
  # PATCH /admin/field_groups/:id/toggle
  def toggle
    @field_group.update(active: !@field_group.active)
    
    respond_to do |format|
      format.html { redirect_to admin_field_groups_path }
      format.json { render json: { active: @field_group.active } }
    end
  end
  
  # POST /admin/field_groups/:id/duplicate
  def duplicate
    new_field_group = @field_group.dup
    new_field_group.name = "#{@field_group.name} (Copy)"
    new_field_group.slug = "#{@field_group.slug}_copy_#{Time.now.to_i}"
    
    if new_field_group.save
      # Duplicate fields
      @field_group.custom_fields.each do |field|
        new_field = field.dup
        new_field.field_group = new_field_group
        new_field.save
      end
      
      redirect_to edit_admin_field_group_path(new_field_group),
                  notice: 'Field group duplicated successfully.'
    else
      redirect_to admin_field_groups_path, alert: 'Failed to duplicate field group.'
    end
  end
  
  # POST /admin/field_groups/reorder
  def reorder
    params[:order].each_with_index do |id, index|
      FieldGroup.find(id).update(position: index)
    end
    
    head :ok
  end
  
  private
  
  def set_field_group
    @field_group = FieldGroup.find(params[:id])
  end
  
  def field_group_params
    params.require(:field_group).permit(
      :name,
      :slug,
      :description,
      :position,
      :active,
      location_rules: {},
      custom_fields_attributes: [
        :id,
        :name,
        :label,
        :field_type,
        :instructions,
        :required,
        :default_value,
        :position,
        :_destroy,
        choices: {},
        conditional_logic: {},
        settings: {}
      ]
    )
  end
  
  def field_group_json(field_group)
    {
      id: field_group.id,
      name: field_group.name,
      slug: field_group.slug,
      description: field_group.description,
      active: field_group.active,
      fields_count: field_group.custom_fields.count,
      location_rules: field_group.location_rules
    }
  end
end





