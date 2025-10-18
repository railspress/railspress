class Admin::BuilderController < Admin::BaseController
  before_action :set_current_theme, only: [:index, :show, :create_version, :save_draft, :publish, :rollback, :preview, :sections, :update_section, :reorder_sections, :remove_section, :add_section, :add_block, :remove_block, :update_block, :update_theme_settings]
  before_action :set_builder_theme, only: [:show, :save_draft, :publish, :rollback, :preview, :sections, :update_section, :reorder_sections, :remove_section, :add_section, :add_block, :remove_block, :update_block, :update_theme_settings]
  before_action :ensure_editor_access, except: [:preview, :save_draft]
  skip_before_action :verify_authenticity_token, only: [:preview]
  
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
    
    # Get template data from ThemePreview (new system)
    theme_preview = ThemePreview.find_or_create_for_builder(@builder_theme, @current_template_name)
    
    # Clean up any duplicate sections first
    theme_preview.cleanup_duplicates!
    
    @current_page_sections = {}
    @section_order = []
    
    # Build sections hash from ThemePreviewSection records
    Rails.logger.info "=== SHOW ACTION DEBUG ==="
    Rails.logger.info "ThemePreview sections count: #{theme_preview.ordered_sections.count}"
    
    # DEDUPLICATE SECTIONS: Group by section_id and take the latest one
    sections_by_id = theme_preview.ordered_sections.group_by(&:section_id)
    Rails.logger.info "Sections grouped by ID: #{sections_by_id.keys}"
    
    sections_by_id.each do |section_id, sections|
      # Take the latest section if there are duplicates
      section = sections.max_by(&:updated_at)
      Rails.logger.info "Using section #{section_id} with position #{section.position} (from #{sections.count} duplicates)"
      
      @current_page_sections[section_id] = {
        'type' => section.section_type,
        'settings' => section.settings
      }
      @section_order << section_id
    end
    
    Rails.logger.info "Final section_order: #{@section_order}"
    Rails.logger.info "Final current_page_sections keys: #{@current_page_sections.keys}"
    Rails.logger.info "Section order has duplicates: #{@section_order.length != @section_order.uniq.length}"
    Rails.logger.info "Section order unique count: #{@section_order.uniq.length}"
    
    # FORCE DEDUPLICATION: Always deduplicate section order
    Rails.logger.warn "FORCE DEDUPLICATION: Original order #{@section_order.length}, unique order #{@section_order.uniq.length}"
    @section_order = @section_order.uniq
    Rails.logger.info "FINAL CLEAN section_order: #{@section_order}"
    
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
  
  # PATCH /admin/builder/:id/autosave
  def autosave
    sections_data = JSON.parse(params[:sections_data] || params.dig(:builder, :sections_data) || '{}')
    settings_data = JSON.parse(params[:settings_data] || params.dig(:builder, :settings_data) || '{}')
    template = params[:template] || params.dig(:builder, :template) || 'index'
    
    begin
      Rails.logger.info "Autosave triggered for template: #{template}"
      
      # Get or create theme preview for this template
      theme_preview = ThemePreview.find_or_create_for_builder(@builder_theme, template)
      
      # Update sections in ThemePreview (only if sections_data is provided)
      if sections_data.present?
        # Get existing sections for efficient updates
        existing_sections = theme_preview.theme_preview_sections.index_by(&:section_id)
        processed_section_ids = []
        
        # Create or update sections from the data
        sections_data.each_with_index do |(section_id, section_config), index|
          processed_section_ids << section_id
          
          if existing_sections[section_id]
            # Update existing section
            existing_sections[section_id].update!(
              section_type: section_config['type'] || section_id,
              settings: section_config['settings'] || {},
              position: index
            )
          else
            # Create new section
            theme_preview.theme_preview_sections.create!(
              section_id: section_id,
              section_type: section_config['type'] || section_id,
              settings: section_config['settings'] || {},
              position: index
            )
          end
        end
        
        # Remove sections that are no longer in the data
        sections_to_remove = existing_sections.keys - processed_section_ids
        sections_to_remove.each do |section_id|
          existing_sections[section_id]&.destroy!
        end
      end
      
      # Update theme settings in ThemePreviewFile (only if settings_data is provided)
      if settings_data.present?
        ThemePreviewFile.update_template_content(
          @builder_theme, 
          'settings_data', 
          settings_data
        )
      end
      
      # Update individual files in ThemePreviewFile if provided
      if params[:files].present?
        params[:files].each do |file_path, content|
          preview_file = @builder_theme.theme_preview_files.find_or_create_by(
            file_path: file_path,
            file_type: 'custom'
          ) do |file|
            file.tenant = @builder_theme.tenant
          end
          preview_file.update!(content: content)
        end
      end
      
      respond_to do |format|
        format.json { render json: { success: true, message: 'Autosaved successfully!' } }
      end
      
    rescue => e
      Rails.logger.error "Autosave failed: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      Rails.logger.error "Params: #{params.inspect}"
      render json: { success: false, errors: [e.message], backtrace: e.backtrace.first(5) }, status: :unprocessable_entity
    end
  end

  # PATCH /admin/builder/:id/save_draft
  def save_draft
    Rails.logger.info "=== SAVE DRAFT CALLED ==="
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "@builder_theme: #{@builder_theme.inspect}"
    
    # Check if @builder_theme is nil
    if @builder_theme.nil?
      Rails.logger.error "ERROR: @builder_theme is nil!"
      render json: { success: false, errors: ['Builder theme not found'] }, status: :not_found
      return
    end
    
    sections_data = JSON.parse(params[:sections_data] || params.dig(:builder, :sections_data) || '{}')
    settings_data = JSON.parse(params[:settings_data] || params.dig(:builder, :settings_data) || '{}')
    template = params[:template] || params.dig(:builder, :template) || 'index'
    
    begin
      Rails.logger.info "Save draft params: #{params.inspect}"
      Rails.logger.info "Sections data: #{sections_data.inspect}"
      Rails.logger.info "Settings data: #{settings_data.inspect}"
      
      # Get or create theme preview for this template
      theme_preview = ThemePreview.find_or_create_for_builder(@builder_theme, template)
      
      # Update sections in ThemePreview
      if sections_data.present?
        # Get existing sections for efficient updates
        existing_sections = theme_preview.theme_preview_sections.index_by(&:section_id)
        processed_section_ids = []
        
        # Create or update sections from the data
        sections_data.each_with_index do |(section_id, section_config), index|
          processed_section_ids << section_id
          
          if existing_sections[section_id]
            # Update existing section
            existing_sections[section_id].update!(
              section_type: section_config['type'] || section_id,
              settings: section_config['settings'] || {},
              position: index
            )
          else
            # Create new section
            theme_preview.theme_preview_sections.create!(
              section_id: section_id,
              section_type: section_config['type'] || section_id,
              settings: section_config['settings'] || {},
              position: index
            )
          end
        end
        
        # Remove sections that are no longer in the data
        sections_to_remove = existing_sections.keys - processed_section_ids
        sections_to_remove.each do |section_id|
          existing_sections[section_id]&.destroy!
        end
      end
      
      # Update theme settings in ThemePreviewFile
      if settings_data.present?
        ThemePreviewFile.update_template_content(
          @builder_theme, 
          template, 
          settings_data
        )
      end
      
      # Update individual files in ThemePreviewFile if provided
      if params[:files].present?
        params[:files].each do |file_path, content|
          preview_file = @builder_theme.theme_preview_files.find_or_create_by(
            file_path: file_path,
            file_type: 'custom'
          ) do |file|
            file.tenant = @builder_theme.tenant
          end
          preview_file.update!(content: content)
        end
      end
      
      # Broadcast update to preview
      broadcast_preview_update(@builder_theme)
      
      respond_to do |format|
        format.json { render json: { success: true, message: 'Draft saved to preview successfully!' } }
      end
      
    rescue => e
      Rails.logger.error "Save draft failed: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      Rails.logger.error "Params: #{params.inspect}"
      respond_to do |format|
        format.json { render json: { success: false, errors: [e.message], backtrace: e.backtrace.first(5) }, status: :unprocessable_entity }
      end
    end
  end

  # PATCH /admin/builder/:id/publish
  def publish
    template = params[:template] || params.dig(:builder, :template) || 'index'
    
    begin
      Rails.logger.info "Publishing template: #{template}"
      
      # Get the theme preview
      theme_preview = ThemePreview.find_or_create_for_builder(@builder_theme, template)
      
      # Ensure we have a published version to work with
      published_version = @builder_theme.ensure_published_version!
      
      # Copy sections from ThemePreview to PublishedThemeFile
      sections_data = {}
      section_order = []
      
      theme_preview.ordered_sections.each do |section|
        sections_data[section.section_id] = {
          'type' => section.section_type,
          'settings' => section.settings
        }
        section_order << section.section_id
      end
      
      # Create/update the template file in PublishedThemeFile
      template_content = {
        'name' => template.humanize,
        'sections' => sections_data,
        'order' => section_order
      }
      
      template_file = published_version.published_theme_files.find_or_create_by(
        file_path: "templates/#{template}.json",
        file_type: 'template'
      )
      
      template_file.update!(
        content: template_content.to_json,
        checksum: Digest::MD5.hexdigest(template_content.to_json)
      )
      
      # Copy theme settings if they exist in preview
      settings_file = @builder_theme.theme_preview_files.find_by(
        file_path: 'config/settings_data.json'
      )
      
      if settings_file
        published_settings_file = published_version.published_theme_files.find_or_create_by(
          file_path: 'config/settings_data.json',
          file_type: 'config'
        )
        published_settings_file.update!(
          content: settings_file.content,
          checksum: Digest::MD5.hexdigest(settings_file.content)
        )
      end
      
      # Copy any other custom files from preview to published
      @builder_theme.theme_preview_files.where.not(
        file_path: ['config/settings_data.json', "templates/#{template}.json"]
      ).each do |preview_file|
        published_file = published_version.published_theme_files.find_or_create_by(
          file_path: preview_file.file_path,
          file_type: preview_file.file_type
        )
        published_file.update!(
          content: preview_file.content,
          checksum: Digest::MD5.hexdigest(preview_file.content)
        )
      end
      
      # Mark the builder theme as published
      @builder_theme.update!(published: true)
      
      Rails.logger.info "Successfully published template: #{template}"
      
      respond_to do |format|
        format.json { render json: { success: true, message: 'Theme published successfully!' } }
      end
      
    rescue => e
      Rails.logger.error "Publish failed: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      render json: { success: false, errors: [e.message], backtrace: e.backtrace.first(5) }, status: :unprocessable_entity
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
    
    # Ensure we have a published version to work with for base files (layout, assets)
    published_version = @builder_theme.ensure_published_version!
    
    template_type = params[:template] || 'index'
    
    begin
      # Use ThemePreviewRenderer for builder previews (uses ThemePreview data + PublishedThemeFile base files)
      renderer = ThemePreviewRenderer.new(@builder_theme, template_type)
      @preview_html = renderer.render
      @assets = { css: '', js: '' } # Assets are embedded in HTML by ThemePreviewRenderer
    rescue => e
      Rails.logger.error "Builder preview rendering failed: #{e.message}"
      @preview_html = "<div style='padding: 20px; color: red;'>Preview Error: #{e.message}</div>"
      @assets = { css: '', js: '' }
    end
    
    # Render preview iframe
    render 'preview', layout: false
  end

  # GET /admin/builder/:id/sections/:template
  def sections
    template_name = params[:template]
    
    begin
      # Get or create theme preview for this template
      theme_preview = ThemePreview.find_or_create_for_builder(@builder_theme, template_name)
      
      # Get sections from ThemePreview
      sections = theme_preview.ordered_sections.map do |section|
        {
          section_id: section.section_id,
          section_type: section.section_type,
          settings: section.settings,
          position: section.position
        }
      end
      
      render json: { success: true, sections: sections }
    rescue => e
      Rails.logger.error "Error getting sections: #{e.message}"
      render json: { success: false, errors: [e.message] }, status: :unprocessable_entity
    end
  end

  # GET /admin/builder/:id/available_sections
  def available_sections
    begin
      # Get available sections from the BuilderTheme's theme directory
      @builder_theme = BuilderTheme.find(params[:id])
      
      # Get the theme name from the BuilderTheme
      theme_name = @builder_theme.theme_name
      
      # Get sections directory from the theme
      manager = ThemesManager.new
      sections_dir = File.join(manager.themes_path, theme_name, 'sections')
      
      if Dir.exist?(sections_dir)
        sections = []
        processed_sections = Set.new
        
        # First, process .liquid files
        Dir.glob(File.join(sections_dir, '*.liquid')).each do |file_path|
          section_name = File.basename(file_path, '.liquid')
          section_name = section_name.to_s
          
          # Skip if we've already processed this section
          next if processed_sections.include?(section_name)
          processed_sections.add(section_name)
          
          # Try to read section schema for description
          schema_path = File.join(sections_dir, "#{section_name}.json")
          description = 'Section description'
          category = 'General'
          preview_image = nil
          
          if File.exist?(schema_path)
            begin
              schema = JSON.parse(File.read(schema_path))
              description = schema['description'] || 'Section description'
              category = schema['category'] || 'General'
              preview_image = schema['preview_image']
            rescue JSON::ParserError
              # Use default description if schema is invalid
            end
          end
          
          # Extract context requests from schema
          context_requests = {}
          if File.exist?(schema_path)
            begin
              schema = JSON.parse(File.read(schema_path))
              context_requests = schema['context_requests'] || {}
            rescue JSON::ParserError
              # Use empty context requests if schema is invalid
            end
          end
          
          sections << {
            id: section_name,
            name: section_name.humanize,
            description: description,
            category: category,
            preview_image: preview_image,
            context_requests: context_requests
          }
        end
        
        # Then, process standalone .json files (sections without .liquid files)
        Dir.glob(File.join(sections_dir, '*.json')).each do |file_path|
          section_name = File.basename(file_path, '.json')
          section_name = section_name.to_s
          
          # Skip if we've already processed this section
          next if processed_sections.include?(section_name)
          processed_sections.add(section_name)
          
          begin
            schema = JSON.parse(File.read(file_path))
            sections << {
              id: section_name,
              name: section_name.humanize,
              description: schema['description'] || 'Section description',
              category: schema['category'] || 'General',
              preview_image: schema['preview_image'],
              context_requests: schema['context_requests'] || {}
            }
          rescue JSON::ParserError
            # Skip invalid JSON files
            next
          end
        end
        
        # Add context data for sections that request it
        sections_with_context = sections.map do |section|
          if section[:context_requests].present?
            section[:context_data] = get_context_data_for_section(section[:context_requests])
          end
          section
        end
        
        render json: { success: true, sections: sections_with_context }
      else
        render json: { success: false, errors: ['Sections directory not found'] }, status: :not_found
      end
      
    rescue => e
      Rails.logger.error "Error loading available sections: #{e.message}"
      render json: { success: false, errors: [e.message] }, status: :internal_server_error
    end
  end

  # GET /admin/builder/:id/section_data
  def section_data
    begin
      @builder_theme = BuilderTheme.find(params[:id])
      section_type = params[:section_type]
      
      # Get section schema
      theme_name = @builder_theme.theme_name
      manager = ThemesManager.new
      schema_path = File.join(manager.themes_path, theme_name, 'sections', "#{section_type}.json")
      
      schema = {}
      if File.exist?(schema_path)
        schema = JSON.parse(File.read(schema_path))
      end
      
      # Get context data for this section
      context_data = get_context_data_for_section(schema['context_requests'] || {})
      
      render json: { 
        success: true, 
        schema: schema,
        context_data: context_data
      }
      
    rescue => e
      Rails.logger.error "Error loading section data: #{e.message}"
      render json: { success: false, errors: [e.message] }, status: :internal_server_error
    end
  end

  def get_context_data_for_section(context_requests)
    context_data = {}
    
    context_requests.each do |key, request_config|
      case key
      when 'menus'
        context_data[key] = get_menus_context
      when 'pages'
        context_data[key] = get_pages_context
      when 'posts'
        context_data[key] = get_posts_context
      when 'categories'
        context_data[key] = get_categories_context
      when 'products'
        context_data[key] = get_products_context
      else
        Rails.logger.warn "Unknown context request: #{key}"
      end
    end
    
    context_data
  end

  def get_menus_context
    # Return available menus for navigation
    [
      {
        id: 1,
        name: 'Main Navigation',
        menu_items: [
          { id: 1, title: 'Home', url: '/', order: 1 },
          { id: 2, title: 'About', url: '/about', order: 2 },
          { id: 3, title: 'Services', url: '/services', order: 3 },
          { id: 4, title: 'Contact', url: '/contact', order: 4 }
        ]
      },
      {
        id: 2,
        name: 'Footer Links',
        menu_items: [
          { id: 5, title: 'Privacy Policy', url: '/privacy', order: 1 },
          { id: 6, title: 'Terms of Service', url: '/terms', order: 2 },
          { id: 7, title: 'Support', url: '/support', order: 3 }
        ]
      }
    ]
  end

  def get_pages_context
    # Return available pages
    [
      { id: 1, title: 'Home', slug: 'home', url: '/' },
      { id: 2, title: 'About Us', slug: 'about', url: '/about' },
      { id: 3, title: 'Services', slug: 'services', url: '/services' },
      { id: 4, title: 'Contact', slug: 'contact', url: '/contact' },
      { id: 5, title: 'Privacy Policy', slug: 'privacy', url: '/privacy' }
    ]
  end

  def get_posts_context
    # Return recent posts
    [
      { id: 1, title: 'Welcome to Our Blog', slug: 'welcome-blog', url: '/blog/welcome-blog' },
      { id: 2, title: 'Getting Started Guide', slug: 'getting-started', url: '/blog/getting-started' }
    ]
  end

  def get_categories_context
    # Return post categories
    [
      { id: 1, name: 'News', slug: 'news' },
      { id: 2, name: 'Tutorials', slug: 'tutorials' },
      { id: 3, name: 'Updates', slug: 'updates' }
    ]
  end

  def get_products_context
    # Return sample products (for e-commerce sections)
    [
      { id: 1, title: 'Sample Product 1', price: 29.99, url: '/products/sample-1' },
      { id: 2, title: 'Sample Product 2', price: 49.99, url: '/products/sample-2' }
    ]
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


  # POST /admin/builder/:id/add_section
  def add_section
    section_type = params[:section_type]
    # Handle both string and ActionController::Parameters for settings
    raw_settings = params[:settings] || params.dig(:builder, :settings) || {}
    settings = case raw_settings
               when String
                 JSON.parse(raw_settings)
               when ActionController::Parameters
                 raw_settings.to_unsafe_h
               else
                 raw_settings || {}
               end
    
    # Ensure settings is always a Hash (not nil) to satisfy the NOT NULL constraint
    settings = {} if settings.nil?
    template = params[:template] || 'index'
    
    begin
      Rails.logger.info "Add section params: #{params.inspect}"
      Rails.logger.info "Section type: #{section_type}, Template: #{template}"
      
      if section_type.blank?
        return render json: { success: false, errors: ['Section type is required'] }, status: :bad_request
      end

      # Get or create theme preview (without auto-initialization to avoid clearing sections)
      theme_preview = ThemePreview.find_or_create_by(
        builder_theme: @builder_theme,
        template_name: template
      ) do |preview|
        preview.tenant = @builder_theme.tenant
      end
      
      # Generate a unique section ID
      section_id = "#{section_type}_#{SecureRandom.hex(4)}"
      
      # Create new section in ThemePreviewSection
      section = theme_preview.theme_preview_sections.create!(
        section_id: section_id,
        section_type: section_type,
        settings: settings,
        position: theme_preview.theme_preview_sections.count
      )
      
      Rails.logger.info "Successfully added section #{section_id} (#{section_type}) to template #{template}"
      
      respond_to do |format|
        format.json { render json: { 
          success: true, 
          section: {
            section_id: section.section_id,
            section_type: section.section_type,
            settings: section.settings,
            position: section.position
          }
        } }
      end
      
    rescue => e
      Rails.logger.error "Add section failed: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      Rails.logger.error "Params: #{params.inspect}"
      render json: { success: false, errors: [e.message], backtrace: e.backtrace.first(5) }, status: :unprocessable_entity
    end
  end

  # DELETE /admin/builder/:id/remove_section/:section_id
  def remove_section
    section_id = params[:section_id]
    template = params[:template] || 'index'
    
    begin
      Rails.logger.info "Remove section params: #{params.inspect}"
      Rails.logger.info "Section ID: #{section_id}, Template: #{template}"
      
      if section_id.blank?
        return render json: { success: false, errors: ['Section ID is required'] }, status: :bad_request
      end

      # Get or create theme preview
      theme_preview = ThemePreview.find_or_create_for_builder(@builder_theme, template)
      
      # Find and remove the section from ThemePreviewSection
      section = theme_preview.theme_preview_sections.find_by(section_id: section_id)
      if section
        section.destroy!
        Rails.logger.info "Successfully removed section #{section_id} from template #{template}"
        
        render json: { success: true, message: 'Section removed successfully!' }
      else
        Rails.logger.warn "Section #{section_id} not found in template #{template}"
        render json: { success: false, errors: ['Section not found'] }, status: :not_found
      end
      
    rescue => e
      Rails.logger.error "Remove section failed: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      Rails.logger.error "Params: #{params.inspect}"
      render json: { success: false, errors: [e.message], backtrace: e.backtrace.first(5) }, status: :unprocessable_entity
    end
  end

  # POST /admin/builder/:id/add_block
  def add_block
    section_id = params[:section_id]
    block_type = params[:block_type]
    block_id = params[:block_id]
    settings = case params[:settings]
               when String
                 JSON.parse(params[:settings])
               when ActionController::Parameters
                 params[:settings].to_unsafe_h
               else
                 params[:settings] || {}
               end
    template = params[:template] || 'index'
    
    begin
      Rails.logger.info "Add block params: #{params.inspect}"
      Rails.logger.info "Section ID: #{section_id}, Block Type: #{block_type}, Block ID: #{block_id}"
      
      if section_id.blank? || block_type.blank? || block_id.blank?
        return render json: { success: false, errors: ['Section ID, block type, and block ID are required'] }, status: :bad_request
      end

      # Get or create theme preview
      theme_preview = ThemePreview.find_or_create_by(
        builder_theme: @builder_theme,
        template_name: template
      ) do |preview|
        preview.tenant = @builder_theme.tenant
      end
      
      # Find the section
      section = theme_preview.theme_preview_sections.find_by(section_id: section_id)
      if !section
        return render json: { success: false, errors: ['Section not found'] }, status: :not_found
      end
      
      # Create new block
      block = section.theme_preview_blocks.create!(
        block_id: block_id,
        block_type: block_type,
        settings: settings,
        position: section.theme_preview_blocks.count
      )
      
      Rails.logger.info "Successfully added block #{block_id} (#{block_type}) to section #{section_id}"
      
      respond_to do |format|
        format.json { render json: { 
          success: true, 
          block: {
            block_id: block.block_id,
            block_type: block.block_type,
            settings: block.settings,
            position: block.position
          }
        } }
      end
      
    rescue => e
      Rails.logger.error "Add block failed: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      Rails.logger.error "Params: #{params.inspect}"
      render json: { success: false, errors: [e.message], backtrace: e.backtrace.first(5) }, status: :unprocessable_entity
    end
  end

  # DELETE /admin/builder/:id/remove_block/:block_id
  def remove_block
    block_id = params[:block_id]
    section_id = params[:section_id]
    template = params[:template] || 'index'
    
    begin
      Rails.logger.info "Remove block params: #{params.inspect}"
      Rails.logger.info "Block ID: #{block_id}, Section ID: #{section_id}"
      
      if block_id.blank?
        return render json: { success: false, errors: ['Block ID is required'] }, status: :bad_request
      end

      # Get theme preview
      theme_preview = ThemePreview.find_or_create_by(
        builder_theme: @builder_theme,
        template_name: template
      ) do |preview|
        preview.tenant = @builder_theme.tenant
      end
      
      # Find the section and block
      section = theme_preview.theme_preview_sections.find_by(section_id: section_id)
      if !section
        return render json: { success: false, errors: ['Section not found'] }, status: :not_found
      end
      
      block = section.theme_preview_blocks.find_by(block_id: block_id)
      if block
        block.destroy!
        Rails.logger.info "Successfully removed block #{block_id} from section #{section_id}"
        
        render json: { success: true, message: 'Block removed successfully!' }
      else
        Rails.logger.warn "Block #{block_id} not found in section #{section_id}"
        render json: { success: false, errors: ['Block not found'] }, status: :not_found
      end
      
    rescue => e
      Rails.logger.error "Remove block failed: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      Rails.logger.error "Params: #{params.inspect}"
      render json: { success: false, errors: [e.message], backtrace: e.backtrace.first(5) }, status: :unprocessable_entity
    end
  end

  # PATCH /admin/builder/:id/update_block/:block_id
  def update_block
    block_id = params[:block_id]
    section_id = params[:section_id]
    template = params[:template] || 'index'
    settings = case params[:settings]
               when String
                 JSON.parse(params[:settings])
               when ActionController::Parameters
                 params[:settings].to_unsafe_h
               else
                 params[:settings] || {}
               end

    begin
      Rails.logger.info "Update block params: #{params.inspect}"
      Rails.logger.info "Block ID: #{block_id}, Section ID: #{section_id}, Settings: #{settings.inspect}"
      
      if block_id.blank?
        return render json: { success: false, errors: ['Block ID is required'] }, status: :bad_request
      end
      
      # Get theme preview
      theme_preview = ThemePreview.find_or_create_by(
        builder_theme: @builder_theme,
        template_name: template
      ) do |preview|
        preview.tenant = @builder_theme.tenant
      end
      
      # Find the section and block
      section = theme_preview.theme_preview_sections.find_by(section_id: section_id)
      if !section
        return render json: { success: false, errors: ['Section not found'] }, status: :not_found
      end
      
      block = section.theme_preview_blocks.find_by(block_id: block_id)
      if !block
        return render json: { success: false, errors: ['Block not found'] }, status: :not_found
      end
      
      # Update the block settings
      block.update!(settings: settings)
      
      Rails.logger.info "Successfully updated block #{block_id} for section #{section_id}"
      
      render json: { 
        success: true, 
        message: 'Block updated successfully!',
        block_id: block_id,
        updated_settings: settings
      }
      
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parsing error in update_block: #{e.message}"
      render json: { success: false, errors: ['Invalid JSON in settings'] }, status: :bad_request
    rescue => e
      Rails.logger.error "Update block failed: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      Rails.logger.error "Params: #{params.inspect}"
      render json: { success: false, errors: [e.message], backtrace: e.backtrace.first(5) }, status: :unprocessable_entity
    end
  end

  # PATCH /admin/builder/:id/update_theme_settings
  def update_theme_settings
    template = params[:template] || 'index'
    settings = case params[:settings]
               when String
                 JSON.parse(params[:settings])
               when ActionController::Parameters
                 params[:settings].to_unsafe_h
               else
                 params[:settings] || {}
               end

    begin
      Rails.logger.info "Update theme settings params: #{params.inspect}"
      Rails.logger.info "Template: #{template}, Settings: #{settings.inspect}"
      
      # Get or create theme preview
      theme_preview = ThemePreview.find_or_create_by(
        builder_theme: @builder_theme,
        template_name: template
      ) do |preview|
        preview.tenant = @builder_theme.tenant
      end
      
      # Update theme settings
      theme_preview.update!(theme_settings_json: settings)
      
      Rails.logger.info "Successfully updated theme settings for template #{template}"
      
      render json: { 
        success: true, 
        message: 'Theme settings updated successfully!',
        template: template,
        updated_settings: settings
      }
      
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parsing error in update_theme_settings: #{e.message}"
      render json: { success: false, errors: ['Invalid JSON in settings'] }, status: :bad_request
    rescue => e
      Rails.logger.error "Update theme settings failed: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      Rails.logger.error "Params: #{params.inspect}"
      render json: { success: false, errors: [e.message], backtrace: e.backtrace.first(5) }, status: :unprocessable_entity
    end
  end

  # PATCH /admin/builder/:id/update_section/:section_id
  def update_section
    section_id = params[:section_id]
    template = params[:template] || params.dig(:builder, :template) || 'index'
    # params[:settings] can arrive as a Hash (from JSON) or a String
    # Handle both direct params and nested builder params
    raw_settings = params[:settings] || params.dig(:builder, :settings)
    settings = case raw_settings
               when String
                 JSON.parse(raw_settings)
               when ActionController::Parameters
                 raw_settings.to_unsafe_h
               else
                 raw_settings || {}
               end

    begin
      Rails.logger.info "Update section params: #{params.inspect}"
      Rails.logger.info "Section ID: #{section_id}, Template: #{template}, Settings: #{settings.inspect}"
      
      # Validate section_id is present
      if section_id.blank?
        return render json: { success: false, errors: ['Section ID is required'] }, status: :bad_request
      end
      
      # Use ThemePreview for builder previews (separate from published themes)
      theme_preview = ThemePreview.find_or_create_for_builder(@builder_theme, template)
      
      # Update the section settings
      theme_preview.update_section_settings(section_id, settings)
      
      Rails.logger.info "Successfully updated section #{section_id} for template #{template}"
      
      render json: { 
        success: true, 
        message: 'Section updated successfully!',
        section_id: section_id,
        updated_settings: settings
      }
      
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parsing error in update_section: #{e.message}"
      render json: { success: false, errors: ['Invalid JSON in settings'] }, status: :bad_request
    rescue => e
      Rails.logger.error "Update section failed: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      Rails.logger.error "Params: #{params.inspect}"
      render json: { success: false, errors: [e.message], backtrace: e.backtrace.first(5) }, status: :unprocessable_entity
    end
  end

  # PATCH /admin/builder/:id/reorder_sections
  def reorder_sections
    begin
      # Handle both array and JSON string parameters
      raw_section_ids = params[:section_ids] || params.dig(:builder, :section_ids) || []
      
      if raw_section_ids.is_a?(String)
        section_ids = JSON.parse(raw_section_ids)
      else
        section_ids = raw_section_ids
      end
      
      template = params[:template] || params.dig(:builder, :template) || 'index'
      
      Rails.logger.info "=== REORDER SECTIONS DEBUG ==="
      Rails.logger.info "Raw section IDs: #{raw_section_ids.inspect}"
      Rails.logger.info "Processed section IDs: #{section_ids.inspect}"
      Rails.logger.info "Template: #{template}"
      
      # Validate that we have section IDs
      if section_ids.blank?
        return render json: { success: false, errors: ['No section IDs provided'] }, status: :bad_request
      end
      
      # Use ThemePreview for builder previews (separate from published themes)
      theme_preview = ThemePreview.find_or_create_for_builder(@builder_theme, template)
      
      # Validate that all section IDs exist in the preview
      existing_section_ids = theme_preview.theme_preview_sections.pluck(:section_id)
      invalid_section_ids = section_ids - existing_section_ids
      
      if invalid_section_ids.any?
        Rails.logger.error "Invalid section IDs provided: #{invalid_section_ids.inspect}"
        Rails.logger.error "Existing section IDs: #{existing_section_ids.inspect}"
        return render json: { 
          success: false, 
          errors: ["Invalid section IDs: #{invalid_section_ids.join(', ')}"] 
        }, status: :bad_request
      end
      
      # Update the section order
      theme_preview.update_section_order(section_ids)
      
      Rails.logger.info "Successfully reordered sections for template: #{template}"
      
      respond_to do |format|
        format.json { render json: { 
          success: true, 
          message: 'Sections reordered successfully!',
          section_ids: section_ids
        } }
      end
      
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parsing error in reorder_sections: #{e.message}"
      render json: { success: false, errors: ['Invalid JSON in section IDs'] }, status: :bad_request
    rescue => e
      Rails.logger.error "Reorder sections failed: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      render json: { success: false, errors: [e.message], backtrace: e.backtrace.first(5) }, status: :unprocessable_entity
    end
  end

  def format_section_data(section)
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
    Rails.logger.info "Looking for BuilderTheme with ID: #{params[:id]}"
    @builder_theme = BuilderTheme.find_by(id: params[:id])
    
    unless @builder_theme
      Rails.logger.error "BuilderTheme not found with ID: #{params[:id]}"
      Rails.logger.info "Available BuilderThemes: #{BuilderTheme.pluck(:id, :label)}"
      render json: { success: false, errors: ['Builder theme not found'] }, status: :not_found
      return
    end
    
    Rails.logger.info "Found BuilderTheme: #{@builder_theme.inspect}"
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

  def get_context_data_for_section(context_requests)
    context_data = {}
    
    context_requests.each do |key, request_config|
      case key
      when 'menus'
        context_data[key] = get_menus_context
      when 'pages'
        context_data[key] = get_pages_context
      when 'posts'
        context_data[key] = get_posts_context
      when 'categories'
        context_data[key] = get_categories_context
      when 'products'
        context_data[key] = get_products_context
      else
        Rails.logger.warn "Unknown context request: #{key}"
      end
    end
    
    context_data
  end

  def get_menus_context
    # Return available menus for navigation
    [
      {
        id: 1,
        name: 'Main Navigation',
        menu_items: [
          { id: 1, title: 'Home', url: '/', order: 1 },
          { id: 2, title: 'About', url: '/about', order: 2 },
          { id: 3, title: 'Services', url: '/services', order: 3 },
          { id: 4, title: 'Contact', url: '/contact', order: 4 }
        ]
      },
      {
        id: 2,
        name: 'Footer Links',
        menu_items: [
          { id: 5, title: 'Privacy Policy', url: '/privacy', order: 1 },
          { id: 6, title: 'Terms of Service', url: '/terms', order: 2 },
          { id: 7, title: 'Support', url: '/support', order: 3 }
        ]
      }
    ]
  end

  def get_pages_context
    # Return available pages
    [
      { id: 1, title: 'Home', slug: 'home', url: '/' },
      { id: 2, title: 'About Us', slug: 'about', url: '/about' },
      { id: 3, title: 'Services', slug: 'services', url: '/services' },
      { id: 4, title: 'Contact', slug: 'contact', url: '/contact' },
      { id: 5, title: 'Privacy Policy', slug: 'privacy', url: '/privacy' }
    ]
  end

  def get_posts_context
    # Return recent posts
    [
      { id: 1, title: 'Welcome to Our Blog', slug: 'welcome-blog', url: '/blog/welcome-blog' },
      { id: 2, title: 'Getting Started Guide', slug: 'getting-started', url: '/blog/getting-started' }
    ]
  end

  def get_categories_context
    # Return post categories
    [
      { id: 1, name: 'News', slug: 'news' },
      { id: 2, name: 'Tutorials', slug: 'tutorials' },
      { id: 3, name: 'Updates', slug: 'updates' }
    ]
  end

  def get_products_context
    # Return sample products (for e-commerce sections)
    [
      { id: 1, title: 'Sample Product 1', price: 29.99, url: '/products/sample-1' },
      { id: 2, title: 'Sample Product 2', price: 49.99, url: '/products/sample-2' }
    ]
  end

  def format_section_data(section)
    {
      id: section.section_id,
      type: section.section_type,
      settings: section.settings,
      position: section.position,
      created_at: section.created_at,
      updated_at: section.updated_at
    }
  end

  def set_current_theme
    # Allow editing any theme, not just active ones
    if params[:theme_id].present?
      @current_theme = Theme.find(params[:theme_id])
    elsif params[:theme_name].present?
      @current_theme = Theme.where("LOWER(name) = ?", params[:theme_name].downcase).first
    else
      @current_theme = Theme.active.first || Theme.first
    end
  end

  def set_builder_theme
    @builder_theme = BuilderTheme.find(params[:id])
  end

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
