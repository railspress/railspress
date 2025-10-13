# RailsPress Taxonomy System Guide

## Overview

The RailsPress taxonomy system provides a flexible way to organize and classify content. Like WordPress, it supports both built-in taxonomies (Categories, Tags) and unlimited custom taxonomies.

## What is a Taxonomy?

A **taxonomy** is a grouping mechanism for content. It consists of:
- **Taxonomy** - The classification system itself (e.g., "Topics", "Formats")
- **Terms** - The individual items within a taxonomy (e.g., "Technology", "Tutorial")
- **Relationships** - Connections between content and terms

## Taxonomy Types

### Hierarchical Taxonomies
- Support parent/child relationships
- Like Categories
- Example: Topics > Technology > Programming > Ruby
- Use case: Organizing content into nested groups

### Flat Taxonomies
- No hierarchy, just labels
- Like Tags
- Example: ruby, rails, tutorial
- Use case: Flexible labeling and filtering

## Built-in Taxonomies

RailsPress includes two default taxonomies:

### 1. Categories
- **Type**: Hierarchical
- **Applies to**: Posts
- **Purpose**: Primary classification
- **Example**: Technology > Web Development

### 2. Tags
- **Type**: Flat
- **Applies to**: Posts
- **Purpose**: Flexible labeling
- **Example**: ruby, rails, tutorial

## Creating Custom Taxonomies

### From Admin Panel

1. Navigate to **Admin > Organize > Taxonomies**
2. Click **Create Taxonomy**
3. Fill in:
   - **Name**: Display name (e.g., "Topics")
   - **Slug**: URL-friendly identifier (auto-generated)
   - **Description**: What this taxonomy is for
   - **Hierarchical**: Enable for nested structure
   - **Object Types**: Apply to Posts, Pages, or both
4. Click **Create Taxonomy**

### Via Rails Console

```ruby
# Create a hierarchical taxonomy
topics = Taxonomy.create!(
  name: 'Topics',
  slug: 'topic',
  description: 'Main content topics',
  hierarchical: true,
  object_types: ['Post', 'Page']
)

# Create a flat taxonomy
formats = Taxonomy.create!(
  name: 'Content Formats',
  slug: 'format',
  description: 'Content format types',
  hierarchical: false,
  object_types: ['Post']
)
```

### Via API

```bash
POST /api/v1/taxonomies
Authorization: Bearer {admin-token}
Content-Type: application/json

{
  "taxonomy": {
    "name": "Topics",
    "slug": "topic",
    "description": "Main content topics",
    "hierarchical": true,
    "object_types": ["Post", "Page"]
  }
}
```

## Managing Terms

### Adding Terms

**From Admin Panel:**
1. Go to **Taxonomies**
2. Click **Manage Terms** on a taxonomy
3. Use the sidebar form to add new terms
4. For hierarchical taxonomies, select a parent term

**Via Rails:**
```ruby
taxonomy = Taxonomy.find_by(slug: 'topic')

# Add root term
tech = taxonomy.terms.create!(name: 'Technology')

# Add child term
rails_topic = taxonomy.terms.create!(
  name: 'Ruby on Rails',
  parent: tech
)
```

**Via API:**
```bash
POST /api/v1/taxonomies/{taxonomy_id}/terms
Authorization: Bearer {token}

{
  "term": {
    "name": "Technology",
    "description": "Tech-related content",
    "parent_id": null
  }
}
```

## Using Taxonomies in Code

### Include in Models

The `HasTaxonomies` concern is already included in Post and Page models:

```ruby
class Post < ApplicationRecord
  include HasTaxonomies
  
  # Automatically gets:
  # - has_many :terms
  # - has_many :term_relationships
  # - Helper methods for taxonomy management
end
```

### Assigning Terms to Content

```ruby
post = Post.find(1)
taxonomy = Taxonomy.find_by(slug: 'topic')

# Add a single term
term = taxonomy.terms.find_by(name: 'Technology')
post.add_term(term, 'topic')

# Or by name (creates if doesn't exist)
post.add_term('Ruby on Rails', 'topic')

# Set multiple terms for a taxonomy
tech_term = taxonomy.terms.find_by(name: 'Technology')
rails_term = taxonomy.terms.find_by(name: 'Rails')
post.set_terms_for_taxonomy('topic', [tech_term.id, rails_term.id])

# Get terms for a taxonomy
post.terms_for_taxonomy('topic')

# Get term names
post.term_names_for('topic')
# => ['Technology', 'Ruby on Rails']
```

### Querying by Taxonomy

```ruby
# Get all posts with a specific term
term = Term.find_by(slug: 'technology')
posts = term.objects_of_type('Post')

# Filter posts by multiple taxonomies
Post.joins(:terms)
    .where(terms: { taxonomy_id: topics_taxonomy.id, slug: 'technology' })
```

## Using in Views

### Display Terms

```erb
<!-- Show all terms for a post -->
<% @post.terms.each do |term| %>
  <%= link_to term.name, taxonomy_term_path(term.taxonomy.slug, term.slug) %>
<% end %>

<!-- Show terms from specific taxonomy -->
<% @post.terms_for_taxonomy('topic').each do |term| %>
  <span class="badge"><%= term.name %></span>
<% end %>

<!-- Hierarchical breadcrumbs -->
<% term = @post.terms_for_taxonomy('topic').first %>
<% if term %>
  <nav>
    <% term.breadcrumbs.each do |breadcrumb| %>
      <%= link_to breadcrumb.name, taxonomy_term_path(breadcrumb.taxonomy.slug, breadcrumb.slug) %>
      <span>/</span>
    <% end %>
  </nav>
<% end %>
```

### Check for Terms

```ruby
# Check if post has a term
@post.has_term?('technology')
@post.has_term?(term_object)
```

## API Endpoints

### Taxonomies

```bash
# List all taxonomies
GET /api/v1/taxonomies

# Get single taxonomy
GET /api/v1/taxonomies/:id

# Get taxonomy terms
GET /api/v1/taxonomies/:id/terms

# Create taxonomy (admin)
POST /api/v1/taxonomies

# Update taxonomy (admin)
PATCH /api/v1/taxonomies/:id

# Delete taxonomy (admin)
DELETE /api/v1/taxonomies/:id
```

### Terms

```bash
# List all terms
GET /api/v1/terms

# Get single term
GET /api/v1/terms/:id

# Create term
POST /api/v1/taxonomies/:taxonomy_id/terms

# Update term
PATCH /api/v1/taxonomies/:taxonomy_id/terms/:id

# Delete term
DELETE /api/v1/taxonomies/:taxonomy_id/terms/:id
```

### Query Parameters

**Taxonomies:**
- `object_type` - Filter by object type (Post, Page)
- `type` - hierarchical or flat

**Terms:**
- `taxonomy` - Filter by taxonomy slug
- `q` - Search query
- `root_only` - Only root terms (for hierarchical)

## Use Cases

### 1. Content Series

```ruby
# Create Series taxonomy
series = Taxonomy.create!(
  name: 'Series',
  slug: 'series',
  hierarchical: false,
  object_types: ['Post']
)

# Add series terms
['Rails Tutorial', 'Ruby Basics', 'Advanced Patterns'].each do |name|
  series.terms.create!(name: name)
end

# Assign posts to series
post.add_term('Rails Tutorial', 'series')
```

### 2. Content Difficulty

```ruby
# Create Difficulty taxonomy
difficulty = Taxonomy.create!(
  name: 'Difficulty Level',
  slug: 'difficulty',
  hierarchical: false,
  object_types: ['Post']
)

# Add levels
['Beginner', 'Intermediate', 'Advanced', 'Expert'].each do |level|
  difficulty.terms.create!(name: level)
end
```

### 3. Geographic Locations

```ruby
# Hierarchical location taxonomy
locations = Taxonomy.create!(
  name: 'Locations',
  slug: 'location',
  hierarchical: true,
  object_types: ['Post', 'Page']
)

# Add nested locations
usa = locations.terms.create!(name: 'United States')
california = locations.terms.create!(name: 'California', parent: usa)
sf = locations.terms.create!(name: 'San Francisco', parent: california)
```

### 4. Post Formats

```ruby
# Post format taxonomy
formats = Taxonomy.create!(
  name: 'Post Formats',
  slug: 'format',
  hierarchical: false,
  object_types: ['Post']
)

# Add formats
['Standard', 'Video', 'Audio', 'Gallery', 'Quote', 'Link'].each do |format|
  formats.terms.create!(name: format)
end
```

## Advanced Features

### Metadata

Store custom data with terms:

```ruby
term.metadata = {
  color: '#6366f1',
  icon: 'technology.svg',
  featured: true
}
term.save
```

### Term Counting

Terms automatically track how many objects use them:

```ruby
term.count  # Number of posts/pages using this term
term.update_count  # Manually recalculate
```

### Breadcrumbs

For hierarchical taxonomies:

```ruby
term.breadcrumbs
# => [root_term, parent_term, current_term]
```

## Migration from Categories/Tags

The existing Category and Tag models work alongside the new taxonomy system:

```ruby
# Categories still work
post.categories << Category.find_by(name: 'Tech')

# And custom taxonomies
post.add_term('Technology', 'topic')

# Both can coexist
```

## Performance Tips

1. **Eager Load**: Always include terms when querying
   ```ruby
   posts = Post.includes(:terms).published
   ```

2. **Cache Term Counts**: Use the built-in counter cache
   ```ruby
   term.count  # Already cached
   ```

3. **Index Slugs**: Slugs are indexed for fast lookups

4. **Batch Operations**: Use `set_terms_for_taxonomy` for bulk updates

## Security

- **Create/Update/Delete**: Requires Editor or Admin role
- **Read**: Public access via API
- **Admin UI**: Only administrators can manage taxonomies

## Best Practices

1. **Name Taxonomies Clearly**: Use descriptive names
2. **Limit Taxonomies**: Don't create too many (5-10 max)
3. **Plan Hierarchy**: Design structure before creating terms
4. **Use Descriptions**: Help users understand each taxonomy
5. **Consistent Slugs**: Keep slugs short and memorable
6. **Metadata**: Store extra info in metadata hash

## Examples in Production

### E-learning Site
- **Subjects** (hierarchical): Math > Algebra > Linear Equations
- **Difficulty** (flat): Beginner, Intermediate, Advanced
- **Skills** (flat): Problem Solving, Critical Thinking

### News Site
- **Sections** (hierarchical): News > Politics > International
- **Topics** (flat): Breaking, Analysis, Opinion
- **Regions** (hierarchical): North America > USA > California

### Recipe Site
- **Cuisines** (hierarchical): Asian > Chinese > Szechuan
- **Diets** (flat): Vegetarian, Vegan, Gluten-Free
- **Courses** (flat): Appetizer, Main, Dessert

## Troubleshooting

### Terms Not Showing
- Check taxonomy is assigned to correct object types
- Verify terms are created
- Ensure term relationships exist

### Hierarchy Not Working
- Confirm taxonomy.hierarchical = true
- Check parent_id is set correctly
- Verify no circular references

### Performance Issues
- Add database indexes
- Use eager loading
- Cache term counts

---

**Your content organization just got supercharged!** 🚀

Create unlimited custom taxonomies to classify content exactly how you need.



