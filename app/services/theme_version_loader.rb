class ThemeVersionLoader
  class << self
    def current_theme_version
      @current_theme_version ||= ThemeVersion.live.for_theme(current_theme_name).first
    end

    def current_theme_name
      @current_theme_name ||= Railspress::ThemeLoader.current_theme
    end

    def load_template(template_type)
      if current_theme_version
        current_theme_version.template_data(template_type)
      else
        load_base_template(template_type)
      end
    end

    def load_section(section_type)
      if current_theme_version
        current_theme_version.section_content(section_type)
      else
        load_base_section(section_type)
      end
    end

    def load_layout
      if current_theme_version
        current_theme_version.layout_content
      else
        load_base_layout
      end
    end

    def load_assets
      if current_theme_version
        current_theme_version.assets
      else
        load_base_assets
      end
    end

    def render_template(template_type, context = {})
      template_data = load_template(template_type)
      layout_content = load_layout
      
      # Render sections from template data
      sections_html = render_sections_from_template_data(template_data, context)
      
      # Combine with layout
      layout_content.gsub('{{ content_for_layout }}', sections_html)
    end

    private

    def render_sections_from_template_data(template_data, context)
      return '' unless template_data['order'] && template_data['sections']
      
      sections_html = ''
      template_data['order'].each do |section_id|
        section_data = template_data['sections'][section_id]
        next unless section_data
        
        section_content = load_section(section_data['type'])
        next unless section_content
        
        # Create liquid template
        template = Liquid::Template.parse(section_content)
        
        # Prepare context
        liquid_context = {
          'section' => {
            'settings' => section_data['settings'] || {},
            'id' => section_id,
            'type' => section_data['type']
          }
        }.merge(context)
        
        # Render section
        sections_html += template.render(liquid_context)
      end
      
      sections_html
    rescue => e
      Rails.logger.error "Error rendering template: #{e.message}"
      ''
    end

    def load_base_template(template_type)
      theme_path = Rails.root.join('app', 'themes', current_theme_name)
      template_file = theme_path.join('templates', "#{template_type}.json")
      
      if File.exist?(template_file)
        JSON.parse(File.read(template_file))
      else
        { 'sections' => {}, 'order' => [] }
      end
    end

    def load_base_section(section_type)
      theme_path = Rails.root.join('app', 'themes', current_theme_name)
      section_file = theme_path.join('sections', "#{section_type}.liquid")
      
      File.exist?(section_file) ? File.read(section_file) : ''
    end

    def load_base_layout
      theme_path = Rails.root.join('app', 'themes', current_theme_name)
      layout_file = theme_path.join('layout', 'theme.liquid')
      
      if File.exist?(layout_file)
        File.read(layout_file)
      else
        default_layout
      end
    end

    def load_base_assets
      theme_path = Rails.root.join('app', 'themes', current_theme_name)
      
      {
        css: load_asset_file(theme_path, 'assets/theme.css'),
        js: load_asset_file(theme_path, 'assets/theme.js')
      }
    end

    def load_asset_file(theme_path, asset_path)
      asset_file = theme_path.join(asset_path)
      File.exist?(asset_file) ? File.read(asset_file) : ''
    end

    def default_layout
      <<~LIQUID
        <!DOCTYPE html>
        <html>
        <head>
          <title>{{ page.title }}</title>
          <meta name="description" content="{{ page.description }}">
          <style>
            {{ assets.css }}
          </style>
        </head>
        <body>
          {{ content_for_layout }}
          <script>
            {{ assets.js }}
          </script>
        </body>
        </html>
      LIQUID
    end
  end
end




