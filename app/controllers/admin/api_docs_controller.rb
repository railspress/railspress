class Admin::ApiDocsController < Admin::BaseController
  def index
    # Main API documentation landing page
  end

  def rest
    # REST API documentation
    load_rest_endpoints
  end

  def graphql
    # GraphQL playground (moved from /graphiql)
    if Rails.env.production?
      redirect_to admin_api_docs_path, alert: "GraphQL playground is only available in development mode."
    else
      render layout: false
    end
  end

  def graphql_schema
    # GraphQL schema documentation
    @schema = RailspressSchema
    @types = @schema.types.values.reject { |type| type.graphql_name.start_with?('__') }
    @queries = @schema.query.fields.values
    @mutations = @schema.mutation&.fields&.values || []
  end
  
  def plugins
    # Plugin development documentation
    @plugin_docs = load_plugin_docs
  end
  
  def themes
    # Theme development documentation
    @theme_docs = load_theme_docs
  end

  private

  def load_rest_endpoints
    @endpoints = {
      authentication: {
        title: "Authentication",
        description: "Endpoints for user authentication and token management",
        endpoints: [
          {
            method: "POST",
            path: "/api/v1/auth/login",
            description: "Login and receive an API token",
            params: {
              email: "string (required)",
              password: "string (required)"
            },
            response: {
              token: "string",
              user: "object"
            }
          },
          {
            method: "POST",
            path: "/api/v1/auth/register",
            description: "Register a new user account",
            params: {
              email: "string (required)",
              password: "string (required)",
              password_confirmation: "string (required)",
              name: "string (optional)"
            },
            response: {
              token: "string",
              user: "object"
            }
          },
          {
            method: "POST",
            path: "/api/v1/auth/validate",
            description: "Validate an API token",
            headers: {
              Authorization: "Bearer YOUR_TOKEN"
            },
            response: {
              valid: "boolean",
              user: "object"
            }
          }
        ]
      },
      posts: {
        title: "Posts",
        description: "Create, read, update, and delete blog posts",
        endpoints: [
          {
            method: "GET",
            path: "/api/v1/posts",
            description: "List all posts with pagination",
            params: {
              page: "integer (default: 1)",
              per_page: "integer (default: 20)",
              status: "string (published, draft, private_post)",
              search: "string (search query)"
            },
            response: {
              posts: "array",
              meta: {
                total: "integer",
                page: "integer",
                per_page: "integer",
                total_pages: "integer"
              }
            }
          },
          {
            method: "GET",
            path: "/api/v1/posts/:id",
            description: "Get a specific post by ID",
            response: {
              id: "integer",
              title: "string",
              content: "string",
              excerpt: "string",
              slug: "string",
              status: "string",
              published_at: "datetime",
              categories: "array",
              tags: "array",
              user: "object"
            }
          },
          {
            method: "POST",
            path: "/api/v1/posts",
            description: "Create a new post",
            requires_auth: true,
            params: {
              title: "string (required)",
              content: "string (required)",
              excerpt: "string (optional)",
              slug: "string (optional)",
              status: "string (default: draft)",
              category_ids: "array of integers",
              tag_ids: "array of integers"
            },
            response: {
              post: "object",
              message: "string"
            }
          },
          {
            method: "PUT",
            path: "/api/v1/posts/:id",
            description: "Update an existing post",
            requires_auth: true,
            params: {
              title: "string",
              content: "string",
              excerpt: "string",
              status: "string",
              category_ids: "array of integers",
              tag_ids: "array of integers"
            }
          },
          {
            method: "DELETE",
            path: "/api/v1/posts/:id",
            description: "Delete a post",
            requires_auth: true,
            response: {
              message: "string"
            }
          }
        ]
      },
      pages: {
        title: "Pages",
        description: "Manage static pages",
        endpoints: [
          {
            method: "GET",
            path: "/api/v1/pages",
            description: "List all pages"
          },
          {
            method: "GET",
            path: "/api/v1/pages/:id",
            description: "Get a specific page"
          },
          {
            method: "POST",
            path: "/api/v1/pages",
            description: "Create a new page",
            requires_auth: true
          },
          {
            method: "PUT",
            path: "/api/v1/pages/:id",
            description: "Update a page",
            requires_auth: true
          },
          {
            method: "DELETE",
            path: "/api/v1/pages/:id",
            description: "Delete a page",
            requires_auth: true
          }
        ]
      },
      taxonomies: {
        title: "Taxonomies & Terms",
        description: "Manage taxonomies (categories, tags, custom) and their terms",
        endpoints: [
          {
            method: "GET",
            path: "/api/v1/taxonomies",
            description: "List all taxonomies",
            response: {
              taxonomies: "array of taxonomy objects"
            }
          },
          {
            method: "GET",
            path: "/api/v1/taxonomies/:id",
            description: "Get a specific taxonomy with its terms"
          },
          {
            method: "GET",
            path: "/api/v1/taxonomies/:id/terms",
            description: "Get all terms for a taxonomy"
          },
          {
            method: "GET",
            path: "/api/v1/terms",
            description: "List all terms across taxonomies"
          },
          {
            method: "GET",
            path: "/api/v1/terms/:id",
            description: "Get a specific term"
          }
        ]
      },
      comments: {
        title: "Comments",
        description: "Manage post and page comments",
        endpoints: [
          {
            method: "GET",
            path: "/api/v1/posts/:post_id/comments",
            description: "Get comments for a specific post"
          },
          {
            method: "POST",
            path: "/api/v1/posts/:post_id/comments",
            description: "Create a new comment on a post",
            params: {
              content: "string (required)",
              author_name: "string (required)",
              author_email: "string (required)",
              author_url: "string (optional)",
              parent_id: "integer (optional, for replies)"
            }
          },
          {
            method: "PATCH",
            path: "/api/v1/comments/:id/approve",
            description: "Approve a comment",
            requires_auth: true
          },
          {
            method: "PATCH",
            path: "/api/v1/comments/:id/spam",
            description: "Mark a comment as spam",
            requires_auth: true
          }
        ]
      },
      media: {
        title: "Media",
        description: "Upload and manage media files",
        endpoints: [
          {
            method: "GET",
            path: "/api/v1/media",
            description: "List all media files"
          },
          {
            method: "POST",
            path: "/api/v1/media",
            description: "Upload a new media file",
            requires_auth: true,
            params: {
              file: "multipart/form-data (required)"
            }
          },
          {
            method: "DELETE",
            path: "/api/v1/media/:id",
            description: "Delete a media file",
            requires_auth: true
          }
        ]
      },
      users: {
        title: "Users",
        description: "User management endpoints",
        endpoints: [
          {
            method: "GET",
            path: "/api/v1/users",
            description: "List all users",
            requires_auth: true
          },
          {
            method: "GET",
            path: "/api/v1/users/me",
            description: "Get current authenticated user",
            requires_auth: true
          },
          {
            method: "PATCH",
            path: "/api/v1/users/update_profile",
            description: "Update current user profile",
            requires_auth: true
          }
        ]
      },
      ai_agents: {
        title: "AI Agents",
        description: "Execute AI agents for content generation and analysis",
        endpoints: [
          {
            method: "GET",
            path: "/api/v1/ai_agents",
            description: "List all available AI agents"
          },
          {
            method: "POST",
            path: "/api/v1/ai_agents/execute/:agent_type",
            description: "Execute an AI agent by type",
            requires_auth: true,
            params: {
              agent_type: "string (content_summarizer, post_writer, comments_analyzer, seo_analyzer)",
              input: "string (required - the content to process)"
            },
            response: {
              result: "string (AI-generated content)",
              agent: "object",
              success: "boolean"
            }
          }
        ]
      },
      settings: {
        title: "Settings",
        description: "Site settings and configuration",
        endpoints: [
          {
            method: "GET",
            path: "/api/v1/settings",
            description: "List all settings",
            requires_auth: true
          },
          {
            method: "GET",
            path: "/api/v1/settings/get/:key",
            description: "Get a specific setting value"
          }
        ]
      },
      system: {
        title: "System",
        description: "System information and statistics",
        endpoints: [
          {
            method: "GET",
            path: "/api/v1/system/info",
            description: "Get system information"
          },
          {
            method: "GET",
            path: "/api/v1/system/stats",
            description: "Get site statistics",
            response: {
              posts_count: "integer",
              pages_count: "integer",
              users_count: "integer",
              comments_count: "integer"
            }
          }
        ]
      }
    }
  end
  
  def load_plugin_docs
    docs_path = Rails.root.join('docs', 'plugins')
    docs = []
    
    if Dir.exist?(docs_path)
      Dir.glob(File.join(docs_path, '*.md')).each do |file|
        filename = File.basename(file, '.md')
        content = File.read(file)
        
        # Extract title from markdown (first # heading)
        title = content.match(/^#\s+(.+)$/m)&.[](1) || filename.titleize
        
        docs << {
          title: title,
          filename: filename,
          path: file,
          content: content,
          url: "/docs/plugins/#{filename}.md"
        }
      end
    end
    
    # Add core plugin documentation files
    [
      { title: "Plugin Quick Start", path: Rails.root.join('docs', 'PLUGIN_QUICK_START.md') },
      { title: "Plugin MVC Architecture", path: Rails.root.join('docs', 'PLUGIN_MVC_ARCHITECTURE.md') },
      { title: "Plugin Developer Guide", path: Rails.root.join('docs', 'PLUGIN_DEVELOPER_GUIDE.md') }
    ].each do |doc|
      if File.exist?(doc[:path])
        content = File.read(doc[:path])
        docs.unshift({
          title: doc[:title],
          filename: File.basename(doc[:path], '.md'),
          path: doc[:path],
          content: content,
          url: "/docs/#{File.basename(doc[:path])}"
        })
      end
    end
    
    docs.sort_by { |d| d[:title] }
  end
  
  def load_theme_docs
    docs_path = Rails.root.join('docs', 'themes')
    docs = []
    
    if Dir.exist?(docs_path)
      Dir.glob(File.join(docs_path, '*.md')).each do |file|
        filename = File.basename(file, '.md')
        content = File.read(file)
        
        # Extract title from markdown
        title = content.match(/^#\s+(.+)$/m)&.[](1) || filename.titleize
        
        docs << {
          title: title,
          filename: filename,
          path: file,
          content: content,
          url: "/docs/themes/#{filename}.md"
        }
      end
    end
    
    docs.sort_by { |d| d[:title] }
  end
end


