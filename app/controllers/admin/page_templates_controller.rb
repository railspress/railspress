class Admin::PageTemplatesController < Admin::BaseController
  before_action :set_page_template, only: %i[show edit update destroy toggle duplicate]
  layout :choose_layout

  # GET /admin/page_templates
  def index
    @page_templates = PageTemplate.ordered.includes(:pages)
    
    respond_to do |format|
      format.html
      format.json { render json: page_templates_json }
    end
  end

  # GET /admin/page_templates/1
  def show
  end

  # GET /admin/page_templates/new
  def new
    @page_template = PageTemplate.new(template_type: 'default')
  end

  # GET /admin/page_templates/1/edit
  def edit
  end

  # POST /admin/page_templates
  def create
    @page_template = PageTemplate.new(page_template_params)

    respond_to do |format|
      if @page_template.save
        format.html { redirect_to [:admin, @page_template], notice: "Page template was successfully created." }
        format.json { render :show, status: :created, location: @page_template }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @page_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/page_templates/1
  def update
    respond_to do |format|
      if @page_template.update(page_template_params)
        format.html { redirect_to [:admin, @page_template], notice: "Page template was successfully updated." }
        format.json { render :show, status: :ok, location: @page_template }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @page_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/page_templates/1
  def destroy
    @page_template.destroy!

    respond_to do |format|
      format.html { redirect_to admin_page_templates_path, notice: "Page template was successfully destroyed." }
      format.json { head :no_content }
    end
  end
  
  # PATCH /admin/page_templates/1/toggle
  def toggle
    @page_template.update(active: !@page_template.active)
    
    respond_to do |format|
      format.json { render json: { success: true, active: @page_template.active } }
    end
  end
  
  # POST /admin/page_templates/1/duplicate
  def duplicate
    new_template = @page_template.dup
    new_template.name = "#{@page_template.name} (Copy)"
    new_template.position = PageTemplate.maximum(:position).to_i + 1
    
    if new_template.save
      redirect_to [:admin, new_template], notice: "Page template was successfully duplicated."
    else
      redirect_to admin_page_templates_path, alert: "Failed to duplicate page template."
    end
  end
  
  # GET /admin/page_templates/1/customize
  def customize
    @page_template = PageTemplate.find(params[:id])
    render layout: 'grapesjs_fullscreen'
  end
  
  # GET /admin/page_templates/1/theme_edit
  def theme_edit
    @page_template = PageTemplate.find(params[:id])
    @current_file_path = "page_templates/#{@page_template.id}/template.html"
    render layout: 'editor_fullscreen'
  end

  private

  def set_page_template
    @page_template = PageTemplate.find(params[:id])
  end

  def page_template_params
    params.require(:page_template).permit(
      :name, :template_type, :html_content, :css_content, :js_content, 
      :active, :position
    )
  end
  
  def page_templates_json
    @page_templates.map do |template|
      {
        id: template.id,
        name: template.name,
        template_type: template.template_type,
        active: template.active,
        pages_count: template.pages.count,
        position: template.position,
        created_at: template.created_at.strftime("%Y-%m-%d %H:%M"),
        updated_at: template.updated_at.strftime("%Y-%m-%d %H:%M")
      }
    end
  end
  
  def choose_layout
    action_name == 'customize' ? 'grapesjs_fullscreen' : 
    action_name == 'theme_edit' ? 'editor_fullscreen' : 'admin'
  end
end



