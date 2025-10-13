if Rails.env.development?
  GraphiQL::Rails.config.tap do |config|
    config.title = "RailsPress GraphQL Playground"
    config.logo = "RailsPress"
    
    # Headers to include in requests
    config.headers['X-CSRF-Token'] = -> (_context) { 
      form_authenticity_token 
    }
    
    # Initial query to show
    config.initial_query = <<-GRAPHQL
# Welcome to RailsPress GraphQL API!
# 
# Try these example queries:

# 1. List published posts
query {
  publishedPosts(limit: 5) {
    id
    title
    slug
    excerpt
    publishedAt
    author {
      email
    }
    categories {
      name
      slug
    }
  }
}

# 2. Get a specific post with relationships
# query {
#   post(slug: "your-post-slug") {
#     id
#     title
#     contentHtml
#     author { email }
#     categories { name }
#     tags { name }
#     comments { content authorName }
#   }
# }

# 3. Search across content
# {
#   search(query: "rails") {
#     total
#     posts { title url }
#     pages { title url }
#   }
# }

# 4. Get taxonomies and terms
# {
#   taxonomies {
#     name
#     slug
#     terms { name slug count }
#   }
# }

# Press Ctrl+Space for auto-complete!
    GRAPHQL
  end
end




