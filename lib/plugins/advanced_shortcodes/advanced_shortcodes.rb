class AdvancedShortcodes < Railspress::PluginBase
  plugin_name 'Advanced Shortcodes'
  plugin_version '2.0.0'
  plugin_description 'Extended shortcode library with schema-based settings'
  plugin_author 'RailsPress Team'
  
  # Define comprehensive settings schema showcasing all field types
  settings_schema do
    section 'Appearance', description: 'Control the visual appearance of shortcodes' do
      color 'button_color', 'Default Button Color',
        description: 'Default color for [button] shortcodes',
        default: '#3B82F6'
      
      color 'accent_color', 'Accent Color',
        description: 'Accent color used across shortcodes',
        default: '#10B981'
      
      select 'button_style', 'Button Style',
        [
          ['Rounded', 'rounded'],
          ['Square', 'square'],
          ['Pill', 'pill']
        ],
        description: 'Default button border radius style',
        default: 'rounded'
      
      number 'button_padding', 'Button Padding (px)',
        description: 'Internal padding for buttons',
        default: 12,
        min: 4,
        max: 32
    end
    
    section 'Gallery Settings', description: 'Configure gallery shortcode behavior' do
      select 'gallery_layout', 'Default Layout',
        [
          ['Grid', 'grid'],
          ['Masonry', 'masonry'],
          ['Carousel', 'carousel']
        ],
        default: 'grid'
      
      number 'gallery_columns', 'Columns',
        description: 'Number of columns in grid layout',
        default: 3,
        min: 1,
        max: 6
      
      number 'gallery_spacing', 'Spacing (px)',
        description: 'Gap between gallery items',
        default: 16,
        min: 0,
        max: 48
      
      checkbox 'gallery_lightbox', 'Enable Lightbox',
        description: 'Open images in a lightbox when clicked',
        default: true
      
      checkbox 'gallery_lazy_load', 'Lazy Loading',
        description: 'Lazy load gallery images for better performance',
        default: true
    end
    
    section 'Alert/Callout Settings', description: 'Configure alert box shortcodes' do
      radio 'alert_style', 'Alert Style',
        [
          ['Minimal', 'minimal'],
          ['Bordered', 'bordered'],
          ['Filled', 'filled']
        ],
        default: 'bordered'
      
      checkbox 'alert_dismissible', 'Dismissible',
        description: 'Allow users to close alerts',
        default: true
      
      checkbox 'alert_icons', 'Show Icons',
        description: 'Display icons in alert boxes',
        default: true
    end
    
    section 'Video Settings', description: 'Configure video shortcode options' do
      checkbox 'video_responsive', 'Responsive',
        description: 'Make videos responsive (16:9 aspect ratio)',
        default: true
      
      checkbox 'video_autoplay', 'Auto-play by Default',
        description: 'Videos auto-play when page loads (not recommended)',
        default: false
      
      checkbox 'video_controls', 'Show Controls',
        description: 'Display video playback controls',
        default: true
      
      select 'video_preload', 'Preload Strategy',
        [
          ['None', 'none'],
          ['Metadata', 'metadata'],
          ['Auto', 'auto']
        ],
        description: 'How much of the video to preload',
        default: 'metadata'
    end
    
    section 'Advanced Options', description: 'Advanced configuration' do
      code 'custom_css', 'Custom CSS',
        description: 'Add custom CSS for shortcodes',
        language: 'css',
        placeholder: '.my-shortcode { color: red; }'
      
      textarea 'custom_javascript', 'Custom JavaScript',
        description: 'Add custom JavaScript for shortcodes (use carefully!)',
        rows: 6,
        placeholder: 'console.log("Shortcodes loaded");'
      
      checkbox 'debug_mode', 'Debug Mode',
        description: 'Log shortcode rendering details to console',
        default: false
      
      checkbox 'cache_output', 'Cache Output',
        description: 'Cache rendered shortcode output for performance',
        default: true
    end
  end
  
  def initialize
    super
    register_shortcodes if get_setting('enabled', true)
  end
  
  def activate
    super
    Rails.logger.info "Advanced Shortcodes activated with schema settings"
  end
  
  private
  
  def register_shortcodes
    # Button shortcode
    register_shortcode('button') do |atts, content|
      atts = {
        'url' => '#',
        'color' => get_setting('button_color', '#3B82F6'),
        'style' => get_setting('button_style', 'rounded'),
        'size' => 'medium'
      }.merge(atts || {})
      
      radius = case atts['style']
               when 'pill' then '9999px'
               when 'square' then '0'
               else '6px'
               end
      
      padding = get_setting('button_padding', 12)
      
      <<~HTML
        <a href="#{atts['url']}" 
           class="inline-block"
           style="background: #{atts['color']}; color: white; padding: #{padding}px #{padding * 2}px; border-radius: #{radius}; text-decoration: none; font-weight: 500;">
          #{content}
        </a>
      HTML
    end
    
    # Gallery shortcode
    register_shortcode('gallery') do |atts, content|
      layout = get_setting('gallery_layout', 'grid')
      columns = get_setting('gallery_columns', 3)
      spacing = get_setting('gallery_spacing', 16)
      
      <<~HTML
        <div class="gallery-#{layout}" style="display: grid; grid-template-columns: repeat(#{columns}, 1fr); gap: #{spacing}px;">
          <!-- Gallery items would go here -->
          <div style="text-align: center; padding: 20px; background: #f3f4f6; border-radius: 8px;">
            Gallery placeholder (#{columns} columns)
          </div>
        </div>
      HTML
    end
    
    # Alert shortcode
    register_shortcode('alert') do |atts, content|
      atts = {
        'type' => 'info',
        'style' => get_setting('alert_style', 'bordered'),
        'dismissible' => get_setting('alert_dismissible', true)
      }.merge(atts || {})
      
      colors = {
        'info' => '#3B82F6',
        'success' => '#10B981',
        'warning' => '#F59E0B',
        'error' => '#EF4444'
      }
      
      color = colors[atts['type']] || colors['info']
      
      <<~HTML
        <div class="alert alert-#{atts['type']}" style="border-left: 4px solid #{color}; background: rgba(59, 130, 246, 0.1); padding: 1rem; border-radius: 0.5rem; margin: 1rem 0;">
          #{content}
          #{atts['dismissible'] ? '<button onclick="this.parentElement.remove()" style="float: right;">×</button>' : ''}
        </div>
      HTML
    end
    
    # Video shortcode
    register_shortcode('video') do |atts, content|
      atts = {
        'src' => '',
        'responsive' => get_setting('video_responsive', true),
        'autoplay' => get_setting('video_autoplay', false),
        'controls' => get_setting('video_controls', true)
      }.merge(atts || {})
      
      if atts['responsive']
        <<~HTML
          <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden;">
            <video src="#{atts['src']}" 
                   #{atts['controls'] ? 'controls' : ''} 
                   #{atts['autoplay'] ? 'autoplay' : ''}
                   style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;">
            </video>
          </div>
        HTML
      else
        <<~HTML
          <video src="#{atts['src']}" 
                 #{atts['controls'] ? 'controls' : ''} 
                 #{atts['autoplay'] ? 'autoplay' : ''}
                 style="max-width: 100%;">
          </video>
        HTML
      end
    end
    
    Rails.logger.info "Advanced Shortcodes registered with schema-based settings"
  end
end

# Auto-initialize
if Plugin.exists?(name: 'Advanced Shortcodes', active: true)
  AdvancedShortcodes.new
end
