class LiquidTemplateRenderer
  attr_reader :theme_path, :template

  def initialize(theme_name = 'nordic')
    # Ensure Liquid is loaded
    require 'liquid' unless defined?(::Liquid)
    
    @theme_path = Rails.root.join('app', 'themes', theme_name)
    @template = ::Liquid::Template.new
    setup_file_system
    register_filters
    register_tags
  end

  def render(template_name, assigns = {}, layout = 'theme')
    # Load template content
    template_content = load_template(template_name)
    
    # Parse and render template with renderer context
    parsed_template = ::Liquid::Template.parse(template_content)
    content = parsed_template.render(prepare_assigns(assigns), registers: { renderer: self })
    
    # Wrap in layout if specified
    if layout
      layout_content = load_layout(layout)
      layout_template = ::Liquid::Template.parse(layout_content)
      layout_template.render(prepare_assigns(assigns.merge('content_for_layout' => content)), registers: { renderer: self })
    else
      content
    end
  rescue => e
    Rails.logger.error "Liquid Template Error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    render_error(e)
  end

  def render_section(section_name, assigns = {})
    section_content = load_section(section_name)
    
    # Get settings for this section from JSON template
    section_settings = (@section_settings && @section_settings[section_name]) || {}
    
    # Merge section settings into assigns
    section_assigns = assigns.merge({
      'section' => {
        'settings' => section_settings
      }
    })
    
    parsed = ::Liquid::Template.parse(section_content)
    parsed.render(prepare_assigns(section_assigns), registers: { renderer: self })
  end

  def render_snippet(snippet_name, assigns = {})
    snippet_content = load_snippet(snippet_name)
    parsed = ::Liquid::Template.parse(snippet_content)
    parsed.render(prepare_assigns(assigns))
  end

  private

  def setup_file_system
    # Set up file system to look in snippets directory
    ::Liquid::Template.file_system = ::Liquid::LocalFileSystem.new(@theme_path.join('snippets').to_s)
  end

  def register_filters
    ::Liquid::Template.register_filter(LiquidFilters)
  end

  def register_tags
    ::Liquid::Template.register_tag('section', SectionTag)
    ::Liquid::Template.register_tag('snippet', SnippetTag)
    ::Liquid::Template.register_tag('render', RenderTag)
    ::Liquid::Template.register_tag('pixel', PixelTag)
    ::Liquid::Template.register_tag('hook', HookTag)
    ::Liquid::Template.register_tag('schema', SchemaTag)
    ::Liquid::Template.register_tag('paginate', PaginateTag)
    # ::Liquid::Template.register_tag('admin_bar', AdminBarTag) # AdminBarTag not implemented yet
  end

  def load_template(name)
    # Check for JSON template first (FSE)
    json_path = @theme_path.join('templates', "#{name}.json")
    if File.exist?(json_path)
      load_json_template(json_path)
    else
      # Fall back to liquid template
      liquid_path = @theme_path.join('templates', "#{name}.liquid")
      File.read(liquid_path)
    end
  end

  def load_json_template(path)
    json_data = JSON.parse(File.read(path))
    sections_hash = json_data['sections'] || {}
    order = json_data['order'] || sections_hash.keys
    
    # Store section settings in instance variable for access during rendering
    @section_settings = {}
    
    # Build liquid template from sections in order
    order.map do |section_id|
      section_config = sections_hash[section_id]
      next unless section_config
      
      section_type = section_config['type']
      settings = section_config['settings'] || {}
      
      # Store settings for this section
      @section_settings[section_type] = settings
      
      # Simply include the section tag
      "{% section '#{section_type}' %}"
    end.compact.join("\n")
  end

  def load_layout(name)
    File.read(@theme_path.join('layout', "#{name}.liquid"))
  end

  def load_section(name)
    File.read(@theme_path.join('sections', "#{name}.liquid"))
  end

  def load_snippet(name)
    File.read(@theme_path.join('snippets', "#{name}.liquid"))
  end

  def prepare_assigns(assigns)
    # Convert ActiveRecord objects to hashes
    converted_assigns = convert_to_liquid_format(assigns)
    
    # Load site data and merge with menus
    site_data = load_site_data
    site_data['menus'] = load_menus
    
    base_assigns = {
      'site' => site_data,
      'theme' => load_theme_settings,
      'menus' => load_menus,
      'current_user' => converted_assigns[:current_user],
      'request_path' => converted_assigns[:request_path],
      'settings' => load_settings,
      'collections' => {
        'posts' => converted_assigns['posts'] || converted_assigns['featured_posts'] || converted_assigns['recent_posts'] || []
      }
    }
    
    base_assigns.merge(converted_assigns.deep_stringify_keys)
  end
  
  def convert_to_liquid_format(assigns)
    converted = {}
    
    assigns.each do |key, value|
      converted[key] = case value
      when ActiveRecord::Relation, Array
        value.map { |item| item.respond_to?(:attributes) ? to_liquid_hash(item) : item }
      when ActiveRecord::Base
        to_liquid_hash(value)
      else
        value
      end
    rescue NameError => e
      # Handle missing constants (e.g., Category, Tag removed)
      Rails.logger.warn "Liquid conversion error for #{key}: #{e.message}"
      nil
    end
    
    converted
  end
  
  def to_liquid_hash(record)
    hash = record.attributes.dup
    
    # Add common associations and methods
    if record.respond_to?(:user) && record.user
      user = record.user
      hash['author'] = {
        'id' => user.id,
        'email' => user.email,
        'name' => user.name.presence || user.email,
        'bio' => user.bio,
        'avatar_url' => user.avatar_url,
        'twitter' => user.twitter,
        'github' => user.github,
        'linkedin' => user.linkedin
      }
    end
    
    # Add categories and tags from taxonomy system
    if record.respond_to?(:terms)
      category_taxonomy = Taxonomy.find_by(slug: 'category')
      tag_taxonomy = Taxonomy.find_by(slug: 'tag')
      
      if category_taxonomy
        categories = record.terms.where(taxonomy: category_taxonomy)
        hash['categories'] = categories.map { |c| { 'id' => c.id, 'name' => c.name, 'slug' => c.slug, 'url' => "/blog/category/#{c.slug}" } }
      end
      
      if tag_taxonomy
        tags = record.terms.where(taxonomy: tag_taxonomy)
        hash['tags'] = tags.map { |t| { 'id' => t.id, 'name' => t.name, 'slug' => t.slug, 'url' => "/blog/tag/#{t.slug}" } }
      end
    end
    
    # Handle ActionText content
    if record.respond_to?(:content) && record.content.is_a?(ActionText::RichText)
      hash['content'] = record.content.to_s
    elsif record.respond_to?(:content)
      hash['content'] = record.content.to_s
    end
    
    # Add URL/path helpers and computed fields
    if record.is_a?(Post)
      hash['url'] = "/blog/#{record.slug}"
      hash['excerpt'] = record.excerpt.presence || hash['content'].to_s.truncate(200, separator: ' ')
      hash['reading_time'] = ((hash['content'].to_s.split.size / 200.0).ceil rescue 1)
    elsif record.is_a?(Page)
      hash['url'] = "/page/#{record.slug}"
      hash['excerpt'] = hash['content'].to_s.truncate(200, separator: ' ')
    elsif record.is_a?(Term)
      # Terms (from taxonomy system)
      taxonomy_slug = record.taxonomy&.slug
      if taxonomy_slug == 'category'
        hash['url'] = "/blog/category/#{record.slug}"
      elsif taxonomy_slug == 'tag'
        hash['url'] = "/blog/tag/#{record.slug}"
      else
        hash['url'] = "/taxonomy/#{taxonomy_slug}/#{record.slug}"
      end
    end
    
    hash
  end

  def load_site_data
    data_file = @theme_path.join('data', 'site.yml')
    if File.exist?(data_file)
      YAML.load_file(data_file)
    else
      {
        'name' => SiteSetting.get('site_title', 'RailsPress'),
        'description' => SiteSetting.get('site_description', ''),
        'logo' => SiteSetting.get('site_logo', ''),
        'url' => SiteSetting.get('site_url', '')
      }
    end
  end

  def load_theme_settings
    settings_file = @theme_path.join('config', 'settings_data.json')
    if File.exist?(settings_file)
      JSON.parse(File.read(settings_file))
    else
      {}
    end
  end

  def load_menus
    menus_file = @theme_path.join('data', 'menus.yml')
    if File.exist?(menus_file)
      YAML.load_file(menus_file)
    else
      Menu.all.includes(:menu_items).map do |menu|
        {
          menu.location => menu.menu_items.ordered.map do |item|
            {
              'title' => item.title,
              'url' => item.url,
              'target' => item.target
            }
          end
        }
      end.reduce({}, :merge)
    end
  end

  def load_settings
    SiteSetting.all.pluck(:key, :value).to_h
  end

  def render_error(error)
    <<~HTML
      <div style="padding: 20px; background: #fee; border: 2px solid #c00; margin: 20px;">
        <h2>Liquid Template Error</h2>
        <p><strong>#{error.class}:</strong> #{error.message}</p>
        <pre>#{error.backtrace.first(10).join("\n")}</pre>
      </div>
    HTML
  end
end

# Custom Liquid Tags
class SectionTag < ::Liquid::Tag
  def initialize(tag_name, markup, tokens)
    super
    @section_name = markup.strip.gsub(/['"]/, '')
  end

  def render(context)
    renderer = context.registers[:renderer]
    return '' unless renderer
    renderer.render_section(@section_name, context.environments.first || {})
  rescue => e
    "<!-- Section error: #{e.message} -->"
  end
end

class SnippetTag < ::Liquid::Tag
  def initialize(tag_name, markup, tokens)
    super
    @snippet_name = markup.strip.gsub(/['"]/, '')
  end

  def render(context)
    renderer = context.registers[:renderer]
    return '' unless renderer
    renderer.render_snippet(@snippet_name, context.environments.first || {})
  rescue => e
    "<!-- Snippet error: #{e.message} -->"
  end
end

class PixelTag < ::Liquid::Tag
  def initialize(tag_name, markup, tokens)
    super
    @location = markup.strip.gsub(/['"]/, '')
  end

  def render(context)
    pixels = context['pixels'] || []
    pixels.select { |p| p['location'] == @location }.map do |pixel|
      pixel['code']
    end.join("\n")
  end
end

class HookTag < ::Liquid::Tag
  def initialize(tag_name, markup, tokens)
    super
    @hook_name = markup.strip.gsub(/['"]/, '')
  end

  def render(context)
    ''
  end
end

class SchemaTag < ::Liquid::Block
  def render(context)
    ''
  end
end

class PaginateTag < ::Liquid::Block
  def render(context)
    super
  end
end

class RenderTag < ::Liquid::Tag
  def initialize(tag_name, markup, tokens)
    super
    # Parse: {% render 'snippet-name', var: value %}
    parts = markup.strip.split(',', 2)
    @snippet_name = parts.first.gsub(/['"]/, '').strip
    @variables = parse_variables(parts[1]) if parts[1]
  end

  def render(context)
    renderer = context.registers[:renderer]
    return '' unless renderer
    
    # Get the current environment
    env = context.environments.first || {}
    
    # If @variables contains "post: post", we need to pass the current 'post' from context
    merged_context = env.dup
    
    # Simple variable passthrough - if @variables is "post: post", pass the post variable
    if @variables && @variables.include?(':')
      @variables.split(',').each do |pair|
        key, value = pair.split(':').map(&:strip)
        merged_context[key] = context[value] if context[value]
      end
    end
    
    renderer.render_snippet(@snippet_name, merged_context)
  rescue => e
    "<!-- Render error: #{e.message} -->"
  end
  
  private
  
  def parse_variables(vars_string)
    return {} unless vars_string
    
    # This will be resolved from the parent context
    # For now, just extract the variable names
    # Example: "post: post" means pass the 'post' variable from context
    vars_string.strip
  end
end

# Liquid Filters Module
module LiquidFilters
  def asset_url(input)
    "/themes/nordic/assets/#{input}"
  end

  def image_url(input)
    return '' unless input
    input.start_with?('http') ? input : "/uploads/#{input}"
  end

  def truncate_words(input, words = 50, suffix = '...')
    return '' unless input
    word_list = input.to_s.split
    word_list.length > words ? word_list[0...words].join(' ') + suffix : input
  end

  def strip_html(input)
    ActionController::Base.helpers.strip_tags(input.to_s)
  end

  def reading_time(input)
    words = input.to_s.split.length
    minutes = (words / 200.0).ceil
    "#{minutes} min read"
  end

  def date_format(input, format = '%B %d, %Y')
    return '' unless input
    date = input.is_a?(String) ? Date.parse(input) : input
    date.strftime(format)
  end

  def url_encode(input)
    CGI.escape(input.to_s)
  end

  def json(input)
    input.to_json
  end
end

# Custom Liquid tags are defined in config/initializers/liquid.rb
