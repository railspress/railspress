class Admin::ShortcodesController < Admin::BaseController
  
  # GET /admin/shortcodes
  def index
    @shortcodes = build_shortcode_list
  end

  # POST /admin/shortcodes/test
  def test
    content = params[:content]
    result = Railspress::ShortcodeProcessor.process(content)
    
    render json: { 
      success: true, 
      original: content,
      processed: result 
    }
  end

  private

  def build_shortcode_list
    [
      {
        name: 'gallery',
        description: 'Display a gallery of images',
        usage: '[gallery ids="1,2,3" columns="3" size="medium"]',
        attributes: [
          { name: 'ids', description: 'Comma-separated media IDs', required: true },
          { name: 'columns', description: 'Number of columns (1-6)', default: '3' },
          { name: 'size', description: 'Image size (thumbnail, medium, large)', default: 'medium' }
        ],
        category: 'Media'
      },
      {
        name: 'button',
        description: 'Create a styled button/link',
        usage: '[button url="/contact" style="primary" size="medium"]Click Me[/button]',
        attributes: [
          { name: 'url', description: 'Button URL', required: true },
          { name: 'style', description: 'Button style (primary, secondary, success, danger)', default: 'primary' },
          { name: 'size', description: 'Button size (small, medium, large)', default: 'medium' },
          { name: 'target', description: 'Link target (_self, _blank)', default: '_self' }
        ],
        category: 'Content'
      },
      {
        name: 'youtube',
        description: 'Embed a YouTube video',
        usage: '[youtube id="VIDEO_ID" width="560" height="315"]',
        attributes: [
          { name: 'id', description: 'YouTube video ID', required: true },
          { name: 'width', description: 'Video width', default: '560' },
          { name: 'height', description: 'Video height', default: '315' }
        ],
        category: 'Media'
      },
      {
        name: 'recent_posts',
        description: 'Display recent posts',
        usage: '[recent_posts count="5" category="technology"]',
        attributes: [
          { name: 'count', description: 'Number of posts to show', default: '5' },
          { name: 'category', description: 'Filter by category slug', required: false }
        ],
        category: 'Content'
      },
      {
        name: 'contact_form',
        description: 'Display a contact form',
        usage: '[contact_form id="contact" email="admin@example.com"]',
        attributes: [
          { name: 'id', description: 'Form ID', default: 'contact' },
          { name: 'email', description: 'Recipient email', required: false }
        ],
        category: 'Forms'
      },
      {
        name: 'columns',
        description: 'Create column layout',
        usage: '[columns count="2"]Content here[/columns]',
        attributes: [
          { name: 'count', description: 'Number of columns (2-4)', default: '2' }
        ],
        category: 'Layout'
      },
      {
        name: 'alert',
        description: 'Display an alert/notice box',
        usage: '[alert type="info"]Your message here[/alert]',
        attributes: [
          { name: 'type', description: 'Alert type (info, success, warning, danger)', default: 'info' }
        ],
        category: 'Content'
      },
      {
        name: 'code',
        description: 'Display code block with syntax highlighting',
        usage: '[code lang="ruby"]puts "Hello World"[/code]',
        attributes: [
          { name: 'lang', description: 'Programming language', default: 'plaintext' }
        ],
        category: 'Content'
      }
    ]
  end
end






