# RailsPress Default Seeds
# This creates the minimal default content similar to WordPress fresh installation

puts "🌱 Seeding RailsPress..."
puts ""

# ============================================
# 1. USERS
# ============================================
puts "👤 Creating default user..."

admin = User.find_or_create_by!(email: 'admin@example.com') do |user|
  user.password = 'password'
  user.password_confirmation = 'password'
  user.role = 'administrator'
  user.name = 'admin'
end

puts "  ✅ Admin user created (email: admin@example.com, password: password)"
puts ""

# ============================================
# 2. TAXONOMIES
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
end

# Create default "Uncategorized" term
uncategorized = Term.find_or_create_by!(
  taxonomy: category_taxonomy,
  slug: 'uncategorized'
) do |term|
  term.name = 'Uncategorized'
  term.description = 'Posts without a specific category'
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
end

puts "  ✅ Post Format taxonomy (flat) - Available but empty"
puts ""

# ============================================
# 3. POSTS
# ============================================
puts "📝 Creating default post..."

hello_post = Post.find_or_create_by!(slug: 'hello-world') do |post|
  post.title = 'Hello world!'
  post.content = 'Welcome to RailsPress. This is your first post. Edit or delete it, then start writing!'
  post.excerpt = 'Welcome to RailsPress. This is your first post.'
  post.status = 'published'
  post.user = admin
  post.published_at = Time.current
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
  c.user = admin
end

puts "  ✅ Default comment created"
puts ""

# ============================================
# 4. PAGES
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
end

puts "  ✅ 'Sample Page' created"
puts ""

# ============================================
# 5. NAVIGATION MENUS
# ============================================
puts "🧭 Creating default navigation..."

primary_menu = Menu.find_or_create_by!(location: 'primary') do |menu|
  menu.name = 'Primary Menu'
end

# Clear existing items
primary_menu.menu_items.destroy_all

# Add default menu items
primary_menu.menu_items.create!([
  { label: 'Home', url: '/', position: 1 },
  { label: 'Sample Page', url: '/page/sample-page', position: 2 }
])

puts "  ✅ Primary navigation menu created (Home, Sample Page)"
puts ""

# ============================================
# 6. SITE SETTINGS
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
  end
end

puts "  ✅ Site settings configured"
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