class Template < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  belongs_to :theme

  # Template types
  TEMPLATE_TYPES = %w[
    homepage
    blog_index
    blog_single
    page_default
    page_full_width
    archive
    category
    tag
    search
    404
    header
    footer
    sidebar
  ].freeze

  validates :name, presence: true
  validates :template_type, presence: true, inclusion: { in: TEMPLATE_TYPES }
  validates :template_type, uniqueness: { scope: :theme_id }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(template_type: type) }

  # Callbacks
  after_initialize :set_defaults, if: :new_record?

  # Methods
  def render_content
    html_content || default_template
  end

  private

  def set_defaults
    self.active = true if active.nil?
    self.html_content ||= default_template
    self.css_content ||= default_css
    self.js_content ||= ''
  end

  def default_template
    <<-HTML
      <div class="container mx-auto px-4 py-8">
        <h1>Welcome to #{name}</h1>
        <p>Start customizing this template using the visual editor.</p>
      </div>
    HTML
  end

  def default_css
    <<-CSS
      body {
        font-family: system-ui, -apple-system, sans-serif;
        line-height: 1.6;
        color: #333;
      }
      .container {
        max-width: 1200px;
      }
    CSS
  end
end
