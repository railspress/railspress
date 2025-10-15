# Create default content types
puts "Creating default content types..."

# Default "post" type
post_type = ContentType.find_or_create_by!(ident: 'post') do |ct|
  ct.label = 'Post'
  ct.singular = 'Post'
  ct.plural = 'Posts'
  ct.description = 'Standard blog posts'
  ct.icon = 'document-text'
  ct.public = true
  ct.hierarchical = false
  ct.has_archive = true
  ct.menu_position = 5
  ct.supports = ['title', 'editor', 'excerpt', 'thumbnail', 'author', 'comments', 'revisions', 'custom-fields']
  ct.capabilities = {}
  ct.rest_base = 'posts'
  ct.active = true
end

puts "✓ Created '#{post_type.label}' content type"

# Page type
page_type = ContentType.find_or_create_by!(ident: 'page') do |ct|
  ct.label = 'Page'
  ct.singular = 'Page'
  ct.plural = 'Pages'
  ct.description = 'Static pages'
  ct.icon = 'document'
  ct.public = true
  ct.hierarchical = true
  ct.has_archive = false
  ct.menu_position = 10
  ct.supports = ['title', 'editor', 'excerpt', 'thumbnail', 'author', 'page-attributes', 'custom-fields']
  ct.capabilities = {}
  ct.rest_base = 'pages'
  ct.active = true
end

puts "✓ Created '#{page_type.label}' content type"

# Example: Newsletter type
newsletter_type = ContentType.find_or_create_by!(ident: 'newsletter') do |ct|
  ct.label = 'Newsletter'
  ct.singular = 'Newsletter'
  ct.plural = 'Newsletters'
  ct.description = 'Email newsletters and campaigns'
  ct.icon = 'mail'
  ct.public = false
  ct.hierarchical = false
  ct.has_archive = true
  ct.menu_position = 20
  ct.supports = ['title', 'editor', 'excerpt', 'custom-fields']
  ct.capabilities = {}
  ct.rest_base = 'newsletters'
  ct.active = true
end

puts "✓ Created '#{newsletter_type.label}' content type"

# Example: Case Studies type
case_study_type = ContentType.find_or_create_by!(ident: 'case-studies') do |ct|
  ct.label = 'Case Study'
  ct.singular = 'Case Study'
  ct.plural = 'Case Studies'
  ct.description = 'Customer success stories and case studies'
  ct.icon = 'briefcase'
  ct.public = true
  ct.hierarchical = false
  ct.has_archive = true
  ct.menu_position = 25
  ct.supports = ['title', 'editor', 'excerpt', 'thumbnail', 'author', 'custom-fields']
  ct.capabilities = {}
  ct.rest_base = 'case-studies'
  ct.active = true
end

puts "✓ Created '#{case_study_type.label}' content type"

puts "Content types setup complete!"





