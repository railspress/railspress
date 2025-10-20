# MCP API Reference Guide

## Quick Start

### 1. Authentication
All MCP API calls require an API key in the Authorization header:

```bash
Authorization: Bearer your-api-key-here
```

### 2. Base URL
```
https://your-domain.com/api/v1/mcp
```

### 3. Protocol
- **Format**: JSON-RPC 2.0
- **Content-Type**: `application/json`
- **Accept**: `application/json`

## Endpoint Reference

### Session Management

#### Handshake
**POST** `/session/handshake`

Establishes MCP session and negotiates capabilities.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "session/handshake",
  "params": {
    "protocolVersion": "2025-03-26",
    "clientInfo": {
      "name": "your-client-name",
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

**Error Codes:**
- `-32602`: Invalid protocol version
- `-32600`: Invalid Request format

### Tools

#### List Tools
**GET** `/tools/list`

Returns all available tools with their schemas.

**Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "tools": [
      {
        "name": "tool_name",
        "description": "Tool description",
        "inputSchema": {
          "type": "object",
          "properties": {...},
          "required": [...]
        },
        "outputSchema": {
          "type": "object",
          "properties": {...}
        }
      }
    ]
  },
  "id": null
}
```

#### Call Tool
**POST** `/tools/call`

Executes a specific tool with provided arguments.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "tool_name",
    "arguments": {
      "param1": "value1",
      "param2": "value2"
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
          "result": "data"
        }
      }
    ]
  },
  "id": 2
}
```

**Error Codes:**
- `-32601`: Unknown tool
- `-32000`: Permission denied
- `-32603`: Internal error

#### Stream Tool
**GET** `/tools/stream`

Server-Sent Events endpoint for real-time tool execution updates.

**Response:**
```
event: progress
data: {"tool": "tool_name", "progress": 0.5, "partial": {...}}

event: complete
data: {"tool": "tool_name", "result": {...}}

event: error
data: {"tool": "tool_name", "error": "error message"}
```

### Resources

#### List Resources
**GET** `/resources/list`

Returns available resource collections.

**Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "resources": [
      {
        "uri": "railspress://resource_name",
        "name": "Resource Display Name",
        "description": "Resource description",
        "mimeType": "application/json"
      }
    ]
  },
  "id": null
}
```

### Prompts

#### List Prompts
**GET** `/prompts/list`

Returns available prompt templates.

**Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "prompts": [
      {
        "name": "prompt_name",
        "description": "Prompt description",
        "arguments": [
          {
            "name": "arg_name",
            "description": "Argument description",
            "required": true
          }
        ]
      }
    ]
  },
  "id": null
}
```

## Tool Reference

### Content Management

#### Posts

**get_posts**
Retrieve posts with optional filtering.

**Parameters:**
- `status` (string, optional): Filter by status (`published`, `draft`, `pending_review`, `scheduled`, `trash`)
- `limit` (integer, optional): Number of posts to return (1-100, default: 20)
- `offset` (integer, optional): Number of posts to skip (default: 0)
- `search` (string, optional): Search in title and content
- `category` (string, optional): Filter by category slug
- `tag` (string, optional): Filter by tag slug
- `author` (integer, optional): Filter by author ID
- `date_from` (string, optional): Filter posts from date (YYYY-MM-DD)
- `date_to` (string, optional): Filter posts to date (YYYY-MM-DD)

**Response:**
```json
{
  "posts": [
    {
      "id": 1,
      "title": "Post Title",
      "slug": "post-slug",
      "content": "Post content...",
      "excerpt": "Post excerpt...",
      "status": "published",
      "published_at": "2025-01-19T10:00:00Z",
      "created_at": "2025-01-19T09:00:00Z",
      "updated_at": "2025-01-19T10:00:00Z",
      "author": {
        "id": 1,
        "name": "Author Name",
        "email": "author@example.com"
      },
      "categories": [
        {
          "id": 1,
          "name": "Category Name",
          "slug": "category-slug"
        }
      ],
      "tags": [
        {
          "id": 1,
          "name": "Tag Name",
          "slug": "tag-slug"
        }
      ],
      "meta_fields": {}
    }
  ],
  "total": 1,
  "limit": 20,
  "offset": 0
}
```

**get_post**
Retrieve a single post by ID or slug.

**Parameters:**
- `id` (integer, optional): Post ID
- `slug` (string, optional): Post slug

**Response:**
```json
{
  "post": {
    "id": 1,
    "title": "Post Title",
    "slug": "post-slug",
    "content": "Post content...",
    "excerpt": "Post excerpt...",
    "status": "published",
    "published_at": "2025-01-19T10:00:00Z",
    "created_at": "2025-01-19T09:00:00Z",
    "updated_at": "2025-01-19T10:00:00Z",
    "author": {...},
    "categories": [...],
    "tags": [...],
    "meta_fields": {},
    "comments": [...]
  }
}
```

**create_post**
Create a new post.

**Parameters:**
- `title` (string, required): Post title
- `content` (string, optional): Post content
- `excerpt` (string, optional): Post excerpt
- `status` (string, optional): Post status (`draft`, `published`, `pending_review`, `scheduled`, default: `draft`)
- `published_at` (string, optional): Publication date (ISO 8601)
- `slug` (string, optional): Post slug (auto-generated if not provided)
- `meta_title` (string, optional): SEO meta title
- `meta_description` (string, optional): SEO meta description
- `category_ids` (array, optional): Array of category IDs
- `tag_ids` (array, optional): Array of tag IDs
- `meta_fields` (object, optional): Custom meta fields

**Response:**
```json
{
  "post": {
    "id": 1,
    "title": "New Post Title",
    "slug": "new-post-slug",
    "content": "Post content...",
    "excerpt": "Post excerpt...",
    "status": "draft",
    "published_at": null,
    "created_at": "2025-01-19T10:00:00Z",
    "updated_at": "2025-01-19T10:00:00Z"
  }
}
```

**update_post**
Update an existing post.

**Parameters:**
- `id` (integer, required): Post ID
- Plus any fields from `create_post`

**Response:**
```json
{
  "post": {
    "id": 1,
    "title": "Updated Post Title",
    "slug": "updated-post-slug",
    "content": "Updated content...",
    "excerpt": "Updated excerpt...",
    "status": "published",
    "published_at": "2025-01-19T10:00:00Z",
    "created_at": "2025-01-19T09:00:00Z",
    "updated_at": "2025-01-19T11:00:00Z"
  }
}
```

**delete_post**
Delete a post (move to trash).

**Parameters:**
- `id` (integer, required): Post ID

**Response:**
```json
{
  "success": true,
  "message": "Post moved to trash successfully"
}
```

#### Pages

**get_pages**
Retrieve pages with optional filtering.

**Parameters:**
- `status` (string, optional): Filter by status (`published`, `draft`, `pending_review`, `scheduled`, `private_page`, `trash`)
- `limit` (integer, optional): Number of pages to return (1-100, default: 20)
- `offset` (integer, optional): Number of pages to skip (default: 0)
- `search` (string, optional): Search in title and content
- `parent_id` (integer, optional): Filter by parent page ID
- `root_only` (boolean, optional): Only root pages (no parent)
- `channel` (string, optional): Filter by channel slug

**Response:**
```json
{
  "pages": [
    {
      "id": 1,
      "title": "Page Title",
      "slug": "page-slug",
      "content": "Page content...",
      "excerpt": "Page excerpt...",
      "status": "published",
      "published_at": "2025-01-19T10:00:00Z",
      "created_at": "2025-01-19T09:00:00Z",
      "updated_at": "2025-01-19T10:00:00Z",
      "author": {...},
      "parent": null,
      "children": [],
      "meta_fields": {}
    }
  ],
  "total": 1,
  "limit": 20,
  "offset": 0
}
```

**get_page**
Retrieve a single page by ID or slug.

**Parameters:**
- `id` (integer, optional): Page ID
- `slug` (string, optional): Page slug

**Response:**
```json
{
  "page": {
    "id": 1,
    "title": "Page Title",
    "slug": "page-slug",
    "content": "Page content...",
    "excerpt": "Page excerpt...",
    "status": "published",
    "published_at": "2025-01-19T10:00:00Z",
    "created_at": "2025-01-19T09:00:00Z",
    "updated_at": "2025-01-19T10:00:00Z",
    "author": {...},
    "parent": null,
    "children": [...],
    "meta_fields": {},
    "comments": [...]
  }
}
```

**create_page**
Create a new page.

**Parameters:**
- `title` (string, required): Page title
- `content` (string, optional): Page content
- `excerpt` (string, optional): Page excerpt
- `status` (string, optional): Page status (`draft`, `published`, `pending_review`, `scheduled`, `private_page`, default: `draft`)
- `published_at` (string, optional): Publication date (ISO 8601)
- `slug` (string, optional): Page slug (auto-generated if not provided)
- `parent_id` (integer, optional): Parent page ID
- `meta_title` (string, optional): SEO meta title
- `meta_description` (string, optional): SEO meta description
- `meta_fields` (object, optional): Custom meta fields

**Response:**
```json
{
  "page": {
    "id": 1,
    "title": "New Page Title",
    "slug": "new-page-slug",
    "content": "Page content...",
    "excerpt": "Page excerpt...",
    "status": "draft",
    "published_at": null,
    "created_at": "2025-01-19T10:00:00Z",
    "updated_at": "2025-01-19T10:00:00Z"
  }
}
```

**update_page**
Update an existing page.

**Parameters:**
- `id` (integer, required): Page ID
- Plus any fields from `create_page`

**Response:**
```json
{
  "page": {
    "id": 1,
    "title": "Updated Page Title",
    "slug": "updated-page-slug",
    "content": "Updated content...",
    "excerpt": "Updated excerpt...",
    "status": "published",
    "published_at": "2025-01-19T10:00:00Z",
    "created_at": "2025-01-19T09:00:00Z",
    "updated_at": "2025-01-19T11:00:00Z"
  }
}
```

**delete_page**
Delete a page (move to trash).

**Parameters:**
- `id` (integer, required): Page ID

**Response:**
```json
{
  "success": true,
  "message": "Page moved to trash successfully"
}
```

### Taxonomy Management

#### Taxonomies

**get_taxonomies**
Retrieve all taxonomies.

**Parameters:**
- `hierarchical` (boolean, optional): Filter by hierarchical type
- `object_types` (array, optional): Filter by object types

**Response:**
```json
{
  "taxonomies": [
    {
      "id": 1,
      "name": "Categories",
      "slug": "category",
      "description": "Post categories",
      "hierarchical": true,
      "object_types": ["post"],
      "term_count": 5,
      "settings": {}
    }
  ]
}
```

#### Terms

**get_terms**
Retrieve terms for a taxonomy.

**Parameters:**
- `taxonomy` (string, required): Taxonomy slug (e.g., `category`, `post_tag`)
- `parent_id` (integer, optional): Filter by parent term ID
- `root_only` (boolean, optional): Only root terms (no parent)
- `search` (string, optional): Search in term names
- `limit` (integer, optional): Number of terms to return (1-100, default: 50)
- `offset` (integer, optional): Number of terms to skip (default: 0)

**Response:**
```json
{
  "terms": [
    {
      "id": 1,
      "name": "Technology",
      "slug": "technology",
      "description": "Technology related posts",
      "count": 10,
      "parent_id": null,
      "taxonomy": {
        "id": 1,
        "name": "Categories",
        "slug": "category"
      },
      "children": [
        {
          "id": 2,
          "name": "Web Development",
          "slug": "web-development",
          "count": 5,
          "parent_id": 1
        }
      ]
    }
  ],
  "total": 1,
  "limit": 50,
  "offset": 0
}
```

**create_term**
Create a new term.

**Parameters:**
- `name` (string, required): Term name
- `taxonomy` (string, required): Taxonomy slug
- `description` (string, optional): Term description
- `parent_id` (integer, optional): Parent term ID
- `slug` (string, optional): Term slug (auto-generated if not provided)
- `metadata` (object, optional): Term metadata

**Response:**
```json
{
  "term": {
    "id": 1,
    "name": "New Term",
    "slug": "new-term",
    "description": "Term description",
    "count": 0,
    "parent_id": null,
    "taxonomy": {
      "id": 1,
      "name": "Categories",
      "slug": "category"
    }
  }
}
```

**update_term**
Update an existing term.

**Parameters:**
- `id` (integer, required): Term ID
- Plus any fields from `create_term`

**Response:**
```json
{
  "term": {
    "id": 1,
    "name": "Updated Term",
    "slug": "updated-term",
    "description": "Updated description",
    "count": 5,
    "parent_id": null,
    "taxonomy": {
      "id": 1,
      "name": "Categories",
      "slug": "category"
    }
  }
}
```

**delete_term**
Delete a term.

**Parameters:**
- `id` (integer, required): Term ID

**Response:**
```json
{
  "success": true,
  "message": "Term deleted successfully"
}
```

### Media Management

**get_media**
Retrieve media files.

**Parameters:**
- `limit` (integer, optional): Number of files to return (1-100, default: 20)
- `offset` (integer, optional): Number of files to skip (default: 0)
- `search` (string, optional): Search in filename and title
- `mime_type` (string, optional): Filter by MIME type
- `uploaded_by` (integer, optional): Filter by uploader ID
- `date_from` (string, optional): Filter files from date (YYYY-MM-DD)
- `date_to` (string, optional): Filter files to date (YYYY-MM-DD)

**Response:**
```json
{
  "media": [
    {
      "id": 1,
      "filename": "image.jpg",
      "title": "Image Title",
      "alt_text": "Alt text",
      "caption": "Image caption",
      "description": "Image description",
      "mime_type": "image/jpeg",
      "file_size": 1024000,
      "url": "https://example.com/uploads/image.jpg",
      "thumbnail_url": "https://example.com/uploads/thumbnails/image.jpg",
      "uploaded_at": "2025-01-19T10:00:00Z",
      "uploaded_by": {
        "id": 1,
        "name": "User Name",
        "email": "user@example.com"
      }
    }
  ],
  "total": 1,
  "limit": 20,
  "offset": 0
}
```

**upload_media**
Upload a media file.

**Parameters:**
- `file` (string, required): Base64 encoded file data
- `filename` (string, required): Original filename
- `title` (string, optional): Media title
- `alt_text` (string, optional): Alt text for images
- `caption` (string, optional): Media caption
- `description` (string, optional): Media description

**Response:**
```json
{
  "media": {
    "id": 1,
    "filename": "uploaded-file.jpg",
    "title": "Uploaded File",
    "alt_text": "Alt text",
    "caption": "File caption",
    "description": "File description",
    "mime_type": "image/jpeg",
    "file_size": 1024000,
    "url": "https://example.com/uploads/uploaded-file.jpg",
    "thumbnail_url": "https://example.com/uploads/thumbnails/uploaded-file.jpg",
    "uploaded_at": "2025-01-19T10:00:00Z"
  }
}
```

### System Information

**get_content_types**
Retrieve all content types.

**Parameters:** None

**Response:**
```json
{
  "content_types": [
    {
      "id": 1,
      "name": "Post",
      "slug": "post",
      "description": "Blog posts",
      "icon": "post",
      "supports": ["title", "editor", "author", "thumbnail", "excerpt", "comments", "revisions"],
      "labels": {
        "name": "Posts",
        "singular_name": "Post",
        "add_new": "Add New Post",
        "add_new_item": "Add New Post",
        "edit_item": "Edit Post",
        "new_item": "New Post",
        "view_item": "View Post",
        "search_items": "Search Posts",
        "not_found": "No posts found",
        "not_found_in_trash": "No posts found in trash"
      },
      "capabilities": {
        "edit_post": "edit_posts",
        "read_post": "read_posts",
        "delete_post": "delete_posts",
        "edit_posts": "edit_posts",
        "edit_others_posts": "edit_others_posts",
        "publish_posts": "publish_posts",
        "read_private_posts": "read_private_posts"
      },
      "settings": {}
    }
  ]
}
```

**get_users**
Retrieve users.

**Parameters:**
- `limit` (integer, optional): Number of users to return (1-100, default: 20)
- `offset` (integer, optional): Number of users to skip (default: 0)
- `search` (string, optional): Search in name and email
- `role` (string, optional): Filter by role
- `status` (string, optional): Filter by status (`active`, `inactive`)

**Response:**
```json
{
  "users": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "administrator",
      "status": "active",
      "created_at": "2025-01-19T09:00:00Z",
      "last_login_at": "2025-01-19T10:00:00Z"
    }
  ],
  "total": 1,
  "limit": 20,
  "offset": 0
}
```

**get_system_info**
Get system information and statistics.

**Parameters:** None

**Response:**
```json
{
  "system": {
    "name": "RailsPress",
    "version": "1.0.0",
    "rails_version": "7.0.0",
    "ruby_version": "3.2.0",
    "environment": "production",
    "statistics": {
      "posts_count": 100,
      "pages_count": 25,
      "users_count": 10,
      "media_count": 500,
      "comments_count": 250
    }
  }
}
```

## Error Handling

### JSON-RPC Error Codes

- `-32700`: Parse error
- `-32600`: Invalid Request
- `-32601`: Method not found
- `-32602`: Invalid params
- `-32603`: Internal error
- `-32000`: Server error (custom)

### Authentication Errors

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

**Inactive User:**
```json
{
  "success": false,
  "error": "User account is inactive",
  "code": "INACTIVE_USER"
}
```

### Permission Errors

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

### Validation Errors

**Invalid Parameters:**
```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32602,
    "message": "Invalid params",
    "data": {
      "field": "title",
      "message": "Title is required"
    }
  },
  "id": 2
}
```

## Rate Limiting

### Default Limits
- **Per Minute**: 100 requests
- **Per Hour**: 1,000 requests
- **Per Day**: 10,000 requests

### Rate Limit Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

### Rate Limit Exceeded
```json
{
  "success": false,
  "error": "Rate limit exceeded",
  "code": "RATE_LIMIT_EXCEEDED",
  "retry_after": 60
}
```

## Best Practices

### 1. Error Handling
Always check for errors in responses and handle them appropriately.

### 2. Rate Limiting
Implement proper request throttling to avoid hitting rate limits.

### 3. Authentication
Store API keys securely and rotate them regularly.

### 4. Pagination
Use `limit` and `offset` parameters for large datasets.

### 5. Caching
Cache responses when appropriate to reduce API calls.

### 6. Logging
Log API calls for debugging and monitoring purposes.

### 7. Validation
Validate input parameters before making API calls.

### 8. Timeouts
Set appropriate timeouts for API requests.

This API reference provides comprehensive documentation for all MCP endpoints and tools available in the RailsPress system.


