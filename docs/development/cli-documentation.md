# RailsPress CLI Documentation

**WP-CLI inspired command-line interface for RailsPress**

## 📚 Table of Contents

- [Introduction](#introduction)
- [Installation](#installation)
- [Command Reference](#command-reference)
- [Examples & Workflows](#examples--workflows)
- [Comparison with WP-CLI](#comparison-with-wp-cli)
- [Advanced Usage](#advanced-usage)

---

## Introduction

The **RailsPress CLI** is a powerful command-line tool inspired by [WP-CLI](https://wp-cli.org/), designed to manage your RailsPress installation from the terminal. It provides WordPress-like commands for managing users, posts, pages, themes, plugins, and more.

### Why RailsPress CLI?

- 🚀 **Fast** - Bypass the web interface for quick operations
- 🤖 **Scriptable** - Automate repetitive tasks
- 💪 **Powerful** - Access features not available in the admin
- 🎯 **Familiar** - WordPress developers feel right at home

---

## Installation

The CLI is already installed! Just make it executable:

```bash
chmod +x bin/railspress-cli
```

### Create an Alias (Optional)

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
alias wp="./bin/railspress-cli"
```

Now you can use `wp` just like WP-CLI:

```bash
wp user:list
wp post:create --title="Hello World"
```

---

## Command Reference

### Core Commands

Manage the RailsPress core system.

```bash
# Display version information
railspress-cli core:version

# Check for updates
railspress-cli core:check-update

# Update database schema
railspress-cli core:update-db
```

---

### Database Commands

Manage your database.

```bash
# Seed the database with sample data
railspress-cli db:seed

# Reset database (drop, create, migrate, seed)
railspress-cli db:reset

# Create database
railspress-cli db:create

# Drop database (requires confirmation)
railspress-cli db:drop

# Run migrations
railspress-cli db:migrate

# Rollback last migration
railspress-cli db:rollback

# Rollback multiple steps
railspress-cli db:rollback --steps=3
```

**⚠️ Warning**: `db:reset` and `db:drop` will destroy all data!

---

### User Commands

Manage users and their roles.

#### List Users

```bash
# List all users in table format
railspress-cli user:list

# List users in JSON format
railspress-cli user:list --format=json

# List users in CSV format
railspress-cli user:list --format=csv
```

#### Create User

```bash
# Create with auto-generated password
railspress-cli user:create admin@example.com --role=administrator

# Create with custom password
railspress-cli user:create editor@example.com --role=editor --password=securepass123

# Create subscriber (default role)
railspress-cli user:create user@example.com
```

**Available Roles:**
- `administrator` - Full access
- `editor` - Edit posts/pages
- `author` - Create own posts
- `contributor` - Submit posts for review
- `subscriber` - Read-only access

#### Update User

```bash
# Change user role
railspress-cli user:update 5 --role=editor

# Update email (future)
railspress-cli user:update 5 --email=newemail@example.com
```

#### Delete User

```bash
# Delete user by ID
railspress-cli user:delete 5
```

---

### Post Commands

Manage blog posts.

#### List Posts

```bash
# List all posts
railspress-cli post:list

# List published posts only
railspress-cli post:list --status=published

# List drafts
railspress-cli post:list --status=draft

# Limit results
railspress-cli post:list --limit=10

# Output as JSON
railspress-cli post:list --format=json
```

#### Create Post

```bash
# Create draft post
railspress-cli post:create --title="My New Post" --content="Post content here"

# Create and publish immediately
railspress-cli post:create --title="Published Post" --content="Content" --status=published

# Create with auto-generated title
railspress-cli post:create --content="Just the content"
```

#### Publish Post

```bash
# Publish a draft post
railspress-cli post:publish 10
```

#### Delete Post

```bash
# Delete post by ID
railspress-cli post:delete 10

# Delete post by slug
railspress-cli post:delete my-post-slug
```

---

### Page Commands

Manage static pages.

```bash
# List all pages
railspress-cli page:list

# Create new page
railspress-cli page:create --title="About Us" --status=published

# Publish draft page
railspress-cli page:publish 5

# Delete page
railspress-cli page:delete 5
```

---

### Theme Commands

Manage themes like WordPress.

#### List Themes

```bash
# List all available themes
railspress-cli theme:list
```

Example output:
```
Available Themes:
* scandiedge (active)
  default
  dark

Total: 3 themes
```

#### Activate Theme

```bash
# Activate ScandiEdge theme
railspress-cli theme:activate scandiedge

# Activate default theme
railspress-cli theme:activate default
```

#### Check Active Theme

```bash
# Display currently active theme
railspress-cli theme:status
```

---

### Plugin Commands

Manage plugins.

#### List Plugins

```bash
# List all plugins with status
railspress-cli plugin:list
```

Example output:
```
Name                  | Version | Status
---------------------+---------+--------
SEO Optimizer Pro     | 1.0.0   | Active
Sitemap Generator     | 1.2.0   | Active
Related Posts         | 1.0.0   | Inactive
```

#### Activate Plugin

```bash
# Activate a plugin
railspress-cli plugin:activate seo_optimizer_pro
```

#### Deactivate Plugin

```bash
# Deactivate a plugin
railspress-cli plugin:deactivate seo_optimizer_pro
```

---

### Cache Commands

Manage caching.

```bash
# Clear all Rails caches
railspress-cli cache:clear

# Flush Redis cache
railspress-cli cache:flush
```

---

### Media Commands

Manage media library.

```bash
# List all media files
railspress-cli media:list
```

---

### Option Commands

Manage site settings (like `wp option`).

#### List All Options

```bash
# List all site settings
railspress-cli option:list
```

#### Get Option

```bash
# Get a setting value
railspress-cli option:get site_title
railspress-cli option:get site_tagline
railspress-cli option:get posts_per_page
```

#### Set Option

```bash
# Set a setting value
railspress-cli option:set site_title "My Awesome Site"
railspress-cli option:set posts_per_page 10
railspress-cli option:set active_theme scandiedge
```

#### Delete Option

```bash
# Delete a setting
railspress-cli option:delete custom_setting
```

---

### Search Commands

Search content.

```bash
# Search posts
railspress-cli search:posts "ruby on rails"

# Search pages
railspress-cli search:pages "about"
```

---

### Export Commands

Export content (WordPress-style).

```bash
# Export all content
railspress-cli export:all

# Export posts only
railspress-cli export:posts
```

---

### Import Commands

Import content from other platforms.

```bash
# Import from WordPress XML export
railspress-cli import:wordpress export.xml
```

---

### Shell Commands

Access Rails console.

```bash
# Open interactive Rails console
railspress-cli shell:console
```

This is equivalent to `rails console` but follows the CLI naming convention.

---

### Doctor Commands

System health checks.

```bash
# Run all health checks
railspress-cli doctor:check
```

Example output:
```
RailsPress System Health Check

Database connection... ✓ OK
Redis connection... ✓ OK
File permissions... ✓ OK
Loading models... ✓ OK

Diagnostics complete!
```

---

## Examples & Workflows

### Quick Setup Workflow

```bash
# 1. Setup database
railspress-cli db:create
railspress-cli db:migrate
railspress-cli db:seed

# 2. Create admin user
railspress-cli user:create admin@example.com --role=administrator --password=admin123

# 3. Activate theme
railspress-cli theme:activate scandiedge

# 4. Check system health
railspress-cli doctor:check
```

### Content Creation Workflow

```bash
# 1. Create multiple posts
for i in {1..5}; do
  railspress-cli post:create --title="Post $i" --content="Content for post $i"
done

# 2. List all posts
railspress-cli post:list

# 3. Publish specific posts
railspress-cli post:publish 1
railspress-cli post:publish 2
```

### User Management Workflow

```bash
# 1. Create team members
railspress-cli user:create editor@site.com --role=editor
railspress-cli user:create writer1@site.com --role=author
railspress-cli user:create writer2@site.com --role=author

# 2. List all users
railspress-cli user:list

# 3. Promote a user
railspress-cli user:update 3 --role=editor
```

### Theme Development Workflow

```bash
# 1. Check current theme
railspress-cli theme:status

# 2. List available themes
railspress-cli theme:list

# 3. Switch to development theme
railspress-cli theme:activate my-custom-theme

# 4. Clear cache after changes
railspress-cli cache:clear
```

### Maintenance Workflow

```bash
# 1. Backup (export all content)
railspress-cli export:all > backup.json

# 2. Clear caches
railspress-cli cache:clear
railspress-cli cache:flush

# 3. Check system health
railspress-cli doctor:check

# 4. Update database if needed
railspress-cli core:update-db
```

### Search & Cleanup Workflow

```bash
# 1. Find spam posts
railspress-cli search:posts "spam keyword"

# 2. Delete them
railspress-cli post:delete 100
railspress-cli post:delete 101

# 3. List remaining posts
railspress-cli post:list
```

---

## Comparison with WP-CLI

RailsPress CLI mirrors WP-CLI commands for familiarity:

| WP-CLI Command | RailsPress CLI | Notes |
|----------------|----------------|-------|
| `wp core version` | `railspress-cli core:version` | Shows version |
| `wp db reset` | `railspress-cli db:reset` | Reset database |
| `wp user list` | `railspress-cli user:list` | List users |
| `wp user create` | `railspress-cli user:create` | Create user |
| `wp post list` | `railspress-cli post:list` | List posts |
| `wp post create` | `railspress-cli post:create` | Create post |
| `wp theme list` | `railspress-cli theme:list` | List themes |
| `wp theme activate` | `railspress-cli theme:activate` | Activate theme |
| `wp plugin list` | `railspress-cli plugin:list` | List plugins |
| `wp plugin activate` | `railspress-cli plugin:activate` | Activate plugin |
| `wp cache clear` | `railspress-cli cache:clear` | Clear cache |
| `wp option get` | `railspress-cli option:get` | Get setting |
| `wp option set` | `railspress-cli option:set` | Set setting |
| `wp search-replace` | `railspress-cli search:posts` | Search content |
| `wp shell` | `railspress-cli shell:console` | Interactive console |
| `wp doctor` | `railspress-cli doctor:check` | Health check |

---

## Advanced Usage

### Piping and Scripting

#### Export to File

```bash
# Export users to JSON
railspress-cli user:list --format=json > users.json

# Export posts to JSON
railspress-cli post:list --format=json > posts.json
```

#### Batch Operations

```bash
#!/bin/bash
# Create 100 test posts

for i in {1..100}; do
  railspress-cli post:create \
    --title="Test Post $i" \
    --content="Content for test post number $i" \
    --status=draft
done

echo "Created 100 test posts!"
```

#### User Provisioning Script

```bash
#!/bin/bash
# provision-users.sh

# Read from CSV and create users
while IFS=',' read -r email role; do
  railspress-cli user:create "$email" --role="$role"
done < users.csv
```

### Integration with Git Hooks

#### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run health checks before commit
./bin/railspress-cli doctor:check || exit 1
```

#### Post-merge Hook

```bash
#!/bin/bash
# .git/hooks/post-merge

# Update database after pulling changes
./bin/railspress-cli core:update-db
./bin/railspress-cli cache:clear
```

### Cron Jobs

```bash
# Daily backup at 2 AM
0 2 * * * cd /path/to/railspress && ./bin/railspress-cli export:all > backups/backup-$(date +\%Y\%m\%d).json

# Clear cache every 6 hours
0 */6 * * * cd /path/to/railspress && ./bin/railspress-cli cache:clear

# Health check every hour
0 * * * * cd /path/to/railspress && ./bin/railspress-cli doctor:check >> logs/health.log
```

### Docker Integration

```dockerfile
# Dockerfile
FROM ruby:3.2

WORKDIR /app
COPY . .

RUN bundle install
RUN chmod +x bin/railspress-cli

# Use CLI in entrypoint
ENTRYPOINT ["./bin/railspress-cli"]
```

Usage:
```bash
docker run my-railspress user:list
docker run my-railspress post:create --title="Docker Post"
```

### CI/CD Integration

#### GitHub Actions

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
      
      - name: Install dependencies
        run: bundle install
      
      - name: Update database
        run: ./bin/railspress-cli core:update-db
      
      - name: Clear cache
        run: ./bin/railspress-cli cache:clear
      
      - name: Health check
        run: ./bin/railspress-cli doctor:check
```

### Remote Server Management

```bash
# SSH into server and run commands
ssh user@server 'cd /var/www/railspress && ./bin/railspress-cli cache:clear'

# Or create an alias
alias wp-prod='ssh user@server "cd /var/www/railspress && ./bin/railspress-cli"'

# Now use it
wp-prod user:list
wp-prod post:create --title="Remote Post"
```

---

## Environment Variables

Control CLI behavior with environment variables:

```bash
# Enable debug mode
DEBUG=1 railspress-cli user:list

# Set Rails environment
RAILS_ENV=production railspress-cli db:migrate

# Combine both
RAILS_ENV=production DEBUG=1 railspress-cli doctor:check
```

---

## Output Formats

Many commands support multiple output formats:

```bash
# Table format (default)
railspress-cli user:list

# JSON format (for scripting)
railspress-cli user:list --format=json

# CSV format (for spreadsheets)
railspress-cli user:list --format=csv
```

---

## Error Handling

The CLI provides clear error messages:

```bash
# User not found
$ railspress-cli user:delete 9999
✗ User not found: 9999

# Invalid command
$ railspress-cli invalid:command
✗ Unknown command: invalid
```

---

## Tips & Tricks

### 1. Create Aliases

```bash
# In ~/.bashrc or ~/.zshrc
alias rpcli="./bin/railspress-cli"
alias rpuser="./bin/railspress-cli user"
alias rppost="./bin/railspress-cli post"
alias rpcache="./bin/railspress-cli cache:clear"

# Now use them
rpuser:list
rppost:create --title="Quick Post"
rpcache
```

### 2. Autocomplete (Future)

```bash
# Add to shell config for autocomplete
eval "$(railspress-cli completion)"
```

### 3. Quick Lookups

```bash
# Find post by title
railspress-cli search:posts "title keyword"

# Get user by email
railspress-cli user:list --format=json | jq '.[] | select(.email=="admin@example.com")'
```

### 4. Bulk Operations

```bash
# Delete all draft posts
railspress-cli post:list --status=draft --format=json | \
  jq -r '.[].id' | \
  xargs -I {} railspress-cli post:delete {}
```

### 5. Monitoring

```bash
# Watch post count
watch -n 5 'railspress-cli post:list | tail -1'

# Monitor user growth
while true; do
  railspress-cli user:list | tail -1
  sleep 60
done
```

---

## Troubleshooting

### Command Not Found

```bash
# Make sure it's executable
chmod +x bin/railspress-cli

# Check if file exists
ls -la bin/railspress-cli
```

### Rails Not Loading

```bash
# Make sure you're in the Rails root
cd /path/to/railspress

# Check if bundle is installed
bundle install
```

### Database Errors

```bash
# Check database connection
railspress-cli doctor:check

# Reset if needed
railspress-cli db:reset
```

### Permission Errors

```bash
# Fix file permissions
chmod +x bin/railspress-cli
chmod -R 755 tmp/
```

---

## Future Enhancements

Planned features:

- ✅ All core commands implemented
- 🔄 Import/Export functionality (in progress)
- 📋 Shell autocomplete
- 🔍 Advanced search filters
- 📊 Analytics commands
- 🔐 Security audit commands
- 📦 Backup/restore commands
- 🌐 Multi-site management
- 📧 Email commands
- 🎨 Theme scaffolding
- 🔌 Plugin generator

---

## Contributing

Want to add new commands? See `bin/railspress-cli` and add a new command class!

Example:
```ruby
class CustomCommands < BaseCommands
  def print_help
    # Help text
  end

  def my_command
    # Implementation
  end
end
```

---

## Resources

- **WP-CLI Documentation**: https://wp-cli.org/
- **Rails Guides**: https://guides.rubyonrails.org/
- **RailsPress Docs**: See README.md

---

**Version**: 1.0.0  
**License**: MIT  
**Inspired by**: WP-CLI (WordPress Command Line Interface)

---

*Happy commanding! 🚀*



