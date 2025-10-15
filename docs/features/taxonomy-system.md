# Taxonomy System

RailsPress uses a unified taxonomy system that provides WordPress-compatible categorization and tagging, plus support for custom taxonomies.

## Overview

The taxonomy system replaces the old separate Category and Tag models with a flexible, unified approach that supports:

- **Hierarchical taxonomies** (like WordPress categories)
- **Flat taxonomies** (like WordPress tags)
- **Custom taxonomies** (for any content type)
- **Meta fields** on terms
- **Multiple object types** per taxonomy

## Default Taxonomies

### 1. Category (Hierarchical)

```ruby
taxonomy = Taxonomy.find_by(slug: 'category')
# => Taxonomy(slug: 'category', hierarchical: true)

taxonomy.singular_name # => "Category"
taxonomy.plural_name   # => "Categories"
```

**Features:**
- Hierarchical structure (parent/child)
- Default "Uncategorized" term
- WordPress-compatible
- Applies to: Posts

**Usage:**
```ruby
# Get all categories
categories = Taxonomy.find_by(slug: 'category').terms

# Create a category
tech = taxonomy.terms.create!(
  name: 'Technology',
  slug: 'technology',
  description: 'Tech-related posts'
)

# Create sub-category
ruby = taxonomy.terms.create!(
  name: 'Ruby',
  slug: 'ruby',
  parent: tech
)

# Assign to post
post.term_relationships.create!(term: tech)
```

### 2. Tag (Flat)

```ruby
taxonomy = Taxonomy.find_by(slug: 'tag')
# => Taxonomy(slug: 'tag', hierarchical: false)

taxonomy.singular_name # => "Tag"
taxonomy.plural_name   # => "Tags"
```

**Features:**
- Flat structure (no hierarchy)
- No default terms
- WordPress-compatible
- Applies to: Posts

**Usage:**
```ruby
# Get all tags
tags = Taxonomy.find_by(slug: 'tag').terms

# Create tags
rails_tag = taxonomy.terms.create!(name: 'rails', slug: 'rails')
ruby_tag = taxonomy.terms.create!(name: 'ruby', slug: 'ruby')

# Assign to post
post.term_relationships.create!(term: rails_tag)
post.term_relationships.create!(term: ruby_tag)

# Tag a post with multiple tags
tags = ['ruby', 'rails', 'tutorial']
tags.each do |tag_name|
  tag = taxonomy.terms.find_or_create_by!(slug: tag_name) do |t|
    t.name = tag_name
  end
  post.term_relationships.find_or_create_by!(term: tag)
end
```

### 3. Post Format (Theme Feature)

```ruby
taxonomy = Taxonomy.find_by(slug: 'post_format')
# => Taxonomy(slug: 'post_format', hierarchical: false)

taxonomy.singular_name # => "Format"
taxonomy.plural_name   # => "Formats"
```

**Features:**
- Available but empty by default
- Theme can define formats (video, audio, gallery, quote, link)
- Not shown in admin menu by default
- WordPress-compatible

**Usage:**
```ruby
# Create post formats (typically done by theme)
formats = ['video', 'audio', 'gallery', 'quote', 'link', 'aside', 'status']
formats.each do |format_name|
  taxonomy.terms.find_or_create_by!(slug: format_name) do |t|
    t.name = format_name.titleize
  end
end

# Assign format to post
video_format = taxonomy.terms.find_by(slug: 'video')
post.term_relationships.create!(term: video_format)
```

## Creating Custom Taxonomies

### Example: Topics Taxonomy

```ruby
topics = Taxonomy.create!(
  name: 'Topic',
  singular_name: 'Topic',
  plural_name: 'Topics',
  slug: 'topic',
  description: 'Content topics',
  hierarchical: true,
  object_types: ['Post', 'Page'],
  settings: {
    'show_in_menu' => true,
    'show_in_api' => true,
    'show_ui' => true,
    'public' => true
  }
)

# Create terms
web_dev = topics.terms.create!(
  name: 'Web Development',
  slug: 'web-development'
)

frontend = topics.terms.create!(
  name: 'Frontend',
  slug: 'frontend',
  parent: web_dev
)
```

### Example: Difficulty Level Taxonomy

```ruby
difficulty = Taxonomy.create!(
  name: 'Difficulty Level',
  singular_name: 'Difficulty',
  plural_name: 'Difficulty Levels',
  slug: 'difficulty',
  hierarchical: false,
  object_types: ['Post'],
  settings: {
    'show_in_menu' => false,
    'show_in_api' => true,
    'public' => true
  }
)

# Create difficulty levels
['Beginner', 'Intermediate', 'Advanced', 'Expert'].each do |level|
  difficulty.terms.create!(name: level, slug: level.downcase)
end
```

## Working with Terms

### Creating Terms

```ruby
taxonomy = Taxonomy.find_by(slug: 'category')

# Simple term
term = taxonomy.terms.create!(
  name: 'Technology',
  slug: 'technology',
  description: 'Posts about technology'
)

# Term with parent (hierarchical)
child = taxonomy.terms.create!(
  name: 'Ruby',
  slug: 'ruby',
  parent: term
)

# Term with meta data
term = taxonomy.terms.create!(
  name: 'Featured',
  slug: 'featured',
  meta: {
    'color' => '#ff0000',
    'icon' => 'star',
    'featured' => true
  }
)
```

### Querying Terms

```ruby
# All terms in a taxonomy
terms = taxonomy.terms

# Root terms only (hierarchical)
roots = taxonomy.root_terms

# Find term by slug
term = taxonomy.terms.friendly.find('technology')

# Find term by id
term = taxonomy.terms.find(123)

# Terms ordered by name
terms = taxonomy.terms.ordered

# Terms with posts
terms = taxonomy.terms.joins(:term_relationships)
                      .where(term_relationships: { taggable_type: 'Post' })
                      .distinct
```

### Updating Terms

```ruby
term = taxonomy.terms.find_by(slug: 'technology')

term.update(
  name: 'Tech & Innovation',
  description: 'Updated description'
)

# Update meta
term.meta['featured'] = true
term.save
```

### Deleting Terms

```ruby
term = taxonomy.terms.find_by(slug: 'old-category')

# Simple delete
term.destroy

# Protected delete (e.g., Uncategorized)
if term.slug == 'uncategorized'
  # Don't delete, or reassign posts first
else
  # Reassign posts to Uncategorized
  uncategorized = taxonomy.terms.find_by(slug: 'uncategorized')
  term.term_relationships.where(taggable_type: 'Post').each do |rel|
    rel.update(term: uncategorized)
  end
  term.destroy
end
```

## Assigning Terms to Posts

### Using HasTaxonomies Concern

```ruby
# Post includes HasTaxonomies
post = Post.find(1)

# Get all terms
post.terms
# => [#<Term id: 1, name: "Technology">, ...]

# Get categories only
category_taxonomy = Taxonomy.find_by(slug: 'category')
post.terms.where(taxonomy: category_taxonomy)

# Get tags only
tag_taxonomy = Taxonomy.find_by(slug: 'tag')
post.terms.where(taxonomy: tag_taxonomy)

# Assign a category
tech = category_taxonomy.terms.find_by(slug: 'technology')
post.term_relationships.create!(term: tech)

# Assign multiple tags
['ruby', 'rails', 'tutorial'].each do |tag_name|
  tag = tag_taxonomy.terms.find_or_create_by!(slug: tag_name) do |t|
    t.name = tag_name
  end
  post.term_relationships.find_or_create_by!(term: tag)
end

# Remove a term
relationship = post.term_relationships.find_by(term: tech)
relationship.destroy

# Replace all categories
new_categories = [term1, term2, term3]
# Remove old category relationships
post.term_relationships.where(term: category_taxonomy.terms).destroy_all
# Add new ones
new_categories.each do |cat|
  post.term_relationships.create!(term: cat)
end
```

## Querying Posts by Term

### Filter by Category

```ruby
# Single category
tech = Taxonomy.find_by(slug: 'category').terms.find_by(slug: 'technology')
posts = Post.joins(:term_relationships)
            .where(term_relationships: { term: tech })
            .distinct

# Category and its children (hierarchical)
tech_and_children = [tech] + tech.children
posts = Post.joins(:term_relationships)
            .where(term_relationships: { term: tech_and_children })
            .distinct
```

### Filter by Tag

```ruby
tag_taxonomy = Taxonomy.find_by(slug: 'tag')
ruby_tag = tag_taxonomy.terms.find_by(slug: 'ruby')

posts = Post.joins(:term_relationships)
            .where(term_relationships: { term: ruby_tag })
            .distinct
```

### Filter by Multiple Terms

```ruby
# Posts with ALL specified tags
tags = tag_taxonomy.terms.where(slug: ['ruby', 'rails'])
posts = Post.joins(:term_relationships)
            .where(term_relationships: { term: tags })
            .group('posts.id')
            .having('COUNT(DISTINCT term_relationships.term_id) = ?', tags.count)

# Posts with ANY specified tags
posts = Post.joins(:term_relationships)
            .where(term_relationships: { term: tags })
            .distinct
```

## Admin Integration

### Categories Page
- Route: `/admin/categories`
- Shows all category terms
- Hierarchical tree view
- Create/edit/delete categories
- Parent selector for sub-categories
- Posts count per category
- Protected deletion for "Uncategorized"

### Tags Page
- Route: `/admin/tags`
- Shows all tag terms
- Flat list view
- Create/edit/delete tags
- Posts count per tag
- Simple forms (no parent)

### Taxonomies Page
- Route: `/admin/taxonomies`
- Manage all taxonomies
- Create custom taxonomies
- Configure object types
- Set hierarchical/flat

### Terms Page
- Route: `/admin/taxonomies/:taxonomy_id/terms`
- Manage terms within a taxonomy
- Hierarchical or flat based on taxonomy
- Bulk operations
- Meta fields editing

## GraphQL API

```graphql
# Get all categories
query {
  categories {
    id
    name
    slug
    description
    count
    parent {
      name
    }
  }
}

# Get all tags
query {
  tags {
    id
    name
    slug
    count
  }
}

# Get terms by taxonomy
query {
  terms(taxonomy_slug: "category") {
    id
    name
    slug
    taxonomy {
      name
    }
  }
}

# Get posts by category
query {
  posts(category_slug: "technology") {
    id
    title
    terms {
      name
      taxonomy {
        slug
      }
    }
  }
}
```

## REST API

```bash
# Get all taxonomies
GET /api/v1/taxonomies

# Get specific taxonomy
GET /api/v1/taxonomies/category

# Get terms in taxonomy
GET /api/v1/taxonomies/category/terms

# Get posts by category
GET /api/v1/posts?category=technology

# Get posts by tag
GET /api/v1/posts?tag=ruby
```

## Best Practices

### 1. Use Helper Methods
```ruby
# DO THIS
Taxonomy.categories.terms

# DON'T DO THIS
Taxonomy.find_by(slug: 'category').terms
```

### 2. Check if Taxonomy Exists
```ruby
taxonomy = Taxonomy.find_by(slug: 'category')
return [] unless taxonomy

taxonomy.terms
```

### 3. Use Scopes
```ruby
# Get root categories
Taxonomy.find_by(slug: 'category').root_terms

# Get ordered tags
Taxonomy.find_by(slug: 'tag').terms.ordered
```

### 4. Handle Empty Results
```ruby
categories = Taxonomy.find_by(slug: 'category')&.terms || []
```

### 5. Use find_or_create for Tags
```ruby
tag_names = ['ruby', 'rails', 'tutorial']
tag_taxonomy = Taxonomy.find_by(slug: 'tag')

tags = tag_names.map do |name|
  tag_taxonomy.terms.find_or_create_by!(slug: name.parameterize) do |t|
    t.name = name
  end
end
```

## Migration from Old System

If upgrading from Category/Tag models:

```ruby
# Old way
post.categories << Category.find_by(slug: 'tech')
post.tags << Tag.find_by(slug: 'ruby')

# New way
category_tax = Taxonomy.find_by(slug: 'category')
tag_tax = Taxonomy.find_by(slug: 'tag')

tech_term = category_tax.terms.find_by(slug: 'tech')
ruby_term = tag_tax.terms.find_by(slug: 'ruby')

post.term_relationships.create!(term: tech_term)
post.term_relationships.create!(term: ruby_term)
```

The migration automatically converts all existing categories and tags to terms.

## Related Documentation

- [Default Seeds](../installation/DEFAULT_SEEDS.md)
- [Taxonomy Tests](../testing/TAXONOMY_TESTS.md)
- [GraphQL API](../api/graphql.md)
- [REST API](../api/posts.md)






