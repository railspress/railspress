class BuilderLiquidRenderer
  attr_reader :builder_theme, :theme_file_manager

  def initialize(builder_theme)
    @builder_theme = builder_theme
    @themes_manager = ThemesManager.new
    
    # Configure Liquid to allow includes and renders
    setup_liquid_file_system
  end

  # Render a template using the builder theme's data
  def render_template(template_name, context = {})
    # Get rendered file data (template + layout + sections + settings)
    rendered_data = builder_theme.get_rendered_file(template_name)
    return '<div class="error">Template not found</div>' unless rendered_data
    
    # Get layout content from filesystem
    layout_content = rendered_data[:layout_content]
    return '<div class="error">Layout not found</div>' unless layout_content
    
    # Render sections based on file settings
    sections_html = render_sections_from_rendered_data(rendered_data, context)
    
    # Replace content_for_layout with rendered sections
    layout_content = layout_content.gsub('{{ content_for_layout }}', sections_html)
    
    # Render the layout with all sections and settings
    render_layout_with_sections(layout_content, context, rendered_data)
  end

  # Render a specific section using filesystem content + database settings
  def render_section(section_id, section_data, context = {})
    # Get section content from filesystem (latest developer changes)
    section_content = get_section_content(section_data['type'])
    return '' unless section_content

    # Register custom filters
    self.class.register_liquid_filters(builder_theme.id)

    # Create liquid template with permissive settings
    template = Liquid::Template.parse(section_content, error_mode: :strict)
    
    # Prepare context with settings from database (user customizations)
    liquid_context = {
      'section' => {
        'settings' => section_data['settings'] || {},
        'id' => section_id,
        'type' => section_data['type']
      }
    }.merge(context)
    
    # Render section
    template.render!(liquid_context)
  rescue Liquid::Error => e
    Rails.logger.error "Liquid error in section #{section_id}: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
    "<div class='error'>Liquid error in section #{section_id}: #{e.message}<br>Backtrace: #{e.backtrace.first(5).join('<br>')}</div>"
  rescue => e
    Rails.logger.error "Error rendering section #{section_id}: #{e.message}"
    "<div class='error'>Error rendering section: #{e.message}</div>"
  end

  # Render section with content and settings
  def render_section_with_content(section, section_content, context = {})
    return '' unless section_content

    # Register custom filters
    self.class.register_liquid_filters(builder_theme.id)

    # Create liquid template with permissive settings
    template = Liquid::Template.parse(section_content, error_mode: :strict)
    
    # Prepare context with settings from database (user customizations)
    liquid_context = {
      'section' => {
        'settings' => section.settings || {},
        'id' => section.section_id,
        'type' => section.section_type
      }
    }.merge(context)
    
    # Render section
    template.render!(liquid_context)
  rescue Liquid::Error => e
    Rails.logger.error "Liquid error in section #{section.section_id}: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
    "<div class='error'>Liquid error in section #{section.section_id}: #{e.message}<br>Backtrace: #{e.backtrace.first(5).join('<br>')}</div>"
  rescue => e
    Rails.logger.error "Error rendering section #{section.section_id}: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
    "<div class='error'>Error rendering section: #{e.message}<br>Backtrace: #{e.backtrace.first(5).join('<br>')}</div>"
  end

  # Get all available template types
  def available_templates
    template_files = builder_theme.builder_theme_files.templates
    template_files.map { |file| file.template_name }.compact
  end

  # Get all available section types
  def available_sections
    section_files = builder_theme.builder_theme_files.sections
    section_files.map { |file| file.section_name }.compact
  end

  # Get template data - always from filesystem (latest changes)
  def get_template_data(template_type)
    @themes_manager.get_parsed_file("templates/#{template_type}.json") || {}
  end

  # Get section content - from filesystem or PublishedThemeFile
  def get_section_content(section_type)
    content = get_file_content("sections/#{section_type}.liquid") || ''
    
    # Remove schema tags from section content for rendering
    # Schema tags are used by the builder UI, not for rendering
    content.gsub(/{%\s*schema\s*%}.*?{%\s*endschema\s*%}/m, '')
  end

  # Get layout content - from filesystem or PublishedThemeFile
  def get_layout_content
    get_file_content("layout/theme.liquid") || default_layout
  end

  # Get theme assets - from filesystem or PublishedThemeFile
  def assets
    {
      css: get_file_content('assets/theme.css') || '',
      js: get_file_content('assets/theme.js') || ''
    }
  end

  private

  def setup_liquid_file_system
    # Create a custom file system that can resolve includes from PublishedThemeFile
    if @builder_theme.respond_to?(:instance_variable_get) && 
       @builder_theme.instance_variable_get(:@published_version)
      
      published_version = @builder_theme.instance_variable_get(:@published_version)
      
      # Use PublishedVersion directly as the file system
      Liquid::Template.file_system = published_version
      Rails.logger.info "Set up PublishedVersion as Liquid file system"
    else
      # Use default file system for regular themes
      Liquid::Template.file_system = Liquid::LocalFileSystem.new("/", "%s.liquid")
    end
  end

  # Get file content from either PublishedThemeFile or ThemesManager
  def get_file_content(file_path)
    # Check if we're using PublishedThemeFile (FrontendRendererService)
    if @builder_theme.respond_to?(:instance_variable_get) && 
       @builder_theme.instance_variable_get(:@published_version)
      
      published_version = @builder_theme.instance_variable_get(:@published_version)
      file = published_version.published_theme_files.find_by(file_path: file_path)
      return file&.content
    end
    
    # Otherwise use ThemesManager
    @themes_manager.get_file(file_path)
  end

  # Get asset content - from filesystem or PublishedThemeFile
  def get_asset_content(asset_path)
    get_file_content(asset_path) || ''
  end

  # Get theme settings
  def theme_settings
    # Return empty hash since BuilderTheme doesn't have settings_data
    {}
  end

  # Render preview - should use real data, not sample data
  def render_preview(template_type = 'index')
    # This method should not be used - use real context data instead
    raise "render_preview should not be used - use render_template with real context data"
  end

  # Update template data
  def update_template_data(template_type, template_data)
    content = JSON.pretty_generate(template_data)
    builder_theme.update_file("templates/#{template_type}.json", content)
  end

  # Update section content
  def update_section_content(section_type, content)
    builder_theme.update_file("sections/#{section_type}.liquid", content)
  end

  # Update layout content
  def update_layout_content(content)
    builder_theme.update_file("layout/theme.liquid", content)
  end

  # Update asset content
  def update_asset_content(asset_type, content)
    builder_theme.update_file("assets/theme.#{asset_type}", content)
  end

  # Update theme settings
  def update_theme_settings(settings)
    # BuilderTheme doesn't have settings_data, so we'll skip this for now
    # In the future, this could be stored in a separate settings table
    Rails.logger.info "Theme settings update requested: #{settings}"
  end

  private

  def render_layout_with_sections(layout_content, context, rendered_data = {})
    # Register custom filters
    self.class.register_liquid_filters(builder_theme.id)
    
    # Process section tags first
    processed_content = process_section_tags(layout_content, context)
    
    # Parse the layout as a Liquid template with permissive settings
    template = Liquid::Template.parse(processed_content, error_mode: :strict)
    
    # Prepare context with all available data
    liquid_context = build_liquid_context(context, rendered_data)
    
    # Render the layout
    template.render!(liquid_context)
  rescue Liquid::Error => e
    Rails.logger.error "Liquid error in layout: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
    "<div class='error'>Liquid error in layout: #{e.message}<br>Backtrace: #{e.backtrace.first(5).join('<br>')}</div>"
  rescue => e
    Rails.logger.error "Error rendering layout: #{e.message}"
    "<div class='error'>Error rendering layout: #{e.message}</div>"
  end

  def process_section_tags(content, context)
    # Replace {% section 'section_name' %} with rendered section content
    content.gsub(/{%\s*section\s+['"]([^'"]+)['"]\s*%}/) do |match|
      section_name = $1
      render_section_by_name(section_name, context)
    end
  end

  def render_section_by_name(section_name, context)
    section_content = load_section_content(section_name)
    return '' unless section_content

    # Register custom filters
    self.class.register_liquid_filters(builder_theme.id)

    # Create liquid template with permissive settings
    template = Liquid::Template.parse(section_content, error_mode: :strict)
    
    # Prepare context
    liquid_context = build_liquid_context(context)
    
    # Render section
    template.render!(liquid_context)
  rescue Liquid::Error => e
    Rails.logger.error "Liquid error in section #{section_name}: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
    "<div class='error'>Liquid error in section #{section_name}: #{e.message}<br>Backtrace: #{e.backtrace.first(5).join('<br>')}</div>"
  rescue => e
    Rails.logger.error "Error rendering section #{section_name}: #{e.message}"
    "<div class='error'>Error rendering section #{section_name}: #{e.message}</div>"
  end

  def load_template_data(template_type)
    template_data(template_type)
  end

  def load_section_content(section_type)
    get_section_content(section_type)
  end

  def load_layout_content
    layout_content
  end

  def asset_content(asset_path)
    asset_file = builder_theme.get_file(asset_path)
    asset_file&.content || ''
  end

  def render_sections_from_rendered_data(rendered_data, context)
    sections_html = ''
    
    # Get sections from template content with proper order
    template_content = rendered_data[:template_content] || {}
    sections = template_content['sections'] || {}
    section_order = template_content['order'] || sections.keys
    
    # Render sections in the correct order
    section_order.each do |section_id|
      section_data = sections[section_id]
      next unless section_data
      
      Rails.logger.info "Rendering section: #{section_id} (#{section_data['type']}) with settings: #{section_data['settings']}"
      
      # Skip header/footer as they're rendered by the layout
      next if %w[header footer].include?(section_data['type'])
      
      # Get section content from filesystem
      section_content = get_section_content(section_data['type'])
      next unless section_content
      
      # Create a mock section object for compatibility
      section = OpenStruct.new(
        section_id: section_id,
        section_type: section_data['type'],
        settings: section_data['settings'] || {}
      )
      
      # Render section with its settings
      sections_html += render_section_with_content(section, section_content, context)
    end
    
    sections_html
  rescue => e
    Rails.logger.error "Error rendering template sections: #{e.message}"
    "<div class='error'>Error rendering template: #{e.message}</div>"
  end

  def build_liquid_context(context = {}, rendered_data = {})
    # Start with minimal base context - no sample data
    base_context = {
      'site' => {
        'title' => 'RailsPress Site',
        'description' => 'A RailsPress powered website',
        'url' => 'https://example.com'
      },
      'page' => {
        'title' => 'Page Title',
        'url' => '/current-page'
      }
    }
    
    # Add rendered data context
    if rendered_data.present?
      base_context.merge!({
        'template_settings' => rendered_data[:template_settings] || {},
        'layout_settings' => rendered_data[:layout_settings] || {},
        'theme_settings' => rendered_data[:theme_settings] || {}
      })
    end
    
    base_context.merge(context)
  end


  # Register all Liquid filters and tags
  def self.register_liquid_filters(builder_theme_id = nil)
    # Create a custom asset filter with the theme ID
    custom_asset_filters = Module.new do
      define_method :asset_url do |input|
        if builder_theme_id
          "/admin/builder/#{builder_theme_id}/#{input}"
        else
          "/assets/#{input}"
        end
      end
      
      define_method :image_url do |input|
        "/images/#{input}"
      end
    end
    
    Liquid::Template.register_filter(custom_asset_filters)
    Liquid::Template.register_filter(ContentFilters)
    Liquid::Template.register_filter(DateFilters)
    Liquid::Template.register_filter(StringFilters)
    Liquid::Template.register_filter(ArrayFilters)
    Liquid::Template.register_filter(UrlFilters)
    Liquid::Template.register_filter(MetaFilters)
    
    # Register custom tags
    Liquid::Template.register_tag('section', SectionTag)
    Liquid::Template.register_tag('paginate', PaginateTag)
    Liquid::Template.register_tag('form', FormTag)
    Liquid::Template.register_tag('comment_form', CommentFormTag)
    Liquid::Template.register_tag('search_form', SearchFormTag)
  end

  # Asset filters
  module AssetFilters
    def asset_url(input)
      # Return builder asset URL for preview
      # This will be set by the renderer when registering filters
      if @builder_theme_id
        "/admin/builder/#{@builder_theme_id}/#{input}"
      else
        "/assets/#{input}"
      end
    end

    def image_url(input)
      # Return a placeholder URL for preview
      "/images/#{input}"
    end

    def file_url(input)
      # Return a placeholder URL for preview
      "/files/#{input}"
    end

    def stylesheet_url(input)
      "/assets/#{input}.css"
    end

    def script_url(input)
      "/assets/#{input}.js"
    end
  end

  # Content filters
  module ContentFilters
    def strip_html(input)
      return '' unless input
      ActionController::Base.helpers.strip_tags(input.to_s)
    end

    def truncate(input, length = 50, truncate_string = '...')
      return '' unless input
      input.to_s.length > length ? input.to_s[0, length] + truncate_string : input.to_s
    end

    def truncatewords(input, words = 15, truncate_string = '...')
      return '' unless input
      words_array = input.to_s.split
      words_array.length > words ? words_array[0, words].join(' ') + truncate_string : input.to_s
    end

    def strip_newlines(input)
      return '' unless input
      input.to_s.gsub(/\r?\n/, ' ')
    end

    def newline_to_br(input)
      return '' unless input
      input.to_s.gsub(/\r?\n/, '<br>')
    end

    def escape_html(input)
      return '' unless input
      ERB::Util.html_escape(input.to_s)
    end

    def unescape_html(input)
      return '' unless input
      CGI.unescapeHTML(input.to_s)
    end

    def json(input)
      return '{}' unless input
      input.to_json
    end

    def xml_escape(input)
      return '' unless input
      input.to_s.gsub(/&/, '&amp;').gsub(/</, '&lt;').gsub(/>/, '&gt;').gsub(/"/, '&quot;').gsub(/'/, '&#39;')
    end
  end

  # Date filters
  module DateFilters
    def date(input, format = '%B %d, %Y')
      return '' unless input
      begin
        date = case input
        when String
          Time.parse(input)
        when Date, Time, DateTime
          input
        else
          input.to_time
        end
        date.strftime(format)
      rescue
        input.to_s
      end
    end

    def time(input, format = '%I:%M %p')
      date(input, format)
    end

    def datetime(input, format = '%B %d, %Y at %I:%M %p')
      date(input, format)
    end

    def time_ago(input)
      return '' unless input
      begin
        time = case input
        when String
          Time.parse(input)
        when Date, Time, DateTime
          input
        else
          input.to_time
        end
        time_ago_in_words(time)
      rescue
        input.to_s
      end
    end

    def time_ago_in_words(time)
      distance = Time.current - time
      case distance
      when 0..1.minute
        'just now'
      when 1.minute..1.hour
        "#{(distance / 1.minute).round} minutes ago"
      when 1.hour..1.day
        "#{(distance / 1.hour).round} hours ago"
      when 1.day..1.week
        "#{(distance / 1.day).round} days ago"
      when 1.week..1.month
        "#{(distance / 1.week).round} weeks ago"
      when 1.month..1.year
        "#{(distance / 1.month).round} months ago"
      else
        "#{(distance / 1.year).round} years ago"
      end
    end
  end

  # String filters
  module StringFilters
    def capitalize(input)
      return '' unless input
      input.to_s.capitalize
    end

    def upcase(input)
      return '' unless input
      input.to_s.upcase
    end

    def downcase(input)
      return '' unless input
      input.to_s.downcase
    end

    def capitalize_words(input)
      return '' unless input
      input.to_s.split.map(&:capitalize).join(' ')
    end

    def replace(input, string, replacement = '')
      return '' unless input
      input.to_s.gsub(string, replacement)
    end

    def remove(input, string)
      return '' unless input
      input.to_s.gsub(string, '')
    end

    def append(input, string)
      return string unless input
      input.to_s + string.to_s
    end

    def prepend(input, string)
      return input unless string
      string.to_s + input.to_s
    end

    def slice(input, start, length = 1)
      return '' unless input
      input.to_s[start.to_i, length.to_i] || ''
    end

    def size(input)
      return 0 unless input
      input.to_s.length
    end

    def lstrip(input)
      return '' unless input
      input.to_s.lstrip
    end

    def rstrip(input)
      return '' unless input
      input.to_s.rstrip
    end

    def strip(input)
      return '' unless input
      input.to_s.strip
    end
  end

  # Array filters
  module ArrayFilters
    def join(input, glue = ' ')
      return '' unless input
      Array(input).join(glue)
    end

    def first(input)
      return '' unless input
      Array(input).first
    end

    def last(input)
      return '' unless input
      Array(input).last
    end

    def size(input)
      return 0 unless input
      Array(input).size
    end

    def sort(input, property = nil)
      return [] unless input
      array = Array(input)
      if property
        array.sort_by { |item| item.respond_to?(property) ? item.send(property) : item }
      else
        array.sort
      end
    end

    def reverse(input)
      return [] unless input
      Array(input).reverse
    end

    def uniq(input)
      return [] unless input
      Array(input).uniq
    end

    def where(input, property, value)
      return [] unless input
      Array(input).select { |item| item.respond_to?(property) && item.send(property) == value }
    end

    def where_not(input, property, value)
      return [] unless input
      Array(input).reject { |item| item.respond_to?(property) && item.send(property) == value }
    end

    def limit(input, count)
      return [] unless input
      Array(input).first(count.to_i)
    end

    def offset(input, count)
      return [] unless input
      Array(input).drop(count.to_i)
    end
  end

  # URL filters
  module UrlFilters
    def url_encode(input)
      return '' unless input
      ERB::Util.url_encode(input.to_s)
    end

    def url_decode(input)
      return '' unless input
      CGI.unescape(input.to_s)
    end

    def link_to(text, url, options = {})
      return '' unless text && url
      attributes = options.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
      "<a href=\"#{url}\" #{attributes}>#{text}</a>"
    end

    def link_to_if(condition, text, url, options = {})
      return text unless condition
      link_to(text, url, options)
    end

    def link_to_unless(condition, text, url, options = {})
      return text if condition
      link_to(text, url, options)
    end
  end

  # Meta filters
  module MetaFilters
    def meta(input, key)
      return '' unless input
      if input.respond_to?(:meta) && input.meta.is_a?(Hash)
        input.meta[key.to_s] || ''
      else
        ''
      end
    end

    def has_meta(input, key)
      return false unless input
      if input.respond_to?(:meta) && input.meta.is_a?(Hash)
        input.meta.key?(key.to_s)
      else
        false
      end
    end

    def meta_keys(input)
      return [] unless input
      if input.respond_to?(:meta) && input.meta.is_a?(Hash)
        input.meta.keys
      else
        []
      end
    end
  end

  # Custom Liquid tags
  class SectionTag < Liquid::Tag
    def initialize(tag_name, markup, options)
      super
      @section_name = markup.strip.gsub(/['"]/, '')
    end

    def render(context)
      # This would be handled by the main renderer
      "<!-- Section: #{@section_name} -->"
    end
  end

  class PaginateTag < Liquid::Tag
    def initialize(tag_name, markup, options)
      super
      @markup = markup.strip
    end

    def render(context)
      paginate = context['paginate']
      return '' unless paginate

      html = []
      html << "<div class=\"pagination\">"
      
      if paginate['current_page'] > 1
        html << "<a href=\"?page=#{paginate['current_page'] - 1}\" class=\"prev\">Previous</a>"
      end
      
      (1..paginate['total_pages']).each do |page|
        if page == paginate['current_page']
          html << "<span class=\"current\">#{page}</span>"
        else
          html << "<a href=\"?page=#{page}\" class=\"page\">#{page}</a>"
        end
      end
      
      if paginate['current_page'] < paginate['total_pages']
        html << "<a href=\"?page=#{paginate['current_page'] + 1}\" class=\"next\">Next</a>"
      end
      
      html << "</div>"
      html.join("\n")
    end
  end

  class FormTag < Liquid::Tag
    def initialize(tag_name, markup, options)
      super
      @markup = markup.strip
    end

    def render(context)
      # Basic form rendering
      "<form method=\"post\" class=\"liquid-form\">#{@markup}</form>"
    end
  end

  class CommentFormTag < Liquid::Tag
    def render(context)
      post = context['post']
      return '' unless post

      html = []
      html << "<form method=\"post\" action=\"/comments\" class=\"comment-form\">"
      html << "<input type=\"hidden\" name=\"post_id\" value=\"#{post.id}\">"
      html << "<div class=\"form-group\">"
      html << "<label for=\"author_name\">Name:</label>"
      html << "<input type=\"text\" name=\"author_name\" id=\"author_name\" required>"
      html << "</div>"
      html << "<div class=\"form-group\">"
      html << "<label for=\"author_email\">Email:</label>"
      html << "<input type=\"email\" name=\"author_email\" id=\"author_email\" required>"
      html << "</div>"
      html << "<div class=\"form-group\">"
      html << "<label for=\"content\">Comment:</label>"
      html << "<textarea name=\"content\" id=\"content\" required></textarea>"
      html << "</div>"
      html << "<button type=\"submit\">Submit Comment</button>"
      html << "</form>"
      html.join("\n")
    end
  end

  class SearchFormTag < Liquid::Tag
    def render(context)
      html = []
      html << "<form method=\"get\" action=\"/search\" class=\"search-form\">"
      html << "<input type=\"text\" name=\"q\" placeholder=\"Search...\" value=\"#{context['search_query'] || ''}\">"
      html << "<button type=\"submit\">Search</button>"
      html << "</form>"
      html.join("\n")
    end
  end


  def default_layout
    <<~LIQUID
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{{ page.title | default: site.title }}</title>
        <meta name="description" content="{{ page.description | default: site.description }}">
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
