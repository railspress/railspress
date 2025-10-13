# RailsPress CLI Quick Reference

**One-page cheat sheet for common commands**

## 🚀 Getting Started

```bash
# Show help
./bin/railspress-cli --help

# Show version
./bin/railspress-cli --version

# Run health check
./bin/railspress-cli doctor:check
```

## 💾 Database

```bash
railspress-cli db:seed                  # Seed database
railspress-cli db:reset                 # Reset everything
railspress-cli db:migrate               # Run migrations
railspress-cli db:rollback              # Undo last migration
```

## 👤 Users

```bash
# List users
railspress-cli user:list
railspress-cli user:list --format=json

# Create user
railspress-cli user:create EMAIL --role=ROLE

# Delete user
railspress-cli user:delete ID

# Update user
railspress-cli user:update ID --role=ROLE
```

**Roles**: `administrator`, `editor`, `author`, `contributor`, `subscriber`

## 📝 Posts

```bash
# List posts
railspress-cli post:list
railspress-cli post:list --status=published
railspress-cli post:list --limit=10

# Create post
railspress-cli post:create --title="TITLE" --content="CONTENT"

# Publish post
railspress-cli post:publish ID

# Delete post
railspress-cli post:delete ID
```

## 📄 Pages

```bash
# List pages
railspress-cli page:list

# Create page
railspress-cli page:create --title="TITLE"

# Publish page
railspress-cli page:publish ID

# Delete page
railspress-cli page:delete ID
```

## 🎨 Themes

```bash
# List themes
railspress-cli theme:list

# Activate theme
railspress-cli theme:activate THEME_NAME

# Check active theme
railspress-cli theme:status
```

## 🔌 Plugins

```bash
# List plugins
railspress-cli plugin:list

# Activate plugin
railspress-cli plugin:activate PLUGIN_NAME

# Deactivate plugin
railspress-cli plugin:deactivate PLUGIN_NAME
```

## 🗑️ Cache

```bash
# Clear Rails cache
railspress-cli cache:clear

# Flush Redis cache
railspress-cli cache:flush
```

## ⚙️ Options (Settings)

```bash
# List all settings
railspress-cli option:list

# Get setting
railspress-cli option:get KEY

# Set setting
railspress-cli option:set KEY VALUE

# Delete setting
railspress-cli option:delete KEY
```

**Common Settings:**
- `site_title` - Site name
- `site_tagline` - Site description
- `posts_per_page` - Posts per page
- `active_theme` - Current theme

## 🔍 Search

```bash
# Search posts
railspress-cli search:posts "QUERY"

# Search pages
railspress-cli search:pages "QUERY"
```

## 📦 Media

```bash
# List media files
railspress-cli media:list
```

## 💻 Shell

```bash
# Open Rails console
railspress-cli shell:console
```

## 🏥 Doctor

```bash
# Run system health check
railspress-cli doctor:check
```

---

## 🎯 Common Workflows

### Initial Setup
```bash
railspress-cli db:create
railspress-cli db:migrate
railspress-cli db:seed
railspress-cli user:create admin@site.com --role=administrator
railspress-cli theme:activate scandiedge
```

### Create Content
```bash
railspress-cli post:create --title="My Post" --content="Content here"
railspress-cli page:create --title="About Us"
railspress-cli post:list
```

### Maintenance
```bash
railspress-cli cache:clear
railspress-cli doctor:check
railspress-cli core:update-db
```

### User Management
```bash
railspress-cli user:list
railspress-cli user:create editor@site.com --role=editor
railspress-cli user:update 5 --role=administrator
```

---

## 🎨 Output Formats

Add `--format=FORMAT` to most list commands:

- `table` (default) - Nice table display
- `json` - JSON output for scripting
- `csv` - CSV for spreadsheets

```bash
railspress-cli user:list --format=json
railspress-cli post:list --format=csv
```

---

## 🔧 Common Flags

```bash
--help              # Show help for command
--format=FORMAT     # Output format (table, json, csv)
--status=STATUS     # Filter by status
--role=ROLE         # Specify user role
--limit=N           # Limit results to N items
--title="TEXT"      # Set title
--content="TEXT"    # Set content
--password="PASS"   # Set password
```

---

## 📋 Examples

### Create Admin User
```bash
railspress-cli user:create admin@example.com \
  --role=administrator \
  --password=securepass123
```

### Publish Multiple Posts
```bash
railspress-cli post:publish 1
railspress-cli post:publish 2
railspress-cli post:publish 3
```

### Export Users to JSON
```bash
railspress-cli user:list --format=json > users.json
```

### Activate Theme and Clear Cache
```bash
railspress-cli theme:activate scandiedge && \
railspress-cli cache:clear
```

### Check System Health
```bash
railspress-cli doctor:check
```

---

## 🚨 Destructive Commands

**⚠️ These commands delete data - use carefully!**

```bash
railspress-cli db:drop      # Drop database
railspress-cli db:reset     # Reset database
railspress-cli user:delete  # Delete user
railspress-cli post:delete  # Delete post
```

---

## 🔗 Aliases

Create shortcuts in your shell config:

```bash
# Add to ~/.bashrc or ~/.zshrc
alias rp='./bin/railspress-cli'
alias rpu='./bin/railspress-cli user'
alias rpp='./bin/railspress-cli post'

# Use them:
rp theme:list
rpu:list
rpp:create --title="Quick Post"
```

---

## 📚 More Help

```bash
# General help
railspress-cli --help

# Command-specific help
railspress-cli user --help
railspress-cli post --help
railspress-cli theme --help
```

**Full documentation**: See `CLI_DOCUMENTATION.md`

---

*Quick reference for RailsPress CLI v1.0.0*



