# Menu System in Nordic Theme

## Overview

The Nordic theme has full integration with RailsPress's menu system, supporting both database-managed menus and theme-defined menus.

## How It Works

### Menu Loading Priority

1. **Theme YAML File** (if exists): `app/themes/nordic/data/menus.yml`
2. **Database Menus** (fallback): Managed via Admin > Menus

### Current Implementation

#### Header Menu
Location: `sections/header.liquid`

```liquid
<header class="header">
  <a class="brand" href="/">{{ site.title }}</a>
  <nav class="nav">
    {% for item in site.menus.primary %}
      <a href="{{ item.url }}">{{ item.title }}</a>
    {% endfor %}
  </nav>
</header>
```

Pulls from: `site.menus.primary`

#### Footer Menu
Location: `sections/footer.liquid`

```liquid
<footer class="footer">
  <div class="muted">&copy; {{ 'now' | date: '%Y' }} {{ site.title }}</div>
  <nav class="nav small">
    {% for item in site.menus.footer %}
      <a href="{{ item.url }}">{{ item.title }}</a>
    {% endfor %}
  </nav>
</footer>
```

Pulls from: `site.menus.footer`

## Managing Menus

### Option 1: Via Theme YAML File

Edit `app/themes/nordic/data/menus.yml`:

```yaml
primary:
  - { title: "Home", url: "/" }
  - { title: "Blog", url: "/blog" }
  - { title: "About", url: "/page/about" }
  - { title: "Contact", url: "/page/contact" }

footer:
  - { title: "Privacy", url: "/page/privacy" }
  - { title: "Terms", url: "/page/terms" }
  - { title: "RSS", url: "/feed.xml" }
```

**Pros:**
- ✅ Version controlled
- ✅ Fast (no database queries)
- ✅ Easy to edit
- ✅ Deploy with theme

**Cons:**
- ❌ Requires file access to edit
- ❌ Not editable via admin panel

### Option 2: Via Admin Panel

1. Delete or rename `app/themes/nordic/data/menus.yml`
2. Go to **Admin > Menus**
3. Create/edit menus with location `primary` or `footer`
4. Add menu items

**Pros:**
- ✅ User-friendly interface
- ✅ No file access needed
- ✅ Real-time updates
- ✅ Drag & drop ordering

**Cons:**
- ❌ Requires database
- ❌ Slightly slower (database query)

## Database Menu Structure

### Creating a Menu via Admin

```ruby
# Create primary menu
primary_menu = Menu.create!(
  name: 'Main Navigation',
  location: 'primary'
)

# Add menu items
primary_menu.menu_items.create!([
  { title: 'Home', url: '/', position: 1 },
  { title: 'Blog', url: '/blog', position: 2 },
  { title: 'About', url: '/page/about', position: 3 }
])
```

### Menu Locations

The Nordic theme supports these menu locations:
- `primary` - Header navigation
- `footer` - Footer navigation

### Menu Item Attributes

- `title` - Display text
- `url` - Link URL
- `target` - Link target (`_self`, `_blank`, etc.)
- `position` - Sort order
- `parent_id` - For nested menus (optional)

## Advanced Menu Features

### Nested Menus

```yaml
primary:
  - title: "Services"
    url: "/services"
    children:
      - { title: "Web Design", url: "/services/web-design" }
      - { title: "Development", url: "/services/development" }
```

### Dynamic Menus

You can also create menus programmatically:

```ruby
# In a plugin or initializer
Menu.find_or_create_by(location: 'primary') do |menu|
  menu.name = 'Dynamic Menu'
  menu.menu_items.build([
    { title: 'Latest Posts', url: '/blog', position: 1 },
    { title: 'Categories', url: '/categories', position: 2 }
  ])
end
```

### Menu in Liquid Templates

Access menus anywhere in your theme:

```liquid
<!-- Primary menu -->
{% for item in site.menus.primary %}
  <a href="{{ item.url }}" 
     {% if item.target %}target="{{ item.target }}"{% endif %}>
    {{ item.title }}
  </a>
{% endfor %}

<!-- Footer menu -->
{% for item in site.menus.footer %}
  <a href="{{ item.url }}">{{ item.title }}</a>
{% endfor %}

<!-- Custom menu location -->
{% for item in site.menus.sidebar %}
  <a href="{{ item.url }}">{{ item.title }}</a>
{% endfor %}
```

## Styling Menus

### Header Menu Styles

From `theme.css`:
```css
.nav a {
  margin-right: 16px;
  color: var(--muted);
}

.nav a:hover {
  text-decoration: underline;
}
```

### Footer Menu Styles

```css
.nav.small a {
  margin-right: 12px;
  font-size: var(--step--1);
}
```

### Active Menu Item

Add active state styling:

```liquid
{% for item in site.menus.primary %}
  <a href="{{ item.url }}" 
     class="{% if request_path == item.url %}active{% endif %}">
    {{ item.title }}
  </a>
{% endfor %}
```

Then in CSS:
```css
.nav a.active {
  color: var(--accent);
  font-weight: 600;
}
```

## Mobile Menu

For responsive mobile menus, you can enhance the header:

```liquid
<header class="header">
  <a class="brand" href="/">{{ site.title }}</a>
  
  <!-- Mobile menu toggle -->
  <button class="mobile-menu-toggle lg:hidden" onclick="toggleMobileMenu()">
    <svg>...</svg>
  </button>
  
  <!-- Desktop nav -->
  <nav class="nav hidden lg:flex">
    {% for item in site.menus.primary %}
      <a href="{{ item.url }}">{{ item.title }}</a>
    {% endfor %}
  </nav>
  
  <!-- Mobile nav (hidden by default) -->
  <nav id="mobile-menu" class="mobile-nav hidden">
    {% for item in site.menus.primary %}
      <a href="{{ item.url }}">{{ item.title }}</a>
    {% endfor %}
  </nav>
</header>
```

## Testing Menus

### Check Current Menus

```bash
# List all menus
rails console
> Menu.all.each { |m| puts "#{m.name} (#{m.location})" }

# List menu items
> Menu.find_by(location: 'primary').menu_items.ordered.each { |i| puts "  #{i.title} -> #{i.url}" }
```

### Verify Menu Rendering

Visit any page and check the HTML source:
```html
<nav class="nav">
  <a href="/">Home</a>
  <a href="/blog">Blog</a>
  <a href="/page/about">About</a>
</nav>
```

## Best Practices

### 1. Use Descriptive Titles
```yaml
✅ Good: "About Us"
❌ Bad: "about"
```

### 2. Use Absolute URLs
```yaml
✅ Good: "/blog"
✅ Good: "https://external-site.com"
❌ Bad: "blog" (relative)
```

### 3. Limit Menu Items
Keep menus focused:
- **Primary:** 5-7 items max
- **Footer:** 3-5 items max

### 4. Order Matters
Use the `position` field or YAML order to control display order.

### 5. Test on Mobile
Ensure menus work on small screens.

## Troubleshooting

### Menu Not Showing?

**Check:**
1. Does `app/themes/nordic/data/menus.yml` exist?
2. If yes, check YAML syntax
3. If no, check database menus exist
4. Verify menu location name matches (`primary`, `footer`)

### Menu Items Missing?

**Check:**
1. Menu items have correct `position` values
2. Menu items are not hidden/disabled
3. Menu relationship is correct (`menu_id`)

### Wrong Menu Showing?

**Check:**
1. Menu `location` field
2. Theme is looking for correct location
3. YAML file vs database priority

---

## ✅ **Menu System Status**

- ✅ **Fully Integrated** with Nordic theme
- ✅ **Dual Source:** YAML file or database
- ✅ **Header Menu:** Working (`primary`)
- ✅ **Footer Menu:** Working (`footer`)
- ✅ **Admin Interface:** Full CRUD at Admin > Menus
- ✅ **Liquid Support:** `site.menus.{location}`
- ✅ **Extensible:** Add custom menu locations easily

**Current Menus:**
- Primary: Home, Blog, About
- Footer: Privacy, RSS

**Status:** ✅ **WORKING PERFECTLY**

---

**Last Updated:** October 12, 2025  
**Version:** 1.0



