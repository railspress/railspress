

# RailsPress GraphQL API Guide

**Modern GraphQL API for Posts, Pages, Users, and Taxonomies**

---

## 📚 Table of Contents

- [Introduction](#introduction)
- [Quick Start](#quick-start)
- [Schema Overview](#schema-overview)
- [Queries](#queries)
- [Mutations](#mutations)
- [Examples](#examples)
- [Authentication](#authentication)
- [Best Practices](#best-practices)

---

## Introduction

RailsPress provides a powerful GraphQL API as an alternative to the REST API. GraphQL allows you to:

- ✅ **Request exactly what you need** - No over-fetching
- ✅ **Get multiple resources in one request** - Efficient batching
- ✅ **Strongly typed** - Built-in validation and documentation
- ✅ **Introspection** - Self-documenting API
- ✅ **Real-time updates** - Subscription support (future)

---

## Quick Start

### GraphiQL Playground (Development)

Visit **http://localhost:3000/graphiql** for an interactive GraphQL IDE.

### Basic Query

```graphql
query {
  posts(limit: 5) {
    id
    title
    slug
    excerpt
    publishedAt
    author {
      email
      role
    }
    categories {
      name
      slug
    }
  }
}
```

### cURL Example

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ posts { id title } }"}'
```

---

## Schema Overview

### Available Types

```graphql
type Post { ... }
type Page { ... }
type User { ... }
type Taxonomy { ... }
type Term { ... }
type Category { ... }
type Tag { ... }
type Comment { ... }
type SearchResults { ... }
```

### Root Query

```graphql
type Query {
  # Posts
  posts(...): [Post!]!
  post(...): Post
  publishedPosts(...): [Post!]!
  
  # Pages
  pages(...): [Page!]!
  page(...): Page
  rootPages: [Page!]!
  
  # Users
  users(...): [User!]!
  user(...): User
  currentUser: User
  
  # Taxonomies
  taxonomies: [Taxonomy!]!
  taxonomy(...): Taxonomy
  
  # Terms
  terms(...): [Term!]!
  term(...): Term
  
  # Categories
  categories(...): [Category!]!
  category(...): Category
  rootCategories: [Category!]!
  
  # Tags
  tags(...): [Tag!]!
  tag(...): Tag
  
  # Comments
  comments(...): [Comment!]!
  comment(...): Comment
  
  # Search
  search(...): SearchResults!
}
```

---

## Queries

### Posts

#### List All Posts

```graphql
query {
  posts {
    id
    title
    slug
    excerpt
    status
    publishedAt
  }
}
```

#### Filter by Status

```graphql
query {
  posts(status: "published", limit: 10) {
    id
    title
    publishedAt
  }
}
```

#### Filter by Category

```graphql
query {
  posts(categorySlug: "technology") {
    id
    title
    categories {
      name
    }
  }
}
```

#### Get Single Post

```graphql
query {
  post(slug: "my-post-slug") {
    id
    title
    contentHtml
    author {
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
    comments {
      content
      authorName
      createdAt
    }
  }
}
```

#### Get Post with Related Content

```graphql
query {
  post(id: "1") {
    id
    title
    categories {
      name
      posts(limit: 5) {
        id
        title
        slug
      }
    }
  }
}
```

---

### Pages

#### List All Pages

```graphql
query {
  pages {
    id
    title
    slug
    status
  }
}
```

#### Get Page with Hierarchy

```graphql
query {
  page(slug: "about") {
    id
    title
    contentHtml
    parent {
      title
      slug
    }
    children {
      title
      slug
    }
    ancestors {
      title
      slug
    }
  }
}
```

#### Root Pages Only

```graphql
query {
  rootPages {
    id
    title
    slug
    children {
      title
      slug
    }
  }
}
```

---

### Users

#### List Users

```graphql
query {
  users {
    id
    email
    role
    postCount
    pageCount
  }
}
```

#### Filter by Role

```graphql
query {
  users(role: "administrator") {
    id
    email
    createdAt
  }
}
```

#### Get User with Content

```graphql
query {
  user(id: "1") {
    id
    email
    role
    posts(status: "published", limit: 10) {
      id
      title
      publishedAt
    }
    pages {
      id
      title
    }
  }
}
```

#### Get Current User

```graphql
query {
  currentUser {
    id
    email
    role
    isAdmin
  }
}
```

---

### Taxonomies & Terms

#### List All Taxonomies

```graphql
query {
  taxonomies {
    id
    name
    slug
    description
    hierarchical
    termCount
  }
}
```

#### Get Taxonomy with Terms

```graphql
query {
  taxonomy(slug: "topics") {
    id
    name
    description
    terms {
      id
      name
      slug
      description
      count
    }
  }
}
```

#### Get Term with Content

```graphql
query {
  term(id: "1") {
    id
    name
    slug
    taxonomy {
      name
      slug
    }
    posts(limit: 10) {
      id
      title
      publishedAt
    }
    children {
      name
      slug
    }
  }
}
```

#### List Terms for a Taxonomy

```graphql
query {
  terms(taxonomySlug: "post-formats") {
    id
    name
    slug
    count
  }
}
```

---

### Categories

#### List Categories

```graphql
query {
  categories {
    id
    name
    slug
    description
    postCount
  }
}
```

#### Get Category Hierarchy

```graphql
query {
  category(slug: "technology") {
    id
    name
    parent {
      name
      slug
    }
    children {
      name
      slug
      postCount
    }
    posts(limit: 10) {
      title
      publishedAt
    }
  }
}
```

#### Root Categories

```graphql
query {
  rootCategories {
    id
    name
    slug
    children {
      name
      slug
    }
  }
}
```

---

### Tags

#### List All Tags

```graphql
query {
  tags(limit: 20) {
    id
    name
    slug
    postCount
  }
}
```

#### Get Tag with Posts

```graphql
query {
  tag(slug: "rails") {
    id
    name
    slug
    posts(limit: 10) {
      title
      publishedAt
    }
  }
}
```

---

### Comments

#### List Comments

```graphql
query {
  comments(limit: 10) {
    id
    content
    authorName
    authorEmail
    status
    createdAt
  }
}
```

#### Comments for a Post

```graphql
query {
  comments(postId: "1") {
    id
    content
    authorName
    createdAt
    replies {
      content
      authorName
      createdAt
    }
  }
}
```

#### Get Comment with Context

```graphql
query {
  comment(id: "1") {
    id
    content
    authorName
    post {
      title
      slug
    }
    parent {
      content
      authorName
    }
    replies {
      content
      authorName
    }
  }
}
```

---

### Search

#### Search Across Content

```graphql
query {
  search(query: "rails graphql", limit: 20) {
    total
    posts {
      id
      title
      excerpt
      url
    }
    pages {
      id
      title
      url
    }
  }
}
```

---

## Complex Queries

### Blog Homepage Data

```graphql
query BlogHomepage {
  publishedPosts(limit: 6) {
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
    readingTime
  }
  
  rootCategories {
    name
    slug
    postCount
  }
  
  tags(limit: 10) {
    name
    slug
    postCount
  }
}
```

### Post Detail Page

```graphql
query PostDetail($slug: String!) {
  post(slug: $slug) {
    id
    title
    contentHtml
    publishedAt
    readingTime
    
    author {
      email
      posts(status: "published", limit: 3) {
        id
        title
        slug
      }
    }
    
    categories {
      name
      slug
      posts(limit: 5) {
        id
        title
        slug
      }
    }
    
    tags {
      name
      slug
    }
    
    comments(status: "approved") {
      id
      content
      authorName
      createdAt
      replies {
        content
        authorName
        createdAt
      }
    }
  }
}
```

Variables:
```json
{
  "slug": "my-post-slug"
}
```

### User Profile

```graphql
query UserProfile($userId: ID!) {
  user(id: $userId) {
    id
    email
    role
    postCount
    pageCount
    
    posts(status: "published", limit: 10) {
      id
      title
      slug
      publishedAt
      commentCount
    }
    
    pages(status: "published") {
      id
      title
      slug
    }
  }
}
```

### Taxonomy Browser

```graphql
query TaxonomyBrowser {
  taxonomies {
    id
    name
    slug
    description
    hierarchical
    termCount
    
    terms(limit: 20) {
      id
      name
      slug
      count
      children {
        name
        slug
        count
      }
    }
  }
}
```

---

## Mutations

Coming soon! Mutations will allow you to:
- Create/update/delete posts
- Create/update/delete pages
- Create/update/delete comments
- Manage taxonomies and terms

---

## Authentication

### Using Session (Devise)

If you're logged in via the web interface, GraphQL queries will automatically use your session:

```graphql
query {
  currentUser {
    id
    email
    role
  }
}
```

### Using API Token (Future)

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -d '{"query": "{ currentUser { email } }"}'
```

---

## Pagination

### Using Limits and Offsets

```graphql
query {
  posts(limit: 10, offset: 20) {
    id
    title
  }
}
```

### Relay-Style Connections (Future)

```graphql
query {
  posts(first: 10, after: "cursor") {
    edges {
      node {
        id
        title
      }
      cursor
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

---

## Error Handling

### Query Errors

```json
{
  "errors": [
    {
      "message": "Post not found",
      "locations": [{"line": 2, "column": 3}],
      "path": ["post"]
    }
  ],
  "data": {
    "post": null
  }
}
```

### Validation Errors

```json
{
  "errors": [
    {
      "message": "Title can't be blank",
      "extensions": {
        "code": "VALIDATION_ERROR"
      }
    }
  ]
}
```

---

## Best Practices

### 1. Request Only What You Need

❌ **Don't:**
```graphql
query {
  posts {
    id
    title
    contentHtml  # Large field
    author {
      id
      email
      posts {  # N+1 query
        id
        title
      }
    }
  }
}
```

✅ **Do:**
```graphql
query {
  posts(limit: 10) {
    id
    title
    excerpt  # Smaller field
    author {
      email
    }
  }
}
```

### 2. Use Variables

❌ **Don't:**
```graphql
query {
  post(slug: "my-hardcoded-slug") {
    title
  }
}
```

✅ **Do:**
```graphql
query GetPost($slug: String!) {
  post(slug: $slug) {
    title
  }
}
```

### 3. Use Fragments

```graphql
fragment PostFields on Post {
  id
  title
  slug
  excerpt
  publishedAt
}

query {
  publishedPosts(limit: 5) {
    ...PostFields
  }
  
  posts(categorySlug: "tech", limit: 5) {
    ...PostFields
  }
}
```

### 4. Leverage Aliases

```graphql
query {
  techPosts: posts(categorySlug: "technology", limit: 5) {
    title
  }
  
  railsPosts: posts(tagSlug: "rails", limit: 5) {
    title
  }
}
```

---

## JavaScript Client Examples

### Using Fetch

```javascript
async function fetchPosts() {
  const response = await fetch('http://localhost:3000/graphql', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      query: `
        query {
          posts(limit: 10) {
            id
            title
            slug
            excerpt
          }
        }
      `
    })
  });
  
  const data = await response.json();
  return data.data.posts;
}
```

### Using Apollo Client

```javascript
import { ApolloClient, InMemoryCache, gql } from '@apollo/client';

const client = new ApolloClient({
  uri: 'http://localhost:3000/graphql',
  cache: new InMemoryCache()
});

const GET_POSTS = gql`
  query GetPosts($limit: Int!) {
    posts(limit: $limit) {
      id
      title
      slug
      excerpt
      publishedAt
    }
  }
`;

const { data } = await client.query({
  query: GET_POSTS,
  variables: { limit: 10 }
});
```

### Using urql

```javascript
import { createClient } from 'urql';

const client = createClient({
  url: 'http://localhost:3000/graphql',
});

const result = await client.query(`
  query {
    posts {
      id
      title
    }
  }
`).toPromise();
```

---

## Advanced Queries

### Nested Relationships

```graphql
query {
  categories {
    name
    posts(limit: 3) {
      title
      author {
        email
        posts(limit: 2) {
          title
        }
      }
      comments {
        content
        replies {
          content
        }
      }
    }
  }
}
```

### Multiple Queries

```graphql
query Dashboard {
  recentPosts: posts(status: "published", limit: 5) {
    id
    title
    publishedAt
  }
  
  draftPosts: posts(status: "draft", limit: 5) {
    id
    title
    createdAt
  }
  
  rootPages: rootPages {
    id
    title
  }
  
  currentUser {
    email
    role
  }
}
```

### Computed Fields

```graphql
query {
  posts {
    title
    readingTime  # Computed field
    commentCount  # Count aggregation
    url  # Generated URL
    permalink  # Alias for URL
  }
}
```

---

## Performance Tips

### 1. Use Limits

Always specify limits to avoid loading too much data:

```graphql
query {
  posts(limit: 20) { ... }
  comments(limit: 50) { ... }
}
```

### 2. Avoid Deep Nesting

GraphQL has a max depth of 15. Avoid queries like:

```graphql
# Too deep!
query {
  posts {
    comments {
      user {
        posts {
          comments {
            user {
              # ...
            }
          }
        }
      }
    }
  }
}
```

### 3. Use DataLoader (Future)

For N+1 query prevention, we'll add DataLoader:

```ruby
# Future implementation
class Sources::PostSource < GraphQL::Dataloader::Source
  def fetch(ids)
    Post.where(id: ids).index_by(&:id).values_at(*ids)
  end
end
```

---

## Introspection

### Get Schema

```graphql
query {
  __schema {
    types {
      name
      description
    }
  }
}
```

### Get Type Info

```graphql
query {
  __type(name: "Post") {
    name
    description
    fields {
      name
      type {
        name
        kind
      }
    }
  }
}
```

---

## Testing

### RSpec Example

```ruby
RSpec.describe 'GraphQL Queries' do
  describe 'posts query' do
    it 'returns published posts' do
      create_list(:post, 5, status: 'published')
      
      query = <<~GQL
        query {
          posts {
            id
            title
            status
          }
        }
      GQL
      
      result = RailspressSchema.execute(query)
      
      expect(result['errors']).to be_nil
      expect(result['data']['posts'].length).to eq(5)
    end
  end
end
```

---

## GraphQL vs REST API

### When to Use GraphQL

✅ **Use GraphQL when:**
- You need nested relationships
- You want to minimize requests
- You need flexible queries
- You're building a SPA/mobile app
- You want type safety

### When to Use REST

✅ **Use REST when:**
- You need simple CRUD operations
- You want HTTP caching
- You prefer standard HTTP methods
- You're integrating with legacy systems

---

## Tooling

### GraphiQL (Built-in)

Visit `/graphiql` in development for:
- Interactive query editor
- Auto-completion
- Documentation browser
- Query history

### GraphQL Playground

Alternative to GraphiQL:

```ruby
# Gemfile
gem 'graphql-playground'

# routes.rb
mount GraphqlPlayground::Rails::Engine, at: "/playground", graphql_path: "/graphql"
```

### GraphQL Code Generator

Generate TypeScript types:

```bash
npm install --save-dev @graphql-codegen/cli
npx graphql-codegen init
```

---

## Security

### Query Complexity

Queries are limited to:
- **Max Depth**: 15 levels
- **Max Complexity**: 300 points

### Rate Limiting

GraphQL endpoint is rate-limited via Rack::Attack:

```ruby
# 100 requests per minute per IP
throttle('graphql/ip', limit: 100, period: 1.minute)
```

### Field-Level Authorization

Coming soon:
```ruby
field :email, String, null: false do
  authorize :read, :user
end
```

---

## Monitoring

### Query Logging

All GraphQL queries are logged:

```ruby
# config/initializers/graphql.rb
RailspressSchema.subscribe RailspressSchema::Logging.new
```

### Performance Monitoring

Use tools like:
- AppSignal
- New Relic
- Scout APM

To monitor GraphQL query performance.

---

## Common Errors

### "Field doesn't exist on type"

❌ **Error:**
```graphql
query {
  posts {
    invalidField  # Error!
  }
}
```

✅ **Fix:** Check available fields via introspection or documentation.

### "Variable is required"

❌ **Error:**
```graphql
query GetPost($slug: String!) {
  post(slug: $slug) {
    title
  }
}
# Missing variables!
```

✅ **Fix:** Provide variables in request:
```json
{
  "query": "query GetPost($slug: String!) { ... }",
  "variables": { "slug": "my-post" }
}
```

---

## Roadmap

### Coming Soon

- [ ] Mutations for CRUD operations
- [ ] Subscriptions for real-time updates
- [ ] DataLoader for N+1 prevention
- [ ] Field-level authorization with Pundit
- [ ] File uploads via GraphQL
- [ ] Cursor-based pagination
- [ ] Custom scalar types
- [ ] Query batching
- [ ] Persisted queries

---

## Resources

- **GraphiQL**: http://localhost:3000/graphiql
- **GraphQL Official**: https://graphql.org/
- **graphql-ruby**: https://graphql-ruby.org/
- **Apollo Client**: https://www.apollographql.com/

---

## Examples Repository

### Complete Query Examples

See `/examples/graphql/` for:
- Complete query examples
- JavaScript client examples
- React hooks examples
- TypeScript integration

---

**Version**: 1.0.0  
**Last Updated**: October 2025  
**Status**: Production Ready

---

*Happy querying with GraphQL! 🚀*



