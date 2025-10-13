class Admin::ThemeEditorController < Admin::BaseController
  layout :resolve_layout
  before_action :set_theme_manager
  before_action :set_current_file, only: [:edit, :update, :destroy, :download, :versions, :restore]
  
  def index
    @active_theme = SiteSetting.get('active_theme', 'default')
    @file_tree = @manager.file_tree
    @current_file_path = params[:file]
    
    if @current_file_path
      @file_content = @manager.read_file(@current_file_path)
      @file_versions = @manager.file_versions(@current_file_path)
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
    if @manager.write_file(@current_file_path, file_params[:content])
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('flash-messages', partial: 'admin/shared/flash', locals: { 
              notice: 'File saved successfully!' 
            }),
            turbo_stream.replace('file-versions', partial: 'admin/theme_editor/versions', locals: { 
              versions: @manager.file_versions(@current_file_path) 
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
    
    if @manager.create_file(file_path, content)
      render json: { success: true, message: 'File created successfully!', file_path: file_path }
    else
      render json: { success: false, errors: @manager.errors }, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @manager.delete_file(@current_file_path)
      redirect_to admin_theme_editor_index_path, notice: 'File deleted successfully!'
    else
      redirect_to admin_theme_editor_index_path(file: @current_file_path), alert: @manager.errors.join(', ')
    end
  end
  
  def rename
    old_path = params[:old_path]
    new_path = params[:new_path]
    
    if @manager.rename_file(old_path, new_path)
      render json: { success: true, message: 'File renamed successfully!', new_path: new_path }
    else
      render json: { success: false, errors: @manager.errors }, status: :unprocessable_entity
    end
  end
  
  def download
    full_path = @manager.instance_variable_get(:@theme_path).join(@current_file_path)
    
    if File.exist?(full_path)
      send_file full_path, filename: File.basename(@current_file_path)
    else
      redirect_to admin_theme_editor_index_path, alert: 'File not found'
    end
  end
  
  def search
    query = params[:query]
    results = @manager.search(query)
    
    render json: { results: results, count: results.size }
  end
  
  def versions
    @versions = @manager.file_versions(@current_file_path)
    
    respond_to do |format|
      format.html
      format.json { render json: @versions }
    end
  end
  
  def restore
    version_id = params[:version_id]
    
    if @manager.restore_version(version_id)
      redirect_to admin_theme_editor_index_path(file: @current_file_path), notice: 'Version restored successfully!'
    else
      redirect_to admin_theme_editor_index_path(file: @current_file_path), alert: @manager.errors.join(', ')
    end
  end
  
  def preview
    # Render preview iframe
    render layout: false
  end
  
  private
  
  def set_theme_manager
    theme_name = params[:theme] || SiteSetting.get('active_theme', 'default')
    @manager = ThemeFileManager.new(theme_name)
  rescue ArgumentError => e
    redirect_to admin_root_path, alert: e.message
  end
  
  def set_current_file
    @current_file_path = params[:file] || params[:id]
    @file_content = @manager.read_file(@current_file_path)
    @file_versions = @manager.file_versions(@current_file_path)
    
    if @file_content.nil?
      redirect_to admin_theme_editor_index_path, alert: @manager.errors.join(', ')
    end
  end
  
  def file_params
    params.require(:file).permit(:content, :change_summary)
  end
  
  def resolve_layout
    action_name == 'index' ? 'editor_fullscreen' : 'admin'
  end
end

