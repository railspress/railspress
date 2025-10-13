# 🚀 RailsPress Quick Start Guide

**Get up and running in 5 minutes!**

---

## ⚡ Quick Setup (One Command!)

```bash
# Complete setup (database, admin user, demo content)
./scripts/quick-setup.sh

# Then start the server
./railspress start
# or
bin/dev
```

That's it! Your CMS is ready! 🎉

---

## 🔐 Default Login Credentials

### Admin Access

**Login URL**: http://localhost:3000/auth/sign_in

**Credentials:**
- **Email**: `admin@railspress.com`
- **Password**: `password`

⚠️ **Change this password immediately!**

---

## 🌐 Access Points

After logging in, you can access:

### Frontend
- **Homepage**: http://localhost:3000
- **Blog**: http://localhost:3000/blog
- **Sample Post**: http://localhost:3000/blog/welcome-to-railspress

### Admin Dashboard
- **Main Dashboard**: http://localhost:3000/admin
- **Posts**: http://localhost:3000/admin/posts
- **Pages**: http://localhost:3000/admin/pages
- **Media**: http://localhost:3000/admin/media
- **Comments**: http://localhost:3000/admin/comments

### Appearance
- **Themes**: http://localhost:3000/admin/themes
- **Template Customizer** (GrapesJS): http://localhost:3000/admin/template_customizer
- **Theme Editor** (Monaco): http://localhost:3000/admin/theme_editor
- **Menus**: http://localhost:3000/admin/menus
- **Widgets**: http://localhost:3000/admin/widgets

### Content Organization
- **Categories**: http://localhost:3000/admin/categories
- **Tags**: http://localhost:3000/admin/tags
- **Taxonomies**: http://localhost:3000/admin/taxonomies

### Extensions
- **Plugins**: http://localhost:3000/admin/plugins
- **Shortcodes**: http://localhost:3000/admin/shortcodes
- **Webhooks**: http://localhost:3000/admin/webhooks

### Settings
- **General**: http://localhost:3000/admin/settings/general
- **Writing**: http://localhost:3000/admin/settings/writing
- **Reading**: http://localhost:3000/admin/settings/reading
- **Email**: http://localhost:3000/admin/settings/email
- **Privacy**: http://localhost:3000/admin/settings/privacy

### System
- **Users**: http://localhost:3000/admin/users
- **Updates**: http://localhost:3000/admin/updates
- **Cache**: http://localhost:3000/admin/cache
- **Email Logs**: http://localhost:3000/admin/email_logs

### Developer Tools
- **API Docs**: http://localhost:3000/api/v1/docs
- **GraphQL Playground**: http://localhost:3000/graphiql
- **Feature Flags**: http://localhost:3000/admin/flipper
- **Background Jobs**: http://localhost:3000/admin/sidekiq

---

## 🎨 Using the Editors

### Template Customizer (GrapesJS) - Visual Editor

**Best for**: Page layouts, visual design, drag & drop

1. Login at http://localhost:3000/auth/sign_in
2. Go to **Admin → Customize**
3. Or visit: http://localhost:3000/admin/template_customizer
4. Select a template (Header, Footer, Homepage, etc.)
5. Drag & drop components
6. Customize styles
7. Click "Save"

**Features:**
- Drag & drop interface
- Pre-built components
- Visual styling
- No code required

### Theme Editor (Monaco) - Code Editor

**Best for**: Theme development, file editing, customization

1. Login at http://localhost:3000/auth/sign_in
2. Go to **Admin → Theme Editor**
3. Or visit: http://localhost:3000/admin/theme_editor
4. Browse file tree in left sidebar
5. Click file to edit
6. Make changes in Monaco editor
7. Press `Cmd+S` or click "Save"

**Features:**
- VS Code-style editor
- Syntax highlighting
- Auto-completion
- Version control
- Search in files
- Format on save

---

## 🎯 Common Tasks

### Change Theme

```bash
# Via CLI
./bin/railspress-cli theme list
./bin/railspress-cli theme activate scandiedge

# Via Admin
# Go to Admin → Themes → Click "Activate" on desired theme
```

### Create Content

```bash
# Via CLI
./bin/railspress-cli post create --title="My First Post" --content="Hello World"
./bin/railspress-cli page create --title="About Us"

# Via Admin
# Go to Admin → Posts → Add New
# Go to Admin → Pages → Add New
```

### Customize Design

**Visual (GrapesJS)**:
1. Go to Template Customizer
2. Edit templates visually
3. Save changes

**Code (Monaco)**:
1. Go to Theme Editor
2. Edit theme files
3. Save with Cmd+S

### Setup Webhooks

1. Go to **Admin → Webhooks**
2. Click "Add Webhook"
3. Enter URL and select events
4. Save

### Use GraphQL

1. Visit: http://localhost:3000/graphiql
2. Run queries:
```graphql
{
  posts(limit: 5) {
    id
    title
    author { email }
  }
}
```

---

## 📋 Step-by-Step First Use

### 1. Initial Setup

```bash
# Clone or navigate to project
cd railspress

# Run quick setup
./scripts/quick-setup.sh

# This will:
# - Install dependencies
# - Create database
# - Run migrations
# - Seed sample data
# - Create admin user
# - Activate ScandiEdge theme
```

### 2. Start Server

```bash
./railspress start
```

Wait for: "Listening on http://0.0.0.0:3000"

### 3. Login

1. Open: http://localhost:3000/auth/sign_in
2. Email: `admin@railspress.com`
3. Password: `password`
4. Click "Log in"

### 4. Explore

- View Dashboard
- Click through sidebar menu
- Check out the ScandiEdge theme on frontend
- Try the Template Customizer (GrapesJS)
- Try the Theme Editor (Monaco)

---

## 🎨 Activate ScandiEdge Theme

The premium Scandinavian theme!

```bash
# Via CLI (Recommended)
./bin/railspress-cli theme activate scandiedge

# Via Admin
1. Login
2. Go to Admin → Themes
3. Find "ScandiEdge"
4. Click "Activate"

# Via Console
rails console
SiteSetting.set('active_theme', 'scandiedge')
```

Then visit the frontend to see the beautiful design!

---

## 🛠️ Using the CLI

```bash
# Show all commands
./bin/railspress-cli --help

# List users
./bin/railspress-cli user list

# Create post
./bin/railspress-cli post create --title="CLI Post"

# Check for updates
./bin/railspress-cli core check-update

# View theme status
./bin/railspress-cli theme status

# Clear cache
./bin/railspress-cli cache clear
```

---

## 📚 Documentation

### Getting Started
- This file: `QUICK_START_GUIDE.md`
- Login info: `LOGIN_CREDENTIALS.md`
- Main docs: `README.md`

### Features
- **ScandiEdge Theme**: `SCANDIEDGE_THEME_SUMMARY.md`
- **CLI Tool**: `CLI_QUICK_REFERENCE.md`
- **GraphQL API**: `GRAPHQL_QUICK_REFERENCE.md`
- **Webhooks**: `WEBHOOKS_QUICK_REFERENCE.md`
- **Theme Editor**: `THEME_EDITOR_GUIDE.md`

### Full Documentation
- 30+ markdown files
- 8,000+ lines of documentation
- Complete guides for every feature

---

## 🐛 Troubleshooting

### Can't Login?

**Check credentials:**
```bash
./bin/railspress-cli user list
```

**Reset password:**
```bash
rails console
User.first.update!(password: 'newpass', password_confirmation: 'newpass')
```

### Server Won't Start?

**Check if port 3000 is in use:**
```bash
lsof -ti:3000
```

**Kill and restart:**
```bash
lsof -ti:3000 | xargs kill -9
./railspress start
```

### Database Errors?

**Reset database:**
```bash
./bin/railspress-cli db reset
```

### CSS Not Loading?

**Restart Tailwind watcher:**
```bash
# Stop server
# Restart with:
bin/dev
```

---

## 🎯 Next Steps

### 1. Change Password

```bash
./bin/railspress-cli user update 1 --password=SecurePassword123
```

### 2. Create Content

- Create posts via Admin → Posts
- Create pages via Admin → Pages
- Upload media via Admin → Media

### 3. Customize Theme

**Visual Way:**
- Use Template Customizer (GrapesJS)

**Code Way:**
- Use Theme Editor (Monaco)
- Edit files directly

### 4. Setup Integrations

- Configure webhooks for notifications
- Set up email (SMTP or Resend)
- Connect to external services

### 5. Configure SEO

- Edit posts/pages
- Fill in meta fields
- Add Open Graph images
- Set focus keyphrases

---

## 🏆 What's Included

✨ **Premium Theme** (ScandiEdge)  
✨ **Visual Editor** (GrapesJS)  
✨ **Code Editor** (Monaco)  
✨ **CLI Tool** (50+ commands)  
✨ **GraphQL API** (8 types, 30+ queries)  
✨ **REST API** (Complete v1)  
✨ **Webhooks** (14 events)  
✨ **SEO System** (14 meta fields)  
✨ **Auto-Updates** (GitHub)  
✨ **Complete Documentation** (30 files)  

---

## 📞 Help & Support

### Documentation
- See all `.md` files in project root
- Each feature has a complete guide

### CLI Help
```bash
./bin/railspress-cli --help
./bin/railspress-cli user --help
./bin/railspress-cli post --help
```

### Console
```bash
rails console
# Access all models and methods
```

### Health Check
```bash
./bin/railspress-cli doctor check
```

---

## 🎊 You're Ready!

Your RailsPress installation is complete and ready to use!

**Login**: http://localhost:3000/auth/sign_in  
**Admin**: http://localhost:3000/admin  
**Frontend**: http://localhost:3000  

**Happy building with RailsPress!** 🚀✨

---

*For detailed documentation, see README.md and other guides in the project root.*



