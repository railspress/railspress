# RailsPress API Documentation v1

## Overview

The RailsPress API provides programmatic access to all CMS functionality. It's a RESTful API that returns JSON responses and supports full CRUD operations for all resources.

## Base URL

```
http://localhost:3000/api/v1
```

Production: `https://your-domain.com/api/v1`

## Authentication

### Getting an API Token

**Login to get token:**

```bash
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "admin@railspress.com",
  "password": "password"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "email": "admin@railspress.com",
      "role": "administrator"
    },
    "api_token": "your-api-token-here",
    "message": "Login successful"
  }
}
```

### Using the API Token

Include the token in the `Authorization` header for all authenticated requests:

```bash
Authorization: Bearer your-api-token-here
```

### Rate Limiting

- **Limit**: 1000 requests per hour per user
- **Headers**: Rate limit info returned in response headers
- **Reset**: Automatically resets every hour

## Response Format

### Success Response

```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "current_page": 1,
    "per_page": 25,
    "total_pages": 5,
    "total_count": 120,
    "next_page": 2,
    "prev_page": null
  }
}
```

### Error Response

```json
{
  "success": false,
  "error": "Error message here"
}
```

## Endpoints

### Authentication

#### Login
```
POST /api/v1/auth/login
```

**Body:**
```json
{
  "email": "user@example.com",
  "password": "password"
}
```

#### Register
```
POST /api/v1/auth/register
```

**Body:**
```json
{
  "email": "newuser@example.com",
  "password": "password",
  "password_confirmation": "password"
}
```

#### Validate Token
```
POST /api/v1/auth/validate
Authorization: Bearer {token}
```

---

### Posts

#### List Posts
```
GET /api/v1/posts
```

**Query Parameters:**
- `status` - Filter by status (draft, published, scheduled, etc.)
- `category` - Filter by category slug
- `tag` - Filter by tag slug
- `q` - Search query
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 25)

**Example:**
```bash
GET /api/v1/posts?status=published&category=technology&page=1&per_page=10
```

#### Get Single Post
```
GET /api/v1/posts/:id
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "title": "My Post Title",
    "slug": "my-post-title",
    "content": "<p>Full content here...</p>",
    "excerpt": "Short excerpt...",
    "status": "published",
    "published_at": "2025-10-12T00:00:00.000Z",
    "author": {
      "id": 1,
      "name": "admin",
      "email": "admin@railspress.com"
    },
    "categories": [
      { "id": 1, "name": "Technology", "slug": "technology" }
    ],
    "tags": [
      { "id": 1, "name": "Ruby", "slug": "ruby" }
    ],
    "comments_count": 5,
    "featured_image": "https://...",
    "meta": {
      "description": "SEO description",
      "keywords": "seo, keywords"
    },
    "url": "https://your-site.com/blog/my-post-title"
  }
}
```

#### Create Post
```
POST /api/v1/posts
Authorization: Bearer {token}
Content-Type: application/json
```

**Body:**
```json
{
  "post": {
    "title": "New Post",
    "content": "<p>Content here</p>",
    "excerpt": "Excerpt",
    "status": "published",
    "category_ids": [1, 2],
    "tag_ids": [1, 2, 3],
    "meta_description": "SEO description",
    "meta_keywords": "keyword1, keyword2"
  }
}
```

#### Update Post
```
PATCH /api/v1/posts/:id
Authorization: Bearer {token}
```

**Body:** Same as create

#### Delete Post
```
DELETE /api/v1/posts/:id
Authorization: Bearer {token}
```

---

### Pages

#### List Pages
```
GET /api/v1/pages
```

**Query Parameters:**
- `status` - Filter by status
- `parent_id` - Filter by parent page
- `root_only` - Only root pages (true/false)
- `page` - Page number
- `per_page` - Items per page

#### Get Single Page
```
GET /api/v1/pages/:id
```

**Response includes:**
- Page details
- Content
- Parent/child relationships
- Breadcrumbs
- Comments count

#### Create Page
```
POST /api/v1/pages
Authorization: Bearer {token}
```

**Body:**
```json
{
  "page": {
    "title": "About Us",
    "content": "<p>Page content</p>",
    "status": "published",
    "parent_id": null,
    "order": 1,
    "template": "default"
  }
}
```

#### Update Page
```
PATCH /api/v1/pages/:id
Authorization: Bearer {token}
```

#### Delete Page
```
DELETE /api/v1/pages/:id
Authorization: Bearer {token}
```

---

### Categories

#### List Categories
```
GET /api/v1/categories
```

**Query Parameters:**
- `parent_id` - Filter by parent
- `root_only` - Only root categories
- `q` - Search query

**No authentication required for reading**

#### Get Single Category
```
GET /api/v1/categories/:id
```

**Response includes:**
- Category details
- Post count
- Parent/child relationships
- Recent posts

#### Create Category
```
POST /api/v1/categories
Authorization: Bearer {token}
```

**Body:**
```json
{
  "category": {
    "name": "Technology",
    "description": "Tech posts",
    "parent_id": null
  }
}
```

#### Update/Delete Category
```
PATCH /api/v1/categories/:id
DELETE /api/v1/categories/:id
Authorization: Bearer {token}
```

---

### Tags

#### List Tags
```
GET /api/v1/tags?popular=true
```

**Query Parameters:**
- `q` - Search query
- `popular` - Show popular tags (true/false)

#### Get Single Tag
```
GET /api/v1/tags/:id
```

#### Create/Update/Delete Tag
```
POST /api/v1/tags
PATCH /api/v1/tags/:id
DELETE /api/v1/tags/:id
Authorization: Bearer {token}
```

---

### Comments

#### List Comments
```
GET /api/v1/comments
```

**Query Parameters:**
- `status` - Filter by status (pending, approved, spam)
- `post_id` - Comments for specific post
- `page_id` - Comments for specific page
- `root_only` - Only top-level comments

#### Create Comment
```
POST /api/v1/comments
```

**Body (Guest):**
```json
{
  "comment": {
    "content": "Great post!",
    "author_name": "John Doe",
    "author_email": "john@example.com",
    "author_url": "https://johndoe.com",
    "commentable_type": "Post",
    "commentable_id": 1,
    "parent_id": null
  }
}
```

**Body (Authenticated):**
```json
{
  "comment": {
    "content": "Great post!",
    "commentable_type": "Post",
    "commentable_id": 1
  }
}
```

#### Approve Comment
```
PATCH /api/v1/comments/:id/approve
Authorization: Bearer {token}
```

#### Mark as Spam
```
PATCH /api/v1/comments/:id/spam
Authorization: Bearer {token}
```

---

### Media

#### List Media
```
GET /api/v1/media
```

**Query Parameters:**
- `type` - Filter by type (images, videos, documents)
- `q` - Search query

#### Upload Media
```
POST /api/v1/media
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Body:**
```
medium[title]: "My Image"
medium[description]: "Image description"
medium[alt_text]: "Alt text"
medium[file]: [binary file]
```

#### Get/Update/Delete Media
```
GET /api/v1/media/:id
PATCH /api/v1/media/:id
DELETE /api/v1/media/:id
Authorization: Bearer {token}
```

---

### Users

#### List Users (Admin Only)
```
GET /api/v1/users
Authorization: Bearer {token}
```

**Query Parameters:**
- `role` - Filter by role
- `q` - Search by email

#### Get Current User
```
GET /api/v1/users/me
Authorization: Bearer {token}
```

#### Update Profile
```
PATCH /api/v1/users/update_profile
Authorization: Bearer {token}
```

**Body:**
```json
{
  "user": {
    "email": "newemail@example.com",
    "password": "newpassword",
    "password_confirmation": "newpassword"
  }
}
```

#### Regenerate API Token
```
POST /api/v1/users/regenerate_token
Authorization: Bearer {token}
```

---

### Menus

#### List Menus
```
GET /api/v1/menus?location=primary
```

#### Get Menu with Items
```
GET /api/v1/menus/:id
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Main Menu",
    "location": "primary",
    "items": [
      {
        "id": 1,
        "label": "Home",
        "url": "/",
        "position": 1,
        "children": []
      },
      {
        "id": 2,
        "label": "Blog",
        "url": "/blog",
        "position": 2,
        "children": [
          {
            "id": 3,
            "label": "Tech",
            "url": "/category/tech",
            "position": 1
          }
        ]
      }
    ]
  }
}
```

---

### Settings

#### List All Settings
```
GET /api/v1/settings
Authorization: Bearer {token}
```

#### Get Setting Value
```
GET /api/v1/settings/get/site_title
Authorization: Bearer {token}
```

#### Create/Update Setting
```
POST /api/v1/settings
Authorization: Bearer {token}
```

**Body:**
```json
{
  "setting": {
    "key": "site_title",
    "value": "My Site",
    "setting_type": "string"
  }
}
```

---

### System Info

#### Get API Info
```
GET /api/v1/system/info
```

**No authentication required**

#### Get System Stats (Admin Only)
```
GET /api/v1/system/stats
Authorization: Bearer {token}
```

---

## Pagination

All list endpoints support pagination:

**Parameters:**
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 25, max: 100)

**Response Meta:**
```json
{
  "meta": {
    "current_page": 1,
    "per_page": 25,
    "total_pages": 5,
    "total_count": 120,
    "next_page": 2,
    "prev_page": null
  }
}
```

## Filtering & Searching

Most endpoints support filtering:

```bash
# Filter posts by status
GET /api/v1/posts?status=published

# Filter by category
GET /api/v1/posts?category=technology

# Search posts
GET /api/v1/posts?q=ruby+rails

# Combine filters
GET /api/v1/posts?status=published&category=tech&q=tutorial
```

## Error Codes

| Code | Meaning |
|------|---------|
| 200 | OK - Request successful |
| 201 | Created - Resource created |
| 400 | Bad Request - Invalid parameters |
| 401 | Unauthorized - Missing or invalid token |
| 403 | Forbidden - No permission |
| 404 | Not Found - Resource not found |
| 422 | Unprocessable Entity - Validation failed |
| 429 | Too Many Requests - Rate limit exceeded |
| 500 | Internal Server Error |

## Examples

### cURL Examples

#### Get Posts
```bash
curl -X GET "http://localhost:3000/api/v1/posts?status=published" \
  -H "Content-Type: application/json"
```

#### Create Post
```bash
curl -X POST "http://localhost:3000/api/v1/posts" \
  -H "Authorization: Bearer your-token-here" \
  -H "Content-Type: application/json" \
  -d '{
    "post": {
      "title": "My New Post",
      "content": "<p>Post content</p>",
      "status": "published",
      "category_ids": [1],
      "tag_ids": [1, 2]
    }
  }'
```

#### Upload Media
```bash
curl -X POST "http://localhost:3000/api/v1/media" \
  -H "Authorization: Bearer your-token-here" \
  -F "medium[title]=My Image" \
  -F "medium[file]=@/path/to/image.jpg"
```

### JavaScript Examples

#### Fetch Posts
```javascript
fetch('http://localhost:3000/api/v1/posts?status=published')
  .then(response => response.json())
  .then(data => {
    console.log('Posts:', data.data);
    console.log('Pagination:', data.meta);
  });
```

#### Create Post (Authenticated)
```javascript
const token = 'your-api-token';

fetch('http://localhost:3000/api/v1/posts', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    post: {
      title: 'New Post via API',
      content: '<p>Content here</p>',
      status: 'published',
      category_ids: [1],
      tag_ids: [1, 2]
    }
  })
})
.then(response => response.json())
.then(data => console.log('Created:', data));
```

### Python Examples

```python
import requests

# Get posts
response = requests.get('http://localhost:3000/api/v1/posts', params={
    'status': 'published',
    'page': 1,
    'per_page': 10
})
posts = response.json()

# Create post
token = 'your-api-token'
headers = {
    'Authorization': f'Bearer {token}',
    'Content-Type': 'application/json'
}
data = {
    'post': {
        'title': 'New Post',
        'content': '<p>Content</p>',
        'status': 'published'
    }
}
response = requests.post(
    'http://localhost:3000/api/v1/posts',
    json=data,
    headers=headers
)
result = response.json()
```

## Permissions

### User Roles

| Role | Posts | Pages | Comments | Media | Users | Settings |
|------|-------|-------|----------|-------|-------|----------|
| Subscriber | Read | Read | Create | - | - | - |
| Contributor | Create | - | Create | Upload | - | - |
| Author | CRUD Own | CRUD Own | Manage | Upload | - | - |
| Editor | CRUD All | CRUD All | CRUD All | CRUD All | - | Read |
| Administrator | CRUD All | CRUD All | CRUD All | CRUD All | CRUD All | CRUD All |

## Advanced Features

### Nested Resources

```bash
# Get comments for a specific post
GET /api/v1/posts/1/comments

# Get menu items for a menu
GET /api/v1/menus/1/menu_items
```

### Filtering & Sorting

```bash
# Get published posts in Technology category
GET /api/v1/posts?status=published&category=technology

# Get root categories only
GET /api/v1/categories?root_only=true

# Search pages
GET /api/v1/pages?q=about

# Popular tags
GET /api/v1/tags?popular=true
```

### System Information

```bash
# Get API version and endpoints
GET /api/v1/system/info

# Get system statistics (admin only)
GET /api/v1/system/stats
Authorization: Bearer {admin-token}
```

## Webhooks (Future)

Coming soon:
- Post published webhook
- Comment posted webhook
- User registered webhook
- Media uploaded webhook

## Rate Limiting Details

**Headers:**
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 2025-10-12T01:00:00Z
```

**When Exceeded:**
```json
{
  "success": false,
  "error": "Rate limit exceeded. Try again in 30 minutes."
}
```

## Best Practices

### 1. Always Use HTTPS in Production
```
https://your-domain.com/api/v1
```

### 2. Handle Errors Gracefully
```javascript
try {
  const response = await fetch(url);
  const data = await response.json();
  
  if (!data.success) {
    console.error('API Error:', data.error);
  }
} catch (error) {
  console.error('Network Error:', error);
}
```

### 3. Implement Pagination
```javascript
let page = 1;
let allPosts = [];

while (page) {
  const response = await fetch(`/api/v1/posts?page=${page}`);
  const data = await response.json();
  
  allPosts = [...allPosts, ...data.data];
  page = data.meta.next_page;
}
```

### 4. Cache Responses
```javascript
// Use ETags or cache headers
const response = await fetch(url, {
  headers: {
    'If-None-Match': cachedETag
  }
});

if (response.status === 304) {
  // Use cached data
}
```

### 5. Secure Your Token
```javascript
// Store in environment variables
const API_TOKEN = process.env.RAILSPRESS_API_TOKEN;

// Never commit tokens to source control
// Use .env files
```

## Versioning

The API uses URL versioning:
- Current: `/api/v1`
- Future: `/api/v2` (when available)

Breaking changes will be introduced in new versions only.

## Support

- **Documentation**: This file
- **Issues**: GitHub repository
- **API Status**: `GET /api/v1/system/info`

## Changelog

### v1.0.0 (2025-10-12)
- Initial API release
- Full CRUD for Posts, Pages, Categories, Tags, Comments
- Media upload support
- User management
- Menu and widget APIs
- Settings API
- Authentication with tokens
- Rate limiting
- Pagination
- Filtering and search

---

**Happy coding with RailsPress API!** 🚀



