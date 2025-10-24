module AppearanceHelper
  # Generate minimal CSS for user customizations only
  def user_customization_css
    primary = SiteSetting.get('primary_color', '#6366F1')
    secondary = SiteSetting.get('secondary_color', '#8B5CF6')
    
    <<~CSS
      <style id="user-customizations">
        :root {
          --admin-primary: #{primary};
          --admin-primary-hover: #{darken_color(primary, 8)};
          --color-primary: #{primary};
          
          --admin-secondary: #{secondary};
          --admin-secondary-hover: #{darken_color(secondary, 8)};
          --color-secondary: #{secondary};
          
          --font-heading: #{SiteSetting.get('heading_font', 'Inter')};
          --font-body: #{SiteSetting.get('body_font', 'Inter')};
          --font-paragraph: #{SiteSetting.get('paragraph_font', 'Inter')};
        }
      </style>
    CSS
    .html_safe
  end
  
  # Get current color scheme for theme loading
  def current_color_scheme
    SiteSetting.get('color_scheme', 'onyx')
  end
  
  # Generate dynamic CSS based on appearance settings (OLD - keep for now)
  def dynamic_appearance_css
    color_scheme = SiteSetting.get('color_scheme', 'midnight')
    primary_color = SiteSetting.get('primary_color', '#6366F1')
    secondary_color = SiteSetting.get('secondary_color', '#8B5CF6')
    heading_font = SiteSetting.get('heading_font', 'Inter')
    body_font = SiteSetting.get('body_font', 'Inter')
    paragraph_font = SiteSetting.get('paragraph_font', 'Inter')
    
    # Color scheme variables
    scheme_colors = color_scheme_colors(color_scheme)
    
    # Determine if light theme
    is_light_theme = color_scheme == 'amanecer'
    
    # Set text colors based on theme with better contrast
    text_primary = is_light_theme ? '#1a202c' : '#ffffff'
    text_secondary = is_light_theme ? '#2d3748' : '#e8e8e8'
    text_tertiary = is_light_theme ? '#4a5568' : '#a8a8a8'
    text_muted = is_light_theme ? '#718096' : '#6b7280'
    text_placeholder = is_light_theme ? '#a0aec0' : '#4b5563'
    
    <<~CSS
      <style id="dynamic-appearance">
        :root {
          /* Modern Admin Color System */
          
          /* Backgrounds - Layered depth */
          --bg-primary: #{scheme_colors[:bg_primary]};
          --bg-secondary: #{scheme_colors[:bg_secondary]};
          --bg-tertiary: #{scheme_colors[:bg_tertiary]};
          --admin-bg-app: #{scheme_colors[:bg_primary]};
          --admin-bg-primary: #{scheme_colors[:bg_secondary]};
          --admin-bg-secondary: #{scheme_colors[:bg_tertiary]};
          --admin-bg-tertiary: #{lighten_color(scheme_colors[:bg_tertiary], 3)};
          --admin-bg-elevated: #{lighten_color(scheme_colors[:bg_tertiary], 5)};
          
          /* Borders - Subtle hierarchy */
          --border-color: #{scheme_colors[:border_color]};
          --admin-border-subtle: #{scheme_colors[:border_color]};
          --admin-border: #{lighten_color(scheme_colors[:border_color], 5)};
          --admin-border-strong: #{lighten_color(scheme_colors[:border_color], 10)};
          
          /* Text - High contrast */
          --text-primary: #{text_primary};
          --text-secondary: #{text_secondary};
          --text-muted: #{text_muted};
          --admin-text-primary: #{text_primary};
          --admin-text-secondary: #{text_secondary};
          --admin-text-tertiary: #{text_tertiary};
          --admin-text-muted: #{text_muted};
          --admin-text-placeholder: #{text_placeholder};
          
          /* Brand Colors - Vibrant accents */
          --color-primary: #{primary_color};
          --color-secondary: #{secondary_color};
          --admin-primary: #{primary_color};
          --admin-primary-hover: #{darken_color(primary_color, 8)};
          --admin-primary-light: #{hex_to_rgba(primary_color, 0.1)};
          --admin-secondary: #{secondary_color};
          --admin-secondary-hover: #{darken_color(secondary_color, 8)};
          --admin-secondary-light: #{hex_to_rgba(secondary_color, 0.1)};
          
          /* Status Colors */
          --admin-success: #10b981;
          --admin-success-light: rgba(16, 185, 129, 0.1);
          --admin-success-border: rgba(16, 185, 129, 0.2);
          
          --admin-warning: #f59e0b;
          --admin-warning-light: rgba(245, 158, 11, 0.1);
          --admin-warning-border: rgba(245, 158, 11, 0.2);
          
          --admin-error: #ef4444;
          --admin-error-light: rgba(239, 68, 68, 0.1);
          --admin-error-border: rgba(239, 68, 68, 0.2);
          
          --admin-info: #3b82f6;
          --admin-info-light: rgba(59, 130, 246, 0.1);
          --admin-info-border: rgba(59, 130, 246, 0.2);
          
          /* Typography */
          --font-heading: #{heading_font};
          --font-body: #{body_font};
          --font-paragraph: #{paragraph_font};
        }
        
        /* Apply brand colors */
        .bg-indigo-600, .bg-primary {
          background-color: var(--color-primary) !important;
        }
        
        .text-indigo-600, .text-indigo-400 {
          color: var(--color-primary) !important;
        }
        
        .border-indigo-500, .focus\\:ring-indigo-500:focus {
          border-color: var(--color-primary) !important;
        }
        
        .ring-indigo-500 {
          --tw-ring-color: var(--color-primary) !important;
        }
        
        /* Hover states */
        .hover\\:bg-indigo-700:hover {
          background-color: #{darken_color(primary_color, 10)} !important;
        }
        
        /* Secondary color */
        .bg-purple-600 {
          background-color: var(--color-secondary) !important;
        }
        
        /* Text color overrides for consistency */
        .text-white {
          color: var(--text-primary) !important;
        }
        
        .text-gray-300, .text-gray-400 {
          color: var(--text-secondary) !important;
        }
        
        .text-gray-500, .text-gray-600 {
          color: var(--text-muted) !important;
        }
        
        /* Typography */
        h1, h2, h3, h4, h5, h6 {
          font-family: var(--font-heading), sans-serif !important;
        }
        
        body, button, input, select, textarea {
          font-family: var(--font-body), sans-serif !important;
        }
        
        p, .paragraph {
          font-family: var(--font-paragraph), sans-serif !important;
        }
        
        /* Color scheme background */
        .bg-\\[\\#0a0a0a\\], .bg-\\[\\#111111\\] {
          background-color: var(--bg-primary) !important;
        }
        
        .bg-\\[\\#1a1a1a\\] {
          background-color: var(--bg-secondary) !important;
        }
        
        .border-\\[\\#2a2a2a\\] {
          border-color: var(--border-color) !important;
        }
        
        /* Light theme text colors */
        #{color_scheme == 'amanecer' ? '
        body, .text-white {
          color: #1a202c !important;
        }
        
        .text-gray-300, .text-gray-400 {
          color: #4a5568 !important;
        }
        
        .text-gray-500, .text-gray-600 {
          color: #718096 !important;
        }
        
        h1, h2, h3, h4, h5, h6 {
          color: #1a202c !important;
        }
        
        input, select, textarea {
          color: #1a202c !important;
          background-color: #ffffff !important;
        }
        
        input::placeholder, textarea::placeholder {
          color: #a0aec0 !important;
        }
        
        /* Update specific dark text classes for light theme */
        .text-emerald-400, .text-green-400 {
          color: #10b981 !important;
        }
        
        .text-red-400 {
          color: #ef4444 !important;
        }
        
        .text-blue-400, .text-indigo-400 {
          color: #6366f1 !important;
        }
        
        .text-yellow-400 {
          color: #f59e0b !important;
        }
        
        /* Sidebar text */
        nav a, nav span {
          color: #4a5568 !important;
        }
        
        nav a:hover {
          color: #1a202c !important;
        }
        
        /* Top bar */
        header {
          border-bottom-color: #e2e8f0 !important;
        }
        ' : ''}
      </style>
    CSS
    .html_safe
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
  
  def color_scheme_colors(scheme)
    case scheme
    when 'midnight' # New default - Modern, sophisticated
      {
        bg_primary: '#0f0f0f',
        bg_secondary: '#141414',
        bg_tertiary: '#1a1a1a',
        border_color: '#2f2f2f'
      }
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
    when 'slate' # Cool gray
      {
        bg_primary: '#0f172a',
        bg_secondary: '#1e293b',
        bg_tertiary: '#334155',
        border_color: '#475569'
      }
    else # midnight (default)
      {
        bg_primary: '#0f0f0f',
        bg_secondary: '#141414',
        bg_tertiary: '#1a1a1a',
        border_color: '#2f2f2f'
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

