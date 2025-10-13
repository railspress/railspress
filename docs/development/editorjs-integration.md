# Editor.js Integration - Notion-Style Writing Experience

## Overview

Integrated [Editor.js](https://editorjs.io/) for a beautiful, distraction-free, full-screen writing experience similar to Notion.

---

## Features

✅ **Full-Screen Mode** - Distraction-free writing environment  
✅ **15+ Block Types** - Headers, lists, quotes, code, images, tables, and more  
✅ **Auto-Save** - Content saves as you type  
✅ **Keyboard Shortcuts** - Power user productivity  
✅ **Clean JSON Output** - Perfect for APIs and mobile apps  
✅ **HTML Conversion** - Seamless ActionText compatibility  
✅ **Notion-Like UI** - Minimal, focused, beautiful  
✅ **Dark Mode** - Automatic system preference detection  
✅ **Inline Formatting** - Marker, underline, inline code  
✅ **Media Support** - Images, files, YouTube, Vimeo embeds  

---

## Access

### Create New Post (Fullscreen)
- Click "**Write (Full Screen)**" on Posts index
- Or visit: `/admin/posts/write`

### Edit Existing Post (Fullscreen)
- Visit: `/admin/posts/:id/write`

---

## Block Types

### Text Blocks
- **Paragraph** - Regular text (default)
- **Headers** - H1 through H6
- **List** - Nested bullet/numbered lists
- **Checklist** - To-do items
- **Quote** - Blockquotes with attribution

### Code & Technical
- **Code Block** - Syntax-highlighted code
- **Inline Code** - Inline `code` formatting
- **Raw HTML** - Direct HTML input
- **Table** - Structured data tables

### Media
- **Image** - Upload or URL
- **File Attachments** - PDFs, documents
- **Embed** - YouTube, Vimeo, Twitter, Instagram, CodePen, GitHub

### Layout
- **Warning** - Callout boxes
- **Delimiter** - Horizontal divider

---

## Keyboard Shortcuts

### General
- `⌘/Ctrl + S` - Save draft
- `⌘/Ctrl + Enter` - Publish post
- `?` - Show shortcuts help
- `Esc` - Close dialogs

### Formatting
- `⌘/Ctrl + B` - Bold
- `⌘/Ctrl + I` - Italic
- `⌘/Ctrl + U` - Underline
- `⌘/Ctrl + E` - Inline code
- `⌘ + ⇧ + M` - Highlight/marker

### Blocks
- `⌘ + ⇧ + H` - Add header
- `⌘ + ⇧ + L` - Add list
- `⌘ + ⇧ + Q` - Add quote
- `⌘ + ⇧ + C` - Add code block
- `/` - Show all block types

### Navigation
- `Tab` - Indent list
- `⇧ + Tab` - Outdent list
- `Enter` - New block
- `⌫` - Delete empty block

---

## Interface Design

### Notion-Inspired Elements

1. **Clean Canvas**
   - White background (dark in dark mode)
   - 700px max-width content area
   - Centered layout
   - Ample padding

2. **Large Title Input**
   - 40px font size
   - Bold weight
   - Subtle placeholder
   - No visible borders

3. **Sticky Toolbar**
   - Glassmorphism effect
   - Blur backdrop
   - Subtle border
   - Auto-hide on scroll (optional)

4. **Floating Save Indicator**
   - "✓ Saved" appears briefly
   - Green confirmation
   - Auto-disappears

5. **Status Badges**
   - Draft (yellow)
   - Published (green)
   - Minimal, rounded design

---

## Technical Implementation

### Files Created/Modified

1. **`app/views/layouts/editor_fullscreen.html.erb`**
   - Dedicated fullscreen layout
   - Minimal, distraction-free
   - Editor.js CDN scripts
   - Custom Notion-like styles

2. **`app/javascript/controllers/editorjs_controller.js`**
   - Stimulus controller
   - Editor.js initialization
   - Auto-save logic
   - JSON ↔ HTML conversion

3. **`app/views/admin/posts/write.html.erb`**
   - Fullscreen editor view
   - Floating toolbar
   - Title input
   - Content container

4. **`app/controllers/admin/posts_controller.rb`**
   - Added `write` and `write_new` actions
   - Layout switching logic
   - Route handling

5. **`config/routes.rb`**
   - Added write routes
   - Collection and member routes

6. **`config/initializers/secure_headers.rb`**
   - Updated CSP for Google Fonts
   - Added fonts.googleapis.com
   - Added fonts.gstatic.com

7. **`app/views/admin/posts/index.html.erb`**
   - Added "Write (Full Screen)" button
   - Primary action button

---

## How It Works

### 1. User Clicks "Write"
```
User → Write Button → /admin/posts/write
```

### 2. Controller Loads Editor
```ruby
def write_new
  @post = current_user.posts.build(status: :draft)
  render :write, layout: 'editor_fullscreen'
end
```

### 3. Stimulus Initializes Editor.js
```javascript
await this.waitForEditorJS()
this.editor = new EditorJS({ ... })
```

### 4. User Writes Content
- Blocks update in real-time
- JSON structure maintained
- Auto-save on changes

### 5. Save Converts to HTML
```javascript
const outputData = await this.editor.save()
const html = this.convertToHTML(outputData)
this.inputTarget.value = html  // Saves to ActionText
```

### 6. Stored in Database
- HTML for ActionText rendering
- JSON preserved in data attribute
- Compatible with all viewers

---

## Comparison with Other Editors

| Feature | Editor.js | BlockNote | CKEditor | Trix |
|---------|-----------|-----------|----------|------|
| Block-Style | ✅ | ✅ | ❌ | ❌ |
| JSON Output | ✅ | ✅ | ❌ | ❌ |
| Notion-Like | ✅ | ✅ | ❌ | ❌ |
| Clean UI | ✅ | ✅ | ⚠️ | ✅ |
| Extensible | ✅ | ✅ | ✅ | ⚠️ |
| File Size | Small | Medium | Large | Small |
| Learning Curve | Low | Low | High | Low |

---

## Block Output Example

### What You Type
```
# My Amazing Post

This is a paragraph with **bold** and *italic* text.

- First item
  - Nested item
- Second item

> A thoughtful quote
> — Author Name
```

### JSON Output
```json
{
  "time": 1697097600000,
  "blocks": [
    {
      "type": "header",
      "data": {
        "text": "My Amazing Post",
        "level": 1
      }
    },
    {
      "type": "paragraph",
      "data": {
        "text": "This is a paragraph with <b>bold</b> and <i>italic</i> text."
      }
    },
    {
      "type": "list",
      "data": {
        "style": "unordered",
        "items": ["First item", "Nested item", "Second item"]
      }
    },
    {
      "type": "quote",
      "data": {
        "text": "A thoughtful quote",
        "caption": "Author Name"
      }
    }
  ]
}
```

### HTML Output
```html
<h1>My Amazing Post</h1>
<p>This is a paragraph with <b>bold</b> and <i>italic</i> text.</p>
<ul>
  <li>First item</li>
  <li>Nested item</li>
  <li>Second item</li>
</ul>
<blockquote>
  <p>A thoughtful quote</p>
  <cite>Author Name</cite>
</blockquote>
```

---

## Usage Tips

### 1. Start Writing Immediately
- Focus is automatic on title
- Type `/` to see all block types
- Just start typing for paragraph

### 2. Use Keyboard Shortcuts
- Learn `⌘ + ⇧ + H/L/Q/C` for common blocks
- `⌘ + S` to save drafts quickly
- `?` to see all shortcuts

### 3. Add Media Quickly
- Drag & drop images
- Paste URLs for embeds
- Upload files inline

### 4. Organize with Structure
- Use headers for sections
- Nested lists for hierarchy
- Tables for data
- Checklists for tasks

### 5. Save Often
- Auto-save is enabled
- Manual save with `⌘ + S`
- Draft saved before publish

---

## CDN Scripts Loaded

All Editor.js components loaded from https://cdn.jsdelivr.net:

- **Core**: @editorjs/editorjs
- **Text**: @editorjs/header, @editorjs/paragraph
- **Lists**: @editorjs/list, @editorjs/nested-list, @editorjs/checklist  
- **Code**: @editorjs/code, @editorjs/inline-code, @editorjs/raw
- **Media**: @editorjs/image, @editorjs/attaches, @editorjs/embed
- **Format**: @editorjs/quote, @editorjs/marker, @editorjs/underline
- **Layout**: @editorjs/table, @editorjs/warning, @editorjs/delimiter

---

## Benefits

### For Writers
- 🎯 **Focus** - Zero distractions
- 🚀 **Fast** - Keyboard-driven workflow
- 🎨 **Beautiful** - Clean, modern design
- 💪 **Powerful** - All tools you need
- 📱 **Familiar** - Like Notion/Medium

### For Developers
- 📦 **JSON Output** - Easy to parse
- 🔌 **Extensible** - Add custom blocks
- 🌐 **Universal** - Works everywhere
- 🛡️ **Safe** - Built-in sanitization
- 🎯 **Structured** - Clean data model

### For Site
- ⚡ **Fast Loading** - Lazy-loaded from CDN
- 📱 **Responsive** - Mobile-friendly output
- ♿ **Accessible** - Semantic HTML
- 🔍 **SEO** - Proper heading structure
- 🎨 **Themeable** - Custom rendering

---

## Comparison: Editor.js vs BlockNote

**Why We Also Have BlockNote:**
- BlockNote: Default, simpler, React-based
- Editor.js: Advanced, fullscreen, Notion-like

**Use Editor.js When:**
- Want distraction-free writing
- Need structured JSON output
- Building API-first content
- Want Notion-like experience
- Writing long-form content

**Use BlockNote When:**
- Quick edits
- Inline editing
- Prefer React ecosystem
- Need simpler interface

---

## Next Steps

### Customize Further

**Add Custom Blocks:**
```javascript
// In editorjs_controller.js
customBlock: {
  class: MyCustomBlock,
  config: { ... }
}
```

**Modify Styling:**
```css
/* In editor_fullscreen.html.erb <style> */
.ce-paragraph {
  font-size: 18px;  /* Larger text */
  line-height: 1.8;  /* More spacing */
}
```

**Change Max Width:**
```css
.ce-block__content {
  max-width: 900px;  /* Wider content */
}
```

---

## Troubleshooting

### Editor Not Loading

**Check:**
1. Browser console for errors
2. CDN scripts loaded (Network tab)
3. CSP allows cdn.jsdelivr.net
4. Internet connection

**Fix:**
```
1. Hard refresh (⌘ + ⇧ + R)
2. Check secure_headers.rb CSP
3. Verify script tags in layout
```

### Content Not Saving

**Check:**
1. Form submission working
2. Hidden input has value
3. Console for save errors
4. CSRF token present

**Debug:**
```javascript
// In browser console
document.querySelector('[data-editorjs-target="input"]').value
```

### Blocks Not Appearing

**Cause:** Tool not loaded

**Fix:** Check CDN scripts in Network tab

---

## Files

- ✅ Layout: `app/views/layouts/editor_fullscreen.html.erb`
- ✅ View: `app/views/admin/posts/write.html.erb`
- ✅ Controller: `app/javascript/controllers/editorjs_controller.js`
- ✅ Routes: `config/routes.rb`
- ✅ CSP: `config/initializers/secure_headers.rb`
- ✅ Importmap: `config/importmap.rb`

---

## Quick Start

1. **Navigate to Posts**
2. **Click "Write (Full Screen)"**
3. **Enter title**
4. **Start typing** - Type `/` for blocks
5. **Save with ⌘ + S**
6. **Publish when ready**

---

**Status**: ✅ Production Ready  
**Editor**: [Editor.js](https://editorjs.io/) v2.29  
**Layout**: Fullscreen, distraction-free  
**Experience**: Notion-inspired  

Enjoy your beautiful writing experience! ✍️



