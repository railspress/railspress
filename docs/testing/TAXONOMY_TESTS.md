# Taxonomy System Tests

This document describes the comprehensive test suite for the unified taxonomy system in RailsPress.

## 📋 Test Coverage

### Model Tests

#### `test/models/taxonomy_test.rb`
Tests for the core Taxonomy model functionality:

- ✅ Valid taxonomy creation
- ✅ Required field validations (name, slug)
- ✅ Unique slug validation
- ✅ Default values (hierarchical, object_types, settings)
- ✅ Slug generation from name (friendly_id)
- ✅ Taxonomy-term associations
- ✅ Cascading deletes (terms deleted with taxonomy)
- ✅ Root terms query
- ✅ Term counting
- ✅ Object type applicability checks
- ✅ Built-in taxonomy class methods (categories, tags)
- ✅ Scopes (hierarchical, flat, for_posts, for_pages)
- ✅ Singular/plural name attributes
- ✅ JSON serialization (settings, object_types)

**Total Tests:** 18

#### `test/models/term_test.rb`
Tests for the Term model functionality:

- ✅ Valid term creation
- ✅ Required field validations (name, slug, taxonomy)
- ✅ Unique slug within taxonomy
- ✅ Duplicate slugs allowed across taxonomies
- ✅ Slug generation from name
- ✅ Taxonomy association
- ✅ Parent-child relationships (hierarchical)
- ✅ Cascading deletes (children deleted with parent)
- ✅ Term relationships (posts, pages)
- ✅ Post counting via term relationships
- ✅ Scopes (by_taxonomy, root, ordered)
- ✅ Default count attribute
- ✅ Description field
- ✅ Meta fields (JSON)
- ✅ Hierarchical check via taxonomy

**Total Tests:** 15

### Fixtures

#### `test/fixtures/taxonomies.yml`
Fixture data for testing taxonomies:

- `category` - Hierarchical taxonomy for posts
- `tag` - Flat taxonomy for posts  
- `post_format` - Theme feature taxonomy
- `topics` - Custom hierarchical taxonomy

#### `test/fixtures/terms.yml`
Fixture data for testing terms:

- `uncategorized` - Default category term
- `technology`, `programming`, `ruby` - Hierarchical category terms
- `rails_tag`, `webdev_tag`, `tutorial_tag` - Tag terms
- `design_topic`, `development_topic` - Custom taxonomy terms

### Integration Tests

#### `test/integration/default_seeds_test.rb`
Tests for the default seed data:

- ✅ Default taxonomies exist (category, tag, post_format)
- ✅ Correct taxonomy attributes (names, hierarchy, object types)
- ✅ Uncategorized term exists
- ✅ Tag taxonomy has no default terms
- ✅ Post format taxonomy is empty
- ✅ Correct taxonomy settings
- ✅ Default admin user exists
- ✅ Taxonomies apply to Post objects
- ✅ WordPress-compatible structure
- ✅ Correct human-readable names

**Total Tests:** 10

### Controller Tests

#### `test/controllers/admin/taxonomies_controller_test.rb`
Tests for managing taxonomies in the admin:

- ✅ Index page displays all taxonomies
- ✅ Show page displays taxonomy details
- ✅ New page displays form
- ✅ Create action creates taxonomy
- ✅ Invalid data rejected
- ✅ Edit page displays form with data
- ✅ Update action updates taxonomy
- ✅ Invalid update rejected
- ✅ Destroy action deletes taxonomy
- ✅ Non-admin access denied
- ✅ Terms list displayed
- ✅ Hierarchical structure shown
- ✅ Filter by object type
- ✅ Usage count displayed

**Total Tests:** 14

#### `test/controllers/admin/terms_controller_test.rb`
Tests for managing terms in the admin:

- ✅ Index page for taxonomy terms
- ✅ Show page for individual term
- ✅ New page displays form
- ✅ Create action creates term
- ✅ Auto-generate slug from name
- ✅ Create hierarchical term with parent
- ✅ Duplicate slug in same taxonomy rejected
- ✅ Same slug allowed in different taxonomies
- ✅ Edit page displays form
- ✅ Update action updates term
- ✅ Invalid update rejected
- ✅ Destroy action deletes term
- ✅ Parent select for hierarchical taxonomies
- ✅ No parent select for flat taxonomies
- ✅ Term count updates
- ✅ Term usage displayed
- ✅ Meta fields handling
- ✅ Non-admin access denied
- ✅ Bulk delete terms

**Total Tests:** 19

### System Tests

#### `test/system/taxonomy_management_test.rb`
End-to-end tests for the complete taxonomy workflow:

- ✅ View all taxonomies
- ✅ Create new taxonomy
- ✅ Edit existing taxonomy
- ✅ Delete taxonomy
- ✅ Create term in taxonomy
- ✅ Create hierarchical term with parent
- ✅ Edit term
- ✅ Delete term
- ✅ Assign categories to post
- ✅ Assign tags to post
- ✅ Filter posts by category
- ✅ Filter posts by tag
- ✅ Term count display
- ✅ Hierarchical structure display
- ✅ Flat taxonomy (no parent selector)
- ✅ Validation errors displayed
- ✅ Auto-generate slug

**Total Tests:** 17

## 📊 Test Summary

| Test Type | File | Tests | Status |
|-----------|------|-------|--------|
| Model | taxonomy_test.rb | 18 | ✅ Created |
| Model | term_test.rb | 15 | ✅ Created |
| Integration | default_seeds_test.rb | 10 | ✅ Created |
| Controller | taxonomies_controller_test.rb | 14 | ✅ Created |
| Controller | terms_controller_test.rb | 19 | ✅ Created |
| System | taxonomy_management_test.rb | 17 | ✅ Created |
| **TOTAL** | **6 files** | **93 tests** | ✅ **Complete** |

## 🎯 Coverage Areas

### ✅ Model Layer
- Validations
- Associations
- Scopes
- Class methods
- Instance methods
- JSON serialization
- Friendly ID slugs

### ✅ Controller Layer
- CRUD operations
- Authorization
- Filters
- Bulk actions
- Error handling

### ✅ Integration Layer
- Seed data verification
- WordPress compatibility
- Cross-model interactions

### ✅ System Layer
- Full user workflows
- UI interactions
- Form submissions
- JavaScript behaviors

## 🚀 Running Tests

### All taxonomy tests
```bash
rails test test/models/taxonomy_test.rb test/models/term_test.rb
```

### Integration tests
```bash
rails test test/integration/default_seeds_test.rb
```

### Controller tests
```bash
rails test test/controllers/admin/taxonomies_controller_test.rb
rails test test/controllers/admin/terms_controller_test.rb
```

### System tests
```bash
rails test:system test/system/taxonomy_management_test.rb
```

### All tests
```bash
./run_tests.sh
```

## 📝 Test Data

### Fixtures Required
- `users.yml` - Admin and editor users
- `taxonomies.yml` - Default and custom taxonomies
- `terms.yml` - Various terms for testing
- `posts.yml` - Sample posts for term assignment

### Seed Data Tested
- Default taxonomies (category, tag, post_format)
- Uncategorized term
- Human-readable names (singular/plural)
- WordPress-compatible structure

## ✅ WordPress Compatibility Verified

All tests verify that the taxonomy system matches WordPress behavior:

- ✅ Three core taxonomies (category, tag, post_format)
- ✅ Category is hierarchical
- ✅ Tags are flat
- ✅ Uncategorized is default category
- ✅ Human-readable names (Categories vs category)
- ✅ Post assignment works identically
- ✅ Same slug can exist in different taxonomies

## 🔄 Continuous Integration

These tests should be run:
- ✅ Before every commit
- ✅ In CI/CD pipeline
- ✅ Before deployment
- ✅ After taxonomy modifications

## 📚 Related Documentation

- [Taxonomy System](../features/taxonomy-system.md)
- [Default Seeds](../installation/DEFAULT_SEEDS.md)
- [Test Suite Documentation](./TEST_SUITE_DOCUMENTATION.md)


