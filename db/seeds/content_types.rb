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