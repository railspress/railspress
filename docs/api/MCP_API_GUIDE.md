# MCP (Model Context Protocol) API Documentation

## Overview

The RailsPress MCP API provides OpenAI 3.1 compatible endpoints for managing content through the Model Context Protocol. This allows AI assistants and other tools to interact with RailsPress content management features.

## Base URL

All MCP endpoints are available under `/api/v1/mcp/`

## Authentication

Most MCP endpoints require API authentication using Bearer tokens. Some endpoints (handshake, tools list, resources list, prompts list) are available without authentication.

```bash
Authorization: Bearer your_api_token_here
```

## Endpoints

### 1. Session Handshake

**POST** `/api/v1/mcp/session/handshake`

Establishes a connection and negotiates capabilities.

#### Request
```json
{
  "jsonrpc": "2.0",
  "method": "session/handshake",
  "params": {
    "protocolVersion": "2025-03-26",
    "clientInfo": {
      "name": "gpt-5",
      "version": "5.0.0"
    }
  },
  "id": 1
}
```

#### Response
```json
{
  "jsonrpc": "2.0",
  "result": {
    "protocolVersion": "2025-03-26",
    "capabilities": ["tools", "resources", "prompts"],
    "serverInfo": {
      "name": "railspress-mcp-server",
      "version": "1.0.0"
    }
  },
  "id": 1
}
```

### 2. List Available Tools

**GET** `/api/v1/mcp/tools/list`

Returns all available tools with their schemas.

#### Response
```json
{
  "jsonrpc": "2.0",
  "result": {
    "tools": [
      {
        "name": "get_posts",
        "description": "Retrieve posts with optional filtering",
        "inputSchema": {
          "type": "object",
          "properties": {
            "status": { "type": "string", "enum": ["published", "draft", "pending_review", "scheduled", "trash"] },
            "limit": { "type": "integer", "minimum": 1, "maximum": 100, "default": 20 },
            "offset": { "type": "integer", "minimum": 0, "default": 0 },
            "search": { "type": "string", "description": "Search in title and content" },
            "category": { "type": "string", "description": "Filter by category slug" },
            "tag": { "type": "string", "description": "Filter by tag slug" },
            "author": { "type": "integer", "description": "Filter by author ID" },
            "date_from": { "type": "string", "format": "date" },
            "date_to": { "type": "string", "format": "date" }
          }
        },
        "outputSchema": {
          "type": "object",
          "properties": {
            "posts": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "id": { "type": "integer" },
                  "title": { "type": "string" },
                  "slug": { "type": "string" },
                  "content": { "type": "string" },
                  "excerpt": { "type": "string" },
                  "status": { "type": "string" },
                  "published_at": { "type": "string", "format": "date-time" },
                  "created_at": { "type": "string", "format": "date-time" },
                  "updated_at": { "type": "string", "format": "date-time" },
                  "author": { "type": "object" },
                  "categories": { "type": "array" },
                  "tags": { "type": "array" },
                  "meta_fields": { "type": "object" }
                }
              }
            },
            "total": { "type": "integer" },
            "limit": { "type": "integer" },
            "offset": { "type": "integer" }
          }
        }
      }
    ]
  },
  "id": null
}
```

### 3. Call Tool

**POST** `/api/v1/mcp/tools/call`

Executes a specific tool with provided arguments.

#### Request
```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get_posts",
    "arguments": {
      "status": "published",
      "limit": 10,
      "search": "technology"
    }
  },
  "id": 2
}
```

#### Response
```json
{
  "jsonrpc": "2.0",
  "result": {
    "content": [
      {
        "type": "output",
        "data": {
          "posts": [
            {
              "id": 1,
              "title": "Technology Trends 2024",
              "slug": "technology-trends-2024",
              "content": "Content here...",
              "excerpt": "Excerpt here...",
              "status": "published",
              "published_at": "2024-01-15T10:00:00Z",
              "created_at": "2024-01-15T09:00:00Z",
              "updated_at": "2024-01-15T10:00:00Z",
              "author": {
                "id": 1,
                "name": "John Doe",
                "email": "john@example.com"
              },
              "categories": [
                {
                  "id": 1,
                  "name": "Technology",
                  "slug": "technology"
                }
              ],
              "tags": [
                {
                  "id": 1,
                  "name": "AI",
                  "slug": "ai"
                }
              ],
              "meta_fields": {
                "featured_image": "image.jpg",
                "seo_title": "Custom SEO Title"
              }
            }
          ],
          "total": 1,
          "limit": 10,
          "offset": 0
        }
      }
    ]
  },
  "id": 2
}
```

### 4. Stream Tool Execution

**GET** `/api/v1/mcp/tools/stream`

Streams tool execution progress via Server-Sent Events.

#### Parameters
- `tool`: Tool name to execute
- `arguments`: JSON string of tool arguments

#### Example
```bash
GET /api/v1/mcp/tools/stream?tool=get_posts&arguments={"limit":5}
```

#### Response (SSE)
```
event: tools/update
data: {"tool": "get_posts", "progress": 0.1, "partial": {"message": "Fetching posts..."}}

event: tools/update
data: {"tool": "get_posts", "progress": 0.5, "partial": {"message": "Processing data..."}}

event: tools/complete
data: {"tool": "get_posts", "content": [{"type": "output", "data": {...}}]}
```

### 5. List Resources

**GET** `/api/v1/mcp/resources/list`

Returns available resource collections.

#### Response
```json
{
  "jsonrpc": "2.0",
  "result": {
    "resources": [
      {
        "uri": "railspress://posts",
        "name": "Posts Collection",
        "description": "All posts in the system",
        "mimeType": "application/json"
      },
      {
        "uri": "railspress://pages",
        "name": "Pages Collection",
        "description": "All pages in the system",
        "mimeType": "application/json"
      },
      {
        "uri": "railspress://taxonomies",
        "name": "Taxonomies Collection",
        "description": "All taxonomies in the system",
        "mimeType": "application/json"
      },
      {
        "uri": "railspress://terms",
        "name": "Terms Collection",
        "description": "All terms in the system",
        "mimeType": "application/json"
      },
      {
        "uri": "railspress://media",
        "name": "Media Collection",
        "description": "All media files in the system",
        "mimeType": "application/json"
      },
      {
        "uri": "railspress://users",
        "name": "Users Collection",
        "description": "All users in the system",
        "mimeType": "application/json"
      },
      {
        "uri": "railspress://content-types",
        "name": "Content Types Collection",
        "description": "All content types in the system",
        "mimeType": "application/json"
      }
    ]
  },
  "id": null
}
```

### 6. List Prompts

**GET** `/api/v1/mcp/prompts/list`

Returns available prompt templates.

#### Response
```json
{
  "jsonrpc": "2.0",
  "result": {
    "prompts": [
      {
        "name": "seo_optimize",
        "description": "Optimize content for SEO",
        "arguments": [
          {
            "name": "content",
            "description": "The content to optimize",
            "required": true
          },
          {
            "name": "target_keywords",
            "description": "Target keywords for SEO",
            "required": false
          },
          {
            "name": "content_type",
            "description": "Type of content (post, page)",
            "required": false
          }
        ]
      },
      {
        "name": "content_summarize",
        "description": "Summarize content",
        "arguments": [
          {
            "name": "content",
            "description": "The content to summarize",
            "required": true
          },
          {
            "name": "max_length",
            "description": "Maximum length of summary",
            "required": false
          }
        ]
      },
      {
        "name": "content_generate",
        "description": "Generate content based on topic",
        "arguments": [
          {
            "name": "topic",
            "description": "Topic to generate content about",
            "required": true
          },
          {
            "name": "content_type",
            "description": "Type of content to generate",
            "required": false
          },
          {
            "name": "tone",
            "description": "Tone of the content",
            "required": false
          },
          {
            "name": "length",
            "description": "Desired length of content",
            "required": false
          }
        ]
      },
      {
        "name": "meta_description_generate",
        "description": "Generate meta description for content",
        "arguments": [
          {
            "name": "title",
            "description": "Content title",
            "required": true
          },
          {
            "name": "content",
            "description": "Content body",
            "required": true
          },
          {
            "name": "keywords",
            "description": "Target keywords",
            "required": false
          }
        ]
      }
    ]
  },
  "id": null
}
```

## Available Tools

### Content Management Tools

#### Posts
- `get_posts` - Retrieve posts with filtering
- `get_post` - Get single post by ID or slug
- `create_post` - Create new post
- `update_post` - Update existing post
- `delete_post` - Delete post (move to trash)

#### Pages
- `get_pages` - Retrieve pages with filtering
- `get_page` - Get single page by ID or slug
- `create_page` - Create new page
- `update_page` - Update existing page
- `delete_page` - Delete page (move to trash)

#### Taxonomies
- `get_taxonomies` - Get all taxonomies
- `get_terms` - Get terms for a taxonomy
- `create_term` - Create new term
- `update_term` - Update existing term
- `delete_term` - Delete term

#### Media
- `get_media` - Retrieve media files
- `upload_media` - Upload new media file

#### System
- `get_users` - Get users
- `get_content_types` - Get content types
- `get_system_info` - Get system information

## Error Handling

The API uses JSON-RPC 2.0 error format:

```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32603,
    "message": "Internal error: Detailed error message"
  },
  "id": 1
}
```

### Error Codes
- `-32600`: Invalid Request
- `-32601`: Method not found
- `-32602`: Invalid params
- `-32603`: Internal error
- `-32000` to `-32099`: Server error

## Rate Limiting

The MCP API follows the same rate limiting as the main API:
- 1000 requests per hour per API token
- Rate limit headers included in responses

## Testing

Use the provided test script to verify MCP functionality:

```bash
ruby test_mcp_api.rb [base_url]
```

Example:
```bash
ruby test_mcp_api.rb http://localhost:3000
```

## Examples

### Complete Workflow Example

```bash
# 1. Handshake
curl -X POST http://localhost:3000/api/v1/mcp/session/handshake \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "session/handshake",
    "params": {
      "protocolVersion": "2025-03-26",
      "clientInfo": {"name": "test-client", "version": "1.0.0"}
    },
    "id": 1
  }'

# 2. List tools
curl http://localhost:3000/api/v1/mcp/tools/list

# 3. Create a post (requires auth)
curl -X POST http://localhost:3000/api/v1/mcp/tools/call \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your_api_token" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "create_post",
      "arguments": {
        "title": "My New Post",
        "content": "This is the content",
        "status": "draft"
      }
    },
    "id": 2
  }'

# 4. Get posts
curl -X POST http://localhost:3000/api/v1/mcp/tools/call \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your_api_token" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "get_posts",
      "arguments": {"limit": 5}
    },
    "id": 3
  }'
```

## Integration with AI Assistants

The MCP API is designed to work seamlessly with AI assistants that support the Model Context Protocol. The tools provide comprehensive content management capabilities while maintaining proper authentication and permission controls.

Key features for AI integration:
- Structured input/output schemas
- Streaming support for long operations
- Comprehensive error handling
- Permission-based access control
- Rich content metadata


