class LiquidTemplateVersionRenderer
  def initialize(theme_version, template_type)
    @theme_version = theme_version
    @template_type = template_type
    @theme_name = theme_version.theme_name
  end

  def render
    # Get template data from the theme version
    template_data = @theme_version.template_data(@template_type)
    
    # Render the layout with sections
    layout_content = render_layout
    
    # Render sections in order
    sections_html = render_sections(template_data)
    
    # Combine layout with sections
    layout_content.gsub('{{ content_for_layout }}', sections_html)
  end

  def render_section(section_id, section_data)
    section_type = section_data['type']
    section_settings = section_data['settings'] || {}
    
    # Get section content from theme version
    section_content = @theme_version.section_content(section_type)
    return '' if section_content.blank?
    
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
    
    # Add sample data for preview
    context.merge!(sample_data)
    
    # Render the section
    template.render(context)
  rescue => e
    Rails.logger.error "Error rendering section #{section_id}: #{e.message}"
    "<div class='error'>Error rendering section: #{section_type}</div>"
  end

  private

  def render_layout
    layout_content = @theme_version.layout_content
    
    if layout_content.present?
      # Create liquid template
      template = Liquid::Template.parse(layout_content)
      
      # Prepare context
      context = {
        'template' => @template_type,
        'settings' => load_theme_settings,
        'page' => load_page_data
      }
      
      # Add sample data
      context.merge!(sample_data)
      
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

  def render_sections(template_data)
    sections_html = ''
    
    if template_data['order'] && template_data['sections']
      template_data['order'].each do |section_id|
        section_data = template_data['sections'][section_id]
        if section_data
          sections_html += render_section(section_id, section_data)
        end
      end
    end
    
    sections_html
  end

  def load_theme_settings
    # Get theme settings from the theme version
    settings_file_content = @theme_version.file_content('config/settings_schema.json')
    
    if settings_file_content.present?
      settings_schema = JSON.parse(settings_file_content)
      
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
  rescue JSON::ParserError
    {}
  end

  def load_page_data
    # Load page-specific data based on template type
    case @template_type
    when 'index'
      {
        'title' => 'Homepage',
        'description' => 'Welcome to our site',
        'posts' => sample_posts
      }
    when 'blog'
      {
        'title' => 'Blog',
        'description' => 'Latest posts',
        'posts' => sample_posts
      }
    when 'page'
      {
        'title' => 'Sample Page',
        'description' => 'This is a sample page',
        'content' => '<p>This is sample page content for preview.</p>'
      }
    when 'post'
      {
        'title' => 'Sample Blog Post',
        'description' => 'This is a sample blog post',
        'content' => '<p>This is sample blog post content for preview.</p>',
        'author' => 'Sample Author',
        'date' => Time.current.strftime('%B %d, %Y')
      }
    else
      {
        'title' => @template_type.humanize,
        'description' => ''
      }
    end
  end

  def sample_data
    {
      'site' => {
        'title' => 'Sample Site',
        'description' => 'A sample site for preview',
        'url' => 'https://example.com'
      },
      'posts' => sample_posts,
      'pages' => sample_pages,
      'collections' => sample_collections
    }
  end

  def sample_posts
    [
      {
        'title' => 'Welcome to Our Blog',
        'excerpt' => 'This is a sample blog post for preview purposes.',
        'content' => '<p>This is the full content of a sample blog post.</p>',
        'author' => 'Sample Author',
        'date' => 1.day.ago.strftime('%B %d, %Y'),
        'url' => '/posts/welcome-to-our-blog'
      },
      {
        'title' => 'Getting Started',
        'excerpt' => 'Learn how to get started with our platform.',
        'content' => '<p>This is another sample blog post.</p>',
        'author' => 'Sample Author',
        'date' => 2.days.ago.strftime('%B %d, %Y'),
        'url' => '/posts/getting-started'
      }
    ]
  end

  def sample_pages
    [
      {
        'title' => 'About Us',
        'content' => '<p>Learn more about our company and mission.</p>',
        'url' => '/pages/about'
      },
      {
        'title' => 'Contact',
        'content' => '<p>Get in touch with us.</p>',
        'url' => '/pages/contact'
      }
    ]
  end

  def sample_collections
    {
      'categories' => [
        { 'name' => 'Technology', 'url' => '/categories/technology' },
        { 'name' => 'Design', 'url' => '/categories/design' }
      ],
      'tags' => [
        { 'name' => 'tutorial', 'url' => '/tags/tutorial' },
        { 'name' => 'guide', 'url' => '/tags/guide' }
      ]
    }
  end

  def default_layout
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>{{ page.title }}</title>
        <meta name="description" content="{{ page.description }}">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 0; padding: 20px; background: #f9fafb; }
          .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        </style>
      </head>
      <body>
        <div class="container">
          {{ content_for_layout }}
        </div>
      </body>
      </html>
    HTML
  end
end

