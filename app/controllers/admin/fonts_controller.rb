class Admin::FontsController < Admin::BaseController
  before_action :set_font, only: [:show, :edit, :update, :destroy, :toggle, :preview]
  
  # GET /admin/fonts
  def index
    @fonts = CustomFont.ordered.all
    
    respond_to do |format|
      format.html
      format.json {
        render json: @fonts.map { |f| font_json(f) }
      }
    end
  end
  
  # GET /admin/fonts/:id
  def show
  end
  
  # GET /admin/fonts/new
  def new
    @font = CustomFont.new
    @font.weights = ['400']
    @font.styles = ['normal']
  end
  
  # GET /admin/fonts/:id/edit
  def edit
  end
  
  # POST /admin/fonts
  def create
    @font = CustomFont.new(font_params)
    
    if @font.save
      redirect_to admin_fonts_path, notice: 'Font added successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /admin/fonts/:id
  def update
    if @font.update(font_params)
      redirect_to admin_fonts_path, notice: 'Font updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  # DELETE /admin/fonts/:id
  def destroy
    @font.destroy
    redirect_to admin_fonts_path, notice: 'Font deleted successfully.'
  end
  
  # PATCH /admin/fonts/:id/toggle
  def toggle
    @font.update(active: !@font.active)
    
    respond_to do |format|
      format.html { redirect_to admin_fonts_path }
      format.json { render json: { active: @font.active } }
    end
  end
  
  # GET /admin/fonts/:id/preview
  def preview
    render layout: false
  end
  
  # GET /admin/fonts/google
  def google
    # Popular Google Fonts list
    @popular_fonts = [
      { name: 'Inter', category: 'sans-serif', popularity: 1 },
      { name: 'Roboto', category: 'sans-serif', popularity: 2 },
      { name: 'Open Sans', category: 'sans-serif', popularity: 3 },
      { name: 'Lato', category: 'sans-serif', popularity: 4 },
      { name: 'Montserrat', category: 'sans-serif', popularity: 5 },
      { name: 'Poppins', category: 'sans-serif', popularity: 6 },
      { name: 'Raleway', category: 'sans-serif', popularity: 7 },
      { name: 'Playfair Display', category: 'serif', popularity: 8 },
      { name: 'Merriweather', category: 'serif', popularity: 9 },
      { name: 'Roboto Mono', category: 'monospace', popularity: 10 }
    ]
    
    render layout: false
  end
  
  # POST /admin/fonts/add_google
  def add_google
    font_family = params[:family]
    
    font = CustomFont.create!(
      name: font_family,
      family: font_family,
      source: 'google',
      weights: params[:weights] || ['400'],
      styles: params[:styles] || ['normal'],
      fallback: params[:fallback] || 'sans-serif',
      active: true
    )
    
    redirect_to admin_fonts_path, notice: "Added #{font_family} from Google Fonts."
  end
  
  private
  
  def set_font
    @font = CustomFont.find(params[:id])
  end
  
  def font_params
    params.require(:custom_font).permit(
      :name,
      :family,
      :source,
      :url,
      :fallback,
      :active,
      weights: [],
      styles: []
    )
  end
  
  def font_json(font)
    {
      id: font.id,
      name: font.name,
      family: font.family,
      source: font.source,
      weights: font.weights,
      styles: font.styles,
      active: font.active,
      url: font.font_url
    }
  end
end




