# RailsPress Documentation

Complete documentation for RailsPress - A modern, WordPress-compatible CMS built with Ruby on Rails.

> 📖 **[Complete Documentation Index](./INDEX.md)** - Browse all documentation organized by topic

## 📚 Quick Start

- [Quick Start Tutorial](./setup/quick-start.md) - Get up and running in 5 minutes
- [Default Seeds](./installation/DEFAULT_SEEDS.md) - Understand the default data
- [Credentials Setup](./setup/credentials.md) - Configure API keys

## 🎨 Features

### Core Features
- [Taxonomy System](./features/taxonomy-system.md) - WordPress-compatible categories, tags, and custom taxonomies
- [Content Editors](./features/CONTENT_EDITORS.md) - BlockNote, Trix, CKEditor, Editor.js
- [Menu System](./features/menu-system.md) - Dynamic navigation menus
- [Headless Mode](./features/headless-mode.md) - API-first CMS capabilities
- [SEO System](./features/seo.md) - Built-in SEO optimization
- [Multi-tenancy](./features/multi-tenancy.md) - Multiple sites, one installation

### Advanced Features
- [AI Agents](./plugins/AI_AGENTS_INTEGRATION.md) - Content generation, summarization, analysis
- [Shortcodes](./plugins/shortcodes-guide.md) - Embeddable content
- [Webhooks](./features/webhooks.md) - Event notifications
- [Background Jobs](./plugins/background-jobs.md) - Async processing

### Theme System
- [Liquid Themes](./themes/liquid-migration.md) - Modern templating
- [Nordic Theme](./themes/nordic.md) - Default minimalist theme
- [Twenty Twenty-Five Theme](./themes/twenty_twenty_five.md) - WordPress-inspired theme
- [Themes Overview](./themes/themes_overview.md) - Theme system guide

## 🎨 Design

- [Admin Design System](./design/ADMIN_DESIGN_SYSTEM.md) - Modern UI components
- [Color Schemes](./design/color-schemes.md) - Customizable themes
- [Typography](./design/typography.md) - Font system

## 🔌 Plugin Development

- **[Plugin Quick Start](./PLUGIN_QUICK_START.md)** - Create your first plugin in 5 minutes ⚡
- **[Plugin MVC Architecture](./PLUGIN_MVC_ARCHITECTURE.md)** - Complete MVC guide 🏗️
- **[Plugin Developer Guide](./PLUGIN_DEVELOPER_GUIDE.md)** - Advanced features 🚀

### Plugin Resources
- [Admin Pages](./plugins/admin-pages.md) - Creating admin interfaces
- [Routes System](./plugins/ROUTES.md) - Plugin routing
- [Settings Schema](./plugins/settings-schema.md) - Configure settings
- [Example Plugins](./plugins/) - SlickForms, Sitemap, and more

## 🔌 API

### REST API
- [Quick Start](./api/QUICK_START.md)
- [API Overview](./api/overview.md)
- [AI Agents API](./api/AI_AGENTS_API.md)
- [Taxonomy API](./api/taxonomy-api.md)
- [Quick Reference](./api/quick-reference.md)

### GraphQL
- [GraphQL Overview](./api/graphql.md)
- [Schema Reference](./api/graphql-schema.md)
- [Playground](http://localhost:3000/graphiql)

## 🧪 Testing

- [Test Suite Documentation](./testing/TEST_SUITE_DOCUMENTATION.md)
- [Taxonomy Tests](./testing/TAXONOMY_TESTS.md)
- [Running Tests](./testing/TEST_README.md)
- [Test Coverage](./testing/TEST_SUITE_SUMMARY.md)

## 🔧 Development

- [Contributing Guide](./development/CONTRIBUTING.md)
- [Code Standards](./development/CODE_STANDARDS.md)
- [Database Migrations](./development/migrations.md)
- [Debugging Guide](./development/debugging.md)

## 🚀 Deployment

- [Production Setup](./deployment/production.md)
- [Environment Variables](./deployment/environment.md)
- [Performance Tuning](./deployment/performance.md)
- [Backup & Recovery](./deployment/backup.md)

## 📖 Architecture

- [System Architecture](./architecture/SYSTEM_OVERVIEW.md)
- [Database Schema](./architecture/database-schema.md)
- [Request Lifecycle](./architecture/request-lifecycle.md)
- [Multi-tenancy Architecture](./architecture/multi-tenancy.md)

## 🔐 Security

- [Security Best Practices](./security/best-practices.md)
- [Authentication](./security/authentication.md)
- [API Tokens](./security/api-tokens.md)
- [CORS Configuration](./security/cors.md)

## 📋 Reference

- [Configuration Options](./reference/configuration.md)
- [Helper Methods](./reference/helpers.md)
- [Hooks & Filters](./reference/hooks.md)
- [Shortcode Reference](./reference/shortcodes.md)

## 🆕 What's New

### Latest Updates (October 2025)

#### Taxonomy System 2.0
- ✅ Unified taxonomy system (categories, tags, formats)
- ✅ WordPress-compatible structure
- ✅ Default taxonomies: category, tag, post_format
- ✅ Hierarchical categories with parent support
- ✅ Flat tags for keywords
- ✅ 93 comprehensive tests

#### Content Editor System
- ✅ 4 editors: BlockNote, Trix, CKEditor, Editor.js
- ✅ User-specific preferences
- ✅ Reusable partial across all forms
- ✅ Automatic editor detection
- ✅ Graceful fallbacks

#### Modern Admin Design
- ✅ 5 color schemes (Midnight, Vallarta, Amanecer, Onyx, Slate)
- ✅ 500+ lines of design system CSS
- ✅ Gradient cards, smooth animations
- ✅ Glass morphism effects
- ✅ Professional tooltips
- ✅ Responsive grids
- ✅ WCAG AA accessible

#### Nordic Theme
- ✅ Liquid templating system
- ✅ Full Site Editing (FSE) with JSON
- ✅ SEO-optimized sections
- ✅ Menu integration
- ✅ Comment system
- ✅ Mobile-responsive

#### AI Agents
- ✅ Content Summarizer
- ✅ Post Writer
- ✅ Comments Analyzer
- ✅ SEO Analyzer
- ✅ Reusable AI popup
- ✅ Multi-provider support (OpenAI, Cohere, Anthropic, Google)

#### Headless CMS Mode
- ✅ Full REST & GraphQL APIs
- ✅ CORS configuration
- ✅ API token management
- ✅ Frontend route disabling
- ✅ Next.js/Remix/Nuxt ready

## 🎯 WordPress Compatibility

RailsPress maintains WordPress compatibility for:

- ✅ **Taxonomy Structure** - category, tag, post_format
- ✅ **Default Content** - "Hello world!" post, "Sample Page"
- ✅ **User Roles** - Administrator, Editor, Author, Contributor, Subscriber
- ✅ **Post Statuses** - Draft, Published, Scheduled, Pending Review, Private
- ✅ **Menu System** - Locations, hierarchical items
- ✅ **Shortcodes** - [shortcode] syntax
- ✅ **Hooks System** - do_action, apply_filters
- ✅ **Comment System** - Threaded comments, moderation

## 📊 Project Status

| Feature | Status | Tests | Docs |
|---------|--------|-------|------|
| Taxonomy System | ✅ Complete | 93 tests | ✅ |
| Content Editors | ✅ Complete | 15 tests | ✅ |
| Admin Design | ✅ Complete | 45 tests | ✅ |
| Nordic Theme | ✅ Complete | 60 tests | ✅ |
| AI Agents | ✅ Complete | 40 tests | ✅ |
| Headless Mode | ✅ Complete | 25 tests | ✅ |
| Plugin System | ✅ Complete | 50 tests | ✅ |
| Multi-tenancy | ✅ Complete | 35 tests | ✅ |

**Total Tests:** 700+  
**Test Coverage:** ~90%  
**Production Ready:** ✅ Yes

## 🤝 Community

- [GitHub Repository](https://github.com/your-org/railspress)
- [Discussion Forum](https://discuss.railspress.io)
- [Discord Community](https://discord.gg/railspress)
- [Twitter](https://twitter.com/railspress)

## 📜 License

RailsPress is open source software licensed under the [MIT License](../LICENSE).

## 🙏 Credits

Built with ❤️ by the RailsPress team.

Inspired by WordPress and powered by Ruby on Rails.

---

**Need help?** Check our [Troubleshooting Guide](./troubleshooting/COMMON_ISSUES.md) or [open an issue](https://github.com/your-org/railspress/issues).
