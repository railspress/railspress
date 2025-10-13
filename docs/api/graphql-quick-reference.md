# GraphQL API Quick Reference

**One-page cheat sheet for RailsPress GraphQL API**

---

## 🚀 Getting Started

```bash
# Development playground
http://localhost:3000/graphiql

# Production endpoint
POST http://localhost:3000/graphql
```

---

## 📋 Quick Queries

### Posts

```graphql
# List posts
{ posts { id title slug } }

# Published posts only
{ publishedPosts(limit: 10) { id title publishedAt } }

# Get single post
{ post(slug: "my-post") { id title contentHtml } }

# Filter by category
{ posts(categorySlug: "tech") { title } }

# Filter by tag
{ posts(tagSlug: "rails") { title } }
```

### Pages

```graphql
# List pages
{ pages { id title slug } }

# Get single page
{ page(slug: "about") { id title contentHtml } }

# Root pages only
{ rootPages { id title children { title } } }
```

### Users

```graphql
# List users
{ users { id email role } }

# Get user
{ user(id: "1") { email postCount } }

# Current user
{ currentUser { email role } }

# Filter by role
{ users(role: "administrator") { email } }
```

### Taxonomies

```graphql
# List taxonomies
{ taxonomies { id name slug termCount } }

# Get taxonomy with terms
{
  taxonomy(slug: "topics") {
    name
    terms { name slug count }
  }
}

# Get term
{
  term(id: "1") {
    name
    posts { title }
  }
}
```

### Categories

```graphql
# List categories
{ categories { id name slug postCount } }

# Get category
{ category(slug: "tech") { name posts { title } } }

# Root categories
{ rootCategories { name children { name } } }
```

### Tags

```graphql
# List tags
{ tags { id name slug postCount } }

# Get tag
{ tag(slug: "rails") { name posts { title } } }
```

### Comments

```graphql
# List comments
{ comments { id content authorName } }

# Post comments
{ comments(postId: "1") { content createdAt } }

# With replies
{
  comments {
    content
    replies { content authorName }
  }
}
```

### Search

```graphql
{
  search(query: "rails") {
    total
    posts { title }
    pages { title }
  }
}
```

---

## 🎯 Common Patterns

### With Variables

```graphql
query GetPost($slug: String!) {
  post(slug: $slug) {
    id
    title
  }
}
```

Variables:
```json
{ "slug": "my-post" }
```

### With Fragments

```graphql
fragment PostCard on Post {
  id
  title
  slug
  excerpt
  publishedAt
}

query {
  publishedPosts { ...PostCard }
  posts(categorySlug: "tech") { ...PostCard }
}
```

### With Aliases

```graphql
query {
  tech: posts(categorySlug: "technology") { title }
  design: posts(categorySlug: "design") { title }
}
```

---

## 🌐 cURL Examples

### Basic Query

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ posts { id title } }"}'
```

### With Variables

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query($slug: String!) { post(slug: $slug) { title } }",
    "variables": {"slug": "my-post"}
  }'
```

---

## ⚡ Tips

1. ✅ **Use GraphiQL** at `/graphiql`
2. ✅ **Use Variables** - Don't hardcode
3. ✅ **Use Fragments** - DRY code
4. ✅ **Specify Limits** - Avoid over-fetching
5. ✅ **Use Aliases** - Multiple queries
6. ✅ **Check Depth** - Max 15 levels

---

**Full docs**: `GRAPHQL_API_GUIDE.md`

*RailsPress GraphQL API v1.0.0*

