module AppearanceHelper
  # NEW: Minimal user customization CSS (only user's colors/fonts)
  def user_customization_css
    primary_color = SiteSetting.get('primary_color', '#6366F1')
    secondary_color = SiteSetting.get('secondary_color', '#8B5CF6')
    link_color = SiteSetting.get('link_color', '')
    heading_color = SiteSetting.get('heading_color', '')
    body_color = SiteSetting.get('body_color', '')
    button_text_color = SiteSetting.get('button_text_color', '')
    
    # Button-specific settings
    primary_button_bg = SiteSetting.get('primary_button_bg', primary_color)
    primary_button_text = SiteSetting.get('primary_button_text', '#ffffff')
    secondary_button_bg = SiteSetting.get('secondary_button_bg', secondary_color)
    secondary_button_text = SiteSetting.get('secondary_button_text', '#ffffff')
    
    heading_font = SiteSetting.get('heading_font', 'Inter')
    body_font = SiteSetting.get('body_font', 'Inter')
    paragraph_font = SiteSetting.get('paragraph_font', 'Inter')
    
    <<~CSS
      <style id="user-customizations">
        :root {
          /* User's brand colors */
          --color-primary: #{primary_color};
          --admin-primary: #{primary_color};
          --admin-primary-hover: #{darken_color(primary_color, 8)};
          --admin-primary-light: #{hex_to_rgba(primary_color, 0.1)};
          
          --color-secondary: #{secondary_color};
          --admin-secondary: #{secondary_color};
          --admin-secondary-hover: #{darken_color(secondary_color, 8)};
          --admin-secondary-light: #{hex_to_rgba(secondary_color, 0.1)};
          
          /* Button-specific colors */
          --admin-primary-button-bg: #{primary_button_bg};
          --admin-primary-button-text: #{primary_button_text};
          --admin-secondary-button-bg: #{secondary_button_bg};
          --admin-secondary-button-text: #{secondary_button_text};
          
          #{link_color.present? ? "/* User's custom link color (overrides theme) */\n--admin-link: #{link_color};\n--admin-link-hover: #{lighten_color(link_color, 10)};" : ''}
          #{heading_color.present? ? "/* User's custom heading color */\n--admin-heading: #{heading_color};" : ''}
          #{body_color.present? ? "/* User's custom body text color */\n--admin-body: #{body_color};" : ''}
          #{button_text_color.present? ? "/* User's custom button text color */\n--admin-btn-text: #{button_text_color};" : ''}
          
          /* User's fonts */
          --font-heading: #{heading_font};
          --font-body: #{body_font};
          --font-paragraph: #{paragraph_font};
        }
        
        /* Apply user's button colors */
        .bg-indigo-600, .bg-primary, .btn-primary {
          background-color: var(--admin-primary-button-bg) !important;
          color: var(--admin-primary-button-text) !important;
        }
        
        .btn-secondary {
          background-color: var(--admin-secondary-button-bg) !important;
          color: var(--admin-secondary-button-text) !important;
        }
        
        .hover\\:bg-indigo-700:hover {
          background-color: var(--admin-primary-hover) !important;
        }
        
        .border-indigo-500, .focus\\:ring-indigo-500:focus {
          border-color: var(--color-primary) !important;
        }
        
        .ring-indigo-500 {
          --tw-ring-color: var(--color-primary) !important;
        }
        
        .bg-purple-600 {
          background-color: var(--color-secondary) !important;
        }
        
        /* DO NOT override .text-indigo-600 - let theme handle link colors */
        
        /* Apply user's fonts */
        h1, h2, h3, h4, h5, h6 {
          font-family: var(--font-heading), sans-serif !important;
        }
        
        body, button, input, select, textarea {
          font-family: var(--font-body), sans-serif !important;
        }
        
        p, .paragraph {
          font-family: var(--font-paragraph), sans-serif !important;
        }
      </style>
    CSS
    .html_safe
  end
  
  # Helper to get current color scheme for loading correct theme file
  def current_color_scheme
    SiteSetting.get('color_scheme', 'onyx')
  end
  # Get white label settings
  def admin_app_name
    SiteSetting.get('admin_app_name', 'RailsPress')
  end
  
  def admin_logo_url
    SiteSetting.get('admin_logo_url', '')
  end
  
  def admin_favicon_url
    SiteSetting.get('admin_favicon_url', '')
  end
  
  def admin_footer_text
    SiteSetting.get('admin_footer_text', 'Powered by RailsPress')
  end
  
  def hide_branding?
    SiteSetting.get('hide_branding', false) == true || SiteSetting.get('hide_branding', false) == '1'
  end
  
  private
  
  # OLD: Still used by old dynamic_appearance_css, will be deleted after testing
  def color_scheme_colors(scheme)
    case scheme
    when 'vallarta' # Blue ocean theme
      {
        bg_primary: '#0a1628',
        bg_secondary: '#0f1e3a',
        bg_tertiary: '#1a2947',
        border_color: '#2a3f5f'
      }
    when 'amanecer' # Light theme
      {
        bg_primary: '#ffffff',
        bg_secondary: '#f8f9fa',
        bg_tertiary: '#f1f3f5',
        border_color: '#e9ecef'
      }
    when 'onyx' # Pure black
      {
        bg_primary: '#000000',
        bg_secondary: '#0a0a0a',
        bg_tertiary: '#111111',
        border_color: '#1a1a1a'
      }
    else # onyx (default)
      {
        bg_primary: '#000000',
        bg_secondary: '#0a0a0a',
        bg_tertiary: '#111111',
        border_color: '#1a1a1a'
      }
    end
  end
  
  def darken_color(hex, percent)
    hex = hex.delete('#')
    rgb = hex.scan(/../).map { |color| color.hex }
    rgb = rgb.map { |color| [(color * (100 - percent) / 100).to_i, 0].max }
    "#%02x%02x%02x" % rgb
  end
  
  def lighten_color(hex, percent)
    hex = hex.delete('#')
    rgb = hex.scan(/../).map { |color| color.hex }
    rgb = rgb.map { |color| [color + (255 - color) * percent / 100, 255].min.to_i }
    "#%02x%02x%02x" % rgb
  end
  
  def hex_to_rgba(hex, alpha = 1.0)
    hex = hex.delete('#')
    rgb = hex.scan(/../).map { |color| color.hex }
    "rgba(#{rgb[0]}, #{rgb[1]}, #{rgb[2]}, #{alpha})"
  end
end

