class CustomFont < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  # Versioning
  has_paper_trail
  
  # Serialization
  serialize :weights, coder: JSON, type: Array
  serialize :styles, coder: JSON, type: Array
  
  # Validations
  validates :name, presence: true, uniqueness: { scope: :tenant_id }
  validates :family, presence: true
  validates :source, presence: true, inclusion: { in: %w[google custom adobe bunny] }
  validates :url, presence: true, if: -> { source == 'custom' }
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :google_fonts, -> { where(source: 'google') }
  scope :custom_fonts, -> { where(source: 'custom') }
  scope :ordered, -> { order(name: :asc) }
  
  # Font sources
  SOURCES = {
    'google' => 'Google Fonts',
    'custom' => 'Custom Font (Self-Hosted)',
    'adobe' => 'Adobe Fonts',
    'bunny' => 'Bunny Fonts (Privacy-Friendly)'
  }.freeze
  
  # Common fallback fonts
  FALLBACKS = {
    'sans-serif' => 'Sans Serif',
    'serif' => 'Serif',
    'monospace' => 'Monospace',
    'cursive' => 'Cursive',
    'fantasy' => 'Fantasy'
  }.freeze
  
  # Font weights
  WEIGHTS = {
    '100' => 'Thin',
    '200' => 'Extra Light',
    '300' => 'Light',
    '400' => 'Regular',
    '500' => 'Medium',
    '600' => 'Semi Bold',
    '700' => 'Bold',
    '800' => 'Extra Bold',
    '900' => 'Black'
  }.freeze
  
  # Font styles
  STYLES = {
    'normal' => 'Normal',
    'italic' => 'Italic'
  }.freeze
  
  # Generate CSS @font-face rule for custom fonts
  def to_css
    return '' unless source == 'custom' && url.present?
    
    css = "@font-face {\n"
    css += "  font-family: '#{family}';\n"
    css += "  src: url('#{url}');\n"
    css += "  font-display: swap;\n"
    
    # Add weight and style if specified
    if weights.present? && weights.first
      css += "  font-weight: #{weights.first};\n"
    end
    
    if styles.present? && styles.first
      css += "  font-style: #{styles.first};\n"
    end
    
    css += "}\n"
    css
  end
  
  # Generate Google Fonts URL
  def google_fonts_url
    return '' unless source == 'google'
    
    # Build Google Fonts API URL
    base_url = "https://fonts.googleapis.com/css2?"
    
    # Family with weights
    family_param = "family=#{family.gsub(' ', '+')}"
    
    if weights.present? && weights.any?
      weights_str = weights.map { |w| "#{w}" }.join(';')
      
      if styles.present? && styles.include?('italic')
        # Include italic variants
        weights_str = weights.map { |w| "0,#{w};1,#{w}" }.join(';')
        family_param += ":ital,wght@#{weights_str}"
      else
        family_param += ":wght@#{weights.join(';')}"
      end
    end
    
    "#{base_url}#{family_param}&display=swap"
  end
  
  # Generate Bunny Fonts URL (privacy-friendly Google Fonts alternative)
  def bunny_fonts_url
    return '' unless source == 'bunny'
    
    # Bunny Fonts uses same API as Google Fonts
    google_fonts_url.gsub('fonts.googleapis.com', 'fonts.bunny.net')
                    .gsub('fonts.gstatic.com', 'fonts.bunny.net')
  end
  
  # Get the appropriate URL based on source
  def font_url
    case source
    when 'google'
      google_fonts_url
    when 'bunny'
      bunny_fonts_url
    when 'adobe'
      url  # Adobe Fonts provides direct URL
    when 'custom'
      url
    else
      ''
    end
  end
  
  # Generate CSS link tag
  def to_link_tag
    return to_css if source == 'custom'
    
    url = font_url
    return '' if url.blank?
    
    "<link rel=\"preconnect\" href=\"#{preconnect_url}\">\n" \
    "<link href=\"#{url}\" rel=\"stylesheet\">"
  end
  
  # Font stack for CSS (includes fallbacks)
  def font_stack
    "'#{family}', #{fallback}"
  end
  
  private
  
  def preconnect_url
    case source
    when 'google'
      'https://fonts.googleapis.com'
    when 'bunny'
      'https://fonts.bunny.net'
    else
      ''
    end
  end
end
