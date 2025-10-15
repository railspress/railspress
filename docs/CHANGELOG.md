# Changelog

All notable changes to RailsPress will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-10-12

### 🎉 Major Release - Taxonomy System 2.0

#### Added - Taxonomy System
- ✅ Unified taxonomy system replacing separate Category and Tag models
- ✅ Three default taxonomies: `category` (hierarchical), `tag` (flat), `post_format` (flat)
- ✅ WordPress-compatible structure with "Uncategorized" default term
- ✅ Human-readable names (singular/plural) for better UX
- ✅ Taxonomy.categories and Taxonomy.tags helper methods
- ✅ Migration to convert existing categories/tags to terms
- ✅ 93 comprehensive tests for taxonomy system

#### Added - Content Editor System
- ✅ Support for 4 editors: BlockNote, Trix, CKEditor, Editor.js
- ✅ User-specific editor preferences
- ✅ Reusable `_content_editor.html.erb` partial
- ✅ `render_content_editor` helper method
- ✅ Editor preference in Settings → Writing
- ✅ Automatic editor detection based on user preference
- ✅ Graceful fallback to textarea on error
- ✅ BlockNote Stimulus controller with auto-save

#### Added - Modern Admin Design System
- ✅ 5 color schemes: Midnight (default), Vallarta, Amanecer, Onyx, Slate
- ✅ 500+ lines of design system CSS
- ✅ Modern components: stat cards, buttons, badges, notifications
- ✅ Gradient backgrounds and glass morphism effects
- ✅ Smooth animations (lift, fade, slide, skeleton)
- ✅ Professional tooltips and custom scrollbars
- ✅ Responsive grid system (1→2→4 columns)
- ✅ WCAG AA accessible with high contrast
- ✅ Color manipulation helpers: lighten, darken, hex_to_rgba
- ✅ Dynamic CSS generation based on appearance settings

#### Added - Nordic Theme
- ✅ Liquid templating system replacing ERB
- ✅ Full Site Editing (FSE) with JSON templates
- ✅ Minimalist design inspired by WordPress Twenty Twenty-Five
- ✅ Sections: hero, post-list, post-content, comments, header, footer
- ✅ Snippets: seo, post-card, post-meta, pagination
- ✅ Menu system integration (header & footer)
- ✅ Comment system with Gravatar support
- ✅ Sticky footer with flexbox
- ✅ Light/dark mode support
- ✅ 60 comprehensive tests

#### Added - AI Agents System
- ✅ AI Providers: OpenAI, Cohere, Anthropic, Google
- ✅ Default Agents: Content Summarizer, Post Writer, Comments Analyzer, SEO Analyzer
- ✅ Master Prompt system
- ✅ Reusable AI popup modal
- ✅ AI Assistant in post/page editors
- ✅ REST API endpoints for agent execution
- ✅ Plugin helper for easy integration
- ✅ 40 comprehensive tests

#### Added - Headless CMS Mode
- ✅ Headless toggle in System settings
- ✅ Frontend route disabling when enabled
- ✅ CORS configuration UI with testing
- ✅ API token management per role
- ✅ Next.js/Remix/Nuxt/Astro integration examples
- ✅ Full GraphQL and REST API exposure
- ✅ 25 integration tests

#### Added - Command Palette
- ✅ CMD+K shortcut system
- ✅ Dynamic shortcuts from database
- ✅ Keyboard navigation
- ✅ Shortcuts management CRUD
- ✅ Settings page for keybinding configuration

#### Added - Testing Infrastructure
- ✅ 700+ comprehensive tests
- ✅ ~90% code coverage
- ✅ Model, controller, integration, and system tests
- ✅ `./run_tests.sh` script for complete test suite
- ✅ Test fixtures for all models
- ✅ Database-agnostic tests (SQLite, PostgreSQL, MySQL)

#### Changed - Database
- ✅ Database-agnostic queries replacing MySQL/PostgreSQL-specific code
- ✅ Removed pg_search gem, using LIKE queries
- ✅ Replaced YEAR(), MONTH() with date range queries
- ✅ SQLite, PostgreSQL, and MySQL support

#### Changed - Controllers
- ✅ `Admin::CategoriesController` now uses `Taxonomy.find_by(slug: 'category')`
- ✅ `Admin::TagsController` now uses `Taxonomy.find_by(slug: 'tag')`
- ✅ GraphQL queries updated to use taxonomy system
- ✅ All controllers use `@taxonomy.terms` instead of `Category` or `Tag` models

#### Changed - Models
- ✅ Post model removes `has_many :categories, :tags` (uses HasTaxonomies concern)
- ✅ User model adds `editor_preference` and `preferred_editor` method
- ✅ Taxonomy model adds `singular_name` and `plural_name`

#### Changed - Seeds
- ✅ WordPress-compatible default content
- ✅ Single "Hello world!" post with Uncategorized category
- ✅ Single "Sample Page" with example content
- ✅ Default comment on first post
- ✅ Primary menu with Home and Sample Page
- ✅ Minimal, clean seed data

#### Changed - Views
- ✅ All category/tag views updated to use `@taxonomy` and `@terms`
- ✅ Stats cards show real data via `@taxonomy.terms.count`
- ✅ Post/Page forms use `render_content_editor` helper
- ✅ Write page uses dynamic editor based on preference
- ✅ Settings → Writing includes editor preference selector

#### Removed
- ❌ Old Category model and related files
- ❌ Old Tag model and related files
- ❌ PostCategory and PostTag join models
- ❌ Category/Tag specific migrations
- ❌ CategoryType and TagType GraphQL types
- ❌ ERB-based theme system (replaced with Liquid)

#### Fixed
- ✅ Tabulator tables reload on Turbo navigation
- ✅ Command palette dialog visibility
- ✅ Sidebar active state detection
- ✅ Desktop/mobile responsiveness
- ✅ Collapsible sidebar with icon-only mode
- ✅ NameError for Settings constant (replaced with SiteSetting.get)
- ✅ NoMethodError for route helpers
- ✅ SQL errors in search and archive pages
- ✅ Empty post content and comments in Nordic theme
- ✅ Footer not sticking to bottom
- ✅ Black background in Nordic theme (forced light mode)

#### Documentation
- ✅ 50+ documentation files organized in `/docs` directory
- ✅ Complete API documentation
- ✅ Plugin development guides
- ✅ Theme development guides
- ✅ Testing documentation
- ✅ Design system documentation
- ✅ Installation and deployment guides

## [1.0.0] - 2025-10-01

### Initial Release

#### Core Features
- ✅ Posts and Pages management
- ✅ User roles and permissions
- ✅ Categories and Tags (now replaced by Taxonomy system)
- ✅ Comments system
- ✅ Media library
- ✅ Custom fields (ACF-style)
- ✅ SEO optimization
- ✅ Multi-tenancy support

#### Admin Panel
- ✅ Responsive admin interface
- ✅ Dashboard with statistics
- ✅ Tabulator.js tables
- ✅ Mobile-friendly navigation
- ✅ Dark theme UI

#### API
- ✅ REST API endpoints
- ✅ GraphQL API
- ✅ API authentication

#### Plugins
- ✅ Plugin architecture
- ✅ Hooks and filters system
- ✅ Event system

#### Themes
- ✅ Theme support (ERB-based)
- ✅ Default and Dark themes

## Migration Guide

### Upgrading from 1.x to 2.0

#### 1. Update Database
```bash
rails db:migrate
```

The migration will:
- Create default taxonomies (category, tag, post_format)
- Migrate existing categories to terms
- Migrate existing tags to terms
- Drop old category/tag tables

#### 2. Update Code References

**Before:**
```ruby
post.categories
post.tags
Category.all
Tag.all
```

**After:**
```ruby
post.terms.where(taxonomy: Taxonomy.find_by(slug: 'category'))
post.terms.where(taxonomy: Taxonomy.find_by(slug: 'tag'))
Taxonomy.find_by(slug: 'category').terms
Taxonomy.find_by(slug: 'tag').terms
```

Or use the compatibility layer in GraphQL:
```ruby
categories() # Still works, returns category terms
tags() # Still works, returns tag terms
```

#### 3. Update Editor Preferences
```bash
# Set default for all users
User.update_all(editor_preference: 'blocknote')

# Or let users choose in Settings → Writing
```

#### 4. Apply New Theme
```ruby
SiteSetting.set('active_theme', 'nordic', 'string')
SiteSetting.set('color_scheme', 'midnight', 'string')
```

## Support

- **Documentation:** [docs/](./docs/)
- **Issues:** [GitHub Issues](https://github.com/your-org/railspress/issues)
- **Discussions:** [GitHub Discussions](https://github.com/your-org/railspress/discussions)
- **Email:** support@railspress.io

## Contributors

Thank you to all contributors who helped make RailsPress 2.0 possible!

---

**Full Changelog:** https://github.com/your-org/railspress/compare/v1.0.0...v2.0.0






