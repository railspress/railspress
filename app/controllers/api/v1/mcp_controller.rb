# Server-Sent Events helper class
class SSE
  def initialize(stream, options = {})
    @stream = stream
    @retry_interval = options[:retry] || 300
    @event = options[:event]
  end

  def write(data, options = {})
    event = options[:event] || @event
    id = options[:id]
    retry_interval = options[:retry] || @retry_interval

    # Write event type
    @stream.write("event: #{event}\n") if event

    # Write event ID
    @stream.write("id: #{id}\n") if id

    # Write retry interval
    @stream.write("retry: #{retry_interval}\n") if retry_interval

    # Write data
    if data.is_a?(String)
      @stream.write("data: #{data}\n\n")
    else
      @stream.write("data: #{data.to_json}\n\n")
    end

    @stream.flush
  end

  def close
    @stream.close
  end
end

module Api
  module V1
    class McpController < BaseController
      before_action :authenticate_api_user!, only: [:tools_call]
      
      # POST /api/v1/mcp/session/handshake
      def handshake
        body = request.body.read
        if body.blank?
          return render_jsonrpc_error(-32700, 'Parse error', nil)
        end
        
        request_data = JSON.parse(body)
        
        # Validate JSON-RPC format
        unless request_data['jsonrpc'] == '2.0' && request_data['method'] == 'session/handshake'
          return render_jsonrpc_error(-32600, 'Invalid Request', request_data['id'])
        end
        
        # Validate protocol version
        protocol_version = request_data.dig('params', 'protocolVersion')
        unless protocol_version == '2025-03-26'
          return render_jsonrpc_error(-32602, 'Invalid protocol version', request_data['id'])
        end
        
        # Respond with server capabilities
        response_data = {
          jsonrpc: '2.0',
          result: {
            protocolVersion: '2025-03-26',
            capabilities: ['tools', 'resources', 'prompts'],
            serverInfo: {
              name: 'railspress-mcp-server',
              version: '1.0.0'
            }
          },
          id: request_data['id']
        }
        
        render json: response_data
      end
      
      # GET /api/v1/mcp/tools/list
      def tools_list
        tools = [
          {
            name: 'get_posts',
            description: 'Retrieve posts with optional filtering',
            inputSchema: {
              type: 'object',
              properties: {
                status: { type: 'string', enum: ['published', 'draft', 'pending_review', 'scheduled', 'trash'] },
                limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
                offset: { type: 'integer', minimum: 0, default: 0 },
                search: { type: 'string', description: 'Search in title and content' },
                category: { type: 'string', description: 'Filter by category slug' },
                tag: { type: 'string', description: 'Filter by tag slug' },
                author: { type: 'integer', description: 'Filter by author ID' },
                date_from: { type: 'string', format: 'date' },
                date_to: { type: 'string', format: 'date' }
              }
            },
            outputSchema: {
              type: 'object',
              properties: {
                posts: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      id: { type: 'integer' },
                      title: { type: 'string' },
                      slug: { type: 'string' },
                      content: { type: 'string' },
                      excerpt: { type: 'string' },
                      status: { type: 'string' },
                      published_at: { type: 'string', format: 'date-time' },
                      created_at: { type: 'string', format: 'date-time' },
                      updated_at: { type: 'string', format: 'date-time' },
                      author: { type: 'object' },
                      categories: { type: 'array' },
                      tags: { type: 'array' },
                      meta_fields: { type: 'object' }
                    }
                  }
                },
                total: { type: 'integer' },
                limit: { type: 'integer' },
                offset: { type: 'integer' }
              }
            }
          },
          {
            name: 'get_post',
            description: 'Retrieve a single post by ID or slug',
            inputSchema: {
              type: 'object',
              properties: {
                id: { type: 'integer', description: 'Post ID' },
                slug: { type: 'string', description: 'Post slug' }
              },
              anyOf: [
                { required: ['id'] },
                { required: ['slug'] }
              ]
            },
            outputSchema: {
              type: 'object',
              properties: {
                post: {
                  type: 'object',
                  properties: {
                    id: { type: 'integer' },
                    title: { type: 'string' },
                    slug: { type: 'string' },
                    content: { type: 'string' },
                    excerpt: { type: 'string' },
                    status: { type: 'string' },
                    published_at: { type: 'string', format: 'date-time' },
                    created_at: { type: 'string', format: 'date-time' },
                    updated_at: { type: 'string', format: 'date-time' },
                    author: { type: 'object' },
                    categories: { type: 'array' },
                    tags: { type: 'array' },
                    meta_fields: { type: 'object' },
                    comments: { type: 'array' }
                  }
                }
              }
            }
          },
          {
            name: 'create_post',
            description: 'Create a new post',
            inputSchema: {
              type: 'object',
              properties: {
                title: { type: 'string', minLength: 1 },
                content: { type: 'string' },
                excerpt: { type: 'string' },
                status: { type: 'string', enum: ['draft', 'published', 'pending_review', 'scheduled'], default: 'draft' },
                published_at: { type: 'string', format: 'date-time' },
                slug: { type: 'string' },
                meta_title: { type: 'string' },
                meta_description: { type: 'string' },
                category_ids: { type: 'array', items: { type: 'integer' } },
                tag_ids: { type: 'array', items: { type: 'integer' } },
                meta_fields: { type: 'object' }
              },
              required: ['title']
            },
            outputSchema: {
              type: 'object',
              properties: {
                post: {
                  type: 'object',
                  properties: {
                    id: { type: 'integer' },
                    title: { type: 'string' },
                    slug: { type: 'string' },
                    content: { type: 'string' },
                    excerpt: { type: 'string' },
                    status: { type: 'string' },
                    published_at: { type: 'string', format: 'date-time' },
                    created_at: { type: 'string', format: 'date-time' },
                    updated_at: { type: 'string', format: 'date-time' }
                  }
                }
              }
            }
          },
          {
            name: 'update_post',
            description: 'Update an existing post',
            inputSchema: {
              type: 'object',
              properties: {
                id: { type: 'integer' },
                title: { type: 'string' },
                content: { type: 'string' },
                excerpt: { type: 'string' },
                status: { type: 'string', enum: ['draft', 'published', 'pending_review', 'scheduled'] },
                published_at: { type: 'string', format: 'date-time' },
                slug: { type: 'string' },
                meta_title: { type: 'string' },
                meta_description: { type: 'string' },
                category_ids: { type: 'array', items: { type: 'integer' } },
                tag_ids: { type: 'array', items: { type: 'integer' } },
                meta_fields: { type: 'object' }
              },
              required: ['id']
            },
            outputSchema: {
              type: 'object',
              properties: {
                post: {
                  type: 'object',
                  properties: {
                    id: { type: 'integer' },
                    title: { type: 'string' },
                    slug: { type: 'string' },
                    content: { type: 'string' },
                    excerpt: { type: 'string' },
                    status: { type: 'string' },
                    published_at: { type: 'string', format: 'date-time' },
                    created_at: { type: 'string', format: 'date-time' },
                    updated_at: { type: 'string', format: 'date-time' }
                  }
                }
              }
            }
          },
          {
            name: 'delete_post',
            description: 'Delete a post (move to trash)',
            inputSchema: {
              type: 'object',
              properties: {
                id: { type: 'integer' }
              },
              required: ['id']
            },
            outputSchema: {
              type: 'object',
              properties: {
                success: { type: 'boolean' },
                message: { type: 'string' }
              }
            }
          },
          {
            name: 'get_pages',
            description: 'Retrieve pages with optional filtering',
            inputSchema: {
              type: 'object',
              properties: {
                status: { type: 'string', enum: ['published', 'draft', 'pending_review', 'scheduled', 'private_page', 'trash'] },
                limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
                offset: { type: 'integer', minimum: 0, default: 0 },
                search: { type: 'string', description: 'Search in title and content' },
                parent_id: { type: 'integer', description: 'Filter by parent page ID' },
                root_only: { type: 'boolean', description: 'Only root pages' },
                channel: { type: 'string', description: 'Filter by channel slug' }
              }
            },
            outputSchema: {
              type: 'object',
              properties: {
                pages: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      id: { type: 'integer' },
                      title: { type: 'string' },
                      slug: { type: 'string' },
                      content: { type: 'string' },
                      excerpt: { type: 'string' },
                      status: { type: 'string' },
                      published_at: { type: 'string', format: 'date-time' },
                      created_at: { type: 'string', format: 'date-time' },
                      updated_at: { type: 'string', format: 'date-time' },
                      author: { type: 'object' },
                      parent: { type: 'object' },
                      children: { type: 'array' },
                      meta_fields: { type: 'object' }
                    }
                  }
                },
                total: { type: 'integer' },
                limit: { type: 'integer' },
                offset: { type: 'integer' }
              }
            }
          },
          {
            name: 'get_page',
            description: 'Retrieve a single page by ID or slug',
            inputSchema: {
              type: 'object',
              properties: {
                id: { type: 'integer', description: 'Page ID' },
                slug: { type: 'string', description: 'Page slug' }
              },
              anyOf: [
                { required: ['id'] },
                { required: ['slug'] }
              ]
            },
            outputSchema: {
              type: 'object',
              properties: {
                page: {
                  type: 'object',
                  properties: {
                    id: { type: 'integer' },
                    title: { type: 'string' },
                    slug: { type: 'string' },
                    content: { type: 'string' },
                    excerpt: { type: 'string' },
                    status: { type: 'string' },
                    published_at: { type: 'string', format: 'date-time' },
                    created_at: { type: 'string', format: 'date-time' },
                    updated_at: { type: 'string', format: 'date-time' },
                    author: { type: 'object' },
                    parent: { type: 'object' },
                    children: { type: 'array' },
                    meta_fields: { type: 'object' },
                    comments: { type: 'array' }
                  }
                }
              }
            }
          },
          {
            name: 'create_page',
            description: 'Create a new page',
            inputSchema: {
              type: 'object',
              properties: {
                title: { type: 'string', minLength: 1 },
                content: { type: 'string' },
                excerpt: { type: 'string' },
                status: { type: 'string', enum: ['draft', 'published', 'pending_review', 'scheduled', 'private_page'], default: 'draft' },
                published_at: { type: 'string', format: 'date-time' },
                slug: { type: 'string' },
                parent_id: { type: 'integer' },
                meta_title: { type: 'string' },
                meta_description: { type: 'string' },
                meta_fields: { type: 'object' }
              },
              required: ['title']
            },
            outputSchema: {
              type: 'object',
              properties: {
                page: {
                  type: 'object',
                  properties: {
                    id: { type: 'integer' },
                    title: { type: 'string' },
                    slug: { type: 'string' },
                    content: { type: 'string' },
                    excerpt: { type: 'string' },
                    status: { type: 'string' },
                    published_at: { type: 'string', format: 'date-time' },
                    created_at: { type: 'string', format: 'date-time' },
                    updated_at: { type: 'string', format: 'date-time' }
                  }
                }
              }
            }
          },
          {
            name: 'update_page',
            description: 'Update an existing page',
            inputSchema: {
              type: 'object',
              properties: {
                id: { type: 'integer' },
                title: { type: 'string' },
                content: { type: 'string' },
                excerpt: { type: 'string' },
                status: { type: 'string', enum: ['draft', 'published', 'pending_review', 'scheduled', 'private_page'] },
                published_at: { type: 'string', format: 'date-time' },
                slug: { type: 'string' },
                parent_id: { type: 'integer' },
                meta_title: { type: 'string' },
                meta_description: { type: 'string' },
                meta_fields: { type: 'object' }
              },
              required: ['id']
            },
            outputSchema: {
              type: 'object',
              properties: {
                page: {
                  type: 'object',
                  properties: {
                    id: { type: 'integer' },
                    title: { type: 'string' },
                    slug: { type: 'string' },
                    content: { type: 'string' },
                    excerpt: { type: 'string' },
                    status: { type: 'string' },
                    published_at: { type: 'string', format: 'date-time' },
                    created_at: { type: 'string', format: 'date-time' },
                    updated_at: { type: 'string', format: 'date-time' }
                  }
                }
              }
            }
          },
          {
            name: 'delete_page',
            description: 'Delete a page (move to trash)',
            inputSchema: {
              type: 'object',
              properties: {
                id: { type: 'integer' }
              },
              required: ['id']
            },
            outputSchema: {
              type: 'object',
              properties: {
                success: { type: 'boolean' },
                message: { type: 'string' }
              }
            }
          },
          {
            name: 'get_taxonomies',
            description: 'Retrieve all taxonomies',
            inputSchema: {
              type: 'object',
              properties: {
                hierarchical: { type: 'boolean', description: 'Filter by hierarchical type' },
                object_types: { type: 'array', items: { type: 'string' }, description: 'Filter by object types' }
              }
            },
            outputSchema: {
              type: 'object',
              properties: {
                taxonomies: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      id: { type: 'integer' },
                      name: { type: 'string' },
                      slug: { type: 'string' },
                      description: { type: 'string' },
                      hierarchical: { type: 'boolean' },
                      object_types: { type: 'array' },
                      term_count: { type: 'integer' },
                      settings: { type: 'object' }
                    }
                  }
                }
              }
            }
          },
          {
            name: 'get_terms',
            description: 'Retrieve terms for a taxonomy',
            inputSchema: {
              type: 'object',
              properties: {
                taxonomy: { type: 'string', description: 'Taxonomy slug (e.g., category, post_tag)' },
                parent_id: { type: 'integer', description: 'Filter by parent term ID' },
                root_only: { type: 'boolean', description: 'Only root terms' },
                search: { type: 'string', description: 'Search in term names' },
                limit: { type: 'integer', minimum: 1, maximum: 100, default: 50 },
                offset: { type: 'integer', minimum: 0, default: 0 }
              },
              required: ['taxonomy']
            },
            outputSchema: {
              type: 'object',
              properties: {
                terms: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      id: { type: 'integer' },
                      name: { type: 'string' },
                      slug: { type: 'string' },
                      description: { type: 'string' },
                      count: { type: 'integer' },
                      parent_id: { type: 'integer' },
                      taxonomy: { type: 'object' },
                      children: { type: 'array' }
                    }
                  }
                },
                total: { type: 'integer' },
                limit: { type: 'integer' },
                offset: { type: 'integer' }
              }
            }
          },
          {
            name: 'create_term',
            description: 'Create a new term',
            inputSchema: {
              type: 'object',
              properties: {
                name: { type: 'string', minLength: 1 },
                taxonomy: { type: 'string', description: 'Taxonomy slug' },
                description: { type: 'string' },
                parent_id: { type: 'integer' },
                slug: { type: 'string' },
                metadata: { type: 'object' }
              },
              required: ['name', 'taxonomy']
            },
            outputSchema: {
              type: 'object',
              properties: {
                term: {
                  type: 'object',
                  properties: {
                    id: { type: 'integer' },
                    name: { type: 'string' },
                    slug: { type: 'string' },
                    description: { type: 'string' },
                    count: { type: 'integer' },
                    parent_id: { type: 'integer' },
                    taxonomy: { type: 'object' }
                  }
                }
              }
            }
          },
          {
            name: 'update_term',
            description: 'Update an existing term',
            inputSchema: {
              type: 'object',
              properties: {
                id: { type: 'integer' },
                name: { type: 'string' },
                description: { type: 'string' },
                parent_id: { type: 'integer' },
                slug: { type: 'string' },
                metadata: { type: 'object' }
              },
              required: ['id']
            },
            outputSchema: {
              type: 'object',
              properties: {
                term: {
                  type: 'object',
                  properties: {
                    id: { type: 'integer' },
                    name: { type: 'string' },
                    slug: { type: 'string' },
                    description: { type: 'string' },
                    count: { type: 'integer' },
                    parent_id: { type: 'integer' },
                    taxonomy: { type: 'object' }
                  }
                }
              }
            }
          },
          {
            name: 'delete_term',
            description: 'Delete a term',
            inputSchema: {
              type: 'object',
              properties: {
                id: { type: 'integer' }
              },
              required: ['id']
            },
            outputSchema: {
              type: 'object',
              properties: {
                success: { type: 'boolean' },
                message: { type: 'string' }
              }
            }
          },
          {
            name: 'get_content_types',
            description: 'Retrieve all content types',
            inputSchema: {
              type: 'object',
              properties: {}
            },
            outputSchema: {
              type: 'object',
              properties: {
                content_types: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      id: { type: 'integer' },
                      name: { type: 'string' },
                      slug: { type: 'string' },
                      description: { type: 'string' },
                      icon: { type: 'string' },
                      supports: { type: 'array' },
                      labels: { type: 'object' },
                      capabilities: { type: 'object' },
                      settings: { type: 'object' }
                    }
                  }
                }
              }
            }
          },
          {
            name: 'get_media',
            description: 'Retrieve media files',
            inputSchema: {
              type: 'object',
              properties: {
                limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
                offset: { type: 'integer', minimum: 0, default: 0 },
                search: { type: 'string', description: 'Search in filename and title' },
                mime_type: { type: 'string', description: 'Filter by MIME type' },
                uploaded_by: { type: 'integer', description: 'Filter by uploader ID' },
                date_from: { type: 'string', format: 'date' },
                date_to: { type: 'string', format: 'date' }
              }
            },
            outputSchema: {
              type: 'object',
              properties: {
                media: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      id: { type: 'integer' },
                      filename: { type: 'string' },
                      title: { type: 'string' },
                      alt_text: { type: 'string' },
                      caption: { type: 'string' },
                      description: { type: 'string' },
                      mime_type: { type: 'string' },
                      file_size: { type: 'integer' },
                      url: { type: 'string' },
                      thumbnail_url: { type: 'string' },
                      uploaded_at: { type: 'string', format: 'date-time' },
                      uploaded_by: { type: 'object' }
                    }
                  }
                },
                total: { type: 'integer' },
                limit: { type: 'integer' },
                offset: { type: 'integer' }
              }
            }
          },
          {
            name: 'upload_media',
            description: 'Upload a media file',
            inputSchema: {
              type: 'object',
              properties: {
                file: { type: 'string', description: 'Base64 encoded file data' },
                filename: { type: 'string' },
                title: { type: 'string' },
                alt_text: { type: 'string' },
                caption: { type: 'string' },
                description: { type: 'string' }
              },
              required: ['file', 'filename']
            },
            outputSchema: {
              type: 'object',
              properties: {
                media: {
                  type: 'object',
                  properties: {
                    id: { type: 'integer' },
                    filename: { type: 'string' },
                    title: { type: 'string' },
                    alt_text: { type: 'string' },
                    caption: { type: 'string' },
                    description: { type: 'string' },
                    mime_type: { type: 'string' },
                    file_size: { type: 'integer' },
                    url: { type: 'string' },
                    thumbnail_url: { type: 'string' },
                    uploaded_at: { type: 'string', format: 'date-time' }
                  }
                }
              }
            }
          },
          {
            name: 'get_users',
            description: 'Retrieve users',
            inputSchema: {
              type: 'object',
              properties: {
                limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
                offset: { type: 'integer', minimum: 0, default: 0 },
                search: { type: 'string', description: 'Search in name and email' },
                role: { type: 'string', description: 'Filter by role' },
                status: { type: 'string', enum: ['active', 'inactive'] }
              }
            },
            outputSchema: {
              type: 'object',
              properties: {
                users: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      id: { type: 'integer' },
                      name: { type: 'string' },
                      email: { type: 'string' },
                      role: { type: 'string' },
                      status: { type: 'string' },
                      created_at: { type: 'string', format: 'date-time' },
                      last_login_at: { type: 'string', format: 'date-time' }
                    }
                  }
                },
                total: { type: 'integer' },
                limit: { type: 'integer' },
                offset: { type: 'integer' }
              }
            }
          },
          {
            name: 'get_system_info',
            description: 'Get system information and statistics',
            inputSchema: {
              type: 'object',
              properties: {}
            },
            outputSchema: {
              type: 'object',
              properties: {
                system: {
                  type: 'object',
                  properties: {
                    name: { type: 'string' },
                    version: { type: 'string' },
                    rails_version: { type: 'string' },
                    ruby_version: { type: 'string' },
                    environment: { type: 'string' },
                    statistics: {
                      type: 'object',
                      properties: {
                        posts_count: { type: 'integer' },
                        pages_count: { type: 'integer' },
                        users_count: { type: 'integer' },
                        media_count: { type: 'integer' },
                        comments_count: { type: 'integer' }
                      }
                    }
                  }
                }
              }
            }
          }
        ]
        
        render_jsonrpc_success({ tools: tools })
      end
      
      # POST /api/v1/mcp/tools/call
      def tools_call
        body = request.body.read
        if body.blank?
          return render_jsonrpc_error(-32700, 'Parse error', nil)
        end
        
        request_data = JSON.parse(body)
        
        unless request_data['jsonrpc'] == '2.0' && request_data['method'] == 'tools/call'
          return render_jsonrpc_error(-32600, 'Invalid Request', request_data['id'])
        end
        
        tool_name = request_data.dig('params', 'name')
        arguments = request_data.dig('params', 'arguments') || {}
        
        result = execute_tool(tool_name, arguments)
        
        if result[:success]
          render_jsonrpc_success({
            content: [
              {
                type: 'output',
                data: result[:data]
              }
            ]
          }, request_data['id'])
        else
          render_jsonrpc_error(-32603, result[:error], request_data['id'])
        end
      rescue => e
        Rails.logger.error "MCP Tool Error: #{e.message}"
        render_jsonrpc_error(-32603, "Internal error: #{e.message}", request_data['id'])
      end
      
      # GET /api/v1/mcp/tools/stream
      def tools_stream
        response.headers['Content-Type'] = 'text/event-stream'
        response.headers['Cache-Control'] = 'no-cache'
        response.headers['Connection'] = 'keep-alive'
        
        tool_name = params[:tool]
        arguments = JSON.parse(params[:arguments] || '{}')
        
        sse = SSE.new(response.stream, retry: 300, event: "message")
        
        begin
          # Send initial progress
          sse.write({ progress: 0.1, message: "Starting #{tool_name}" }, event: 'tools/update')
          
          # Execute tool with streaming updates
          result = execute_tool_with_streaming(tool_name, arguments) do |progress, partial_data|
            sse.write({
              tool: tool_name,
              progress: progress,
              partial: partial_data
            }, event: 'tools/update')
          end
          
          # Send final result
          sse.write({
            tool: tool_name,
            content: [
              {
                type: 'output',
                data: result[:data]
              }
            ]
          }, event: 'tools/complete')
          
        rescue => e
          sse.write({
            tool: tool_name,
            error: e.message
          }, event: 'tools/error')
        ensure
          sse.close
        end
      end
      
      # GET /api/v1/mcp/resources/list
      def resources_list
        resources = [
          {
            uri: 'railspress://posts',
            name: 'Posts Collection',
            description: 'All posts in the system',
            mimeType: 'application/json'
          },
          {
            uri: 'railspress://pages',
            name: 'Pages Collection',
            description: 'All pages in the system',
            mimeType: 'application/json'
          },
          {
            uri: 'railspress://taxonomies',
            name: 'Taxonomies Collection',
            description: 'All taxonomies in the system',
            mimeType: 'application/json'
          },
          {
            uri: 'railspress://terms',
            name: 'Terms Collection',
            description: 'All terms in the system',
            mimeType: 'application/json'
          },
          {
            uri: 'railspress://media',
            name: 'Media Collection',
            description: 'All media files in the system',
            mimeType: 'application/json'
          },
          {
            uri: 'railspress://users',
            name: 'Users Collection',
            description: 'All users in the system',
            mimeType: 'application/json'
          },
          {
            uri: 'railspress://content-types',
            name: 'Content Types Collection',
            description: 'All content types in the system',
            mimeType: 'application/json'
          }
        ]
        
        render_jsonrpc_success({ resources: resources })
      end
      
      # GET /api/v1/mcp/prompts/list
      def prompts_list
        prompts = [
          {
            name: 'seo_optimize',
            description: 'Optimize content for SEO',
            arguments: [
              {
                name: 'content',
                description: 'The content to optimize',
                required: true
              },
              {
                name: 'target_keywords',
                description: 'Target keywords for SEO',
                required: false
              },
              {
                name: 'content_type',
                description: 'Type of content (post, page)',
                required: false
              }
            ]
          },
          {
            name: 'content_summarize',
            description: 'Summarize content',
            arguments: [
              {
                name: 'content',
                description: 'The content to summarize',
                required: true
              },
              {
                name: 'max_length',
                description: 'Maximum length of summary',
                required: false
              }
            ]
          },
          {
            name: 'content_generate',
            description: 'Generate content based on topic',
            arguments: [
              {
                name: 'topic',
                description: 'Topic to generate content about',
                required: true
              },
              {
                name: 'content_type',
                description: 'Type of content to generate',
                required: false
              },
              {
                name: 'tone',
                description: 'Tone of the content',
                required: false
              },
              {
                name: 'length',
                description: 'Desired length of content',
                required: false
              }
            ]
          },
          {
            name: 'meta_description_generate',
            description: 'Generate meta description for content',
            arguments: [
              {
                name: 'title',
                description: 'Content title',
                required: true
              },
              {
                name: 'content',
                description: 'Content body',
                required: true
              },
              {
                name: 'keywords',
                description: 'Target keywords',
                required: false
              }
            ]
          }
        ]
        
        render_jsonrpc_success({ prompts: prompts })
      end
      
      private
      
      def execute_tool(tool_name, arguments)
        case tool_name
        when 'get_posts'
          execute_get_posts(arguments)
        when 'get_post'
          execute_get_post(arguments)
        when 'create_post'
          execute_create_post(arguments)
        when 'update_post'
          execute_update_post(arguments)
        when 'delete_post'
          execute_delete_post(arguments)
        when 'get_pages'
          execute_get_pages(arguments)
        when 'get_page'
          execute_get_page(arguments)
        when 'create_page'
          execute_create_page(arguments)
        when 'update_page'
          execute_update_page(arguments)
        when 'delete_page'
          execute_delete_page(arguments)
        when 'get_taxonomies'
          execute_get_taxonomies(arguments)
        when 'get_terms'
          execute_get_terms(arguments)
        when 'create_term'
          execute_create_term(arguments)
        when 'update_term'
          execute_update_term(arguments)
        when 'delete_term'
          execute_delete_term(arguments)
        when 'get_content_types'
          execute_get_content_types(arguments)
        when 'get_media'
          execute_get_media(arguments)
        when 'upload_media'
          execute_upload_media(arguments)
        when 'get_users'
          execute_get_users(arguments)
        when 'get_system_info'
          execute_get_system_info(arguments)
        else
          { success: false, error: "Unknown tool: #{tool_name}" }
        end
      end
      
      def execute_tool_with_streaming(tool_name, arguments, &block)
        case tool_name
        when 'get_posts'
          execute_get_posts_streaming(arguments, &block)
        when 'get_media'
          execute_get_media_streaming(arguments, &block)
        else
          # For tools that don't support streaming, execute normally
          result = execute_tool(tool_name, arguments)
          yield(0.5, { message: "Processing #{tool_name}" })
          yield(1.0, result[:data])
          result
        end
      end
      
      # Tool implementations
      def execute_get_posts(arguments)
        posts = Post.all
        
        # Apply filters
        posts = posts.where(status: arguments['status']) if arguments['status'].present?
        posts = posts.search_full_text(arguments['search']) if arguments['search'].present?
        
        if arguments['category'].present?
          category_term = Term.for_taxonomy('category').find_by(slug: arguments['category'])
          posts = posts.joins(:term_relationships).where(term_relationships: { term_id: category_term.id }) if category_term
        end
        
        if arguments['tag'].present?
          tag_term = Term.for_taxonomy('post_tag').find_by(slug: arguments['tag'])
          posts = posts.joins(:term_relationships).where(term_relationships: { term_id: tag_term.id }) if tag_term
        end
        
        posts = posts.where(user_id: arguments['author']) if arguments['author'].present?
        
        if arguments['date_from'].present?
          posts = posts.where('published_at >= ?', Date.parse(arguments['date_from']))
        end
        
        if arguments['date_to'].present?
          posts = posts.where('published_at <= ?', Date.parse(arguments['date_to']))
        end
        
        # Pagination
        limit = arguments['limit'] || 20
        offset = arguments['offset'] || 0
        total = posts.count
        posts = posts.limit(limit).offset(offset).order(created_at: :desc)
        
        {
          success: true,
          data: {
            posts: posts.map { |post| serialize_post(post) },
            total: total,
            limit: limit,
            offset: offset
          }
        }
      end
      
      def execute_get_posts_streaming(arguments, &block)
        yield(0.1, { message: "Fetching posts..." })
        
        posts = Post.all
        yield(0.3, { message: "Applying filters..." })
        
        # Apply same filters as execute_get_posts
        posts = posts.where(status: arguments['status']) if arguments['status'].present?
        posts = posts.search_full_text(arguments['search']) if arguments['search'].present?
        
        yield(0.6, { message: "Counting total..." })
        total = posts.count
        
        yield(0.8, { message: "Serializing data..." })
        limit = arguments['limit'] || 20
        offset = arguments['offset'] || 0
        posts = posts.limit(limit).offset(offset).order(created_at: :desc)
        
        {
          success: true,
          data: {
            posts: posts.map { |post| serialize_post(post) },
            total: total,
            limit: limit,
            offset: offset
          }
        }
      end
      
      def execute_get_post(arguments)
        if arguments['id'].present?
          post = Post.find(arguments['id'])
        elsif arguments['slug'].present?
          post = Post.find_by(slug: arguments['slug'])
        else
          return { success: false, error: 'Either id or slug must be provided' }
        end
        
        unless post
          return { success: false, error: 'Post not found' }
        end
        
        {
          success: true,
          data: {
            post: serialize_post(post, detailed: true)
          }
        }
      end
      
      def execute_create_post(arguments)
        unless current_api_user&.can_create_posts?
          return { success: false, error: 'You do not have permission to create posts' }
        end
        
        post = current_api_user.posts.build(
          title: arguments['title'],
          content: arguments['content'],
          excerpt: arguments['excerpt'],
          status: arguments['status'] || 'draft',
          slug: arguments['slug'],
          meta_title: arguments['meta_title'],
          meta_description: arguments['meta_description']
        )
        
        if arguments['published_at'].present?
          post.published_at = Time.parse(arguments['published_at'])
        end
        
        if post.save
          # Handle categories and tags
          if arguments['category_ids'].present?
            post.category_ids = arguments['category_ids']
          end
          
          if arguments['tag_ids'].present?
            post.tag_ids = arguments['tag_ids']
          end
          
          # Handle meta fields
          if arguments['meta_fields'].present?
            arguments['meta_fields'].each do |key, value|
              post.set_meta(key, value)
            end
          end
          
          {
            success: true,
            data: {
              post: serialize_post(post)
            }
          }
        else
          {
            success: false,
            error: post.errors.full_messages.join(', ')
          }
        end
      end
      
      def execute_update_post(arguments)
        post = Post.find(arguments['id'])
        
        unless current_api_user&.can_edit_others_posts? || (current_api_user&.id == post.user_id)
          return { success: false, error: 'You do not have permission to edit this post' }
        end
        
        update_params = arguments.except('id', 'category_ids', 'tag_ids', 'meta_fields')
        
        if arguments['published_at'].present?
          update_params['published_at'] = Time.parse(arguments['published_at'])
        end
        
        if post.update(update_params)
          # Handle categories and tags
          if arguments['category_ids'].present?
            post.category_ids = arguments['category_ids']
          end
          
          if arguments['tag_ids'].present?
            post.tag_ids = arguments['tag_ids']
          end
          
          # Handle meta fields
          if arguments['meta_fields'].present?
            arguments['meta_fields'].each do |key, value|
              post.set_meta(key, value)
            end
          end
          
          {
            success: true,
            data: {
              post: serialize_post(post)
            }
          }
        else
          {
            success: false,
            error: post.errors.full_messages.join(', ')
          }
        end
      end
      
      def execute_delete_post(arguments)
        post = Post.find(arguments['id'])
        
        unless current_api_user&.can_delete_posts? || (current_api_user&.id == post.user_id)
          return { success: false, error: 'You do not have permission to delete this post' }
        end
        
        post.discard
        
        {
          success: true,
          data: {
            success: true,
            message: 'Post moved to trash'
          }
        }
      end
      
      def execute_get_pages(arguments)
        pages = Page.all
        
        # Apply filters
        pages = pages.where(status: arguments['status']) if arguments['status'].present?
        pages = pages.where(parent_id: arguments['parent_id']) if arguments['parent_id'].present?
        pages = pages.root_pages if arguments['root_only'] == true
        pages = pages.search_full_text(arguments['search']) if arguments['search'].present?
        
        if arguments['channel'].present?
          channel = Channel.find_by(slug: arguments['channel'])
          if channel
            pages = pages.left_joins(:channels)
                         .where('channels.id = ? OR channels.id IS NULL', channel.id)
          end
        end
        
        # Pagination
        limit = arguments['limit'] || 20
        offset = arguments['offset'] || 0
        total = pages.count
        pages = pages.limit(limit).offset(offset).order(order: :asc, created_at: :desc)
        
        {
          success: true,
          data: {
            pages: pages.map { |page| serialize_page(page) },
            total: total,
            limit: limit,
            offset: offset
          }
        }
      end
      
      def execute_get_page(arguments)
        if arguments['id'].present?
          page = Page.find(arguments['id'])
        elsif arguments['slug'].present?
          page = Page.find_by(slug: arguments['slug'])
        else
          return { success: false, error: 'Either id or slug must be provided' }
        end
        
        unless page
          return { success: false, error: 'Page not found' }
        end
        
        {
          success: true,
          data: {
            page: serialize_page(page, detailed: true)
          }
        }
      end
      
      def execute_create_page(arguments)
        unless current_api_user&.can_create_pages?
          return { success: false, error: 'You do not have permission to create pages' }
        end
        
        page = current_api_user.pages.build(
          title: arguments['title'],
          content: arguments['content'],
          excerpt: arguments['excerpt'],
          status: arguments['status'] || 'draft',
          slug: arguments['slug'],
          parent_id: arguments['parent_id'],
          meta_title: arguments['meta_title'],
          meta_description: arguments['meta_description']
        )
        
        if arguments['published_at'].present?
          page.published_at = Time.parse(arguments['published_at'])
        end
        
        if page.save
          # Handle meta fields
          if arguments['meta_fields'].present?
            arguments['meta_fields'].each do |key, value|
              page.set_meta(key, value)
            end
          end
          
          {
            success: true,
            data: {
              page: serialize_page(page)
            }
          }
        else
          {
            success: false,
            error: page.errors.full_messages.join(', ')
          }
        end
      end
      
      def execute_update_page(arguments)
        page = Page.find(arguments['id'])
        
        unless current_api_user&.can_edit_others_posts? || (current_api_user&.id == page.user_id)
          return { success: false, error: 'You do not have permission to edit this page' }
        end
        
        update_params = arguments.except('id', 'meta_fields')
        
        if arguments['published_at'].present?
          update_params['published_at'] = Time.parse(arguments['published_at'])
        end
        
        if page.update(update_params)
          # Handle meta fields
          if arguments['meta_fields'].present?
            arguments['meta_fields'].each do |key, value|
              page.set_meta(key, value)
            end
          end
          
          {
            success: true,
            data: {
              page: serialize_page(page)
            }
          }
        else
          {
            success: false,
            error: page.errors.full_messages.join(', ')
          }
        end
      end
      
      def execute_delete_page(arguments)
        page = Page.find(arguments['id'])
        
        unless current_api_user&.can_delete_posts? || (current_api_user&.id == page.user_id)
          return { success: false, error: 'You do not have permission to delete this page' }
        end
        
        page.discard
        
        {
          success: true,
          data: {
            success: true,
            message: 'Page moved to trash'
          }
        }
      end
      
      def execute_get_taxonomies(arguments)
        taxonomies = Taxonomy.all
        
        taxonomies = taxonomies.where(hierarchical: arguments['hierarchical']) if arguments['hierarchical'].present?
        
        if arguments['object_types'].present?
          object_types_filter = arguments['object_types'].map { |type| "%#{type}%" }
          taxonomies = taxonomies.where(object_types.map { |type| "object_types LIKE ?" }.join(' OR '), *object_types_filter)
        end
        
        {
          success: true,
          data: {
            taxonomies: taxonomies.map { |taxonomy| serialize_taxonomy(taxonomy) }
          }
        }
      end
      
      def execute_get_terms(arguments)
        taxonomy = Taxonomy.find_by(slug: arguments['taxonomy'])
        unless taxonomy
          return { success: false, error: 'Taxonomy not found' }
        end
        
        terms = taxonomy.terms
        
        # Apply filters
        terms = terms.where(parent_id: arguments['parent_id']) if arguments['parent_id'].present?
        terms = terms.root_terms if arguments['root_only'] == true
        terms = terms.where('name LIKE ?', "%#{arguments['search']}%") if arguments['search'].present?
        
        # Pagination
        limit = arguments['limit'] || 50
        offset = arguments['offset'] || 0
        total = terms.count
        terms = terms.limit(limit).offset(offset).ordered
        
        {
          success: true,
          data: {
            terms: terms.map { |term| serialize_term(term) },
            total: total,
            limit: limit,
            offset: offset
          }
        }
      end
      
      def execute_create_term(arguments)
        unless current_api_user&.can_edit_others_posts?
          return { success: false, error: 'You do not have permission to create terms' }
        end
        
        taxonomy = Taxonomy.find_by(slug: arguments['taxonomy'])
        unless taxonomy
          return { success: false, error: 'Taxonomy not found' }
        end
        
        term = taxonomy.terms.build(
          name: arguments['name'],
          description: arguments['description'],
          parent_id: arguments['parent_id'],
          slug: arguments['slug'],
          metadata: arguments['metadata'] || {}
        )
        
        if term.save
          {
            success: true,
            data: {
              term: serialize_term(term)
            }
          }
        else
          {
            success: false,
            error: term.errors.full_messages.join(', ')
          }
        end
      end
      
      def execute_update_term(arguments)
        unless current_api_user&.can_edit_others_posts?
          return { success: false, error: 'You do not have permission to edit terms' }
        end
        
        term = Term.find(arguments['id'])
        
        update_params = arguments.except('id')
        
        if term.update(update_params)
          {
            success: true,
            data: {
              term: serialize_term(term)
            }
          }
        else
          {
            success: false,
            error: term.errors.full_messages.join(', ')
          }
        end
      end
      
      def execute_delete_term(arguments)
        unless current_api_user&.administrator?
          return { success: false, error: 'You do not have permission to delete terms' }
        end
        
        term = Term.find(arguments['id'])
        term.destroy
        
        {
          success: true,
          data: {
            success: true,
            message: 'Term deleted'
          }
        }
      end
      
      def execute_get_content_types(arguments)
        content_types = ContentType.all
        
        {
          success: true,
          data: {
            content_types: content_types.map { |ct| serialize_content_type(ct) }
          }
        }
      end
      
      def execute_get_media(arguments)
        media = Medium.all
        
        # Apply filters
        media = media.where('filename LIKE ? OR title LIKE ?', "%#{arguments['search']}%", "%#{arguments['search']}%") if arguments['search'].present?
        media = media.where(mime_type: arguments['mime_type']) if arguments['mime_type'].present?
        media = media.where(uploaded_by_id: arguments['uploaded_by']) if arguments['uploaded_by'].present?
        
        if arguments['date_from'].present?
          media = media.where('created_at >= ?', Date.parse(arguments['date_from']))
        end
        
        if arguments['date_to'].present?
          media = media.where('created_at <= ?', Date.parse(arguments['date_to']))
        end
        
        # Pagination
        limit = arguments['limit'] || 20
        offset = arguments['offset'] || 0
        total = media.count
        media = media.limit(limit).offset(offset).order(created_at: :desc)
        
        {
          success: true,
          data: {
            media: media.map { |m| serialize_media(m) },
            total: total,
            limit: limit,
            offset: offset
          }
        }
      end
      
      def execute_get_media_streaming(arguments, &block)
        yield(0.1, { message: "Fetching media..." })
        
        media = Medium.all
        yield(0.3, { message: "Applying filters..." })
        
        # Apply same filters as execute_get_media
        media = media.where('filename LIKE ? OR title LIKE ?', "%#{arguments['search']}%", "%#{arguments['search']}%") if arguments['search'].present?
        media = media.where(mime_type: arguments['mime_type']) if arguments['mime_type'].present?
        media = media.where(uploaded_by_id: arguments['uploaded_by']) if arguments['uploaded_by'].present?
        
        yield(0.6, { message: "Counting total..." })
        total = media.count
        
        yield(0.8, { message: "Serializing data..." })
        limit = arguments['limit'] || 20
        offset = arguments['offset'] || 0
        media = media.limit(limit).offset(offset).order(created_at: :desc)
        
        {
          success: true,
          data: {
            media: media.map { |m| serialize_media(m) },
            total: total,
            limit: limit,
            offset: offset
          }
        }
      end
      
      def execute_upload_media(arguments)
        unless current_api_user&.can_upload_files?
          return { success: false, error: 'You do not have permission to upload media' }
        end
        
        # Decode base64 file
        file_data = Base64.decode64(arguments['file'])
        filename = arguments['filename']
        
        # Create temporary file
        temp_file = Tempfile.new([filename, File.extname(filename)])
        temp_file.binmode
        temp_file.write(file_data)
        temp_file.rewind
        
        # Create media record
        media = Medium.new(
          filename: filename,
          title: arguments['title'] || filename,
          alt_text: arguments['alt_text'],
          caption: arguments['caption'],
          description: arguments['description'],
          uploaded_by: current_api_user
        )
        
        # Attach file
        media.file.attach(
          io: temp_file,
          filename: filename,
          content_type: MIME::Types.type_for(filename).first&.content_type || 'application/octet-stream'
        )
        
        if media.save
          temp_file.close
          temp_file.unlink
          
          {
            success: true,
            data: {
              media: serialize_media(media)
            }
          }
        else
          temp_file.close
          temp_file.unlink
          
          {
            success: false,
            error: media.errors.full_messages.join(', ')
          }
        end
      end
      
      def execute_get_users(arguments)
        users = User.all
        
        # Apply filters
        users = users.where('name LIKE ? OR email LIKE ?', "%#{arguments['search']}%", "%#{arguments['search']}%") if arguments['search'].present?
        users = users.where(role: arguments['role']) if arguments['role'].present?
        users = users.where(active: arguments['status'] == 'active') if arguments['status'].present?
        
        # Pagination
        limit = arguments['limit'] || 20
        offset = arguments['offset'] || 0
        total = users.count
        users = users.limit(limit).offset(offset).order(created_at: :desc)
        
        {
          success: true,
          data: {
            users: users.map { |user| serialize_user(user) },
            total: total,
            limit: limit,
            offset: offset
          }
        }
      end
      
      def execute_get_system_info(arguments)
        {
          success: true,
          data: {
            system: {
              name: 'RailsPress API',
              version: 'v1',
              rails_version: Rails.version,
              ruby_version: RUBY_VERSION,
              environment: Rails.env,
              statistics: {
                posts_count: Post.count,
                pages_count: Page.count,
                users_count: User.count,
                media_count: Medium.count,
                comments_count: Comment.count
              }
            }
          }
        }
      end
      
      # Serialization methods
      def serialize_post(post, detailed: false)
        data = {
          id: post.id,
          title: post.title,
          slug: post.slug,
          content: post.content.to_s,
          excerpt: post.excerpt,
          status: post.status,
          published_at: post.published_at&.iso8601,
          created_at: post.created_at.iso8601,
          updated_at: post.updated_at.iso8601,
          author: {
            id: post.user.id,
            name: post.user.name,
            email: post.user.email
          },
          categories: post.categories.map { |cat| { id: cat.id, name: cat.name, slug: cat.slug } },
          tags: post.tags.map { |tag| { id: tag.id, name: tag.name, slug: tag.slug } },
          meta_fields: post.meta_fields.map { |mf| { key: mf.key, value: mf.value } }.index_by { |mf| mf[:key] }
        }
        
        if detailed
          data[:comments] = post.comments.map { |comment| serialize_comment(comment) }
        end
        
        data
      end
      
      def serialize_page(page, detailed: false)
        data = {
          id: page.id,
          title: page.title,
          slug: page.slug,
          content: page.content.to_s,
          excerpt: page.excerpt,
          status: page.status,
          published_at: page.published_at&.iso8601,
          created_at: page.created_at.iso8601,
          updated_at: page.updated_at.iso8601,
          author: {
            id: page.user.id,
            name: page.user.name,
            email: page.user.email
          },
          parent: page.parent ? { id: page.parent.id, title: page.parent.title, slug: page.parent.slug } : nil,
          children: page.children.map { |child| { id: child.id, title: child.title, slug: child.slug } },
          meta_fields: page.meta_fields.map { |mf| { key: mf.key, value: mf.value } }.index_by { |mf| mf[:key] }
        }
        
        if detailed
          data[:comments] = page.comments.map { |comment| serialize_comment(comment) }
        end
        
        data
      end
      
      def serialize_taxonomy(taxonomy)
        {
          id: taxonomy.id,
          name: taxonomy.name,
          slug: taxonomy.slug,
          description: taxonomy.description,
          hierarchical: taxonomy.hierarchical,
          object_types: taxonomy.object_types,
          term_count: taxonomy.term_count,
          settings: taxonomy.settings
        }
      end
      
      def serialize_term(term)
        {
          id: term.id,
          name: term.name,
          slug: term.slug,
          description: term.description,
          count: term.count,
          parent_id: term.parent_id,
          taxonomy: {
            id: term.taxonomy.id,
            name: term.taxonomy.name,
            slug: term.taxonomy.slug
          },
          children: term.children.map { |child| { id: child.id, name: child.name, slug: child.slug } }
        }
      end
      
      def serialize_content_type(content_type)
        {
          id: content_type.id,
          name: content_type.name,
          slug: content_type.slug,
          description: content_type.description,
          icon: content_type.icon,
          supports: content_type.supports,
          labels: content_type.labels,
          capabilities: content_type.capabilities,
          settings: content_type.settings
        }
      end
      
      def serialize_media(media)
        {
          id: media.id,
          filename: media.filename,
          title: media.title,
          alt_text: media.alt_text,
          caption: media.caption,
          description: media.description,
          mime_type: media.mime_type,
          file_size: media.file_size,
          url: media.file.url,
          thumbnail_url: media.file.attached? ? media.file.variant(resize_to_limit: [300, 300]).processed.url : nil,
          uploaded_at: media.created_at.iso8601,
          uploaded_by: {
            id: media.uploaded_by.id,
            name: media.uploaded_by.name,
            email: media.uploaded_by.email
          }
        }
      end
      
      def serialize_user(user)
        {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          status: user.active? ? 'active' : 'inactive',
          created_at: user.created_at.iso8601,
          last_login_at: user.last_sign_in_at&.iso8601
        }
      end
      
      def serialize_comment(comment)
        {
          id: comment.id,
          content: comment.content,
          author_name: comment.author_name,
          author_email: comment.author_email,
          author_url: comment.author_url,
          status: comment.status,
          created_at: comment.created_at.iso8601,
          updated_at: comment.updated_at.iso8601
        }
      end
      
      def render_jsonrpc_success(data, id = nil)
        response_data = {
          jsonrpc: '2.0',
          result: data,
          id: id
        }
        render json: response_data
      end
      
      def render_jsonrpc_error(code, message, id = nil)
        response_data = {
          jsonrpc: '2.0',
          error: {
            code: code,
            message: message
          },
          id: id
        }
        render json: response_data, status: :bad_request
      end

      def authenticate_api_user!
        # Check for API key authentication
        api_key = request.headers['Authorization']&.gsub(/^Bearer /, '') || params[:api_key]
        
        if api_key.blank?
          render json: {
            success: false,
            error: 'API key required',
            code: 'MISSING_API_KEY'
          }, status: :unauthorized
          return
        end
        
        @api_user = User.find_by(api_key: api_key)
        
        unless @api_user
          render json: {
            success: false,
            error: 'Invalid API key',
            code: 'INVALID_API_KEY'
          }, status: :unauthorized
          return
        end
        
        # Check if user is active
        unless @api_user.active?
          render json: {
            success: false,
            error: 'User account is inactive',
            code: 'INACTIVE_USER'
          }, status: :forbidden
          return
        end
      end
    end
  end
end