class Admin::BuilderController < Admin::BaseController
  before_action :set_current_theme, only: [:index, :show, :create_version, :save_draft, :publish, :rollback, :preview, :sections]
  before_action :set_builder_theme, only: [:show, :save_draft, :publish, :rollback, :preview, :sections]
  before_action :ensure_editor_access, except: [:preview]
  skip_before_action :verify_authenticity_token, only: [:asset, :preview]
  
  # GET /admin/builder
  def index
    @current_theme_name = @current_theme&.name&.underscore || 'default'
    @builder_theme = BuilderTheme.draft_for_theme(@current_theme_name) || 
                    BuilderTheme.current_for_theme(@current_theme_name)
    
    if @builder_theme
      redirect_to admin_builder_path(@builder_theme)
    else
      # Create initial version
      @builder_theme = BuilderTheme.create_version(@current_theme_name, current_user)
      redirect_to admin_builder_path(@builder_theme)
    end
  end
  
  # GET /admin/builder/:id
  def show
    @current_theme_name = @current_theme&.name&.underscore || 'default'
    @versions = BuilderTheme.for_theme(@current_theme_name).latest.limit(10)
    @snapshots = BuilderThemeSnapshot.for_theme(@current_theme_name).latest.limit(10)
    
    # Get available templates
    @available_templates = get_available_templates
    
    # Load current template (default to index)
    @current_template_name = params[:template] || 'index'
    
    # Get template data from ThemesManager
    @template_data = @builder_theme.get_rendered_file(@current_template_name)
    @current_page_sections = @template_data[:template_content]['sections'] || {}
    @section_order = @template_data[:template_content]['order'] || []
    @theme_schema = load_theme_schema
    
    render layout: 'builder'
  end
  
  # POST /admin/builder/:id/create_version
  def create_version
    parent_version = @builder_theme
    label = params[:label] || "Version #{Time.current.strftime('%Y%m%d_%H%M%S')}"
    
    new_version = BuilderTheme.create_version(
      @current_theme_name,
      current_user,
      parent_version,
      label
    )
    
    # Copy all files from parent version
    parent_version.builder_theme_files.each do |file|
      new_version.builder_theme_files.create!(
        path: file.path,
        content: file.content,
        checksum: file.checksum,
        file_size: file.file_size,
        tenant: new_version.tenant
      )
    end
    
    respond_to do |format|
      format.json { render json: { success: true, version_id: new_version.id, redirect_url: admin_builder_path(new_version) } }
      format.html { redirect_to admin_builder_path(new_version), notice: 'New version created successfully!' }
    end
  end
  
  # PATCH /admin/builder/:id/save_draft
  def save_draft
    sections_data = JSON.parse(params[:sections_data] || '{}')
    settings_data = JSON.parse(params[:settings_data] || '{}')
    
    # Update theme settings
    @builder_theme.settings_data = settings_data
    @builder_theme.save!
    
    # Update sections if provided
    if sections_data.present?
      # Clear existing sections
      @builder_theme.builder_theme_sections.destroy_all
      
      # Add new sections
      sections_data.each do |section_id, section_data|
        @builder_theme.add_section(
          section_data['type'],
          section_data['settings'] || {}
        )
      end
    end
    
    # Update individual files if provided
    if params[:files].present?
      params[:files].each do |file_path, content|
        @builder_theme.update_file(file_path, content)
      end
    end
    
    # Broadcast update to preview
    broadcast_preview_update(@builder_theme)
    
    respond_to do |format|
      format.json { render json: { success: true, message: 'Draft saved successfully!' } }
    end
  end
  
  # POST /admin/builder/:id/publish
  def publish
    begin
      # Publish the builder theme as a PublishedThemeVersion
      published_version = @builder_theme.publish!(current_user)
      
      respond_to do |format|
        format.json { render json: { success: true, message: 'Theme published successfully!', version_id: published_version.id } }
        format.html { redirect_to admin_builder_path(@builder_theme), notice: 'Theme published successfully!' }
      end
    rescue => e
      Rails.logger.error "Publish failed: #{e.message}"
      respond_to do |format|
        format.json { render json: { success: false, errors: [e.message] }, status: :unprocessable_entity }
        format.html { redirect_to admin_builder_path(@builder_theme), alert: "Publish failed: #{e.message}" }
      end
    end
  end
  
  # POST /admin/builder/:id/rollback
  def rollback
    target_snapshot_id = params[:snapshot_id]
    target_snapshot = BuilderThemeSnapshot.find(target_snapshot_id)
    
    new_version = target_snapshot.rollback_to!(target_snapshot)
    
    respond_to do |format|
      format.json { render json: { success: true, version_id: new_version.id, redirect_url: admin_builder_path(new_version) } }
      format.html { redirect_to admin_builder_path(new_version), notice: 'Rolled back successfully!' }
    end
  end
  
  # GET /admin/builder/:id/preview
  def preview
    @builder_theme = BuilderTheme.find(params[:id])
    @current_theme_name = @builder_theme.theme_name
    
    # Get the PublishedThemeVersion for this builder theme
    published_version = PublishedThemeVersion.where(theme: @builder_theme.theme).latest.first
    
    if published_version
      # Use FrontendRendererService for proper rendering
      renderer = FrontendRendererService.new(published_version)
      template_type = params[:template] || 'index'
      
      begin
        @preview_html = renderer.render_template(template_type, preview_context)
        @assets = renderer.assets
      rescue => e
        Rails.logger.error "Preview rendering failed: #{e.message}"
        @preview_html = "<div style='padding: 20px; color: red;'>Preview Error: #{e.message}</div>"
        @assets = { css: '', js: '' }
      end
    else
      @preview_html = "<div style='padding: 20px; color: red;'>No published version found</div>"
      @assets = { css: '', js: '' }
    end
    
    # Render preview iframe
    render 'preview', layout: false
  end

  # GET /admin/builder/:id/sections/:template
  def sections
    template_name = params[:template]
    
    # Get template data from ThemesManager
    template_data = @builder_theme.get_rendered_file(template_name)
    
    if template_data && template_data[:template_content]
      sections_hash = template_data[:template_content]['sections'] || {}
      section_order = template_data[:template_content]['order'] || []
      
      # Convert to array format for JavaScript
      sections = section_order.map.with_index do |section_id, index|
        section_config = sections_hash[section_id]
        next unless section_config
        
        {
          section_id: section_id,
          section_type: section_config['type'],
          settings: section_config['settings'] || {},
          position: index
        }
      end.compact
      
      render json: { success: true, sections: sections }
    else
      render json: { success: false, errors: ['Template not found'] }, status: :not_found
    end
  end
  
  # GET /admin/builder/:id/file/:file_path
  def get_file
    @builder_theme = BuilderTheme.find(params[:id])
    file_path = params[:file_path]
    
    file = @builder_theme.get_file(file_path)
    
    if file
      render json: {
        success: true,
        file: {
          path: file.path,
          content: file.content,
          file_type: file.file_type,
          schema: file.schema_data
        }
      }
    else
      render json: { success: false, error: 'File not found' }, status: :not_found
    end
  end
  
  # PATCH /admin/builder/:id/file/:file_path
  def update_file
    @builder_theme = BuilderTheme.find(params[:id])
    file_path = params[:file_path]
    content = params[:content]
    
    file = @builder_theme.update_file(file_path, content)
    
    # Broadcast update to preview
    broadcast_preview_update(@builder_theme)
    
    render json: {
      success: true,
      file: {
        path: file.path,
        content: file.content,
        checksum: file.checksum,
        file_size: file.file_size
      }
    }
  end
  
  # GET /admin/builder/:id/render_preview
  def render_preview
    @builder_theme = BuilderTheme.find(params[:id])
    template_type = params[:template] || 'index'
    
    renderer = BuilderLiquidRenderer.new(@builder_theme)
    preview_html = renderer.render_preview(template_type)
    
    render json: {
      success: true,
      html: preview_html,
      template: template_type
    }
  end

  # GET /admin/builder/:id/:asset_name
  def asset
    @builder_theme = BuilderTheme.find(params[:id])
    asset_name = params[:asset_name]
    
    # Map common asset names to file paths
    asset_paths = {
      'theme.css' => 'assets/theme.css',
      'theme.js' => 'assets/theme.js',
      'login.css' => 'assets/login.css'
    }
    
    file_path = asset_paths[asset_name] || "assets/#{asset_name}"
    
    # Use ThemesManager to get the file content
    manager = ThemesManager.new
    file_content = manager.get_file(file_path)
    
    if file_content
      content_type = case File.extname(asset_name)
      when '.css'
        'text/css'
      when '.js'
        'application/javascript'
      else
        'text/plain'
      end
      
      render plain: file_content, content_type: content_type
    else
      render plain: '', status: :not_found
    end
  end

  # POST /admin/builder/:id/add_section
  def add_section
    section_type = params[:section_type]
    settings = JSON.parse(params[:settings] || '{}')
    template = params[:template] || 'index'
    
    # Get the current page
    page = @builder_theme.builder_pages.find_by(template_name: template)
    return render json: { success: false, errors: 'Page not found' } unless page
    
    # Add section to the page using BuilderPageSection.create_section
    section = BuilderPageSection.create_section(page, section_type, settings)
    
    respond_to do |format|
      format.json { render json: { success: true, section: section_data(section) } }
    end
  end

  # DELETE /admin/builder/:id/remove_section/:section_id
  def remove_section
    section_id = params[:section_id]
    template = params[:template] || 'index'
    
    # Get the current page
    page = @builder_theme.builder_pages.find_by(template_name: template)
    return render json: { success: false, errors: 'Page not found' } unless page
    
    # Find and remove the section
    section = page.builder_page_sections.find_by(section_id: section_id)
    if section
      section.destroy!
      render json: { success: true, message: 'Section removed successfully!' }
    else
      render json: { success: false, errors: 'Section not found' }
    end
  end

  # PATCH /admin/builder/:id/update_section/:section_id
  def update_section
    section_id = params[:section_id]
    template = params[:template] || 'index'
    # params[:settings] can arrive as a Hash (from JSON) or a String
    raw_settings = params[:settings]
    settings = raw_settings.is_a?(String) ? JSON.parse(raw_settings) : (raw_settings || {})

    # Update the specific section on the current page
    page = @builder_theme.builder_pages.find_by(template_name: template)
    unless page
      return render json: { success: false, errors: 'Page not found' }, status: :not_found
    end

    section = page.builder_page_sections.find_by(section_id: section_id)
    unless section
      return render json: { success: false, errors: 'Section not found' }, status: :not_found
    end

    section.update!(settings: settings)

    render json: { success: true, message: 'Section updated successfully!' }
  end

  # PATCH /admin/builder/:id/reorder_sections
  def reorder_sections
    section_ids = JSON.parse(params[:section_ids] || '[]')
    template = params[:template] || 'index'
    
    # Get the current page
    page = @builder_theme.builder_pages.find_by(template_name: template)
    return render json: { success: false, errors: 'Page not found' } unless page
    
    # Reorder sections for the page using BuilderPageSection.reorder_sections
    BuilderPageSection.reorder_sections(page, section_ids)
    
    respond_to do |format|
      format.json { render json: { success: true, message: 'Sections reordered successfully!' } }
    end
  end

  private

  def section_data(section)
    {
      id: section.section_id,
      type: section.section_type,
      settings: section.settings,
      position: section.position,
      display_name: section.display_name,
      description: section.description
    }
  end
  
  # GET /admin/builder/:id/versions
  def versions
    @builder_theme = BuilderTheme.find(params[:id])
    @versions = BuilderTheme.for_theme(@builder_theme.theme_name).includes(:user).latest
    
    render json: {
      versions: @versions.map do |version|
        {
          id: version.id,
          label: version.label,
          created_at: version.created_at,
          created_by: version.user.email,
          published: version.published?,
          version_number: version.version_number
        }
      end
    }
  end
  
  # GET /admin/builder/:id/snapshots
  def snapshots
    @builder_theme = BuilderTheme.find(params[:id])
    @snapshots = BuilderThemeSnapshot.for_theme(@builder_theme.theme_name).includes(:user).latest
    
    render json: {
      snapshots: @snapshots.map do |snapshot|
        {
          id: snapshot.id,
          created_at: snapshot.created_at,
          created_by: snapshot.user.email,
          checksum: snapshot.checksum
        }
      end
    }
  end
  
  private
  
  def set_current_theme
    # Allow editing any theme, not just active ones
    if params[:theme_id].present?
      @current_theme = Theme.find(params[:theme_id])
    elsif params[:theme_name].present?
      @current_theme = Theme.where("LOWER(name) = ?", params[:theme_name].downcase).first
    else
      # Fallback to active theme
      @current_theme = Theme.active.first
    end
  end

  def preview_context
    {
      current_user: current_user,
      request: request
    }
  end
  
  def set_builder_theme
    @builder_theme = BuilderTheme.find(params[:id])
  end
  
  def get_available_templates
    # Use ThemesManager to get routes from the selected theme
    manager = ThemesManager.new
    
    begin
      # Get routes from the current theme (active or selected)
      theme_name = @current_theme&.name&.underscore || 'default'
      routes_data = manager.get_file("config/routes.json", theme_name)
      routes = routes_data['routes'] || []
      
      # Convert to the format expected by the view
      routes.map do |route|
        {
          'name' => route['name'] || route['template'].humanize,
          'template' => route['template'],
          'path' => route['pattern']
        }
      end
    rescue => e
      Rails.logger.error "Error loading routes from ThemesManager: #{e.message}"
      fallback_templates
    end
  end

  private

  def fallback_templates
    # Fallback to default templates
    [
      { 'name' => 'Home', 'template' => 'index', 'path' => '/' },
      { 'name' => 'Blog', 'template' => 'blog', 'path' => '/blog' },
      { 'name' => 'Post', 'template' => 'post', 'path' => '/post' },
      { 'name' => 'Page', 'template' => 'page', 'path' => '/page' },
      { 'name' => 'Search', 'template' => 'search', 'path' => '/search' },
      { 'name' => '404', 'template' => '404', 'path' => '/404' }
    ]
  end

  def load_theme_schema
    # Load theme settings schema from config/settings_schema.json using ThemesManager
    manager = ThemesManager.new
    settings_content = manager.get_file('config/settings_schema.json')
    return [] unless settings_content

    begin
      JSON.parse(settings_content)
    rescue JSON::ParserError
      []
    end
  end
  
  def broadcast_preview_update(builder_theme)
    # Broadcast to ActionCable channel for live preview updates
    ActionCable.server.broadcast(
      "builder_preview_#{builder_theme.id}",
      {
        type: 'preview_update',
        theme_id: builder_theme.id,
        timestamp: Time.current.to_i
      }
    )
  end
  
  def builder_theme_params
    params.require(:builder_theme).permit(:label, :summary)
  end
end
