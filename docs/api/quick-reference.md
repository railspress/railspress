# RailsPress API Quick Reference

## 🚀 Quick Start

### 1. Get API Token
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@railspress.com","password":"password"}'
```

### 2. Use Token
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/api/v1/posts
```

## 📚 Core Endpoints

### Posts
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/posts` | List posts |
| GET | `/api/v1/posts/:id` | Get post |
| POST | `/api/v1/posts` | Create post 🔐 |
| PATCH | `/api/v1/posts/:id` | Update post 🔐 |
| DELETE | `/api/v1/posts/:id` | Delete post 🔐 |

### Pages
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/pages` | List pages |
| GET | `/api/v1/pages/:id` | Get page |
| POST | `/api/v1/pages` | Create page 🔐 |
| PATCH | `/api/v1/pages/:id` | Update page 🔐 |
| DELETE | `/api/v1/pages/:id` | Delete page 🔐 |

### Categories
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/categories` | List categories |
| GET | `/api/v1/categories/:id` | Get category |
| POST | `/api/v1/categories` | Create category 🔐 |
| PATCH | `/api/v1/categories/:id` | Update category 🔐 |
| DELETE | `/api/v1/categories/:id` | Delete category 🔐 |

### Tags
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/tags` | List tags |
| GET | `/api/v1/tags/:id` | Get tag |
| POST | `/api/v1/tags` | Create tag 🔐 |
| PATCH | `/api/v1/tags/:id` | Update tag 🔐 |
| DELETE | `/api/v1/tags/:id` | Delete tag 🔐 |

### Comments
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/comments` | List comments |
| GET | `/api/v1/comments/:id` | Get comment |
| POST | `/api/v1/comments` | Create comment |
| PATCH | `/api/v1/comments/:id/approve` | Approve comment 🔐 |
| PATCH | `/api/v1/comments/:id/spam` | Mark as spam 🔐 |
| DELETE | `/api/v1/comments/:id` | Delete comment 🔐 |

### Media
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/media` | List media files |
| GET | `/api/v1/media/:id` | Get media |
| POST | `/api/v1/media` | Upload media 🔐 |
| PATCH | `/api/v1/media/:id` | Update media 🔐 |
| DELETE | `/api/v1/media/:id` | Delete media 🔐 |

### Users
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/users` | List users 👑 |
| GET | `/api/v1/users/me` | Get current user 🔐 |
| PATCH | `/api/v1/users/update_profile` | Update profile 🔐 |
| POST | `/api/v1/users/regenerate_token` | New API token 🔐 |

### Menus
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/menus` | List menus |
| GET | `/api/v1/menus/:id` | Get menu with items |

### Settings
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/settings` | List all settings 🔐 |
| GET | `/api/v1/settings/get/:key` | Get setting value 🔐 |
| POST | `/api/v1/settings` | Create/update setting 👑 |

### System
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/system/info` | API info |
| GET | `/api/v1/system/stats` | System statistics 👑 |

🔐 = Authentication Required  
👑 = Admin Only

## 🔑 Query Parameters

### Pagination
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 25, max: 100)

### Filtering Posts
- `status` - draft, published, scheduled, pending_review
- `category` - Category slug
- `tag` - Tag slug
- `q` - Search query

### Filtering Comments
- `status` - pending, approved, spam
- `post_id` - Filter by post
- `page_id` - Filter by page
- `root_only` - true/false

### Filtering Categories/Tags
- `q` - Search query
- `parent_id` - Parent category
- `root_only` - true/false

### Filtering Media
- `type` - images, videos, documents
- `q` - Search query

## 📝 Request Examples

### Create Post
```json
POST /api/v1/posts
Authorization: Bearer {token}

{
  "post": {
    "title": "My Post",
    "content": "<p>Content</p>",
    "excerpt": "Short description",
    "status": "published",
    "category_ids": [1, 2],
    "tag_ids": [1, 2, 3],
    "meta_description": "SEO description",
    "meta_keywords": "keyword1, keyword2"
  }
}
```

### Create Page
```json
POST /api/v1/pages
Authorization: Bearer {token}

{
  "page": {
    "title": "About Us",
    "content": "<p>About page</p>",
    "status": "published",
    "parent_id": null,
    "template": "default",
    "meta_description": "About our company"
  }
}
```

### Create Comment
```json
POST /api/v1/comments

{
  "comment": {
    "content": "Great article!",
    "author_name": "John Doe",
    "author_email": "john@example.com",
    "commentable_type": "Post",
    "commentable_id": 1,
    "parent_id": null
  }
}
```

### Upload Media
```bash
curl -X POST http://localhost:3000/api/v1/media \
  -H "Authorization: Bearer {token}" \
  -F "medium[title]=My Image" \
  -F "medium[file]=@/path/to/image.jpg"
```

## 🎯 Response Format

### Success
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "current_page": 1,
    "per_page": 25,
    "total_pages": 5,
    "total_count": 120
  }
}
```

### Error
```json
{
  "success": false,
  "error": "Error message"
}
```

## 📖 Full Documentation

- **Complete Guide**: `API_DOCUMENTATION.md`
- **Interactive Client**: `API_CLIENT_EXAMPLE.html`
- **Postman Collection**: `railspress_api_collection.json`
- **Online Docs**: http://localhost:3000/api/v1/docs

## 🔒 Security

- **Authentication**: Bearer token in Authorization header
- **Rate Limiting**: 1000 requests/hour per user
- **CORS**: Configured for cross-origin requests
- **SSL**: Use HTTPS in production

## ⚡ Rate Limits

- **Limit**: 1000 requests per hour
- **Headers**: 
  - `X-RateLimit-Limit: 1000`
  - `X-RateLimit-Remaining: 999`
  - `X-RateLimit-Reset: 2025-10-12T01:00:00Z`

## 🛠️ Tools

### Test with cURL
```bash
# Get posts
curl http://localhost:3000/api/v1/posts

# Create post (with auth)
curl -X POST http://localhost:3000/api/v1/posts \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"post":{"title":"Test","content":"<p>Test</p>","status":"published"}}'
```

### Test with JavaScript
```javascript
// Fetch posts
fetch('http://localhost:3000/api/v1/posts')
  .then(r => r.json())
  .then(data => console.log(data));

// Create post
fetch('http://localhost:3000/api/v1/posts', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer ' + token,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    post: {
      title: 'New Post',
      content: '<p>Content</p>',
      status: 'published'
    }
  })
});
```

### Import Postman Collection
1. Open Postman
2. Import `railspress_api_collection.json`
3. Set variables: `base_url`, `api_token`
4. Start testing!

## 💡 Tips

1. **Store token securely** - Use environment variables
2. **Handle errors** - Check `success` field
3. **Respect rate limits** - Monitor headers
4. **Use pagination** - For large datasets
5. **Filter results** - Use query parameters
6. **Test locally** - Use API_CLIENT_EXAMPLE.html

---

**Need Help?** Check `API_DOCUMENTATION.md` for detailed information.



