class Admin::TemplateCustomizerController < Admin::BaseController
  layout :resolve_layout
  before_action :load_current_theme, only: [:index, :customize, :load_template_content, :load_section_schema, :save_customization, :publish_customization, :test_data]
  before_action :set_template_data, only: [:customize, :save_customization]
  
  def index
    # Redirect to customize action for the current theme
    redirect_to admin_template_customizer_customize_path(template: 'index')
  end

  def customize
    @template_type = params[:template] || 'index'
    @template_data = load_template_data(@template_type)
    @available_templates = get_available_templates
    @theme_sections = load_theme_sections(@template_type)
    @theme_settings = load_theme_settings
    
    # Debug logging
    Rails.logger.info "Theme sections loaded: #{@theme_sections.keys}"
    Rails.logger.info "Theme sections JSON: #{@theme_sections.to_json}"
    
    render layout: 'editor_fullscreen'
  end

  def test_data
    @template_type = params[:template] || 'index'
    @template_data = load_template_data(@template_type)
    @available_templates = get_available_templates
    @theme_sections = load_theme_sections(@template_type)
    @theme_settings = load_theme_settings
    
    render json: {
      themeSections: @theme_sections.map { |k, v| [k, { 'type' => v['type'], 'name' => v['name'], 'schema' => v['schema'] }] }.to_h,
      themeSettings: @theme_settings,
      templateData: @template_data
    }
  end

  def save_customization
    template_type = params[:template_type]
    template_data = JSON.parse(params[:template_data])
    
    begin
      # Create a preview theme version
      theme_version = ThemeVersion.create_preview(
        @current_theme,
        current_user,
        summary: "Customized #{template_type} template"
      )
      
      # Update the template in the theme version
      service = ThemeVersionService.new(theme_version)
      service.update_template(template_type, template_data)
      
      respond_to do |format|
        format.json { render json: { success: true, message: 'Preview saved successfully', version_id: theme_version.id } }
      end
    rescue => e
      Rails.logger.error "Error saving customization: #{e.message}"
      respond_to do |format|
        format.json { render json: { success: false, errors: [e.message] }, status: :unprocessable_entity }
      end
    end
  end

  def publish_customization
    template_type = params[:template_type]
    template_data = JSON.parse(params[:template_data])
    
    begin
      # Create a live theme version
      theme_version = ThemeVersion.create_live_version(
        @current_theme,
        current_user,
        summary: "Published #{template_type} template"
      )
      
      # Update the template in the theme version
      service = ThemeVersionService.new(theme_version)
      service.update_template(template_type, template_data)
      
      respond_to do |format|
        format.json { render json: { success: true, message: 'Theme published successfully', version_id: theme_version.id } }
      end
    rescue => e
      Rails.logger.error "Error publishing customization: #{e.message}"
      respond_to do |format|
        format.json { render json: { success: false, errors: [e.message] }, status: :unprocessable_entity }
      end
    end
  end

  def load_template_content
    template_type = params[:template_type] || 'index'

    # Get the current live theme version or fallback to base theme files
    live_version = ThemeVersion.live.for_theme(@current_theme).first

    if live_version
      # Use live version data
      template_data = live_version.template_data(template_type)
      sections_data = load_sections_from_version(live_version)
    else
      # Fallback to base theme files (read-only)
      template_data = load_template_data(template_type)
      sections_data = load_theme_sections(template_type)
    end

    # Render preview HTML using the theme version or base files
    begin
      preview_html = render_theme_preview(template_type, template_data, sections_data)
    rescue => e
      Rails.logger.error "Error rendering theme preview: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      preview_html = "<div style='padding: 20px; color: red;'>Error rendering preview: #{e.message}</div>"
    end

    render json: {
      html: preview_html,
      template_data: template_data,
      sections: sections_data,
      settings: load_theme_settings
    }
  end

  def load_section_schema
    section_type = params[:section_type]
    schema = get_section_schema(section_type)
    
    render json: { schema: schema }
  end

  private

  def load_current_theme
    @current_theme = Railspress::ThemeLoader.current_theme
    @theme_config = Railspress::ThemeLoader.theme_config
    @theme_path = Rails.root.join('app', 'themes', @current_theme)
  end

  def set_template_data
    @template_type = params[:template] || 'index'
  end

  def load_template_data(template_type)
    template_file = @theme_path.join('templates', "#{template_type}.json")
    
    if File.exist?(template_file)
      JSON.parse(File.read(template_file))
    else
      # Return default template structure
      {
        'sections' => {},
        'order' => []
      }
    end
  end

  def get_available_templates
    templates_dir = @theme_path.join('templates')
    return [] unless Dir.exist?(templates_dir)
    
    Dir.entries(templates_dir)
       .select { |f| f.end_with?('.json') }
       .map { |f| f.chomp('.json') }
       .reject { |f| f == 'index' } # index is the default
       .unshift('index') # Put index first
  end

  def load_theme_sections(template_type)
    sections_dir = @theme_path.join('sections')
    return {} unless Dir.exist?(sections_dir)
    
    sections = {}
    Dir.entries(sections_dir).each do |file|
      next unless file.end_with?('.liquid')
      
      section_type = file.chomp('.liquid')
      section_file = sections_dir.join(file)
      
      begin
        content = File.read(section_file)
        
        # Extract schema from liquid file
        schema_match = content.match(/\{%\s*schema\s*%\}(.*?)\{%\s*endschema\s*%\}/m)
        
        schema = {}
        if schema_match
          begin
            schema = JSON.parse(schema_match[1])
          rescue JSON::ParserError => e
            Rails.logger.warn "Failed to parse schema for #{section_type}: #{e.message}"
            schema = {}
          end
        end
        
        sections[section_type] = {
          'type' => section_type,
          'name' => schema['name'] || section_type.humanize,
          'schema' => schema,
          'content' => content
        }
      rescue => e
        Rails.logger.error "Error loading section #{section_type}: #{e.message}"
        # Still add the section with basic info
        sections[section_type] = {
          'type' => section_type,
          'name' => section_type.humanize,
          'schema' => {},
          'content' => ''
        }
      end
    end
    
    sections
  end

  def load_theme_settings
    settings_file = @theme_path.join('config', 'settings_schema.json')
    
    if File.exist?(settings_file)
      JSON.parse(File.read(settings_file))
    else
      []
    end
  end

  def get_section_schema(section_type)
    section_file = @theme_path.join('sections', "#{section_type}.liquid")
    
    if File.exist?(section_file)
      content = File.read(section_file)
      schema_match = content.match(/\{%\s*schema\s*%\}(.*?)\{%\s*endschema\s*%\}/m)
      schema_match ? JSON.parse(schema_match[1]) : {}
    else
      {}
    end
  end

  def render_liquid_template(template_type, template_data)
    renderer = LiquidTemplateRenderer.new(@current_theme, template_type, template_data)
    renderer.render
  end

  def create_theme_version(template_type, template_data)
    # Create a new theme file version for the template
    ThemeFileVersion.create!(
      theme_name: @current_theme,
      file_path: "templates/#{template_type}.json",
      content: template_data.to_json,
      file_size: template_data.to_json.bytesize,
      user_id: current_user&.id,
      change_summary: "Updated #{template_type} template via customizer"
    )
  end

  def load_sections_from_version(theme_version)
    sections_data = {}
    
    theme_version.sections.includes(:theme_file).each do |file_version|
      section_type = file_version.file_path.gsub('sections/', '').gsub('.liquid', '')
      sections_data[section_type] = {
        'type' => section_type,
        'schema' => file_version.theme_file&.parsed_schema || {},
        'content' => file_version.content
      }
    end
    
    sections_data
  end

  def render_theme_preview(template_type, template_data, sections_data)
    begin
      # If we have template data with sections, render them
      if template_data && template_data['order'] && template_data['sections']
        return render_sections_from_template_data(template_data, template_type)
      else
        # Fallback to basic template structure
        return render_basic_template(template_type)
      end
    rescue => e
      Rails.logger.error "Error in render_theme_preview: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      return "<div style='padding: 20px; color: red;'>Error rendering preview: #{e.message}</div>"
    end
  end

  def render_sections_from_template_data(template_data, template_type)
    sections_html = ''
    
    template_data['order'].each do |section_id|
      section_data = template_data['sections'][section_id]
      next unless section_data
      
      section_type = section_data['type']
      
      # For now, just use fallback HTML to avoid Liquid parsing issues
      # TODO: Implement proper Liquid parsing with Shopify tag support
      sections_html += generate_fallback_section_html(section_type, section_data)
    end
    
    # Wrap in basic HTML structure
    wrap_in_html_template(sections_html, template_type)
  end

  def render_basic_template(template_type)
    # Return a basic HTML structure for the template type
    case template_type
    when 'index'
      content = '<section class="hero-section"><h1>Welcome to our site</h1><p>This is the homepage content.</p></section>'
    when 'blog'
      content = '<section class="blog-section"><h1>Blog</h1><p>Latest blog posts will appear here.</p></section>'
    when 'page'
      content = '<section class="page-section"><h1>Page Title</h1><p>Page content goes here.</p></section>'
    when 'post'
      content = '<section class="post-section"><h1>Blog Post Title</h1><p>Blog post content goes here.</p></section>'
    else
      content = "<section class=\"#{template_type}-section\"><h1>#{template_type.humanize}</h1><p>Content for #{template_type} page.</p></section>"
    end
    
    wrap_in_html_template(content, template_type)
  end

  def wrap_in_html_template(content, template_type)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>#{template_type.humanize} - Preview</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 0; padding: 20px; }
          .hero-section { background: #f0f0f0; padding: 40px; text-align: center; }
          .blog-section, .page-section, .post-section { padding: 20px; }
        </style>
      </head>
      <body>
        #{content}
      </body>
      </html>
    HTML
  end

  def generate_fallback_section_html(section_type, section_data)
    section_name = section_data['name'] || section_type.humanize
    <<~HTML
      <section class="#{section_type}-section" data-section-type="#{section_type}">
        <div class="section-content">
          <h2>#{section_name}</h2>
          <p>This #{section_name.downcase} section will be loaded from theme files.</p>
        </div>
      </section>
    HTML
  end

  def load_section_content(section_type)
    section_file = @theme_path.join('sections', "#{section_type}.liquid")
    
    if File.exist?(section_file)
      File.read(section_file)
    else
      nil
    end
  end

  def load_page_data(template_type)
    case template_type
    when 'index'
      { 'title' => 'Homepage', 'description' => 'Welcome to our site' }
    when 'blog'
      { 'title' => 'Blog', 'description' => 'Latest posts' }
    when 'page'
      { 'title' => 'Page', 'description' => 'Page content' }
    when 'post'
      { 'title' => 'Blog Post', 'description' => 'Post content' }
    else
      { 'title' => template_type.humanize, 'description' => '' }
    end
  end
  
  def resolve_layout
    action_name == 'customize' ? 'editor_fullscreen' : 'admin'
  end
end
