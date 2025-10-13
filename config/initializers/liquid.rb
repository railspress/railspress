# Configure Liquid (already loaded in application.rb)
# Create a default environment with the configuration
Rails.application.config.after_initialize do
  liquid_env = ::Liquid::Environment.new
  liquid_env.error_mode = :warn # Or :strict for development
  liquid_env.file_system = ::Liquid::BlankFileSystem.new
  
  # Store the environment for use in templates
  Rails.application.config.liquid_environment = liquid_env
end

# Custom Liquid Tags for RailsPress

# Section Tag - Renders theme sections
class SectionTag < Liquid::Tag
  def initialize(tag_name, markup, tokens)
    super
    @section_name = markup.strip.gsub(/['"]/, '')
  end

  def render(context)
    renderer = context.registers[:renderer]
    renderer.render_section(@section_name, context.environments.first)
  end
end

# Snippet Tag - Renders theme snippets
class SnippetTag < Liquid::Tag
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

# Pixel Tag - Renders analytics/tracking pixels
class PixelTag < Liquid::Tag
  def initialize(tag_name, markup, tokens)
    super
    @location = markup.strip.gsub(/['"]/, '')
  end

  def render(context)
    # Render pixels for this location
    pixels = context['pixels'] || []
    pixels.select { |p| p['location'] == @location }.map do |pixel|
      pixel['code']
    end.join("\n")
  end
end

# Hook Tag - Plugin extensibility hooks
class HookTag < Liquid::Tag
  def initialize(tag_name, markup, tokens)
    super
    @hook_name = markup.strip.gsub(/['"]/, '')
  end

  def render(context)
    # Execute hooks for this location
    hook_content = []
    # This integrates with the plugin system
    # PluginSystem.execute_hook(@hook_name, context)
    hook_content.join("\n")
  end
end

# Schema Tag - Defines section settings (Shopify-style)
class SchemaTag < Liquid::Block
  def initialize(tag_name, markup, tokens)
    super
  end

  def render(context)
    # Schema is for the theme editor, not rendered to users
    ''
  end
end

# Paginate Tag - Handles pagination (Shopify-style)
class PaginateTag < Liquid::Block
  def initialize(tag_name, markup, tokens)
    super
    @collection_name = markup.strip.split.first
  end

  def render(context)
    # Render the paginate block content
    super
  end
end

# AdminBar Tag - Renders WordPress-style admin bar for logged-in users
class AdminBarTag < Liquid::Tag
  def render(context)
    renderer = context.registers[:renderer]
    return '' unless renderer
    
    # The admin bar partial will be rendered by the controller
    # This tag just marks where it should appear
    '<!-- ADMIN_BAR_PLACEHOLDER -->'
  end
end

Rails.logger.info "Liquid template engine loaded successfully with custom tags"

# Eagerly load LiquidTemplateRenderer
Rails.application.config.after_initialize do
  require_dependency Rails.root.join('app', 'services', 'liquid_template_renderer').to_s
end
