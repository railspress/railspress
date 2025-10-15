class LiquidTemplateRenderer
  def initialize(theme_name, template_type, template_data = {})
    @theme_name = theme_name
    @template_type = template_type
    @template_data = template_data
    @theme_path = Rails.root.join('app', 'themes', theme_name)
  end

  def render
    # Load the template structure
    template_structure = load_template_structure
    
    # Render the layout
    layout_content = render_layout
    
    # Render sections in order
    sections_html = render_sections(template_structure)
    
    # Combine layout with sections
    layout_content.gsub('{{ content_for_layout }}', sections_html)
  end

  def render_section(section_id, section_data)
    section_type = section_data['type']
    section_settings = section_data['settings'] || {}
    
    # Load section file
    section_file = @theme_path.join('sections', "#{section_type}.liquid")
    return '' unless File.exist?(section_file)
    
    section_content = File.read(section_file)
    
    # Create liquid template with section data
    template = Liquid::Template.parse(section_content)
    
    # Prepare context with section settings
    context = {
      'section' => {
        'settings' => section_settings,
        'id' => section_id,
        'type' => section_type
      }
    }
    
    # Add global theme settings
    context['settings'] = load_theme_settings
    
    # Render the section
    template.render(context)
  rescue => e
    Rails.logger.error "Error rendering section #{section_id}: #{e.message}"
    "<div class='error'>Error rendering section: #{section_type}</div>"
  end

  private

  def load_template_structure
    template_file = @theme_path.join('templates', "#{@template_type}.json")
    
    if File.exist?(template_file)
      JSON.parse(File.read(template_file))
    else
      @template_data
    end
  end

  def render_layout
    layout_file = @theme_path.join('layout', 'theme.liquid')
    
    if File.exist?(layout_file)
      layout_content = File.read(layout_file)
      
      # Create liquid template
      template = Liquid::Template.parse(layout_content)
      
      # Prepare context
      context = {
        'template' => @template_type,
        'settings' => load_theme_settings,
        'page' => load_page_data
      }
      
      # Render the layout
      template.render(context)
    else
      # Default layout if theme.liquid doesn't exist
      default_layout
    end
  rescue => e
    Rails.logger.error "Error rendering layout: #{e.message}"
    default_layout
  end

  def render_sections(template_structure)
    sections_html = ''
    
    if template_structure['order'] && template_structure['sections']
      template_structure['order'].each do |section_id|
        section_data = template_structure['sections'][section_id]
        if section_data
          sections_html += render_section(section_id, section_data)
        end
      end
    end
    
    sections_html
  end

  def load_theme_settings
    settings_file = @theme_path.join('config', 'settings_schema.json')
    
    if File.exist?(settings_file)
      settings_schema = JSON.parse(File.read(settings_file))
      
      # Convert schema to settings with defaults
      settings = {}
      settings_schema.each do |group|
        group['settings'].each do |setting|
          settings[setting['id']] = setting['default']
        end
      end
      
      settings
    else
      {}
    end
  end

  def load_page_data
    # Load page-specific data based on template type
    case @template_type
    when 'index'
      {
        'title' => 'Homepage',
        'description' => 'Welcome to our site'
      }
    when 'blog'
      {
        'title' => 'Blog',
        'description' => 'Latest posts'
      }
    when 'page'
      {
        'title' => 'Page',
        'description' => 'Page content'
      }
    when 'post'
      {
        'title' => 'Blog Post',
        'description' => 'Post content'
      }
    else
      {
        'title' => @template_type.humanize,
        'description' => ''
      }
    end
  end

  def default_layout
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>{{ page.title }}</title>
        <meta name="description" content="{{ page.description }}">
        <link rel="stylesheet" href="/assets/theme.css">
      </head>
      <body>
        {{ content_for_layout }}
        <script src="/assets/theme.js"></script>
      </body>
      </html>
    HTML
  end
end