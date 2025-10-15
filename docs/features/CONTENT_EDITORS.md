# Content Editors System

RailsPress supports multiple content editors with user-specific preferences. Each user can choose their preferred editor, and the system will automatically use it across all content forms.

## 📝 Available Editors

### 1. BlockNote (Default)
- **Type:** Block-based editor
- **Format:** JSON blocks
- **Best For:** Modern, structured content
- **Features:**
  - Slash commands (`/heading`, `/list`, `/quote`)
  - Drag & drop blocks
  - Clean, minimalist interface
  - Excellent for long-form content

### 2. Trix (ActionText)
- **Type:** Rich text WYSIWYG
- **Format:** HTML with Rails ActionText
- **Best For:** Traditional content editing
- **Features:**
  - Built-in with Rails
  - Direct file uploads
  - Simple toolbar
  - Familiar WYSIWYG experience

### 3. CKEditor
- **Type:** Classic WYSIWYG
- **Format:** HTML
- **Best For:** Users familiar with WordPress/traditional CMSs
- **Features:**
  - Full formatting toolbar
  - Media embed support
  - Table support
  - Industry-standard interface

### 4. Editor.js
- **Type:** Block-style JSON editor
- **Format:** JSON
- **Best For:** Structured, API-first content
- **Features:**
  - JSON-based storage
  - Extensible plugins
  - Modern UI
  - API-friendly format

## 🎯 Setting Your Preference

### Via Admin UI
1. Go to **Admin → Settings → Writing**
2. Scroll to **"Your Editor Preference"**
3. Select your preferred editor from dropdown
4. Click **"Save Changes"**

### Via Rails Console
```ruby
user = User.find_by(email: 'your@email.com')
user.update(editor_preference: 'trix')
```

### Via API
```bash
PATCH /api/v1/users/:id
{
  "user": {
    "editor_preference": "ckeditor"
  }
}
```

## 🛠️ Using the Editor in Your Code

### Option 1: Render the Partial Directly
```erb
<%= render 'shared/content_editor',
    form: f,
    content: @post.content,
    field_name: :content,
    placeholder: 'Start writing...' %>
```

### Option 2: Use the Helper Method
```erb
<%= render_content_editor(f, :content) %>
```

### Option 3: With Custom Options
```erb
<%= render_content_editor(f, :content, 
    content: @post.content,
    placeholder: 'Tell your story...' %>
```

## 📍 Where Editors Are Used

The reusable editor partial is used in:

- ✅ **Posts** - New, Edit, and Write pages
- ✅ **Pages** - New and Edit forms
- ✅ **Any content form** - Just include the partial

## 🎨 Editor Partial Details

### Location
`app/views/shared/_content_editor.html.erb`

### Parameters
- `form` - Required. The form builder object
- `content` - Optional. Initial content to load
- `field_name` - Required. The field name (`:content`, `:body`, etc.)
- `placeholder` - Optional. Placeholder text
- `editor_type` - Optional. Override user preference

### Example
```erb
<%= form_with model: @post do |f| %>
  <%= f.text_field :title %>
  
  <%= render 'shared/content_editor',
      form: f,
      content: @post.content,
      field_name: :content,
      placeholder: 'Write something amazing...' %>
  
  <%= f.submit %>
<% end %>
```

## 🔧 Customizing Editors

### Adding a New Editor

1. **Update User Model**
```ruby
# app/models/user.rb
EDITOR_OPTIONS = %w[blocknote trix ckeditor editorjs your_editor].freeze
```

2. **Add Case to Partial**
```erb
<!-- app/views/shared/_content_editor.html.erb -->
<% when 'your_editor' %>
  <!-- Your editor HTML/JavaScript here -->
  <%= form.text_area field_name, ... %>
<% end %>
```

3. **Update Helper Options**
```ruby
# app/helpers/editor_helper.rb
def editor_preference_options
  [
    # ... existing editors
    ['Your Editor Name', 'your_editor']
  ]
end
```

### Styling Editors

All editors use consistent dark theme styling:
- Background: `#0a0a0a`
- Border: `#2a2a2a`
- Text: White
- Accent: Indigo (`#4f46e5`)

## 🎬 Stimulus Controllers

### BlockNote Controller
```javascript
// app/javascript/controllers/blocknote_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]
  // ...initialization
}
```

### Usage
```erb
<div data-controller="blocknote"
     data-blocknote-content-value="<%= content.to_json %>">
  <!-- Editor container -->
</div>
```

## 💾 Content Storage

### BlockNote
```json
{
  "blocks": [
    {
      "type": "heading",
      "props": { "level": 1 },
      "content": [{ "type": "text", "text": "Hello" }]
    }
  ]
}
```

### Trix (ActionText)
```html
<div>Rich HTML content with <strong>formatting</strong></div>
```

### CKEditor
```html
<h1>Heading</h1><p>Paragraph with <em>formatting</em></p>
```

### Editor.js
```json
{
  "time": 1234567890,
  "blocks": [{"type": "paragraph", "data": {"text": "Content"}}]
}
```

## 🔄 Content Migration

### Converting Between Formats

The system handles basic conversions:

**HTML → BlockNote:**
- Headers (`<h1>`) → `heading` blocks
- Paragraphs (`<p>`) → `paragraph` blocks
- Lists (`<ul>`, `<ol>`) → list blocks

**BlockNote → HTML:**
- Rendered for frontend display
- SEO-friendly output
- Clean semantic HTML

## ⚠️ Fallback Behavior

If an editor fails to load:
1. System shows warning message
2. Falls back to plain textarea
3. Content is preserved
4. User can still save/edit
5. Suggests switching to different editor

## 🧪 Testing

### Check Current Editor
```ruby
user = User.find_by(email: 'test@example.com')
puts user.preferred_editor
# => "blocknote"
```

### Test Editor Rendering
```ruby
# In Rails console
include ActionView::Helpers
include EditorHelper

editor_html = render_content_editor(form, :content)
```

## 📚 Related Documentation

- [User Roles & Permissions](./user-roles.md)
- [Settings System](./settings-system.md)
- [ActionText Guide](https://edgeguides.rubyonrails.org/action_text_overview.html)
- [BlockNote Docs](https://www.blocknotejs.org/)
- [CKEditor Docs](https://ckeditor.com/docs/)

## ✅ Best Practices

1. **Always use the partial** - Don't hardcode editor HTML
2. **Respect user preferences** - Let users choose
3. **Handle all formats** - Content should work across editors
4. **Test fallbacks** - Ensure graceful degradation
5. **Keep it simple** - One partial, reused everywhere

## 🚀 Future Enhancements

Potential additions:
- [ ] Markdown editor option
- [ ] Collaborative editing (Yjs, Automerge)
- [ ] AI-assisted writing (integrated with AI Agents)
- [ ] Code syntax highlighting
- [ ] Math equation support (KaTeX)
- [ ] Mermaid diagram support





