class Admin::ThemeEditorController < Admin::BaseController
  layout :resolve_layout
  before_action :set_themes_manager
  before_action :set_active_theme
  before_action :set_current_file, only: [:edit, :update, :destroy, :download, :versions, :restore]
  
  def index
    @file_tree = @themes_manager.file_tree(@active_theme.name)
    @current_file_path = params[:file]
    
    if @current_file_path
      @file_content = @themes_manager.get_file(@current_file_path)
      @file_versions = get_file_versions(@current_file_path)
    end
    
    render layout: 'editor'
  end
  
  def edit
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'file-editor',
          partial: 'admin/theme_editor/editor',
          locals: { file_path: @current_file_path, content: @file_content, versions: @file_versions }
        )
      end
      format.html { redirect_to admin_theme_editor_index_path(file: @current_file_path) }
    end
  end
  
  def update
    # Get the theme file and create new version
    theme_file = ThemeFile.find_by(theme_name: @active_theme.name, file_path: @current_file_path)
    
    if theme_file
      version = @themes_manager.create_file_version(theme_file, file_params[:content], current_user)
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('flash-messages', partial: 'admin/shared/flash', locals: { 
              notice: 'File saved successfully!' 
            }),
            turbo_stream.replace('file-versions', partial: 'admin/theme_editor/versions', locals: { 
              versions: get_file_versions(@current_file_path) 
            })
          ]
        end
        format.json { render json: { success: true, message: 'File saved!' } }
        format.html { redirect_to admin_theme_editor_index_path(file: @current_file_path), notice: 'File saved successfully!' }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('flash-messages', partial: 'admin/shared/flash', locals: { 
            alert: @manager.errors.join(', ') 
          })
        end
        format.json { render json: { success: false, errors: @manager.errors }, status: :unprocessable_entity }
        format.html { redirect_to admin_theme_editor_index_path(file: @current_file_path), alert: @manager.errors.join(', ') }
      end
    end
  end
  
  def create
    file_path = params[:file_path]
    content = params[:content] || ''
    
    if @themes_manager.create_file(file_path, content)
      render json: { success: true, message: 'File created successfully!', file_path: file_path }
    else
      render json: { success: false, errors: @themes_manager.errors }, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @themes_manager.delete_file(@current_file_path)
      redirect_to admin_theme_editor_index_path, notice: 'File deleted successfully!'
    else
      redirect_to admin_theme_editor_index_path(file: @current_file_path), alert: @themes_manager.errors.join(', ')
    end
  end
  
  def rename
    old_path = params[:old_path]
    new_path = params[:new_path]
    
    if @themes_manager.rename_file(old_path, new_path)
      render json: { success: true, message: 'File renamed successfully!', new_path: new_path }
    else
      render json: { success: false, errors: @themes_manager.errors }, status: :unprocessable_entity
    end
  end
  
  def download
    full_path = File.join(@themes_manager.themes_path, @active_theme.name, @current_file_path)
    
    if File.exist?(full_path)
      send_file full_path, filename: File.basename(@current_file_path)
    else
      redirect_to admin_theme_editor_index_path, alert: 'File not found'
    end
  end
  
  def search
    query = params[:query]
    results = @themes_manager.search(query)
    
    render json: { results: results, count: results.size }
  end
  
  def versions
    @versions = @themes_manager.file_versions(@current_file_path)
    
    respond_to do |format|
      format.html
      format.json { render json: @versions }
    end
  end
  
  def restore
    version_id = params[:version_id]
    
    if @themes_manager.restore_version(version_id)
      redirect_to admin_theme_editor_index_path(file: @current_file_path), notice: 'Version restored successfully!'
    else
      redirect_to admin_theme_editor_index_path(file: @current_file_path), alert: @themes_manager.errors.join(', ')
    end
  end
  
  def preview
    # Render preview iframe
    render layout: false
  end
  
  def open_file
    file_path = params[:file]
    
    if file_path.present?
      @current_file_path = file_path
      @file_content = @themes_manager.read_file(@current_file_path)
      @file_versions = @themes_manager.file_versions(@current_file_path)
      
      if @file_content.nil?
        redirect_to admin_theme_editor_index_path, alert: @themes_manager.errors.join(', ')
        return
      end
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('file-editor', partial: 'admin/theme_editor/editor', locals: { 
              file_path: @current_file_path, 
              content: @file_content, 
              versions: @file_versions 
            })
          ]
        end
        format.html { redirect_to admin_theme_editor_index_path(file: @current_file_path) }
      end
    else
      redirect_to admin_theme_editor_index_path, alert: 'No file specified'
    end
  end
  
  def test
    render layout: false
  end
  
  private
  
  def set_themes_manager
    @themes_manager = ThemesManager.new
  end
  
  def set_active_theme
    @active_theme = Theme.active.first
    redirect_to admin_themes_path, alert: 'No active theme found. Please activate a theme first.' unless @active_theme
  end
  
  def set_current_file
    @current_file_path = params[:file] || params[:id]
    @file_content = @themes_manager.get_file(@current_file_path)
    @file_versions = get_file_versions(@current_file_path)
    
    if @file_content.nil?
      redirect_to admin_theme_editor_index_path, alert: 'File not found or could not be read.'
    end
  end
  
  def get_file_versions(file_path)
    theme_file = ThemeFile.find_by(theme_name: @active_theme.name, file_path: file_path)
    return [] unless theme_file
    
    theme_file.theme_file_versions.order(version_number: :desc)
  end
  
  def file_params
    params.require(:file).permit(:content, :change_summary)
  end
  
  def resolve_layout
    action_name == 'index' ? 'editor' : 'admin'
  end
end

