# Headless CMS Mode

## Overview

RailsPress can operate as a **Headless CMS**, providing a powerful API-first architecture for modern frontend frameworks like Next.js, Remix, Nuxt, Astro, and more.

## What is Headless Mode?

When Headless Mode is enabled:

1. ✅ **Frontend routes are disabled** - Visiting `/`, `/blog`, `/page/*` shows an API endpoints page
2. ✅ **Admin panel remains accessible** - Full admin interface at `/admin`
3. ✅ **GraphQL API fully available** - Query all content via GraphQL
4. ✅ **REST API fully available** - Complete REST endpoints for all content types
5. ✅ **CORS configured** - Cross-origin requests allowed for your frontend apps
6. ✅ **Role-based API tokens** - Public, Editor, and Admin access levels

## Enabling Headless Mode

### Via Admin Panel

1. Navigate to **Admin > System > Headless**
2. Toggle **"Enable Headless Mode"**
3. Configure CORS settings
4. Click **"Save Settings"**

### Via Console

```ruby
# Enable headless mode
SiteSetting.set('headless_mode', true)

# Enable CORS
SiteSetting.set('cors_enabled', true)
SiteSetting.set('cors_origins', 'https://mysite.com, https://app.mysite.com')

# Or allow all origins (development only!)
SiteSetting.set('cors_origins', '*')
```

## API Token Management

### Creating API Tokens

1. Navigate to **Admin > System > API Tokens**
2. Click **"New API Token"**
3. Set name and role (Public, Editor, Admin)
4. Save and copy the generated token

### Token Roles & Permissions

#### Public Role
Read-only access to published content:
- ✅ Read posts, pages, categories, tags
- ✅ Read comments
- ❌ Cannot create, update, or delete

#### Editor Role  
Content management access:
- ✅ All Public permissions
- ✅ Create, update posts and pages
- ✅ Create, update categories and tags
- ✅ Manage comments
- ✅ Upload and manage media
- ❌ Cannot manage users or settings

#### Admin Role
Full access:
- ✅ All Editor permissions
- ✅ Manage users
- ✅ Update settings
- ✅ Create/execute AI agents
- ✅ Manage AI providers
- ✅ Full system access

### Using API Tokens

Include the token in your requests:

```bash
# GraphQL
curl -X POST https://your-site.com/graphql \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ posts { id title content } }"}'

# REST API
curl https://your-site.com/api/v1/posts \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## CORS Configuration

### What is CORS?

CORS (Cross-Origin Resource Sharing) allows your frontend application (running on a different domain) to access your RailsPress API.

### Configuring CORS

**Allowed Origins:**
```
https://mysite.com, https://app.mysite.com
```
Or use `*` to allow all origins (not recommended for production).

**Allowed Methods:**
```
GET, POST, PATCH, PUT, DELETE, OPTIONS
```

**Allowed Headers:**
```
*
```
Or specify: `Content-Type, Authorization, X-Requested-With`

### Testing CORS

1. Go to **Admin > System > Headless**
2. Click **"Test CORS Configuration"**
3. Verify the test passes

Or test manually:
```bash
curl -X OPTIONS https://your-site.com/api/v1/posts \
  -H "Origin: https://your-frontend.com" \
  -H "Access-Control-Request-Method: GET" \
  -v
```

## Available APIs

### GraphQL API

**Endpoint:** `POST /graphql`

**Explorer:** `/graphiql` (development)

**Example Query:**
```graphql
query {
  posts(first: 10, status: "published") {
    nodes {
      id
      title
      content
      excerpt
      slug
      publishedAt
      author {
        name
        email
      }
      categories {
        name
        slug
      }
      tags {
        name
        slug
      }
      featuredImage {
        url
        alt
      }
    }
  }
}
```

### REST API

**Base URL:** `/api/v1`

**Available Endpoints:**

| Resource | Endpoint | Methods |
|----------|----------|---------|
| Posts | `/api/v1/posts` | GET, POST, PATCH, DELETE |
| Pages | `/api/v1/pages` | GET, POST, PATCH, DELETE |
| Categories | `/api/v1/categories` | GET, POST, PATCH, DELETE |
| Tags | `/api/v1/tags` | GET, POST, PATCH, DELETE |
| Comments | `/api/v1/comments` | GET, POST, PATCH, DELETE |
| Media | `/api/v1/media` | GET, POST, DELETE |
| Users | `/api/v1/users` | GET (Admin only) |
| Menus | `/api/v1/menus` | GET |
| AI Agents | `/api/v1/ai_agents` | GET, POST, PATCH, DELETE |
| AI Providers | `/api/v1/ai_providers` | GET (Admin only) |

**Example Request:**
```bash
curl https://your-site.com/api/v1/posts?status=published&limit=10 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Frontend Framework Integration

### Next.js Example

```javascript
// lib/api.js
const RAILSPRESS_URL = process.env.NEXT_PUBLIC_RAILSPRESS_URL;
const API_TOKEN = process.env.RAILSPRESS_API_TOKEN;

export async function getPosts() {
  const response = await fetch(`${RAILSPRESS_URL}/api/v1/posts?status=published`, {
    headers: {
      'Authorization': `Bearer ${API_TOKEN}`,
      'Content-Type': 'application/json'
    }
  });
  
  return response.json();
}

export async function getPost(slug) {
  const response = await fetch(`${RAILSPRESS_URL}/api/v1/posts/${slug}`, {
    headers: {
      'Authorization': `Bearer ${API_TOKEN}`
    }
  });
  
  return response.json();
}

// pages/blog/index.js
import { getPosts } from '@/lib/api';

export async function getStaticProps() {
  const posts = await getPosts();
  
  return {
    props: { posts },
    revalidate: 60 // ISR: revalidate every 60 seconds
  };
}

export default function Blog({ posts }) {
  return (
    <div>
      <h1>Blog</h1>
      {posts.map(post => (
        <article key={post.id}>
          <h2>{post.title}</h2>
          <p>{post.excerpt}</p>
          <a href={`/blog/${post.slug}`}>Read more</a>
        </article>
      ))}
    </div>
  );
}
```

### Remix Example

```javascript
// app/lib/railspress.server.ts
const RAILSPRESS_URL = process.env.RAILSPRESS_URL;
const API_TOKEN = process.env.RAILSPRESS_API_TOKEN;

export async function getPosts() {
  const response = await fetch(`${RAILSPRESS_URL}/api/v1/posts?status=published`, {
    headers: {
      'Authorization': `Bearer ${API_TOKEN}`
    }
  });
  
  return response.json();
}

// app/routes/blog._index.tsx
import { json } from "@remix-run/node";
import { useLoaderData } from "@remix-run/react";
import { getPosts } from "~/lib/railspress.server";

export async function loader() {
  const posts = await getPosts();
  return json({ posts });
}

export default function BlogIndex() {
  const { posts } = useLoaderData<typeof loader>();
  
  return (
    <div>
      <h1>Blog</h1>
      {posts.map(post => (
        <article key={post.id}>
          <h2>{post.title}</h2>
          <p>{post.excerpt}</p>
        </article>
      ))}
    </div>
  );
}
```

### Nuxt Example

```javascript
// composables/useRailsPress.ts
export const useRailsPress = () => {
  const config = useRuntimeConfig();
  const baseURL = config.public.railspressUrl;
  const apiToken = config.public.railspressToken;
  
  const getPosts = async () => {
    const { data } = await useFetch(`${baseURL}/api/v1/posts`, {
      headers: {
        'Authorization': `Bearer ${apiToken}`
      },
      query: {
        status: 'published'
      }
    });
    
    return data.value;
  };
  
  return {
    getPosts
  };
};

// pages/blog/index.vue
<script setup>
const { getPosts } = useRailsPress();
const { data: posts } = await useAsyncData('posts', () => getPosts());
</script>

<template>
  <div>
    <h1>Blog</h1>
    <article v-for="post in posts" :key="post.id">
      <h2>{{ post.title }}</h2>
      <p>{{ post.excerpt }}</p>
    </article>
  </div>
</template>
```

### Astro Example

```javascript
// src/lib/railspress.ts
const RAILSPRESS_URL = import.meta.env.PUBLIC_RAILSPRESS_URL;
const API_TOKEN = import.meta.env.RAILSPRESS_API_TOKEN;

export async function getPosts() {
  const response = await fetch(`${RAILSPRESS_URL}/api/v1/posts?status=published`, {
    headers: {
      'Authorization': `Bearer ${API_TOKEN}`
    }
  });
  
  return response.json();
}

// src/pages/blog/index.astro
---
import { getPosts } from '@/lib/railspress';

const posts = await getPosts();
---

<html>
  <body>
    <h1>Blog</h1>
    {posts.map(post => (
      <article>
        <h2>{post.title}</h2>
        <p>{post.excerpt}</p>
        <a href={`/blog/${post.slug}`}>Read more</a>
      </article>
    ))}
  </body>
</html>
```

## Security Best Practices

### 1. Use Environment Variables
Never commit API tokens to your repository:

```bash
# .env
RAILSPRESS_URL=https://api.mysite.com
RAILSPRESS_API_TOKEN=your_token_here
```

### 2. Restrict CORS Origins
In production, never use `*`:

```
# Good
https://mysite.com, https://app.mysite.com

# Bad (in production)
*
```

### 3. Use HTTPS
Always use HTTPS in production for API requests.

### 4. Set Token Expiration
Create tokens with expiration dates for enhanced security.

### 5. Regenerate Tokens Regularly
Periodically regenerate tokens, especially if compromised.

### 6. Use Minimal Permissions
Create tokens with the minimum required permissions.

## Monitoring & Analytics

### Track API Usage

View API token usage in **Admin > System > API Tokens**:
- Last used timestamp
- Request count (if implemented)
- Active status

### Rate Limiting

Rate limiting is automatically applied based on role:
- Public: 100 requests/minute
- Editor: 500 requests/minute
- Admin: 1000 requests/minute

## Troubleshooting

### CORS Errors

**Error:** "No 'Access-Control-Allow-Origin' header"

**Solutions:**
1. Enable CORS in **Admin > System > Headless**
2. Add your frontend domain to allowed origins
3. Restart your Rails server
4. Test with the "Test CORS" button

### 401 Unauthorized

**Error:** "Authentication required"

**Solutions:**
1. Verify token is included in headers
2. Check token is active and not expired
3. Ensure token has correct permissions
4. Regenerate token if necessary

### 403 Forbidden

**Error:** "Permission denied"

**Solutions:**
1. Check token role has required permissions
2. Verify resource access level
3. Use a token with higher permissions

## Advanced Usage

### Custom Permissions

Administrators can set custom permissions per token:

```ruby
token = ApiToken.find(id)
token.update(permissions: {
  'posts' => ['read', 'create', 'update'],
  'pages' => ['read'],
  'ai_agents' => ['execute']
})
```

### Programmatic Token Creation

```ruby
# Create a public token
token = current_user.api_tokens.create!(
  name: 'My Frontend App',
  role: 'public',
  expires_at: 1.year.from_now
)

puts "Token: #{token.token}"
```

### GraphQL with Variables

```graphql
query GetPost($slug: String!) {
  post(slug: $slug) {
    id
    title
    content
    publishedAt
    author {
      name
      bio
    }
  }
}
```

```javascript
const response = await fetch('https://api.mysite.com/graphql', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    query: QUERY,
    variables: { slug: 'my-post' }
  })
});
```

## Benefits of Headless Mode

### For Developers
- ✅ Use any frontend framework
- ✅ Complete API access
- ✅ GraphQL flexibility
- ✅ Modern development workflow
- ✅ Deploy frontend separately

### For Performance
- ✅ Static site generation (SSG)
- ✅ Incremental static regeneration (ISR)
- ✅ Edge caching
- ✅ CDN distribution
- ✅ Faster page loads

### For Scalability
- ✅ Separate frontend and backend
- ✅ Multiple frontends from one CMS
- ✅ Mobile apps, web apps, etc.
- ✅ Independent scaling
- ✅ Microservices architecture

---

**See Also:**
- [API Quick Start](../api/QUICK_START.md)
- [GraphQL Guide](../api/graphql-guide.md)
- [AI Agents Integration](../plugins/AI_AGENTS_INTEGRATION.md)

**Status:** Production Ready  
**Version:** 1.0  
**Last Updated:** October 12, 2025





