# GrapesJS Template Customizer Guide

## Overview

RailsPress includes a powerful visual template customizer powered by GrapesJS, allowing you to design and customize your theme templates without writing code.

## Features

### Full-Featured Visual Editor
- **Drag & Drop Interface** - Build templates by dragging components onto the canvas
- **Responsive Design** - Test templates on Desktop, Tablet, and Mobile devices
- **Live Preview** - See changes in real-time
- **Component Library** - Pre-built components ready to use
- **Style Manager** - Visual controls for CSS styling
- **Layer Manager** - Organize and manage page elements
- **Custom Code** - Add custom HTML/CSS/JS when needed

### Built-in Plugins

The template customizer includes these GrapesJS plugins:

1. **Preset Webpage** - Complete webpage building toolkit
2. **Blocks Basic** - Essential building blocks
3. **Forms** - Form components and inputs
4. **Countdown** - Countdown timer components
5. **Export** - Export HTML/CSS/JS
6. **Tabs** - Tabbed content components
7. **Custom Code** - Embed custom HTML/CSS/JS
8. **Touch** - Touch/mobile support
9. **Parser PostCSS** - CSS parsing
10. **Tooltip** - Tooltip components
11. **TUI Image Editor** - Image editing capabilities
12. **Typed** - Typing animation effects
13. **Style Background** - Advanced background styling

### WordPress-Style Template Tags

The editor includes special components for dynamic content:

| Component | Template Tag | Description |
|-----------|--------------|-------------|
| Post Title | `{{post.title}}` | Displays the post title |
| Post Content | `{{post.content}}` | Displays the post content |
| Post Excerpt | `{{post.excerpt}}` | Displays the post excerpt |
| Post Date | `{{post.published_at}}` | Displays publication date |
| Post Author | `{{post.author}}` | Displays author name |
| Post Categories | `{{post.categories}}` | Displays post categories |
| Post Tags | `{{post.tags}}` | Displays post tags |

## Template Types

RailsPress supports 13 different template types:

1. **Homepage** - Main site homepage
2. **Blog Index** - Blog listing page
3. **Blog Single** - Individual blog post
4. **Page Default** - Standard page layout
5. **Page Full Width** - Full-width page layout
6. **Archive** - Date-based archives
7. **Category** - Category archive pages
8. **Tag** - Tag archive pages
9. **Search** - Search results page
10. **404** - Not found error page
11. **Header** - Site header template
12. **Footer** - Site footer template
13. **Sidebar** - Sidebar widget area

## Getting Started

### Accessing the Customizer

1. Log in to the admin panel at `/admin`
2. Navigate to **Template Customizer**
3. Select a template to edit
4. The GrapesJS editor will load

### Editor Interface

The editor consists of several panels:

#### Top Toolbar
- **Visibility Toggle** - Show/hide element borders
- **Fullscreen** - Expand editor to fullscreen
- **Undo** - Undo last action
- **Redo** - Redo last action
- **Clear** - Clear canvas
- **Device Switcher** - Switch between Desktop/Tablet/Mobile views

#### Left Panel - Blocks
- Drag components from here onto the canvas
- Organized by categories
- Includes WordPress-specific blocks

#### Right Panel - Settings
- **Style Manager** - Visual CSS controls
- **Trait Manager** - Component properties
- **Layer Manager** - Element hierarchy

### Basic Workflow

1. **Add Components**
   - Drag blocks from the left panel onto the canvas
   - Position elements where you want them

2. **Style Elements**
   - Select an element on the canvas
   - Use the Style Manager to adjust:
     - Dimensions (width, height, padding, margin)
     - Typography (font, size, color)
     - Decorations (borders, shadows, backgrounds)
     - Advanced (transforms, transitions)

3. **Configure Properties**
   - Use the Trait Manager to set:
     - IDs and classes
     - HTML attributes
     - Link targets
     - Image sources

4. **Test Responsiveness**
   - Click device icons in the toolbar
   - Adjust layouts for different screen sizes
   - Set breakpoint-specific styles

5. **Save Your Work**
   - Click the **Save Template** button in the top right
   - Your changes are saved to the database

## Advanced Features

### Custom HTML/CSS/JS

You can add custom code to templates:

1. Click on a component
2. Select "Edit Code" from the context menu
3. Enter your HTML/CSS/JS
4. Code will be embedded in the template

### Adding Dynamic Content

Use WordPress-style template tags in your HTML:

```html
<article class="post">
  <h1>{{post.title}}</h1>
  <div class="meta">
    Posted on {{post.published_at}} by {{post.author}}
  </div>
  <div class="content">
    {{post.content}}
  </div>
  <div class="tags">
    {{post.tags}}
  </div>
</article>
```

### Responsive Design

1. Switch to different device views
2. Adjust styles for each breakpoint
3. Use Tailwind CSS classes for responsive utilities:
   - `hidden md:block` - Hide on mobile, show on desktop
   - `grid-cols-1 md:grid-cols-3` - 1 column mobile, 3 desktop
   - `text-sm md:text-lg` - Smaller text on mobile

### Tailwind CSS Integration

Templates have access to Tailwind CSS classes:

```html
<div class="container mx-auto px-4 py-8">
  <h1 class="text-3xl font-bold text-gray-900 mb-4">
    Heading
  </h1>
  <p class="text-gray-600 leading-relaxed">
    Paragraph text
  </p>
</div>
```

## Best Practices

### Performance
- Keep templates lean and efficient
- Optimize images before uploading
- Minimize custom CSS/JS
- Use Tailwind utilities instead of custom styles when possible

### Responsive Design
- Always test on all device sizes
- Use mobile-first approach
- Test touch interactions
- Ensure readable font sizes on mobile

### Accessibility
- Use semantic HTML elements
- Add alt text to images
- Ensure sufficient color contrast
- Test keyboard navigation

### SEO
- Use proper heading hierarchy (H1, H2, H3)
- Include meta tags
- Use semantic markup
- Optimize images

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Undo | `Cmd/Ctrl + Z` |
| Redo | `Cmd/Ctrl + Shift + Z` |
| Delete Component | `Delete` |
| Copy | `Cmd/Ctrl + C` |
| Paste | `Cmd/Ctrl + V` |
| Select All | `Cmd/Ctrl + A` |
| Deselect | `Escape` |

## Common Use Cases

### Creating a Blog Post Template

1. Open "Blog Single" template
2. Add these components:
   - Post Title block
   - Post Date block
   - Post Author block
   - Post Content block
   - Post Categories block
   - Post Tags block
3. Style each component
4. Add a container with proper spacing
5. Save the template

### Creating a Homepage

1. Open "Homepage" template
2. Build sections:
   - Hero section with CTA
   - Featured posts grid
   - Recent posts list
   - Categories showcase
3. Add navigation menu
4. Include footer
5. Test on all devices
6. Save

### Custom Page Layout

1. Open "Page Default" template
2. Create your layout structure
3. Add content placeholders
4. Style with Tailwind CSS
5. Test responsiveness
6. Save template

## Troubleshooting

### Template Not Saving
- Check browser console for errors
- Ensure you're logged in as admin
- Verify CSRF token is valid
- Check server logs

### Styles Not Applying
- Clear browser cache
- Check CSS specificity
- Verify Tailwind classes are correct
- Inspect element in browser DevTools

### Components Not Rendering
- Check for JavaScript errors
- Verify component code is valid
- Test in different browsers
- Check responsive settings

### Preview Not Working
- Refresh the page
- Check for syntax errors
- Clear local storage
- Try a different browser

## Tips & Tricks

1. **Use Components Library**
   - Start with pre-built components
   - Customize rather than building from scratch
   - Create reusable component blocks

2. **Test Early, Test Often**
   - Switch between device views frequently
   - Test in real devices when possible
   - Use browser DevTools device emulation

3. **Organize Your Layers**
   - Name elements clearly
   - Use nested structure
   - Group related components

4. **Save Frequently**
   - Save after major changes
   - Keep backup copies of templates
   - Test after saving

5. **Learn Tailwind CSS**
   - Familiarize yourself with Tailwind utilities
   - Use Tailwind docs as reference
   - Leverage responsive modifiers

## Resources

- [GrapesJS Documentation](https://grapesjs.com/docs/)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [Trix Editor Guide](https://trix-editor.org/)
- [Rails Guides](https://guides.rubyonrails.org/)

## Support

For issues or questions:
1. Check the README.md file
2. Review this guide
3. Check browser console for errors
4. Review Rails logs
5. Open an issue on GitHub

---

**Happy Customizing!** 🎨

Create beautiful, responsive templates for your RailsPress site with the power of GrapesJS.



