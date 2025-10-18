class ThemePreviewRenderer
  attr_reader :published_version, :builder_renderer

  def initialize(builder_theme, template_name = 'index')
    @builder_theme = builder_theme
    @template_name = template_name
    @theme_preview = ThemePreview.find_or_create_for_builder(builder_theme, template_name)
    
    # Use published version for base files (layout, assets)
    @published_version = builder_theme.published_version
    
    # Create a mock BuilderTheme for the existing BuilderLiquidRenderer
    @mock_builder_theme = create_mock_builder_theme
    Rails.logger.info "Created mock builder theme for ThemePreviewRenderer"
    
    @builder_renderer = BuilderLiquidRenderer.new(@mock_builder_theme)
    Rails.logger.info "Created BuilderLiquidRenderer for preview"
  end

  # Render a template with all sections, header, footer, etc.
  def render
    # Use the existing BuilderLiquidRenderer
    html = @builder_renderer.render_template(@template_name)
    
    # Replace asset URLs with embedded content for preview
    html = replace_asset_urls_with_content(html)
    
    html
  rescue => e
    Rails.logger.error "ThemePreviewRenderer error: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
    "<div class='error'>ThemePreviewRenderer Error: #{e.message}<br>Backtrace: #{e.backtrace.first(5).join('<br>')}</div>"
  end


  # Get CSS and JS assets including all sections
  def assets
    # Use the existing BuilderLiquidRenderer's assets method
    @builder_renderer.assets
  end

  private

  def create_mock_builder_theme
    # Create a mock BuilderTheme object that delegates to ThemePreview data
    mock_theme = Object.new
    
    # Define methods that BuilderLiquidRenderer expects
    def mock_theme.get_rendered_file(template_name)
      # Return the template data from ThemePreview (not PublishedThemeFile)
      template_content = @theme_preview.template_content
      
      # Get layout file from PublishedThemeFile (base files)
      layout_file = @published_version.published_theme_files.find_by(file_path: 'layout/theme.liquid')
      layout_content = layout_file&.content || default_layout
      
      # Build page sections from ThemePreview data
      page_sections = []
      template_content['order']&.each_with_index do |section_id, index|
        section_config = template_content['sections'][section_id]
        next unless section_config
        
        # Create a mock section object with blocks support
        section = Object.new
        def section.section_id
          @section_id
        end
        def section.section_type
          @section_type
        end
        def section.settings
          @settings
        end
        def section.position
          @position
        end
        def section.blocks
          @blocks || []
        end
        
        section.instance_variable_set(:@section_id, section_id)
        section.instance_variable_set(:@section_type, section_config['type'])
        section.instance_variable_set(:@settings, section_config['settings'] || {})
        section.instance_variable_set(:@position, index)
        
        # Add blocks support if the section has blocks
        if section_config['blocks']
          blocks = section_config['blocks'].map do |block_data|
            block = Object.new
            def block.id
              @id
            end
            def block.type
              @type
            end
            def block.settings
              @settings
            end
            
            block.instance_variable_set(:@id, block_data['id'] || SecureRandom.hex(8))
            block.instance_variable_set(:@type, block_data['type'])
            block.instance_variable_set(:@settings, block_data['settings'] || {})
            block
          end
          section.instance_variable_set(:@blocks, blocks)
        end
        
        page_sections << section
      end
      
      {
        template_name: template_name,
        template_content: template_content,
        layout_content: layout_content,
        theme_settings: {},
        page_sections: page_sections
      }
    end
    
    # Store the theme_preview, published_version, and builder_theme for access in methods
    mock_theme.instance_variable_set(:@theme_preview, @theme_preview)
    mock_theme.instance_variable_set(:@published_version, @published_version)
    mock_theme.instance_variable_set(:@builder_theme, @builder_theme)
    
    # Add other methods that might be needed
    def mock_theme.theme_name
      @published_version.theme.name.underscore
    end
    
    def mock_theme.id
      @builder_theme.id
    end
    
    mock_theme
  end

  def default_layout
    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{{ page.title | default: site.title }}</title>
      </head>
      <body>
        {{ content_for_layout }}
      </body>
      </html>
    HTML
  end


  def replace_asset_urls_with_content(html)
    # Get assets from published theme files
    published_version = @builder_theme.published_version
    
    # Get CSS content
    css_file = published_version.published_theme_files.find_by(file_path: 'assets/theme.css')
    css_content = css_file&.content || ''
    
    # Get JS content
    js_file = published_version.published_theme_files.find_by(file_path: 'assets/theme.js')
    js_content = js_file&.content || ''
    
    # Replace CSS link tags with embedded styles
    html = html.gsub(/<link[^>]*href="[^"]*\/theme\.css"[^>]*>/) do |match|
      if css_content.present?
        "<style>#{css_content}</style>"
      else
        match # Keep original if no CSS
      end
    end
    
    # Replace JS script tags with embedded scripts
    html = html.gsub(/<script[^>]*src="[^"]*\/theme\.js"[^>]*><\/script>/) do |match|
      if js_content.present?
        "<script>#{js_content}</script>"
      else
        match # Keep original if no JS
      end
    end
    
    html
  rescue => e
    Rails.logger.error "Error in replace_asset_urls_with_content: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
    html # Return original HTML if there's an error
  end
end
