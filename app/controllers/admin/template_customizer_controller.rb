class Admin::TemplateCustomizerController < Admin::BaseController
  layout :resolve_layout
  before_action :set_template, only: [:edit, :update]
  
  def index
    @theme = Theme.current || Theme.first
    @templates = @theme&.templates || Template.none
  end

  def edit
    # Edit view will render GrapesJS editor
    render layout: 'editor'
  end

  def update
    if @template.update(template_params)
      respond_to do |format|
        format.html { redirect_to admin_template_customizer_index_path, notice: 'Template was successfully updated.' }
        format.json { render json: { success: true, message: 'Template saved successfully' } }
      end
    else
      respond_to do |format|
        format.html { render :edit, alert: 'Error updating template' }
        format.json { render json: { success: false, errors: @template.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def load_template
    @template = Template.find(params[:id])
    render json: {
      html: @template.html_content,
      css: @template.css_content,
      js: @template.js_content
    }
  end

  private

  def set_template
    @template = Template.find(params[:id])
    @theme = @template.theme
  end

  def template_params
    params.require(:template).permit(:html_content, :css_content, :js_content, :name, :description)
  end
  
  def resolve_layout
    action_name == 'edit' ? 'editor_fullscreen' : 'admin'
  end
end
