# RailsPress Default Seeds

This document describes the minimal default content that RailsPress creates on fresh installation, matching WordPress's default setup.

## 📦 What Gets Seeded

### 1. Users (1)
```json
{
  "email": "admin@example.com",
  "password": "password",
  "role": "administrator",
  "name": "admin"
}
```

### 2. Taxonomies (3)

#### category (Hierarchical)
- **Singular:** Category
- **Plural:** Categories
- **Description:** Organize posts into categories
- **Object Types:** Post
- **Default Term:** Uncategorized
- **Public:** Yes

#### tag (Flat)
- **Singular:** Tag
- **Plural:** Tags
- **Description:** Tag your posts with keywords
- **Object Types:** Post
- **Default Terms:** None (empty until used)
- **Public:** Yes

#### post_format (Flat)
- **Singular:** Format
- **Plural:** Formats
- **Description:** Post format types (video, audio, gallery, etc.)
- **Object Types:** Post
- **Default Terms:** None (available but empty)
- **Public:** No (theme feature)

### 3. Posts (1)

**"Hello world!"**
- **Slug:** `hello-world`
- **Content:** "Welcome to RailsPress. This is your first post. Edit or delete it, then start writing!"
- **Status:** Published
- **Author:** admin
- **Categories:** Uncategorized
- **Tags:** None
- **Comments:** 1

### 4. Comments (1)

**On "Hello world!"**
- **Author:** A WordPress Commenter
- **Email:** wapuu@wordpress.example
- **Content:** "Hi, this is a comment. To get started with moderating, editing, and deleting comments, please visit the Comments screen in the dashboard. Commenter avatars come from Gravatar."
- **Status:** Approved

### 5. Pages (1)

**"Sample Page"**
- **Slug:** `sample-page`
- **Title:** Sample Page
- **Content:** Example page content with placeholder text
- **Status:** Published
- **Author:** admin

### 6. Navigation Menus (1)

**Primary Menu**
- Home → `/`
- Sample Page → `/page/sample-page`

### 7. Site Settings

```json
{
  "site_title": "Nordic Minimal",
  "site_description": "Just another RailsPress site",
  "posts_per_page": "10",
  "active_theme": "nordic",
  "headless_mode": false,
  "cors_enabled": false,
  "cors_origins": "*",
  "command_palette_shortcut": "cmd+k"
}
```

## 🚀 Running Seeds

### Fresh Installation
```bash
rails db:setup
```

### Reset Database (Development)
```bash
rails db:reset
```

### Specific Environment
```bash
RAILS_ENV=production rails db:seed
```

## 🔐 Default Login

- **URL:** http://localhost:3000/admin
- **Email:** admin@example.com
- **Password:** password

⚠️ **Change this password immediately in production!**

## 📊 Summary

| Resource | Count | Notes |
|----------|-------|-------|
| Users | 1 | Admin only |
| Posts | 1 | "Hello world!" |
| Pages | 1 | "Sample Page" |
| Comments | 1 | On first post |
| Taxonomies | 3 | category, tag, post_format |
| Terms | 1 | Uncategorized |
| Menus | 1 | Primary with 2 items |

## 🎯 Philosophy

RailsPress follows WordPress's philosophy of **"Decisions, not options"** for default content:

1. **Minimal but complete** - Just enough to demonstrate all features
2. **Educational** - Sample content teaches users how the system works
3. **Deletable** - Everything can be safely deleted by users
4. **WordPress-compatible** - Familiar to WP users

## 🔄 Comparison with WordPress

| Feature | WordPress | RailsPress | Match |
|---------|-----------|------------|-------|
| Default user | admin | admin | ✅ |
| Default post | "Hello world!" | "Hello world!" | ✅ |
| Default page | "Sample Page" | "Sample Page" | ✅ |
| Default comment | 1 on first post | 1 on first post | ✅ |
| Default category | Uncategorized | Uncategorized | ✅ |
| Default tags | None | None | ✅ |
| Default menu | Home, Sample Page | Home, Sample Page | ✅ |

## 🛠️ Customizing Seeds

To customize the default content, edit `db/seeds.rb` before running:

```ruby
# Change default user
admin = User.find_or_create_by!(email: 'your@email.com') do |user|
  user.password = 'your_secure_password'
  user.role = 'administrator'
  user.name = 'Your Name'
end

# Change site settings
default_settings = {
  'site_title' => 'Your Site Name',
  'site_description' => 'Your site description',
  # ...
}
```

## 📚 Related Documentation

- [Installation Guide](./INSTALLATION.md)
- [Taxonomy System](../features/taxonomy-system.md)
- [User Roles](../features/user-roles.md)
- [Menu System](../features/menu-system.md)





