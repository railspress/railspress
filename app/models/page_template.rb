class PageTemplate < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  # Associations
  has_many :pages, dependent: :nullify
  
  # Template types
  TEMPLATE_TYPES = %w[
    default
    full_width
    landing_page
    contact_page
    about_page
    portfolio_page
    blog_page
    custom
  ].freeze
  
  # Validations
  validates :name, presence: true
  validates :template_type, presence: true, inclusion: { in: TEMPLATE_TYPES }
  validates :template_type, uniqueness: { scope: :tenant_id }
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(template_type: type) }
  scope :ordered, -> { order(:position, :name) }
  
  # Callbacks
  after_initialize :set_defaults, if: :new_record?
  
  # Methods
  def render_content(page = nil)
    content = html_content.presence || default_template
    
    if page
      # Replace template variables with page data
      content = content.gsub('{{page.title}}', page.title || '')
      content = content.gsub('{{page.content}}', page.content.to_s || '')
      content = content.gsub('{{page.slug}}', page.slug || '')
      content = content.gsub('{{page.meta_description}}', page.meta_description || '')
    end
    
    content
  end
  
  def render_css
    css_content.presence || default_css
  end
  
  def render_js
    js_content.presence || ''
  end
  
  def default_template?
    template_type == 'default'
  end
  
  private
  
  def set_defaults
    self.active = true if active.nil?
    self.position ||= 0
    self.html_content ||= default_template
    self.css_content ||= default_css
    self.js_content ||= ''
  end
  
  def default_template
    case template_type
    when 'full_width'
      <<-HTML
        <div class="min-h-screen">
          <div class="container mx-auto px-4 py-8">
            <h1 class="text-4xl font-bold mb-8">{{page.title}}</h1>
            <div class="prose prose-lg max-w-none">
              {{page.content}}
            </div>
          </div>
        </div>
      HTML
    when 'landing_page'
      <<-HTML
        <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
          <div class="container mx-auto px-4 py-16">
            <div class="text-center">
              <h1 class="text-5xl font-bold text-gray-900 mb-6">{{page.title}}</h1>
              <div class="prose prose-lg max-w-3xl mx-auto">
                {{page.content}}
              </div>
            </div>
          </div>
        </div>
      HTML
    when 'contact_page'
      <<-HTML
        <div class="container mx-auto px-4 py-8">
          <div class="max-w-2xl mx-auto">
            <h1 class="text-4xl font-bold mb-8">{{page.title}}</h1>
            <div class="prose prose-lg max-w-none mb-8">
              {{page.content}}
            </div>
            <div class="bg-white rounded-lg shadow-md p-8">
              <!-- Contact form placeholder -->
              <form class="space-y-6">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">Name</label>
                  <input type="text" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">Email</label>
                  <input type="email" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">Message</label>
                  <textarea rows="4" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"></textarea>
                </div>
                <button type="submit" class="w-full bg-indigo-600 text-white py-2 px-4 rounded-md hover:bg-indigo-700">Send Message</button>
              </form>
            </div>
          </div>
        </div>
      HTML
    else
      <<-HTML
        <div class="container mx-auto px-4 py-8">
          <div class="max-w-4xl mx-auto">
            <article class="bg-white rounded-lg shadow-md p-8">
              <h1 class="text-4xl font-bold text-gray-900 mb-8">{{page.title}}</h1>
              <div class="prose prose-lg max-w-none">
                {{page.content}}
              </div>
            </article>
          </div>
        </div>
      HTML
    end
  end
  
  def default_css
    <<-CSS
      /* Page Template Styles */
      .page-template-#{template_type} {
        font-family: system-ui, -apple-system, sans-serif;
        line-height: 1.6;
        color: #333;
      }
      
      .page-template-#{template_type} h1,
      .page-template-#{template_type} h2,
      .page-template-#{template_type} h3 {
        color: #1f2937;
        font-weight: 700;
      }
      
      .page-template-#{template_type} .prose {
        color: #4b5563;
      }
      
      .page-template-#{template_type} .prose a {
        color: #3b82f6;
        text-decoration: none;
      }
      
      .page-template-#{template_type} .prose a:hover {
        text-decoration: underline;
      }
    CSS
  end
end





