# Newsletter Shortcodes - Quick Reference

## Available Shortcodes

### 1. [newsletter] - Full Newsletter Form

Creates a beautiful, styled newsletter signup form.

```
[newsletter]
```

**With Options:**
```
[newsletter 
  title="Join Our Community" 
  description="Get exclusive content and updates" 
  button="Subscribe Now"
  source="blog-post"
  style="minimal"]
```

**Attributes:**
| Attribute | Default | Description |
|-----------|---------|-------------|
| `title` | "Subscribe to our Newsletter" | Form heading |
| `description` | "Get the latest updates..." | Subheading text |
| `button` | "Subscribe" | Submit button text |
| `source` | "shortcode" | Track subscription source |
| `style` | "default" | "default" or "minimal" |

**Renders:**
- Gradient box with email + name fields
- Submit button
- Privacy notice
- Responsive design

---

### 2. [newsletter_inline] - Horizontal Form

Creates a compact, horizontal newsletter form.

```
[newsletter_inline]
```

**With Options:**
```
[newsletter_inline 
  button="Get Updates" 
  placeholder="your@email.com"
  source="sidebar"]
```

**Attributes:**
| Attribute | Default | Description |
|-----------|---------|-------------|
| `button` | "Subscribe" | Submit button text |
| `placeholder` | "Enter your email" | Email input placeholder |
| `source` | "inline_shortcode" | Track source |

**Renders:**
- Single line: email input + button
- Perfect for sidebars, footers, headers
- Minimal, clean design

**Best For:**
- Sidebar widgets
- Footer
- Header bar
- Compact spaces

---

### 3. [newsletter_popup] - Modal Popup Form

Creates a trigger button that opens a modal signup form.

```
[newsletter_popup]
```

**With Options:**
```
[newsletter_popup 
  trigger="📧 Subscribe" 
  button="Join Newsletter"]
```

**Attributes:**
| Attribute | Default | Description |
|-----------|---------|-------------|
| `trigger` | "Join Newsletter" | Trigger button text |
| `button` | "Subscribe" | Modal submit button text |

**Renders:**
- Clickable trigger button
- Modal overlay on click
- Form with email + name fields
- Close button (×)

**Best For:**
- Exit intent popups
- CTA buttons
- Inline content links
- Special offers

---

### 4. [newsletter_count] - Subscriber Count

Displays the number of confirmed subscribers.

```
[newsletter_count]
```

**Example in Content:**
```
Join [newsletter_count] other subscribers and never miss an update!
```

**Renders:**
```
Join 1,234 other subscribers and never miss an update!
```

**Best For:**
- Social proof
- Inline with text
- Call-to-action sections
- Homepage

---

### 5. [newsletter_stats] - Statistics Grid

Shows subscriber statistics in a visual grid.

```
[newsletter_stats]
```

**Renders:**
- Total Subscribers card
- Confirmed card
- Confirmation Rate card
- Styled grid layout

**Best For:**
- About page
- Newsletter landing page
- Transparency displays
- Growth showcase

---

## Common Use Cases

### Use Case 1: Blog Post Footer

```markdown
---

**Enjoyed this post?** Get more content like this delivered to your inbox.

[newsletter_inline button="Subscribe" source="blog-post-footer"]

We respect your privacy. Unsubscribe at any time.
```

### Use Case 2: Homepage Hero

```markdown
# Welcome to Our Blog

Join [newsletter_count] readers who get our best content first!

[newsletter 
  title="Never Miss a Post" 
  description="Get weekly updates and exclusive insights"
  button="Count Me In"
  source="homepage-hero"
  style="default"]
```

### Use Case 3: Sidebar Widget

```erb
<!-- In theme sidebar -->
<aside class="sidebar">
  <div class="widget">
    <h3>Newsletter</h3>
    <%= raw Railspress::ShortcodeProcessor.process('[newsletter_inline placeholder="your@email.com" source="sidebar"]') %>
  </div>
</aside>
```

### Use Case 4: Exit Intent

```html
<script>
let popupShown = false;

document.addEventListener('mouseleave', function(e) {
  if (e.clientY < 10 && !popupShown && !sessionStorage.getItem('newsletter-shown')) {
    popupShown = true;
    sessionStorage.setItem('newsletter-shown', 'true');
    // Show popup
  }
});
</script>

[newsletter_popup trigger="✨ Wait! Get Our Best Content" button="Yes, Subscribe!"]
```

### Use Case 5: About Page Stats

```markdown
# About Our Newsletter

We've been publishing weekly insights since 2020, reaching:

[newsletter_stats]

Want to join our community?

[newsletter 
  title="Subscribe Today" 
  description="Get actionable insights every week"
  source="about-page"]
```

---

## Styling

### Default Style

Gradient purple background, white text, modern rounded design.

**Preview:**
```
╔══════════════════════════════════╗
║   Subscribe to our Newsletter    ║
║  Get the latest updates...       ║
║                                  ║
║  [Email input field]             ║
║  [Name input field]              ║
║  [Subscribe Button]              ║
║                                  ║
║  We respect your privacy.        ║
╚══════════════════════════════════╝
```

### Minimal Style

Light background, bordered, minimal design.

**Usage:**
```
[newsletter style="minimal"]
```

---

## Customization

### Override Styles

Add custom CSS to your theme:

```css
/* Custom newsletter form styles */
.newsletter-form {
  background: your-custom-gradient !important;
  border-radius: 20px !important;
}

.newsletter-submit-btn {
  background: #your-color !important;
}
```

### Custom Form Template

Create a custom shortcode in a plugin:

```ruby
Railspress::ShortcodeProcessor.register('my_newsletter') do |attrs|
  # Your custom HTML
  <<~HTML
    <div class="my-custom-newsletter">
      <!-- Custom form HTML -->
    </div>
  HTML
end
```

---

## API Integration

### Subscribe via JavaScript

```javascript
async function subscribe(email, name, source) {
  const response = await fetch('/api/v1/subscribers', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      subscriber: { email, name },
      source: source
    })
  });
  
  const data = await response.json();
  return data;
}

// Usage
subscribe('user@example.com', 'User Name', 'custom-form')
  .then(result => {
    if (result.success) {
      alert('Please check your email!');
    }
  });
```

### Get Subscriber Count

```javascript
fetch('/api/v1/subscribers/stats')
  .then(res => res.json())
  .then(data => {
    const count = data.data.confirmed;
    document.getElementById('sub-count').textContent = count;
  });
```

---

## Troubleshooting

### Shortcode Not Rendering

**Problem**: Shortcode appears as text  
**Solution**: Ensure content is processed:
```erb
<%= raw Railspress::ShortcodeProcessor.process(@post.content) %>
```

### Form Not Submitting

**Problem**: Form doesn't work  
**Solution**: Check CSRF token is included (automatic in shortcodes)

### Popup Not Opening

**Problem**: Popup doesn't appear  
**Solution**: Ensure JavaScript is loaded and no conflicts

### Count Shows 0

**Problem**: `[newsletter_count]` shows 0  
**Solution**: Add confirmed subscribers in admin

---

## Best Practices

### 1. Choose Right Shortcode for Location

- **[newsletter]**: Content, landing pages, dedicated sections
- **[newsletter_inline]**: Sidebars, footers, headers
- **[newsletter_popup]**: Exit intent, special offers
- **[newsletter_count]**: Inline with content for social proof
- **[newsletter_stats]**: About page, transparency

### 2. Track Sources

Always set source to know what's working:
```
[newsletter source="homepage-hero"]
[newsletter source="blog-post-123"]
[newsletter source="sidebar-widget"]
```

### 3. Use Contextual CTAs

Match the shortcode content to the page:
```
Blog post: "Get more posts like this"
Product page: "Get product updates"
About page: "Join our community"
```

### 4. Don't Overdo It

- One signup form per page is enough
- Don't show popup on every page load
- Use sessionStorage to limit frequency

### 5. Mobile Optimization

All shortcode forms are responsive by default!

---

## Examples in the Wild

### Blog Post Template

```erb
<article>
  <h1><%= @post.title %></h1>
  <div class="content">
    <%= raw Railspress::ShortcodeProcessor.process(@post.content) %>
  </div>
  
  <!-- After content CTA -->
  <div class="post-footer">
    <hr>
    <%= raw Railspress::ShortcodeProcessor.process('[newsletter title="Enjoyed this?" description="Get more articles like this" source="post-footer"]') %>
  </div>
</article>
```

### Sidebar

```erb
<aside class="sidebar">
  <!-- Newsletter widget -->
  <div class="widget bg-white p-4 rounded-lg shadow">
    <%= raw Railspress::ShortcodeProcessor.process('[newsletter_inline source="sidebar"]') %>
  </div>
</aside>
```

### Footer

```erb
<footer>
  <div class="footer-newsletter">
    <h3>Stay Updated</h3>
    <p>Join [newsletter_count] subscribers</p>
    <%= raw Railspress::ShortcodeProcessor.process('[newsletter_inline button="Join" placeholder="Email" source="footer"]') %>
  </div>
</footer>
```

---

## Summary

Newsletter shortcodes provide:

✅ **5 different form types** for every use case  
✅ **Customizable** with attributes  
✅ **Styled by default** (purple gradient or minimal)  
✅ **Mobile responsive** automatically  
✅ **Source tracking** built-in  
✅ **No coding required** - just copy/paste  
✅ **Works anywhere** - posts, pages, widgets  

**Perfect for**:
- Building email lists
- Growing your audience
- Content distribution
- Community building
- Lead generation

Just add a shortcode and start collecting subscribers! 🚀

---

**Quick Reference Card**

```
[newsletter]                          → Full form with gradient
[newsletter_inline]                   → Horizontal email + button
[newsletter_popup]                    → Modal popup form
[newsletter_count]                    → Shows subscriber count
[newsletter_stats]                    → Stats grid

All support custom attributes!
See examples above for details.
```

---

**Last Updated**: October 12, 2025  
**Version**: 1.0.0  
**Status**: ✅ Ready to Use



