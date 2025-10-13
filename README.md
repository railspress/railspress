# RailsPress - A Ruby on Rails CMS

RailsPress is a full-featured Content Management System (CMS) built with Ruby on Rails, inspired by WordPress functionality. It provides a complete blogging platform with advanced features including a visual template customizer powered by GrapesJS.

## Features

### 🔌 Comprehensive REST API
- **Full API v1** with RESTful design
  - Complete CRUD for all resources
  - Token-based authentication
  - Rate limiting (1000 req/hour)
  - Pagination support
  - Advanced filtering and search
  - CORS enabled for cross-origin requests
  - Interactive documentation at `/api/v1/docs`
  - Postman collection included
  - Example API client included

### Core CMS Functionality
- **User Management & Authentication** (via Devise)
  - 5 user roles: Administrator, Editor, Author, Contributor, Subscriber
  - Role-based authorization with granular permissions
  - Secure authentication and session management

### Content Management
- **Posts** - Full-featured blog posts with:
  - Rich text editor (ActionText with Trix)
  - Multiple statuses (draft, published, scheduled, pending review, private, trash)
  - Featured images
  - Categories and tags (many-to-many relationships)
  - SEO meta fields (description, keywords)
  - Friendly URLs (slugs)
  - Publishing schedules
  
- **Pages** - Static pages with:
  - Hierarchical structure (parent-child relationships)
  - Custom templates
  - Rich text content
  - Breadcrumb navigation
  
- **Categories** - Hierarchical taxonomy for organizing content
- **Tags** - Flexible tagging system
- **Comments** - Threaded commenting system with:
  - Moderation workflow (pending, approved, spam, trash)
  - Nested/threaded comments
  - Guest and user comments
  
- **Media Library** - Full media management with:
  - ActiveStorage integration
  - Image uploads and processing
  - File type detection
  - Media metadata

### Theme System
- **Visual Template Customizer** powered by GrapesJS
  - Drag-and-drop interface
  - 13+ template types (homepage, blog, pages, archives, etc.)
  - Real-time preview
  - Responsive design tools
  - Device testing (desktop, tablet, mobile)
  - Custom HTML/CSS/JS support
  - WordPress-style template tags
  
- **Theme Management**
  - Multiple theme support
  - Theme activation/deactivation
  - Theme settings and customization
  - Default template generation

### Navigation & Widgets
- **Menu Management**
  - Multiple menu locations
  - Hierarchical menu items
  - Custom URLs and labels
  - CSS classes and targets
  
- **Widget System**
  - Sidebar widgets
  - Multiple widget types:
    - Text
    - Recent Posts
    - Categories
    - Tags
    - Search
    - Custom HTML
    - Recent Comments
    - Archives

### Transactional Email System
- **Multiple Providers**: SMTP and Resend.com support
- **Email Logging**: Track all sent emails with full details
- **Test Email**: Verify configuration instantly
- **Admin Dashboard**: Beautiful email settings UI
- **Delivery Status**: Monitor sent, failed, and pending emails
- **Full Email Body**: View HTML and raw source
- **Provider Stats**: Track emails by provider
- **One-Click Configuration**: No server restart required

**Supported Providers:**
- SMTP (Gmail, SendGrid, Mailgun, Amazon SES, custom)
- Resend.com API
- Development: Letter Opener

**Email Logs Include:**
- From/To addresses
- Subject and full body
- Delivery status
- Provider used
- Timestamps
- Error messages
- Complete metadata

### Plugin System
- Extensible architecture for custom plugins
- WordPress-style hooks and filters
- 8+ working plugins included
- Plugin marketplace for browsing
- Plugin activation/deactivation
- Plugin settings management

### Shortcode System
- WordPress-compatible shortcode syntax
- 14+ built-in shortcodes
- Interactive shortcode tester
- Plugin integration for custom shortcodes
- Automatic processing in posts/pages
- Support for nested and complex shortcodes

**Built-in Shortcodes:**
- `[gallery]` - Image galleries
- `[button]` - Styled buttons/CTAs
- `[youtube]` - Video embeds
- `[recent_posts]` - Dynamic post lists
- `[contact_form]` - Contact forms
- `[columns]` - Multi-column layouts
- `[alert]` - Notice/alert boxes
- `[code]` - Syntax-highlighted code
- `[accordion]` - Collapsible FAQ sections
- `[pricing]` - Pricing tables
- `[toggle]` - Show/hide content
- `[progress]` - Progress bars
- `[countdown]` - Countdown timers
- `[testimonial]` - Customer testimonials

### SEO Features
- Meta tags support (description, keywords)
- Friendly URLs with FriendlyId
- Customizable permalinks
- Sitemap generation (ready for implementation)

### Admin Dashboard
- Comprehensive admin panel at `/admin`
- Statistics and analytics
- Recent posts and comments overview
- Quick actions
- CRUD operations for all content types

## Technology Stack

- **Ruby on Rails 7.1+**
- **PostgreSQL/SQLite3** - Database
- **Devise** - Authentication
- **Pundit** - Authorization (ready for implementation)
- **ActionText** - Rich text editing
- **ActiveStorage** - File uploads
- **FriendlyId** - Slugs and friendly URLs
- **Kaminari** - Pagination
- **GrapesJS** - Visual template builder
- **Tailwind CSS** - Styling
- **Hotwire** (Turbo & Stimulus) - Modern Rails UX
- **Redis & Sidekiq** - Background jobs

## Installation

### Prerequisites
- Ruby 3.3.9+
- Rails 7.1.5+
- SQLite3 (or PostgreSQL)
- Node.js (for asset compilation)

### Setup

1. **Clone the repository**
   ```bash
   cd railspress
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Setup database**
   ```bash
   rails db:create db:migrate db:seed
   ```

4. **Start the server**
   ```bash
   ./bin/dev
   ```

5. **Access the application**
   - Public site: http://localhost:3000
   - Admin panel: http://localhost:3000/admin
   - Default admin credentials:
     - Email: admin@railspress.com
     - Password: password

## Usage

### Admin Panel

Access the admin panel at `/admin` after logging in with admin credentials.

#### Managing Posts
1. Navigate to **Posts** in the admin menu
2. Click **New Post** to create content
3. Use the rich text editor to format content
4. Add categories, tags, and featured images
5. Set SEO meta information
6. Choose publishing status and schedule

#### Customizing Templates
1. Go to **Template Customizer** in the admin menu
2. Select a template to edit
3. Use the visual GrapesJS editor to:
   - Drag and drop components
   - Customize styles
   - Add custom HTML/CSS/JS
   - Preview on different devices
4. Save your changes

#### Managing Themes
1. Navigate to **Themes**
2. Create new themes or activate existing ones
3. Each theme automatically generates default templates
4. Customize templates through the Template Customizer

#### Setting up Menus
1. Go to **Menus**
2. Create a new menu
3. Add menu items with:
   - Labels and URLs
   - Parent-child relationships
   - CSS classes
4. Assign menu to a location (e.g., "primary")

#### Configuring Widgets
1. Navigate to **Widgets**
2. Create widgets for different sidebar locations
3. Choose widget types:
   - Recent Posts
   - Categories
   - Tags
   - Custom HTML
   - Search
4. Set position and activate

### Public Frontend

The public-facing site provides:

- **Homepage** - Featured and recent posts
- **Blog** - Paginated post listing at `/blog`
- **Single Post** - Individual post pages with comments
- **Category Archives** - `/category/:slug`
- **Tag Archives** - `/tag/:slug`
- **Date Archives** - `/archive/:year(/:month)`
- **Search** - `/search?q=query`
- **Custom Pages** - Any custom URL slug

### Template Variables

Use these in your GrapesJS templates:

```html
<!-- Post/Page Content -->
{{post.title}}
{{post.content}}
{{post.excerpt}}
{{post.published_at}}
{{post.author}}
{{post.categories}}
{{post.tags}}

<!-- Page Content -->
{{page.title}}
{{page.content}}
```

### User Roles & Permissions

| Role | Can Do |
|------|--------|
| **Administrator** | Full access to all features |
| **Editor** | Manage all posts, pages, and comments |
| **Author** | Create and publish own posts |
| **Contributor** | Create posts (requires approval) |
| **Subscriber** | Read content and comment |

## REST API

RailsPress includes a comprehensive REST API for programmatic access to all CMS functionality.

### API Features

- ✅ **RESTful Design** - Standard HTTP methods and status codes
- ✅ **JSON Responses** - All responses in JSON format
- ✅ **Token Authentication** - Secure Bearer token authentication
- ✅ **Rate Limiting** - 1000 requests per hour per user
- ✅ **Pagination** - Efficient handling of large datasets
- ✅ **Filtering & Search** - Advanced query capabilities
- ✅ **CORS Support** - Cross-origin requests enabled
- ✅ **Versioning** - URL-based versioning (v1)
- ✅ **Error Handling** - Consistent error responses
- ✅ **Role-Based Access** - Permissions enforced

### API Resources

Full CRUD support for:
- **Posts** - Blog posts with categories, tags, and metadata
- **Pages** - Static pages with hierarchical structure
- **Categories** - Taxonomy management
- **Tags** - Tagging system
- **Comments** - Comment management with moderation
- **Media** - File upload and management
- **Users** - User management (admin only)
- **Menus** - Navigation menu access
- **Settings** - Site configuration (admin only)
- **System** - API info and statistics

### Quick Start

1. **Get your API token:**
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@railspress.com","password":"password"}'
```

2. **Fetch posts:**
```bash
curl http://localhost:3000/api/v1/posts?status=published \
  -H "Authorization: Bearer YOUR_TOKEN"
```

3. **Create content:**
```bash
curl -X POST http://localhost:3000/api/v1/posts \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "post": {
      "title": "New Post",
      "content": "<p>Content here</p>",
      "status": "published"
    }
  }'
```

### API Documentation

- **Interactive Docs**: http://localhost:3000/api/v1/docs
- **Complete Guide**: `API_DOCUMENTATION.md`
- **Quick Reference**: `API_QUICK_REFERENCE.md`
- **Postman Collection**: `railspress_api_collection.json`
- **Test Client**: `API_CLIENT_EXAMPLE.html`

### API Example Response

```json
{
  "success": true,
  "data": {
    "id": 1,
    "title": "My Post",
    "slug": "my-post",
    "content": "<p>Full content...</p>",
    "status": "published",
    "author": {
      "id": 1,
      "name": "admin",
      "email": "admin@railspress.com"
    },
    "categories": [...],
    "tags": [...],
    "url": "https://your-site.com/blog/my-post"
  },
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 120
  }
}
```

### Authentication

All authenticated endpoints require a Bearer token:

```
Authorization: Bearer your-api-token-here
```

Get your token by logging in via the API or find it in your user profile in the admin panel.

### Rate Limiting

- **Limit**: 1000 requests per hour per user
- **Headers**: Rate limit info in response headers
- **Reset**: Automatically resets every hour

## API (Legacy Section)

### Template Customizer API

**Load Template**
```
GET /admin/template_customizer/:id/load
```

**Update Template**
```
PATCH /admin/template_customizer/:id
Content-Type: application/json

{
  "template": {
    "html_content": "...",
    "css_content": "...",
    "js_content": "..."
  }
}
```

## Customization

### Adding Custom Plugins

1. Create a plugin in the database:
```ruby
Plugin.create!(
  name: 'My Plugin',
  description: 'Custom functionality',
  author: 'Your Name',
  version: '1.0.0',
  active: true
)
```

2. Implement plugin logic in `lib/plugins/my_plugin.rb`

### Creating Custom Widgets

```ruby
Widget.create!(
  title: 'My Widget',
  widget_type: 'custom_html',
  content: '<div>Widget content</div>',
  sidebar_location: 'primary',
  active: true
)
```

### Site Settings

Configure site-wide settings:

```ruby
SiteSetting.set('site_title', 'My Site', 'string')
SiteSetting.set('posts_per_page', '10', 'integer')
SiteSetting.set('comments_enabled', 'true', 'boolean')
```

## Development

### Running Tests
```bash
rails test
```

### Code Quality
```bash
rubocop
```

### Database Console
```bash
rails dbconsole
```

### Rails Console
```bash
rails console
```

## Deployment

### Production Setup

1. **Set environment variables:**
```bash
export RAILS_ENV=production
export SECRET_KEY_BASE=your_secret_key
export DATABASE_URL=your_database_url
```

2. **Precompile assets:**
```bash
rails assets:precompile
```

3. **Run migrations:**
```bash
rails db:migrate
```

4. **Start the server:**
```bash
rails server -e production
```

### Recommended Hosting
- Heroku
- AWS (Elastic Beanstalk, EC2)
- DigitalOcean
- Render
- Fly.io

## Architecture

### Models
- `User` - User authentication and authorization
- `Post` - Blog posts
- `Page` - Static pages
- `Category` - Hierarchical categories
- `Tag` - Tags for posts
- `Comment` - Comments on posts/pages
- `Medium` - Media files
- `Menu` - Navigation menus
- `MenuItem` - Menu items
- `Widget` - Sidebar widgets
- `Theme` - Site themes
- `Template` - Template files for themes
- `Plugin` - Extensible plugins
- `SiteSetting` - Configuration settings

### Key Gems
- `devise` - Authentication
- `friendly_id` - URL slugs
- `kaminari` - Pagination
- `meta-tags` - SEO
- `image_processing` - Image handling
- `sidekiq` - Background jobs
- `redis` - Caching

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is open source and available under the MIT License.

## Support

For issues, questions, or contributions, please visit the GitHub repository.

## Roadmap

### Upcoming Features
- [ ] Advanced SEO tools
- [ ] XML Sitemap generation
- [ ] RSS/Atom feeds
- [ ] Email notifications
- [ ] Advanced analytics
- [ ] Multi-language support (i18n)
- [ ] Custom post types
- [ ] Advanced caching strategies
- [ ] API endpoints (REST/GraphQL)
- [ ] Import/Export functionality
- [ ] Revision history
- [ ] User profiles and avatars
- [ ] Social media integration
- [ ] Advanced search with Elasticsearch

## Credits

Built with ❤️ using Ruby on Rails and powered by:
- GrapesJS for the visual template builder
- Tailwind CSS for styling
- Trix editor for rich text editing

---

**RailsPress** - Bringing WordPress-like simplicity to Rails development.
