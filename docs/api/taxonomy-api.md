# Taxonomy API - Complete Guide

## Overview

RailsPress provides comprehensive REST and GraphQL APIs for managing custom taxonomies and terms. This guide covers both APIs in detail.

---

## Table of Contents

1. [REST API](#rest-api)
   - [Taxonomies Endpoints](#taxonomies-endpoints)
   - [Terms Endpoints](#terms-endpoints)
   - [Examples](#rest-api-examples)
2. [GraphQL API](#graphql-api)
   - [Queries](#graphql-queries)
   - [Mutations](#graphql-mutations)
   - [Examples](#graphql-examples)
3. [Authentication](#authentication)
4. [Response Formats](#response-formats)
5. [Error Handling](#error-handling)
6. [Best Practices](#best-practices)

---

## REST API

Base URL: `https://yoursite.com/api/v1`

### Authentication

All write operations require authentication. Include your API token in the header:

```
Authorization: Bearer YOUR_API_TOKEN
```

Public read operations (index, show) do not require authentication.

---

## Taxonomies Endpoints

### List All Taxonomies

**GET** `/api/v1/taxonomies`

**Query Parameters:**
- `object_type` (string, optional) - Filter by object type (e.g., "Post", "Page")
- `type` (string, optional) - Filter by structure: "hierarchical" or "flat"
- `page` (integer, optional) - Page number for pagination
- `per_page` (integer, optional) - Results per page (default: 20)

**Example Request:**
```bash
curl https://yoursite.com/api/v1/taxonomies?object_type=Post
```

**Example Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Topics",
      "slug": "topic",
      "description": "Main content topics and subjects",
      "hierarchical": true,
      "object_types": ["Post"],
      "term_count": 12
    },
    {
      "id": 2,
      "name": "Post Formats",
      "slug": "format",
      "description": "Content format types",
      "hierarchical": false,
      "object_types": ["Post"],
      "term_count": 6
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total_pages": 1,
    "total_count": 2
  }
}
```

---

### Get Single Taxonomy

**GET** `/api/v1/taxonomies/:id`

**Parameters:**
- `:id` - Taxonomy ID or slug

**Example Request:**
```bash
curl https://yoursite.com/api/v1/taxonomies/topic
```

**Example Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Topics",
    "slug": "topic",
    "description": "Main content topics and subjects",
    "hierarchical": true,
    "object_types": ["Post"],
    "term_count": 12,
    "terms": [
      {
        "id": 1,
        "name": "Technology",
        "slug": "technology",
        "description": "Tech-related content",
        "count": 5,
        "parent_id": null,
        "parent": null,
        "children_count": 2
      }
    ],
    "settings": {}
  }
}
```

---

### Get Taxonomy Terms

**GET** `/api/v1/taxonomies/:id/terms`

**Parameters:**
- `:id` - Taxonomy ID or slug

**Query Parameters:**
- `root_only` (boolean, optional) - Only return root-level terms
- `page` (integer, optional) - Page number
- `per_page` (integer, optional) - Results per page

**Example Request:**
```bash
curl https://yoursite.com/api/v1/taxonomies/topic/terms?root_only=true
```

**Example Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Technology",
      "slug": "technology",
      "description": "Tech-related content",
      "count": 5,
      "parent_id": null,
      "parent": null,
      "children_count": 2
    },
    {
      "id": 4,
      "name": "Design",
      "slug": "design",
      "description": "Design-related content",
      "count": 3,
      "parent_id": null,
      "parent": null,
      "children_count": 2
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total_pages": 1,
    "total_count": 2
  }
}
```

---

### Create Taxonomy

**POST** `/api/v1/taxonomies`

**Authentication:** Required (Administrator only)

**Request Body:**
```json
{
  "taxonomy": {
    "name": "Industries",
    "slug": "industry",
    "description": "Business industries",
    "hierarchical": true,
    "object_types": ["Post", "Page"],
    "settings": {
      "show_in_menu": true,
      "icon": "briefcase"
    }
  }
}
```

**Example Response:**
```json
{
  "success": true,
  "data": {
    "id": 3,
    "name": "Industries",
    "slug": "industry",
    "description": "Business industries",
    "hierarchical": true,
    "object_types": ["Post", "Page"],
    "term_count": 0
  }
}
```

---

### Update Taxonomy

**PATCH/PUT** `/api/v1/taxonomies/:id`

**Authentication:** Required (Administrator only)

**Request Body:**
```json
{
  "taxonomy": {
    "name": "Business Industries",
    "description": "Industries and business sectors"
  }
}
```

---

### Delete Taxonomy

**DELETE** `/api/v1/taxonomies/:id`

**Authentication:** Required (Administrator only)

**Example Response:**
```json
{
  "success": true,
  "data": {
    "message": "Taxonomy deleted successfully"
  }
}
```

---

## Terms Endpoints

### List All Terms

**GET** `/api/v1/terms`

**Query Parameters:**
- `taxonomy` (string, optional) - Filter by taxonomy slug
- `q` (string, optional) - Search term names
- `page` (integer, optional) - Page number
- `per_page` (integer, optional) - Results per page

**Example Request:**
```bash
curl https://yoursite.com/api/v1/terms?taxonomy=topic
```

**Example Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Technology",
      "slug": "technology",
      "description": "Tech-related content",
      "count": 5,
      "taxonomy": {
        "id": 1,
        "name": "Topics",
        "slug": "topic"
      },
      "parent": null,
      "children_count": 2
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total_pages": 1,
    "total_count": 1
  }
}
```

---

### Get Single Term

**GET** `/api/v1/terms/:id`

**Parameters:**
- `:id` - Term ID or slug

**Example Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Technology",
    "slug": "technology",
    "description": "Tech-related content",
    "count": 5,
    "taxonomy": {
      "id": 1,
      "name": "Topics",
      "slug": "topic"
    },
    "parent": null,
    "children_count": 2,
    "children": [
      {
        "id": 2,
        "name": "Web Development",
        "slug": "web-development"
      },
      {
        "id": 3,
        "name": "Mobile Apps",
        "slug": "mobile-apps"
      }
    ],
    "breadcrumbs": [
      {
        "id": 1,
        "name": "Technology",
        "slug": "technology"
      }
    ],
    "metadata": {}
  }
}
```

---

### Create Term

**POST** `/api/v1/taxonomies/:taxonomy_id/terms`

**Authentication:** Required (Editor or Administrator)

**Request Body:**
```json
{
  "term": {
    "name": "Artificial Intelligence",
    "slug": "artificial-intelligence",
    "description": "AI and machine learning",
    "parent_id": 1,
    "metadata": {
      "icon": "cpu",
      "color": "#4F46E5"
    }
  }
}
```

**Example Response:**
```json
{
  "success": true,
  "data": {
    "id": 5,
    "name": "Artificial Intelligence",
    "slug": "artificial-intelligence",
    "description": "AI and machine learning",
    "count": 0,
    "taxonomy": {
      "id": 1,
      "name": "Topics",
      "slug": "topic"
    },
    "parent": {
      "id": 1,
      "name": "Technology",
      "slug": "technology"
    },
    "children_count": 0
  }
}
```

---

### Update Term

**PATCH/PUT** `/api/v1/taxonomies/:taxonomy_id/terms/:id`

**Authentication:** Required (Editor or Administrator)

**Request Body:**
```json
{
  "term": {
    "name": "AI & Machine Learning",
    "description": "Artificial Intelligence and ML topics"
  }
}
```

---

### Delete Term

**DELETE** `/api/v1/taxonomies/:taxonomy_id/terms/:id`

**Authentication:** Required (Administrator only)

**Example Response:**
```json
{
  "success": true,
  "data": {
    "message": "Term deleted successfully"
  }
}
```

---

## REST API Examples

### cURL Examples

#### Get All Taxonomies
```bash
curl -X GET https://yoursite.com/api/v1/taxonomies
```

#### Create a Taxonomy
```bash
curl -X POST https://yoursite.com/api/v1/taxonomies \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "taxonomy": {
      "name": "Locations",
      "slug": "location",
      "hierarchical": true,
      "object_types": ["Post"]
    }
  }'
```

#### Create a Term
```bash
curl -X POST https://yoursite.com/api/v1/taxonomies/topic/terms \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "term": {
      "name": "Cloud Computing",
      "slug": "cloud-computing",
      "parent_id": 1
    }
  }'
```

### JavaScript Examples

#### Fetch Taxonomies
```javascript
fetch('https://yoursite.com/api/v1/taxonomies')
  .then(response => response.json())
  .then(data => {
    console.log('Taxonomies:', data.data);
  });
```

#### Create Term with Authentication
```javascript
const createTerm = async (taxonomyId, termData) => {
  const response = await fetch(
    `https://yoursite.com/api/v1/taxonomies/${taxonomyId}/terms`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ term: termData })
    }
  );
  
  return await response.json();
};

// Usage
createTerm('topic', {
  name: 'Blockchain',
  slug: 'blockchain',
  parent_id: 1
}).then(result => {
  console.log('Created term:', result.data);
});
```

---

## GraphQL API

GraphQL endpoint: `https://yoursite.com/graphql`

GraphiQL playground: `https://yoursite.com/graphiql` (development only)

---

## GraphQL Queries

### Get All Taxonomies

```graphql
query GetTaxonomies {
  taxonomies {
    id
    name
    slug
    description
    hierarchical
    objectTypes
    termCount
    createdAt
    updatedAt
  }
}
```

### Get Single Taxonomy with Terms

```graphql
query GetTaxonomy($slug: String!) {
  taxonomy(slug: $slug) {
    id
    name
    slug
    description
    hierarchical
    objectTypes
    termCount
    terms {
      id
      name
      slug
      description
      count
      parent {
        id
        name
      }
      children {
        id
        name
      }
    }
  }
}
```

**Variables:**
```json
{
  "slug": "topic"
}
```

### Get Taxonomy with Nested Terms

```graphql
query GetTaxonomyWithNestedTerms($slug: String!) {
  taxonomy(slug: $slug) {
    id
    name
    slug
    hierarchical
    terms {
      id
      name
      slug
      count
      children {
        id
        name
        slug
        count
        children {
          id
          name
          slug
          count
        }
      }
    }
  }
}
```

### Get All Terms

```graphql
query GetTerms($taxonomySlug: String, $limit: Int) {
  terms(taxonomySlug: $taxonomySlug, limit: $limit) {
    id
    name
    slug
    description
    count
    taxonomy {
      id
      name
      slug
    }
    parent {
      id
      name
    }
  }
}
```

**Variables:**
```json
{
  "taxonomySlug": "topic",
  "limit": 10
}
```

### Get Term with Associated Content

```graphql
query GetTermWithContent($id: ID!) {
  term(id: $id) {
    id
    name
    slug
    description
    count
    taxonomy {
      id
      name
    }
    parent {
      id
      name
    }
    children {
      id
      name
      slug
    }
    posts(limit: 5) {
      id
      title
      slug
      excerpt
      publishedAt
    }
    pages(limit: 5) {
      id
      title
      slug
    }
  }
}
```

**Variables:**
```json
{
  "id": "1"
}
```

### Get Posts by Taxonomy Term

```graphql
query GetPostsByTerm($termId: ID!) {
  term(id: $termId) {
    name
    posts {
      id
      title
      slug
      excerpt
      publishedAt
      user {
        name
        email
      }
      categories {
        name
      }
      tags {
        name
      }
    }
  }
}
```

---

## GraphQL Mutations

GraphQL mutations are currently in development. Use the REST API for write operations.

---

## GraphQL Examples

### JavaScript with fetch

```javascript
const query = `
  query GetTaxonomy($slug: String!) {
    taxonomy(slug: $slug) {
      id
      name
      terms {
        id
        name
        count
      }
    }
  }
`;

fetch('https://yoursite.com/graphql', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    query: query,
    variables: { slug: 'topic' }
  })
})
.then(res => res.json())
.then(data => {
  console.log('Taxonomy:', data.data.taxonomy);
});
```

### Apollo Client

```javascript
import { gql, useQuery } from '@apollo/client';

const GET_TAXONOMY = gql`
  query GetTaxonomy($slug: String!) {
    taxonomy(slug: $slug) {
      id
      name
      slug
      terms {
        id
        name
        count
        children {
          id
          name
        }
      }
    }
  }
`;

function TaxonomyView({ slug }) {
  const { loading, error, data } = useQuery(GET_TAXONOMY, {
    variables: { slug }
  });

  if (loading) return <p>Loading...</p>;
  if (error) return <p>Error: {error.message}</p>;

  return (
    <div>
      <h1>{data.taxonomy.name}</h1>
      <ul>
        {data.taxonomy.terms.map(term => (
          <li key={term.id}>
            {term.name} ({term.count})
          </li>
        ))}
      </ul>
    </div>
  );
}
```

### urql

```javascript
import { useQuery } from 'urql';

const TaxonomiesQuery = `
  query {
    taxonomies {
      id
      name
      slug
      termCount
    }
  }
`;

const TaxonomiesList = () => {
  const [result] = useQuery({ query: TaxonomiesQuery });

  if (result.fetching) return <p>Loading...</p>;
  if (result.error) return <p>Error: {result.error.message}</p>;

  return (
    <ul>
      {result.data.taxonomies.map(taxonomy => (
        <li key={taxonomy.id}>
          {taxonomy.name} ({taxonomy.termCount} terms)
        </li>
      ))}
    </ul>
  );
};
```

---

## Authentication

### REST API Authentication

#### Get API Token

1. Navigate to your profile in the admin panel
2. Go to Security settings
3. Copy your API token or generate a new one

#### Use Token in Requests

```bash
curl -H "Authorization: Bearer YOUR_API_TOKEN" \
     https://yoursite.com/api/v1/taxonomies
```

### GraphQL Authentication

Pass the token in the Authorization header:

```javascript
fetch('https://yoursite.com/graphql', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${apiToken}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ query: yourQuery })
});
```

---

## Response Formats

### Success Response (REST)

```json
{
  "success": true,
  "data": { /* ... response data ... */ },
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total_pages": 5,
    "total_count": 100
  }
}
```

### Error Response (REST)

```json
{
  "success": false,
  "error": "Taxonomy not found",
  "code": 404
}
```

### GraphQL Response

**Success:**
```json
{
  "data": {
    "taxonomy": {
      "id": "1",
      "name": "Topics"
    }
  }
}
```

**Error:**
```json
{
  "errors": [
    {
      "message": "Taxonomy not found",
      "locations": [{ "line": 2, "column": 3 }],
      "path": ["taxonomy"]
    }
  ],
  "data": null
}
```

---

## Error Handling

### HTTP Status Codes

- `200 OK` - Successful GET/PATCH/PUT/DELETE
- `201 Created` - Successful POST
- `400 Bad Request` - Invalid request parameters
- `401 Unauthorized` - Missing or invalid authentication
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `422 Unprocessable Entity` - Validation errors
- `500 Internal Server Error` - Server error

### Common Errors

#### Validation Error (REST)

```json
{
  "success": false,
  "error": "Name can't be blank, Slug has already been taken"
}
```

#### Not Found (REST)

```json
{
  "success": false,
  "error": "Taxonomy not found",
  "code": 404
}
```

#### Permission Denied (REST)

```json
{
  "success": false,
  "error": "Only administrators can create taxonomies",
  "code": 403
}
```

---

## Best Practices

### Performance

1. **Use Pagination**
   ```bash
   GET /api/v1/taxonomies?page=1&per_page=50
   ```

2. **Request Only Needed Fields (GraphQL)**
   ```graphql
   query {
     taxonomies {
       id
       name
       # Only request what you need
     }
   }
   ```

3. **Cache Taxonomy Data**
   - Taxonomies change infrequently
   - Cache for 1-24 hours depending on needs

### Security

1. **Protect Your API Token**
   ```javascript
   // Store in environment variables
   const apiToken = process.env.RAILSPRESS_API_TOKEN;
   ```

2. **Use HTTPS**
   ```bash
   # Always use HTTPS in production
   https://yoursite.com/api/v1/taxonomies
   ```

3. **Validate Permissions**
   - Only administrators can create/delete taxonomies
   - Editors can create/update terms
   - Authors and above can read all

### Data Modeling

1. **Choose Hierarchical vs Flat**
   - Hierarchical: Categories, locations, topics with subcategories
   - Flat: Tags, formats, simple classifications

2. **Use Descriptive Names**
   ```json
   {
     "name": "Content Topics",
     "slug": "topic",
     "description": "Main categorization for all content"
   }
   ```

3. **Set Object Types**
   ```json
   {
     "object_types": ["Post", "Page"]
   }
   ```

### Integration Patterns

#### React Component

```javascript
import { useEffect, useState } from 'react';

function TaxonomySelect({ objectType, onChange }) {
  const [taxonomies, setTaxonomies] = useState([]);
  
  useEffect(() => {
    fetch(`/api/v1/taxonomies?object_type=${objectType}`)
      .then(res => res.json())
      .then(data => setTaxonomies(data.data));
  }, [objectType]);
  
  return (
    <select onChange={(e) => onChange(e.target.value)}>
      {taxonomies.map(tax => (
        <option key={tax.id} value={tax.id}>
          {tax.name}
        </option>
      ))}
    </select>
  );
}
```

#### Vue Component

```vue
<template>
  <div>
    <h2>{{ taxonomy.name }}</h2>
    <ul>
      <li v-for="term in taxonomy.terms" :key="term.id">
        {{ term.name }} ({{ term.count }})
      </li>
    </ul>
  </div>
</template>

<script>
export default {
  data() {
    return {
      taxonomy: null
    };
  },
  async mounted() {
    const response = await fetch(`/api/v1/taxonomies/${this.$route.params.slug}`);
    const data = await response.json();
    this.taxonomy = data.data;
  }
};
</script>
```

---

## Testing

### Test Endpoint Availability

```bash
# Test if API is accessible
curl https://yoursite.com/api/v1/taxonomies

# Should return JSON with taxonomies list
```

### Test Authentication

```bash
# Without auth (should work for GET)
curl https://yoursite.com/api/v1/taxonomies

# With auth
curl -H "Authorization: Bearer YOUR_TOKEN" \
     https://yoursite.com/api/v1/taxonomies
```

### Test GraphQL

```bash
curl -X POST https://yoursite.com/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ taxonomies { id name } }"}'
```

---

## Rate Limiting

The API is protected by Rack::Attack with the following limits:

- **Per IP**: 300 requests per 5 minutes
- **Per API Token**: 1000 requests per hour

Rate limit headers are included in responses:
- `X-RateLimit-Limit`
- `X-RateLimit-Remaining`
- `X-RateLimit-Reset`

---

## Support & Resources

### Documentation
- **REST API**: `/api/v1/docs`
- **GraphQL Playground**: `/graphiql` (development)
- **API Guide**: This document

### Code Examples
- REST controllers: `app/controllers/api/v1/taxonomies_controller.rb`
- GraphQL types: `app/graphql/types/taxonomy_type.rb`
- Models: `app/models/taxonomy.rb`, `app/models/term.rb`

### Getting Help
1. Check this documentation
2. Review the GraphQL schema in GraphiQL
3. Inspect example responses
4. Check server logs for errors

---

## Changelog

### Version 1.0.0 (October 2025)
- Initial release with full REST and GraphQL support
- Taxonomies CRUD
- Terms CRUD
- Hierarchical term support
- Content associations
- Pagination
- Authentication
- Rate limiting

---

**Status**: ✅ Production Ready  
**Version**: 1.0.0  
**Last Updated**: October 12, 2025



