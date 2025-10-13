# RailsPress Admin Design System

A modern, comprehensive design system for the RailsPress admin panel with consistent colors, typography, components, and interactions.

## 🎨 Color Palette

### Background Colors (Layered Depth)
```css
--admin-bg-app: #0f0f0f           /* App container background */
--admin-bg-primary: #141414        /* Primary content surfaces */
--admin-bg-secondary: #1a1a1a      /* Secondary surfaces */
--admin-bg-tertiary: #1f1f1f       /* Tertiary surfaces */
--admin-bg-elevated: #242424       /* Elevated/floating elements */
```

### Border Colors (Subtle Hierarchy)
```css
--admin-border-subtle: #282828     /* Very subtle borders */
--admin-border: #2f2f2f            /* Standard borders */
--admin-border-strong: #3a3a3a     /* Emphasized borders */
```

### Text Colors (High Contrast)
```css
--admin-text-primary: #ffffff      /* Headings, important text */
--admin-text-secondary: #e8e8e8    /* Body text */
--admin-text-tertiary: #a8a8a8     /* Labels, less important */
--admin-text-muted: #6b7280        /* Help text, hints */
--admin-text-placeholder: #4b5563  /* Form placeholders */
```

### Brand Colors (Dynamic)
```css
--admin-primary: #6366f1           /* Primary brand color (Indigo) */
--admin-primary-hover: #4f46e5     /* Hover state */
--admin-primary-light: rgba(99, 102, 241, 0.1)  /* Light tint */

--admin-secondary: #8b5cf6         /* Secondary brand (Purple) */
--admin-secondary-hover: #7c3aed   /* Hover state */
--admin-secondary-light: rgba(139, 92, 246, 0.1) /* Light tint */
```

### Status Colors (Semantic)
```css
--admin-success: #10b981           /* Success/approved */
--admin-warning: #f59e0b           /* Warning/caution */
--admin-error: #ef4444             /* Error/danger */
--admin-info: #3b82f6              /* Information */
```

## 🎨 Color Schemes

### Midnight (Default)
Modern, sophisticated dark theme
```
Background: #0f0f0f → #1a1a1a
Borders: #2f2f2f
```

### Vallarta
Deep blue ocean theme
```
Background: #0a1628 → #1a2947
Borders: #2a3f5f
```

### Amanecer
Clean light theme
```
Background: #ffffff → #f1f3f5
Borders: #e9ecef
```

### Onyx
Pure black OLED-friendly
```
Background: #000000 → #111111
Borders: #1a1a1a
```

### Slate
Cool gray professional
```
Background: #0f172a → #334155
Borders: #475569
```

## 📦 Components

### Cards

#### Basic Card
```erb
<div class="admin-card">
  <h3>Card Title</h3>
  <p>Card content</p>
</div>
```

**Features:**
- Gradient background
- Hover lift effect
- Subtle shadow
- Rounded corners

#### Flat Card
```erb
<div class="admin-card-flat">
  Content without hover effects
</div>
```

#### Elevated Card
```erb
<div class="admin-card-elevated">
  High-importance content
</div>
```

#### Feature Card
```erb
<div class="admin-feature-card">
  Special highlighted content
</div>
```

### Stat Cards

```erb
<div class="admin-stat-card">
  <div class="admin-stat-icon bg-indigo-500/10">
    <svg>...</svg>
  </div>
  <p class="admin-stat-label">Total Posts</p>
  <p class="admin-stat-value">142</p>
  <p class="admin-stat-meta">12 published this week</p>
</div>
```

**Features:**
- Top accent border on hover
- Icon scaling animation
- Gradient background
- Large, bold numbers

### Buttons

```erb
<!-- Primary -->
<button class="admin-btn admin-btn-primary">
  Primary Action
</button>

<!-- Secondary -->
<button class="admin-btn admin-btn-secondary">
  Secondary Action
</button>

<!-- Ghost -->
<button class="admin-btn admin-btn-ghost">
  Tertiary Action
</button>

<!-- Success -->
<button class="admin-btn admin-btn-success">
  Confirm
</button>

<!-- Danger -->
<button class="admin-btn admin-btn-danger">
  Delete
</button>

<!-- Sizes -->
<button class="admin-btn admin-btn-primary admin-btn-sm">Small</button>
<button class="admin-btn admin-btn-primary">Default</button>
<button class="admin-btn admin-btn-primary admin-btn-lg">Large</button>
```

### Form Elements

```erb
<!-- Input -->
<input type="text" class="admin-input" placeholder="Enter text...">

<!-- Large Input -->
<input type="text" class="admin-input admin-input-lg" placeholder="Large input...">

<!-- Select -->
<select class="admin-select">
  <option>Option 1</option>
</select>

<!-- Textarea -->
<textarea class="admin-textarea" rows="5"></textarea>

<!-- Label -->
<label class="admin-label">Field Label</label>

<!-- Help Text -->
<p class="admin-help-text">Additional information about this field</p>
```

### Badges

```erb
<span class="admin-badge admin-badge-success">Published</span>
<span class="admin-badge admin-badge-warning">Pending</span>
<span class="admin-badge admin-badge-error">Error</span>
<span class="admin-badge admin-badge-info">Draft</span>
<span class="admin-badge admin-badge-neutral">Inactive</span>
```

### Action Icons

```erb
<!-- Edit -->
<button class="admin-action-icon admin-action-icon-primary">
  <svg>...</svg>
</button>

<!-- Delete -->
<button class="admin-action-icon admin-action-icon-danger">
  <svg>...</svg>
</button>

<!-- View -->
<button class="admin-action-icon admin-action-icon-info">
  <svg>...</svg>
</button>
```

### Notifications

```erb
<!-- Success Notice -->
<div class="admin-notice">
  <svg class="w-5 h-5 text-green-500">...</svg>
  <p class="admin-notice-text">Operation completed successfully!</p>
</div>

<!-- Error Alert -->
<div class="admin-alert">
  <svg class="w-5 h-5 text-red-500">...</svg>
  <p class="admin-alert-text">An error occurred</p>
</div>

<!-- Info Box -->
<div class="admin-info-box">
  <p>Here's some helpful information</p>
</div>

<!-- Warning Box -->
<div class="admin-warning-box">
  <p>Please be careful with this action</p>
</div>
```

### Empty States

```erb
<div class="admin-empty-state">
  <svg class="admin-empty-icon">...</svg>
  <h3 class="admin-empty-title">No posts yet</h3>
  <p class="admin-empty-description">Get started by creating your first post</p>
  <button class="admin-btn admin-btn-primary">Create Post</button>
</div>
```

## 📏 Layout System

### Container
```erb
<div class="admin-container">
  <!-- Max-width content, centered -->
</div>
```

### Page Header
```erb
<div class="admin-page-header">
  <div>
    <h1 class="admin-page-title">Page Title</h1>
    <p class="admin-page-subtitle">Description of this page</p>
  </div>
  <div>
    <!-- Action buttons -->
  </div>
</div>
```

### Grid Systems
```erb
<!-- Stats Grid (1 → 2 → 4 columns) -->
<div class="admin-stats-grid">
  <div>Card 1</div>
  <div>Card 2</div>
  <div>Card 3</div>
  <div>Card 4</div>
</div>

<!-- 2-Column Grid -->
<div class="admin-grid-2">
  <div>Column 1</div>
  <div>Column 2</div>
</div>

<!-- 3-Column Grid -->
<div class="admin-grid-3">
  <div>Column 1</div>
  <div>Column 2</div>
  <div>Column 3</div>
</div>
```

## 🎭 Effects & Animations

### Hover Effects
```erb
<!-- Lift on hover -->
<div class="admin-hover-lift">...</div>

<!-- Glow on hover -->
<div class="admin-hover-glow">...</div>
```

### Animations
```erb
<!-- Fade in -->
<div class="admin-fade-in">...</div>

<!-- Slide in -->
<div class="admin-slide-in">...</div>
```

### Loading States
```erb
<!-- Spinner -->
<div class="admin-loading"></div>

<!-- Skeleton -->
<div class="admin-skeleton" style="width: 200px; height: 20px;"></div>
```

## 🎨 Gradients

```erb
<!-- Primary gradient (Indigo → Purple) -->
<div class="admin-gradient-primary">
  Content with gradient background
</div>

<!-- Status gradients -->
<div class="admin-gradient-success">Success gradient</div>
<div class="admin-gradient-warning">Warning gradient</div>
<div class="admin-gradient-error">Error gradient</div>
```

## 🌫️ Glass Morphism

```erb
<!-- Light glass effect -->
<div class="admin-glass">
  Semi-transparent with blur
</div>

<!-- Strong glass effect -->
<div class="admin-glass-strong">
  More opaque with stronger blur
</div>
```

## 🛠️ Utility Classes

### Dividers
```erb
<div class="admin-divider"></div> <!-- Horizontal -->
<div class="admin-divider-vertical"></div> <!-- Vertical -->
```

### Text Colors
```erb
<p class="admin-text-primary">Primary text</p>
<p class="admin-text-secondary">Secondary text</p>
<p class="admin-text-tertiary">Tertiary text</p>
<p class="admin-text-muted">Muted text</p>
```

### Backgrounds
```erb
<div class="admin-bg-primary">Primary background</div>
<div class="admin-bg-secondary">Secondary background</div>
```

### Responsive
```erb
<div class="admin-hide-mobile">Hidden on mobile</div>
<button class="admin-full-width-mobile">Full width on mobile</button>
```

### Accessibility
```erb
<span class="admin-sr-only">Screen reader only text</span>
<button class="admin-focus-visible">Accessible focus</button>
```

### Print
```erb
<div class="admin-no-print">Hidden when printing</div>
```

## 📱 Responsive Breakpoints

```css
/* Mobile */
@media (max-width: 640px) {
  /* Stacked layout, full-width buttons */
}

/* Tablet */
@media (min-width: 640px) and (max-width: 1024px) {
  /* 2-column grids */
}

/* Desktop */
@media (min-width: 1024px) {
  /* 4-column grids, full features */
}
```

## ✨ Best Practices

### 1. Use CSS Variables
```erb
<!-- DO THIS -->
<div style="background: var(--admin-bg-primary)">

<!-- DON'T DO THIS -->
<div style="background: #141414">
```

### 2. Use Design System Classes
```erb
<!-- DO THIS -->
<button class="admin-btn admin-btn-primary">Save</button>

<!-- DON'T DO THIS -->
<button class="px-4 py-2 bg-indigo-600 rounded">Save</button>
```

### 3. Respect Color Hierarchy
- Use `--admin-bg-app` for page background
- Use `--admin-bg-primary` for main content
- Use `--admin-bg-secondary` for cards
- Use `--admin-bg-elevated` for modals/dropdowns

### 4. Consistent Spacing
- Use CSS variable spacing: `var(--admin-space-sm)`, etc.
- Maintain rhythm with grid systems
- Keep padding consistent within component types

### 5. Accessibility First
- Always include focus states
- Use semantic HTML
- Provide alt text for icons
- Test keyboard navigation

## 🎨 Customization

### Change Primary Color
```ruby
# Admin → Settings → Appearance
SiteSetting.set('primary_color', '#your-color', 'string')
```

### Change Color Scheme
```ruby
SiteSetting.set('color_scheme', 'midnight', 'string')
# Options: midnight, vallarta, amanecer, onyx, slate
```

### Add Custom Color Scheme
```ruby
# app/helpers/appearance_helper.rb
def color_scheme_colors(scheme)
  case scheme
  when 'your_scheme'
    {
      bg_primary: '#...',
      bg_secondary: '#...',
      bg_tertiary: '#...',
      border_color: '#...'
    }
  # ... existing schemes
  end
end
```

## 📚 Examples

### Complete Stat Card Example
```erb
<div class="admin-stats-grid">
  <div class="admin-stat-card">
    <div class="admin-stat-icon bg-indigo-500/10 text-indigo-400">
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
      </svg>
    </div>
    <p class="admin-stat-label">Total Posts</p>
    <p class="admin-stat-value">142</p>
    <p class="admin-stat-meta">12 published this week</p>
  </div>
</div>
```

### Complete Form Example
```erb
<div class="admin-card">
  <%= form_with model: @post do |f| %>
    <div class="space-y-6">
      <!-- Input Field -->
      <div>
        <label class="admin-label">Post Title</label>
        <%= f.text_field :title, class: "admin-input", placeholder: "Enter title..." %>
        <p class="admin-help-text">This will be the main heading</p>
      </div>
      
      <!-- Select Field -->
      <div>
        <label class="admin-label">Status</label>
        <%= f.select :status, [...], {}, class: "admin-select" %>
      </div>
      
      <!-- Actions -->
      <div class="flex gap-3">
        <%= f.submit "Save", class: "admin-btn admin-btn-primary" %>
        <%= link_to "Cancel", :back, class: "admin-btn admin-btn-ghost" %>
      </div>
    </div>
  <% end %>
</div>
```

## 🔄 Migration from Old Styles

### Before
```erb
<div class="bg-[#1a1a1a] border border-[#2a2a2a] rounded-xl p-6">
```

### After
```erb
<div class="admin-card">
```

### Benefits
- ✅ Shorter, cleaner markup
- ✅ Consistent across all pages
- ✅ Theme-aware (respects color scheme)
- ✅ Easier to maintain

## 📊 Component Checklist

When creating new admin pages, use:

- [ ] `admin-container` for page wrapper
- [ ] `admin-page-header` for title section
- [ ] `admin-stats-grid` for metrics
- [ ] `admin-stat-card` for individual stats
- [ ] `admin-card` for content sections
- [ ] `admin-btn-primary` for main actions
- [ ] `admin-badge-*` for status indicators
- [ ] `admin-notice` for success messages
- [ ] `admin-alert` for error messages
- [ ] `admin-empty-state` when no data

## 🎯 Design Principles

1. **Consistency** - Same patterns across all pages
2. **Clarity** - Clear visual hierarchy
3. **Feedback** - Hover states, transitions
4. **Accessibility** - WCAG AA compliant
5. **Performance** - Lightweight CSS, minimal JS
6. **Responsiveness** - Mobile-first approach

## 📚 Related Documentation

- [Appearance Settings](../features/appearance.md)
- [Color Scheme Guide](../features/color-schemes.md)
- [Accessibility Guide](../development/accessibility.md)

