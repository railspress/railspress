# RailsPress Default Seeds
# This creates the minimal default content similar to WordPress fresh installation

puts "🌱 Seeding RailsPress..."
puts ""

# ============================================
# 1. TENANT
# ============================================
puts "🏢 Creating default tenant..."

default_tenant = Tenant.find_or_create_by!(name: 'RailsPress Default') do |tenant|
  tenant.domain = 'localhost'
  tenant.subdomain = nil
  tenant.theme = 'nordic'
  tenant.locales = 'en'
  tenant.active = true
  tenant.storage_type = 'local'
  tenant.settings = {
    'site_title' => 'RailsPress',
    'site_tagline' => 'A modern Rails CMS',
    'posts_per_page' => 10,
    'default_post_status' => 'draft',
    'comments_enabled' => true
  }
end

puts "  ✅ Default tenant created: #{default_tenant.name}"
puts ""

# ============================================
# 2. USERS
# ============================================
puts "👤 Creating default user..."

admin = User.find_or_create_by!(email: 'admin@example.com') do |user|
  user.password = 'password'
  user.password_confirmation = 'password'
  user.role = 'administrator'
  user.name = 'admin'
  user.tenant = default_tenant
end

# Update existing admin user to have tenant if it doesn't
admin.update!(tenant: default_tenant) if admin.tenant.nil?

puts "  ✅ Admin user created (email: admin@example.com, password: password)"
puts ""

# ============================================
# 3. TAXONOMIES
# ============================================
puts "🗂️  Creating default taxonomies..."

# Category taxonomy (hierarchical)
category_taxonomy = Taxonomy.find_or_create_by!(slug: 'category') do |t|
  t.name = 'Category'
  t.singular_name = 'Category'
  t.plural_name = 'Categories'
  t.description = 'Organize posts into categories'
  t.hierarchical = true
  t.object_types = ['Post']
  t.settings = {
    'show_in_menu' => true,
    'show_in_api' => true,
    'show_ui' => true,
    'public' => true
  }
  t.tenant = default_tenant
end

# Create default "Uncategorized" term
uncategorized = Term.find_or_create_by!(
  taxonomy: category_taxonomy,
  slug: 'uncategorized'
) do |term|
  term.name = 'Uncategorized'
  term.description = 'Posts without a specific category'
  term.tenant = default_tenant
end

puts "  ✅ Category taxonomy (hierarchical) - Default: Uncategorized"

# Post Tag taxonomy (flat)
tag_taxonomy = Taxonomy.find_or_create_by!(slug: 'tag') do |t|
  t.name = 'Tag'
  t.singular_name = 'Tag'
  t.plural_name = 'Tags'
  t.description = 'Tag your posts with keywords'
  t.hierarchical = false
  t.object_types = ['Post']
  t.settings = {
    'show_in_menu' => true,
    'show_in_api' => true,
    'show_ui' => true,
    'public' => true
  }
  t.tenant = default_tenant
end

puts "  ✅ Tag taxonomy (flat) - Empty until used"

# Post Format taxonomy (flat, available but empty)
format_taxonomy = Taxonomy.find_or_create_by!(slug: 'post_format') do |t|
  t.name = 'Post Format'
  t.singular_name = 'Format'
  t.plural_name = 'Formats'
  t.description = 'Post format types (video, audio, gallery, etc.)'
  t.hierarchical = false
  t.object_types = ['Post']
  t.settings = {
    'show_in_menu' => false,
    'show_in_api' => true,
    'show_ui' => true,
    'public' => false
  }
  t.tenant = default_tenant
end

puts "  ✅ Post Format taxonomy (flat) - Available but empty"
puts ""

# ============================================
# 4. POSTS
# ============================================
puts "📝 Creating default post..."

hello_post = Post.find_or_create_by!(slug: 'hello-world') do |post|
  post.title = 'Hello world!'
  post.content = 'Welcome to RailsPress. This is your first post. Edit or delete it, then start writing!'
  post.excerpt = 'Welcome to RailsPress. This is your first post.'
  post.status = 'published'
  post.user = admin
  post.published_at = Time.current
  post.tenant = default_tenant
end

# Assign to Uncategorized category
unless hello_post.term_relationships.where(term: uncategorized).exists?
  hello_post.term_relationships.create!(term: uncategorized)
end

puts "  ✅ 'Hello world!' post created"

# Create default comment
comment = Comment.find_or_create_by!(
  commentable: hello_post,
  author_name: 'A WordPress Commenter',
  author_email: 'wapuu@wordpress.example'
) do |c|
  c.content = 'Hi, this is a comment. To get started with moderating, editing, and deleting comments, please visit the Comments screen in the dashboard. Commenter avatars come from Gravatar.'
  c.status = 'approved'
  c.comment_type = 'comment'
  c.comment_approved = '1'
  c.author_ip = '127.0.0.1'
  c.author_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
  c.user = admin
  c.tenant = default_tenant
end

puts "  ✅ Default comment created"
puts ""

# ============================================
# 5. PAGES
# ============================================
puts "📄 Creating default page..."

sample_page = Page.find_or_create_by!(slug: 'sample-page') do |page|
  page.title = 'Sample Page'
  page.content = <<~CONTENT
    This is an example page. It's different from a blog post because it will stay in one place and will show up in your site navigation (in most themes). Most people start with an About page that introduces them to potential site visitors. It might say something like this:

    Hi there! I'm a bike messenger by day, aspiring actor by night, and this is my website. I live in Los Angeles, have a great dog named Jack, and I like piña coladas. (And gettin' caught in the rain.)

    ...or something like this:

    The XYZ Doohickey Company was founded in 1971, and has been providing quality doohickeys to the public ever since. Located in Gotham City, XYZ employs over 2,000 people and does all kinds of awesome things for the Gotham community.

    As a new RailsPress user, you should go to your dashboard to delete this page and create new pages for your content. Have fun!
  CONTENT
  page.status = 'published'
  page.user = admin
  page.published_at = Time.current
  page.tenant = default_tenant
end

puts "  ✅ 'Sample Page' created"
puts ""

# ============================================
# 5. NAVIGATION MENUS
# ============================================
puts "🧭 Creating default navigation..."

primary_menu = Menu.find_or_create_by!(location: 'primary') do |menu|
  menu.name = 'Primary Menu'
  menu.tenant = default_tenant
end

# Clear existing items
primary_menu.menu_items.destroy_all

# Add default menu items
primary_menu.menu_items.create!([
  { label: 'Home', url: '/', position: 1, tenant: default_tenant },
  { label: 'Sample Page', url: '/page/sample-page', position: 2, tenant: default_tenant }
])

puts "  ✅ Primary navigation menu created (Home, Sample Page)"
puts ""

# ============================================
# 7. SITE SETTINGS
# ============================================
puts "⚙️  Configuring site settings..."

default_settings = {
  'site_title' => 'Nordic Minimal',
  'site_description' => 'Just another RailsPress site',
  'posts_per_page' => '10',
  'active_theme' => 'nordic',
  'headless_mode' => false,
  'cors_enabled' => false,
  'cors_origins' => '*',
  'command_palette_shortcut' => 'cmd+k'
}

default_settings.each do |key, value|
  SiteSetting.find_or_create_by!(key: key) do |setting|
    setting.value = value.to_s
    setting.setting_type = value.is_a?(TrueClass) || value.is_a?(FalseClass) ? 'boolean' : 'string'
    setting.tenant = default_tenant
  end
end

puts "  ✅ Site settings configured"
puts ""

# ============================================
# 8. AI PROVIDERS
# ============================================
load Rails.root.join('db', 'seeds', 'ai_providers.rb')

# ============================================
# 9. STORAGE PROVIDERS
# ============================================
load Rails.root.join('db', 'seeds', 'storage_providers.rb')

# ============================================
# 10. UPLOAD SECURITY
# ============================================
load Rails.root.join('db', 'seeds', 'upload_security.rb')

# ============================================
# 11. TRASH SETTINGS
# ============================================
load Rails.root.join('db', 'seeds', 'trash_settings.rb')

# ============================================
# 12. AI AGENTS
# ============================================
puts "🤖 Creating default AI agents..."

# Get the first AI provider (should be created in ai_providers seeds)
default_provider = AiProvider.first

if default_provider
  default_agents = [
    {
      name: "Content Summarizer",
      description: "Summarizes long content into concise, readable summaries",
      agent_type: "content_summarizer",
      prompt: "You are a content summarizer. Your task is to create clear, concise summaries of the provided content while maintaining the key points and context. Focus on the main ideas and important details.",
      content: "Create summaries that are:\n- 20-30% of original length\n- Easy to read and understand\n- Include all key points\n- Maintain original tone when appropriate",
      guidelines: "Always maintain factual accuracy and preserve the original meaning.",
      rules: "Never add information not present in the source material.",
      tasks: "Summarize the provided content effectively.",
      master_prompt: "You are an expert content summarizer with years of experience in creating clear, concise summaries.",
      active: true,
      position: 1
    },
    {
      name: "Post Writer",
      description: "Helps create engaging blog posts and articles",
      agent_type: "post_writer",
      prompt: "You are a professional blog post writer. Your task is to create engaging, well-structured blog posts based on the provided topic or outline. Write in a conversational yet professional tone.",
      content: "Create blog posts that are:\n- Well-structured with clear headings\n- Engaging and easy to read\n- SEO-friendly\n- Include relevant examples\n- Have a strong conclusion",
      guidelines: "Write in a conversational tone that connects with readers. Use active voice and short paragraphs.",
      rules: "Always fact-check information and cite sources when possible.",
      tasks: "Write compelling blog posts that inform and engage readers.",
      master_prompt: "You are an expert content writer with extensive experience in creating viral blog posts and articles.",
      active: true,
      position: 2
    },
    {
      name: "Comments Analyzer",
      description: "Analyzes comment sentiment and provides insights",
      agent_type: "comments_analyzer",
      prompt: "You are a comments analyzer. Your task is to analyze the sentiment and content of comments to provide insights about audience engagement and feedback.",
      content: "Analyze comments for:\n- Overall sentiment (positive, negative, neutral)\n- Key themes and topics\n- Engagement patterns\n- Suggestions for improvement",
      guidelines: "Be objective and provide constructive insights based on the data.",
      rules: "Respect privacy and avoid sharing personal information from comments.",
      tasks: "Provide actionable insights based on comment analysis.",
      master_prompt: "You are an expert in social media and community management with deep understanding of audience engagement.",
      active: true,
      position: 3
    },
    {
      name: "SEO Analyzer",
      description: "Analyzes content for SEO optimization opportunities",
      agent_type: "seo_analyzer",
      prompt: "You are an SEO specialist. Your task is to analyze content and provide specific recommendations for improving search engine optimization.",
      content: "Analyze and provide recommendations for:\n- Keyword optimization\n- Meta descriptions\n- Heading structure\n- Content length and quality\n- Internal linking opportunities",
      guidelines: "Focus on white-hat SEO techniques that provide long-term value.",
      rules: "Never recommend keyword stuffing or other black-hat techniques.",
      tasks: "Provide actionable SEO recommendations that improve search rankings.",
      master_prompt: "You are a certified SEO expert with proven track record of improving search rankings for various websites.",
      active: true,
      position: 4
    }
  ]

  default_agents.each do |agent_attrs|
    agent = AiAgent.find_or_create_by!(name: agent_attrs[:name]) do |a|
      a.description = agent_attrs[:description]
      a.agent_type = agent_attrs[:agent_type]
      a.prompt = agent_attrs[:prompt]
      a.content = agent_attrs[:content]
      a.guidelines = agent_attrs[:guidelines]
      a.rules = agent_attrs[:rules]
      a.tasks = agent_attrs[:tasks]
      a.master_prompt = agent_attrs[:master_prompt]
      a.active = agent_attrs[:active]
      a.position = agent_attrs[:position]
      a.ai_provider = default_provider
    end
    
    puts "  ✅ AI Agent created: #{agent.name}"
  end
else
  puts "  ⚠️  No AI provider found. Please run AI providers seeds first."
end

puts ""

# ============================================
# SUMMARY
# ============================================
puts "═══════════════════════════════════════"
puts "✅ RailsPress seeded successfully!"
puts "═══════════════════════════════════════"
puts ""
puts "📊 Summary:"
puts "  • Users: 1 (admin)"
puts "  • Posts: 1 (Hello world!)"
puts "  • Pages: 1 (Sample Page)"
puts "  • Comments: 1"
puts "  • Taxonomies: 3 (category, tag, post_format)"
puts "  • Terms: 1 (Uncategorized)"
puts "  • Menus: 1 (Primary with 2 items)"
puts "  • AI Providers: 5 (OpenAI, Anthropic, Google, Cohere)"
puts ""
puts "🔐 Login Credentials:"
puts "  Email: admin@example.com"
puts "  Password: password"
puts ""
puts "🌐 Visit your site:"
puts "  Frontend: http://localhost:3000"
puts "  Admin: http://localhost:3000/admin"
puts ""
puts "🎉 Happy blogging with RailsPress!"
puts ""