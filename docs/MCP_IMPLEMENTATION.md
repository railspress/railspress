# Model Context Protocol (MCP) Implementation

## Overview

The Model Context Protocol (MCP) implementation provides a comprehensive API for AI models to interact with RailsPress content management system. This implementation follows the OpenAI 3.1 specification and JSON-RPC 2.0 protocol standards.

## Table of Contents

1. [Architecture](#architecture)
2. [API Endpoints](#api-endpoints)
3. [Authentication](#authentication)
4. [Tools Reference](#tools-reference)
5. [Resources Reference](#resources-reference)
6. [Prompts Reference](#prompts-reference)
7. [Admin Settings](#admin-settings)
8. [Configuration](#configuration)
9. [Testing](#testing)
10. [Deployment](#deployment)
11. [Troubleshooting](#troubleshooting)

## Architecture

### Core Components

- **MCP Controller** (`app/controllers/api/v1/mcp_controller.rb`) - Main API endpoint handler
- **MCP Settings Controller** (`app/controllers/admin/mcp_settings_controller.rb`) - Admin configuration
- **MCP Settings View** (`app/views/admin/mcp_settings/show.html.erb`) - Admin interface
- **Routes** (`config/routes.rb`) - API and admin routing
- **Site Settings** - Configuration storage using existing SiteSetting model

### Protocol Support

- **JSON-RPC 2.0** - Request/response protocol
- **Server-Sent Events (SSE)** - Real-time streaming support
- **OpenAI 3.1 Compatibility** - Standard tool and resource schemas
- **RESTful Design** - Clean, predictable API structure

## API Endpoints

### Base URL
```
https://your-domain.com/api/v1/mcp
```

### Endpoints

#### 1. Handshake
**POST** `/session/handshake`

Establishes MCP session and negotiates protocol version.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "session/handshake",
  "params": {
    "protocolVersion": "2025-03-26",
    "clientInfo": {
      "name": "client-name",
      "version": "1.0.0"
    }
  },
  "id": 1
}
```

**Response:**
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

#### 2. Tools List
**GET** `/tools/list`

Returns available tools and their schemas.

**Response:**
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
            "status": {
              "type": "string",
              "enum": ["published", "draft", "pending_review", "scheduled", "trash"]
            },
            "limit": {
              "type": "integer",
              "minimum": 1,
              "maximum": 100,
              "default": 20
            },
            "offset": {
              "type": "integer",
              "minimum": 0,
              "default": 0
            },
            "search": {
              "type": "string",
              "description": "Search in title and content"
            }
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
                  "id": {"type": "integer"},
                  "title": {"type": "string"},
                  "slug": {"type": "string"},
                  "content": {"type": "string"},
                  "status": {"type": "string"},
                  "published_at": {"type": "string", "format": "date-time"}
                }
              }
            },
            "total": {"type": "integer"},
            "limit": {"type": "integer"},
            "offset": {"type": "integer"}
          }
        }
      }
    ]
  },
  "id": null
}
```

#### 3. Tool Call
**POST** `/tools/call`

Executes a specific tool with provided arguments.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get_posts",
    "arguments": {
      "limit": 5,
      "status": "published"
    }
  },
  "id": 2
}
```

**Response:**
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
              "title": "Sample Post",
              "slug": "sample-post",
              "content": "Post content...",
              "status": "published",
              "published_at": "2025-01-19T10:00:00Z"
            }
          ],
          "total": 1,
          "limit": 5,
          "offset": 0
        }
      }
    ]
  },
  "id": 2
}
```

#### 4. Resources List
**GET** `/resources/list`

Returns available resource collections.

**Response:**
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
      }
    ]
  },
  "id": null
}
```

#### 5. Prompts List
**GET** `/prompts/list`

Returns available prompt templates.

**Response:**
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
          }
        ]
      }
    ]
  },
  "id": null
}
```

#### 6. Tools Stream
**GET** `/tools/stream`

Server-Sent Events endpoint for real-time updates.

**Response:**
```
event: progress
data: {"tool": "get_posts", "progress": 0.5, "partial": {"posts": [...]}}

event: complete
data: {"tool": "get_posts", "result": {...}}
```

## Authentication

### API Key Authentication

All tool calls require API key authentication via the `Authorization` header:

```
Authorization: Bearer your-api-key-here
```

### User Permissions

Tools respect RailsPress user permissions:

- **Posts**: Requires `can_create_posts?`, `can_edit_others_posts?`, etc.
- **Pages**: Requires `can_create_pages?`, `can_edit_others_pages?`, etc.
- **Taxonomies**: Requires `can_manage_taxonomies?`
- **Users**: Requires `administrator?` role

### Error Responses

**Missing API Key:**
```json
{
  "success": false,
  "error": "API key required",
  "code": "MISSING_API_KEY"
}
```

**Invalid API Key:**
```json
{
  "success": false,
  "error": "Invalid API key",
  "code": "INVALID_API_KEY"
}
```

**Permission Denied:**
```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32000,
    "message": "Permission denied: User lacks required permissions for this operation"
  },
  "id": 2
}
```

## Tools Reference

### Content Management Tools

#### Posts

**get_posts** - Retrieve posts with filtering
- **Parameters**: `status`, `limit`, `offset`, `search`, `category`, `tag`, `author`, `date_from`, `date_to`
- **Returns**: Array of posts with metadata

**get_post** - Retrieve single post
- **Parameters**: `id` OR `slug`
- **Returns**: Single post object

**create_post** - Create new post
- **Parameters**: `title` (required), `content`, `excerpt`, `status`, `published_at`, `slug`, `meta_title`, `meta_description`, `category_ids`, `tag_ids`, `meta_fields`
- **Returns**: Created post object

**update_post** - Update existing post
- **Parameters**: `id` (required), plus any post fields
- **Returns**: Updated post object

**delete_post** - Delete post (move to trash)
- **Parameters**: `id` (required)
- **Returns**: Success status

#### Pages

**get_pages** - Retrieve pages with filtering
- **Parameters**: `status`, `limit`, `offset`, `search`, `parent_id`, `root_only`, `channel`
- **Returns**: Array of pages with metadata

**get_page** - Retrieve single page
- **Parameters**: `id` OR `slug`
- **Returns**: Single page object

**create_page** - Create new page
- **Parameters**: `title` (required), `content`, `excerpt`, `status`, `published_at`, `slug`, `parent_id`, `meta_title`, `meta_description`, `meta_fields`
- **Returns**: Created page object

**update_page** - Update existing page
- **Parameters**: `id` (required), plus any page fields
- **Returns**: Updated page object

**delete_page** - Delete page (move to trash)
- **Parameters**: `id` (required)
- **Returns**: Success status

### Taxonomy Tools

**get_taxonomies** - Retrieve all taxonomies
- **Parameters**: `hierarchical`, `object_types`
- **Returns**: Array of taxonomy objects

**get_terms** - Retrieve terms for taxonomy
- **Parameters**: `taxonomy` (required), `parent_id`, `root_only`, `search`, `limit`, `offset`
- **Returns**: Array of term objects

**create_term** - Create new term
- **Parameters**: `name` (required), `taxonomy` (required), `description`, `parent_id`, `slug`, `metadata`
- **Returns**: Created term object

**update_term** - Update existing term
- **Parameters**: `id` (required), plus any term fields
- **Returns**: Updated term object

**delete_term** - Delete term
- **Parameters**: `id` (required)
- **Returns**: Success status

### Media Tools

**get_media** - Retrieve media files
- **Parameters**: `limit`, `offset`, `search`, `mime_type`, `uploaded_by`, `date_from`, `date_to`
- **Returns**: Array of media objects

**upload_media** - Upload media file
- **Parameters**: `file` (required, base64), `filename` (required), `title`, `alt_text`, `caption`, `description`
- **Returns**: Uploaded media object

### System Tools

**get_content_types** - Retrieve content types
- **Parameters**: None
- **Returns**: Array of content type objects

**get_users** - Retrieve users
- **Parameters**: `limit`, `offset`, `search`, `role`, `status`
- **Returns**: Array of user objects

**get_system_info** - Get system information
- **Parameters**: None
- **Returns**: System statistics and version info

## Resources Reference

### Available Resources

- **railspress://posts** - Posts collection
- **railspress://pages** - Pages collection
- **railspress://taxonomies** - Taxonomies collection
- **railspress://terms** - Terms collection
- **railspress://media** - Media collection
- **railspress://users** - Users collection
- **railspress://content-types** - Content types collection

### Resource Access

Resources can be accessed via the tools system. Each resource corresponds to a specific tool or set of tools that can query and manipulate the resource data.

## Prompts Reference

### Available Prompts

#### seo_optimize
Optimize content for SEO
- **content** (required): The content to optimize
- **target_keywords** (optional): Target keywords for SEO
- **content_type** (optional): Type of content (post, page)

#### content_summarize
Summarize content
- **content** (required): The content to summarize
- **max_length** (optional): Maximum length of summary

#### content_generate
Generate content based on topic
- **topic** (required): Topic to generate content about
- **content_type** (optional): Type of content to generate
- **tone** (optional): Tone of the content
- **length** (optional): Desired length of content

#### meta_description_generate
Generate meta description for content
- **title** (required): Content title
- **content** (required): Content body
- **keywords** (optional): Target keywords

## Admin Settings

### Accessing MCP Settings

Navigate to **Admin → System → MCP Settings** in the RailsPress admin panel.

### Configuration Sections

#### Basic Settings
- **Enable MCP API**: Toggle MCP API on/off
- **API Key**: Set or generate API key
- **Rate Limits**: Configure requests per minute/hour/day

#### Access Control
- **Allowed Tools**: Restrict which tools are available
- **Allowed Resources**: Restrict which resources are accessible
- **Allowed Prompts**: Restrict which prompts are available
- **Require Authentication**: Force API key authentication

#### Rate Limiting
- **Rate Limit by IP**: Apply limits based on client IP
- **Rate Limit by User**: Apply limits based on authenticated user

#### Logging & Monitoring
- **Log Requests**: Log all incoming API requests
- **Log Responses**: Log API response data
- **Enable Analytics**: Track API usage metrics
- **Analytics Retention**: Days to retain analytics data
- **Debug Log Level**: Set logging verbosity

#### Advanced Features
- **Enable Streaming**: Enable Server-Sent Events
- **Enable CORS**: Enable Cross-Origin Resource Sharing
- **Enable Caching**: Cache API responses
- **Max Stream Duration**: Maximum streaming time
- **Cache TTL**: Cache time-to-live
- **CORS Origins**: Allowed origins for CORS

#### Security Settings
- **Enable Security Headers**: Add security headers
- **Enable Encryption**: Encrypt sensitive data
- **Enable SSL**: Require SSL/TLS
- **Max Request Size**: Maximum request payload size
- **Request Timeout**: Request timeout duration

#### Webhooks
- **Enable Webhooks**: Send webhook notifications
- **Webhook URL**: Target webhook endpoint
- **Webhook Secret**: Secret for webhook verification

### Interactive Features

#### Test Connection
Click "Test Connection" to verify MCP API is working correctly.

#### Generate API Key
Click "Generate API Key" to create a new API key and invalidate the current one.

## Configuration

### Environment Variables

No additional environment variables are required. All configuration is stored in the database using the SiteSetting model.

### Site Settings

MCP settings are stored as site settings with the `mcp_` prefix:

- `mcp_enabled` - Enable/disable MCP API
- `mcp_api_key` - API key for authentication
- `mcp_max_requests_per_minute` - Rate limiting
- `mcp_allowed_tools` - Tool access control
- And 40+ additional configuration options

### Database Schema

MCP uses the existing SiteSetting model for configuration storage. No additional database tables are required.

## Testing

### Manual Testing

Use the provided test scripts:

```bash
# Test MCP API endpoints
ruby test_mcp_comprehensive.rb

# Test MCP settings
ruby test_mcp_settings.rb

# Run final comprehensive test
ruby test_mcp_final.rb
```

### Automated Testing

RSpec tests are available in `spec/controllers/api/v1/mcp_controller_spec.rb`:

```bash
bundle exec rspec spec/controllers/api/v1/mcp_controller_spec.rb
```

### Test Coverage

The test suite covers:
- Handshake protocol negotiation
- Tool discovery and invocation
- Resource and prompt listing
- Authentication and authorization
- Error handling
- Permission checks
- Streaming functionality

## Deployment

### Prerequisites

- RailsPress application running
- Database migrations applied
- Admin user with administrator role

### Installation Steps

1. **Routes**: MCP routes are automatically included in `config/routes.rb`
2. **Controllers**: Controllers are in place and ready
3. **Views**: Admin interface is available
4. **Configuration**: Use admin panel to configure settings

### Production Considerations

#### Security
- Enable SSL/TLS for production
- Use strong API keys
- Configure proper CORS origins
- Enable security headers
- Set appropriate rate limits

#### Performance
- Enable caching for better performance
- Configure appropriate cache TTL
- Monitor API usage and performance
- Set up alerting for errors

#### Monitoring
- Enable request/response logging
- Set up analytics tracking
- Configure webhook notifications
- Monitor error rates and response times

## Troubleshooting

### Common Issues

#### 1. MCP API Returns 404
**Cause**: Routes not properly configured
**Solution**: Check `config/routes.rb` for MCP routes

#### 2. Authentication Failures
**Cause**: Invalid or missing API key
**Solution**: 
- Verify API key in admin settings
- Check Authorization header format
- Ensure user account is active

#### 3. Permission Denied Errors
**Cause**: User lacks required permissions
**Solution**:
- Check user role and permissions
- Verify tool-specific permission requirements
- Ensure user is active and authenticated

#### 4. Rate Limiting Issues
**Cause**: Exceeding configured rate limits
**Solution**:
- Check rate limit settings in admin panel
- Implement proper request throttling
- Consider increasing limits if appropriate

#### 5. Streaming Not Working
**Cause**: SSE not properly configured
**Solution**:
- Enable streaming in admin settings
- Check browser SSE support
- Verify network connectivity

### Debug Mode

Enable debug mode in admin settings to get detailed logging:

1. Go to Admin → System → MCP Settings
2. Enable "Debug Mode"
3. Set "Debug Log Level" to "debug"
4. Check Rails logs for detailed information

### Log Analysis

Monitor these log entries:
- `MCP API Request` - Incoming requests
- `MCP API Response` - Outgoing responses
- `MCP Authentication` - Auth attempts
- `MCP Permission` - Permission checks
- `MCP Error` - Error conditions

### Performance Monitoring

Key metrics to monitor:
- Request response times
- Error rates
- Rate limit hits
- Authentication failures
- Tool execution times

### Support

For additional support:
1. Check Rails logs for error details
2. Enable debug mode for verbose logging
3. Test with provided test scripts
4. Verify configuration in admin panel
5. Check user permissions and roles

## API Examples

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
      "clientInfo": {"name": "example-client", "version": "1.0.0"}
    },
    "id": 1
  }'

# 2. List Tools
curl -X GET http://localhost:3000/api/v1/mcp/tools/list \
  -H "Accept: application/json"

# 3. Call Tool (with API key)
curl -X POST http://localhost:3000/api/v1/mcp/tools/call \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "get_posts",
      "arguments": {"limit": 5}
    },
    "id": 2
  }'
```

### Error Handling Example

```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32601,
    "message": "Unknown tool: invalid_tool_name"
  },
  "id": 2
}
```

This comprehensive documentation covers all aspects of the MCP implementation, from basic usage to advanced configuration and troubleshooting.


