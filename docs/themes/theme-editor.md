# Theme File Editor Guide

**WordPress-style theme editor with Monaco Editor**

---

## 📚 Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Getting Started](#getting-started)
- [File Operations](#file-operations)
- [Monaco Editor Features](#monaco-editor-features)
- [Version Control](#version-control)
- [Security](#security)
- [Best Practices](#best-practices)
- [Keyboard Shortcuts](#keyboard-shortcuts)

---

## Introduction

The RailsPress Theme Editor provides a powerful, WordPress-style interface for editing theme files directly in your browser. Built with **Monaco Editor** (the same editor that powers VS Code), it offers:

✅ **Multi-file editing** with sidebar navigation  
✅ **Syntax highlighting** for all common languages  
✅ **Auto-completion** and IntelliSense  
✅ **Version control** with rollback  
✅ **Find & replace** across files  
✅ **Live preview** capability  
✅ **Format on save** for clean code  
✅ **Security** with path validation  

---

## Features

### 1. Multi-File Sidebar (WordPress/Shopify Style)

- **File Tree Navigation**: Browse all theme files in a tree structure
- **Quick File Switching**: Click to instantly load files
- **Visual Indicators**:
  - 📝 Blue icon = Editable file
  - 🔒 Gray icon = Binary file (download only)
  - 📁 Yellow icon = Directory
- **Expandable Folders**: Click to expand/collapse directories

### 2. Monaco Editor

- **Syntax Highlighting**: Automatic language detection
- **Auto-completion**: Intelligent code completion
- **IntelliSense**: Hover for documentation
- **Error Detection**: Real-time syntax checking
- **Multi-cursor**: Edit multiple lines at once
- **Code Folding**: Collapse/expand code blocks

### 3. File Operations

- ✅ **Create** - New files with custom paths
- ✅ **Edit** - Modify file content
- ✅ **Rename** - Change file names/paths
- ✅ **Delete** - Remove files (with backup)
- ✅ **Download** - Save files locally

### 4. Version Control

- **Automatic Versioning**: Every save creates a version
- **Version History**: View all past versions
- **Restore**: Rollback to any previous version
- **Diff View**: Compare versions (coming soon)
- **User Tracking**: See who made changes

### 5. Search

- **Find in Files**: Search across all theme files
- **Results Preview**: See matched lines
- **Quick Navigation**: Click to open file

### 6. Security

- **Path Validation**: No directory traversal attacks
- **Whitelist**: Only edit files within theme directory
- **Binary Guard**: Binary files cannot be edited
- **Backups**: Auto-backup before modifications
- **Version Tracking**: Full audit trail

---

## Getting Started

### Access the Editor

1. Login to Admin Dashboard
2. Navigate to **Appearance → Theme Editor**
3. Or visit: `http://localhost:3000/admin/theme_editor`

### Select a File

1. Browse the file tree in the left sidebar
2. Click on any file to load it in the editor
3. The editor will auto-detect the language (Ruby, HTML, CSS, JS, etc.)

### Edit and Save

1. Make your changes in the Monaco editor
2. Click "Save File" button or press `Cmd+S` / `Ctrl+S`
3. File is saved and a version is created

---

## File Operations

### Create New File

1. Click **"New File"** button in sidebar
2. Enter file path (e.g., `views/shared/_custom.html.erb`)
3. File is created and opened in editor

**Supported File Types:**
```
.erb, .html, .htm, .haml, .slim       # Templates
.css, .scss, .sass                    # Stylesheets
.js, .coffee                          # JavaScript
.json, .yml, .yaml                    # Config files
.rb                                   # Ruby files
.md, .txt                             # Documentation
```

### Rename File

1. Click **Actions → Rename**
2. Enter new file path
3. Confirm to rename

### Delete File

1. Click **Actions → Delete**
2. Confirm deletion
3. A backup is created in `tmp/theme_backups/`

### Download File

1. Click **Actions → Download**
2. File is downloaded to your computer

---

## Monaco Editor Features

### Language Support

The editor automatically detects file type and provides:

| File Type | Language | Features |
|-----------|----------|----------|
| `.erb` | HTML/ERB | Tag completion, formatting |
| `.html` | HTML | Full HTML5 support |
| `.css` | CSS | Property completion, color picker |
| `.scss` | SCSS | Sass syntax, nesting support |
| `.js` | JavaScript | ES6+ support, JSDoc |
| `.json` | JSON | Schema validation, formatting |
| `.rb` | Ruby | Basic syntax highlighting |
| `.yml` | YAML | Structure validation |
| `.md` | Markdown | Preview support |

### Editor Actions

**Toolbar Buttons:**
- **Format**: Auto-format code
- **Find**: Open find/replace dialog
- **Versions**: View version history
- **Actions**: File operations menu
- **Preview**: Open site preview
- **Save**: Save changes (or use Cmd+S)

### Code Formatting

**Auto-format on save:**
- HTML/ERB: Proper indentation
- CSS/SCSS: Organized properties
- JavaScript: Prettier-like formatting
- JSON: Pretty-print

### Find & Replace

1. Click **Find** button or press `Cmd+F`
2. Enter search term
3. Use replace functionality for bulk changes
4. **Find in Selection**: Search within highlighted code
5. **Regex Support**: Use regular expressions

---

## Version Control

### Automatic Versioning

Every time you save a file:
1. Current content is saved as a version
2. User and timestamp are recorded
3. File size is tracked
4. Versions are listed in chronological order

### View Versions

1. Click **Versions** button (shows count)
2. Right panel opens with version list
3. Each version shows:
   - Timestamp
   - User who made the change
   - File size
   - Optional change summary

### Restore Version

1. Click **"Restore"** on any version
2. Confirm restoration
3. Current content is backed up
4. Selected version becomes current

### Version Limits

- **Stored**: Last 20 versions per file
- **Retention**: Indefinite (or configure cleanup job)
- **Storage**: Database (text column)

---

## Search in Files

### How to Search

1. Click **"Search in Files"** button
2. Enter search query
3. View results with:
   - File path
   - Line number
   - Matched line content
4. Click result to open that file

### Search Features

- **Full-text search** across all editable files
- **Case-sensitive** matching
- **Line context** shown
- **Quick navigation** to matches

---

## Security

### Path Validation

**Whitelist Approach:**
- ✅ Only files within `app/themes/[active_theme]/` can be edited
- ❌ No `..` traversal allowed
- ❌ No absolute paths
- ❌ No symlinks outside theme directory

### File Type Restrictions

**Editable Files:**
```ruby
.erb, .html, .css, .scss, .js, .json, .yml, .rb, .md
```

**Binary Files (Download Only):**
```ruby
.png, .jpg, .gif, .woff, .woff2, .pdf, .zip
```

### Backups

**Before any destructive operation:**
- File is backed up to `tmp/theme_backups/[theme]/`
- Timestamped backup files: `filename.20251012_103045.bak`
- Backups preserved for recovery

### Version Tracking

**Every save records:**
- User who made the change
- Full file content
- Timestamp
- File size
- Optional change summary

---

## Best Practices

### 1. Test in Development First

❌ **Don't** edit production themes directly
✅ **Do** test changes in development environment

### 2. Use Version Control

✅ Commit theme files to Git
✅ Use branches for major changes
✅ Review changes before deploying

### 3. Create Backups

```bash
# Backup before editing
./scripts/backup.sh before-theme-edit

# Or use Git
git commit -am "Before theme edits"
```

### 4. Small, Incremental Changes

✅ Make one change at a time
✅ Save frequently
✅ Test after each change

### 5. Use Child Themes (Future)

Create child themes to preserve parent theme updates:

```
app/themes/
  ├── scandiedge/           # Parent theme
  └── scandiedge-child/     # Your customizations
```

---

## Keyboard Shortcuts

### Editor Shortcuts

| Action | macOS | Windows/Linux |
|--------|-------|---------------|
| Save | `Cmd+S` | `Ctrl+S` |
| Find | `Cmd+F` | `Ctrl+F` |
| Replace | `Cmd+Option+F` | `Ctrl+H` |
| Format | `Shift+Option+F` | `Shift+Alt+F` |
| Command Palette | `Cmd+Shift+P` | `Ctrl+Shift+P` |
| Multi-cursor | `Option+Click` | `Alt+Click` |
| Select Line | `Cmd+L` | `Ctrl+L` |
| Delete Line | `Cmd+Shift+K` | `Ctrl+Shift+K` |
| Move Line Up | `Option+↑` | `Alt+↑` |
| Move Line Down | `Option+↓` | `Alt+↓` |
| Duplicate Line | `Shift+Option+↓` | `Shift+Alt+↓` |
| Comment Line | `Cmd+/` | `Ctrl+/` |
| Fold Code | `Cmd+Option+[` | `Ctrl+Shift+[` |
| Unfold Code | `Cmd+Option+]` | `Ctrl+Shift+]` |

### Multi-cursor Editing

1. Hold `Alt` and click multiple locations
2. Or use `Cmd+Alt+↓` to add cursor below
3. Type to edit all cursors simultaneously

---

## Monaco Editor Configuration

### Current Settings

```javascript
{
  theme: 'vs-dark',           // Dark theme
  fontSize: 14,               // Readable size
  lineNumbers: 'on',          // Show line numbers
  minimap: { enabled: true }, // Code minimap
  wordWrap: 'on',             // Wrap long lines
  tabSize: 2,                 // 2-space tabs
  insertSpaces: true,         // Spaces instead of tabs
  formatOnPaste: true,        // Auto-format pasted code
  formatOnType: true          // Format while typing
}
```

### Customization (Future)

Users will be able to customize:
- Theme (light/dark/high contrast)
- Font size
- Tab size
- Word wrap
- Minimap visibility

---

## File Types & Languages

### Supported Languages

| Extension | Monaco Language | Features |
|-----------|-----------------|----------|
| `.erb` | HTML | Tag completion, Emmet |
| `.html` | HTML | Full HTML5 support |
| `.css` | CSS | Property hints, color picker |
| `.scss` | SCSS | Sass syntax, variables |
| `.js` | JavaScript | ES6+, JSDoc, snippets |
| `.json` | JSON | Schema validation |
| `.rb` | Ruby | Syntax highlighting |
| `.yml` | YAML | Structure validation |
| `.md` | Markdown | Preview support |

### Binary Files

Binary files show a download button instead of editor:
- Images: `.png`, `.jpg`, `.gif`, `.svg`
- Fonts: `.woff`, `.woff2`, `.ttf`
- Archives: `.zip`, `.tar`, `.gz`
- Documents: `.pdf`

---

## Advanced Features

### 1. Format on Save

Code is automatically formatted when you save:

```html
<!-- Before -->
<div><h1>Title</h1><p>Content</p></div>

<!-- After -->
<div>
  <h1>Title</h1>
  <p>Content</p>
</div>
```

### 2. Find in Files

Search across all theme files:

```
Query: "render partial"
Results:
  views/layouts/application.html.erb:24 - <%= render partial: 'shared/header' %>
  views/layouts/application.html.erb:42 - <%= render partial: 'shared/footer' %>
```

### 3. Live Preview (Coming Soon)

Preview changes without deploying:
1. Edit template file
2. Click "Preview"
3. Opens site in new window
4. Save & refresh to see changes

---

## Troubleshooting

### Editor Not Loading

**Issue**: Monaco editor doesn't appear

**Solution**:
1. Check browser console for errors
2. Ensure CDN is accessible
3. Clear browser cache
4. Try different browser

### Can't Save File

**Issue**: "Failed to save file" error

**Solution**:
1. Check file permissions
2. Ensure directory exists
3. Verify file path is valid
4. Check disk space

### File Not Editable

**Issue**: Binary file shows download only

**Solution**: This is intentional for security. Binary files cannot be edited in the browser.

### Version Restore Failed

**Issue**: Cannot restore previous version

**Solution**:
1. Check if version still exists
2. Verify file path is correct
3. Ensure you have write permissions

---

## Security Features

### 1. Path Whitelisting

Only files within the active theme directory can be accessed:

```ruby
# Allowed
app/themes/scandiedge/views/layouts/application.html.erb

# Blocked
app/themes/../config/database.yml  # Path traversal
/etc/passwd                         # Absolute path
app/models/user.rb                  # Outside theme dir
```

### 2. File Type Validation

Only text-based files can be edited:

```ruby
# Allowed
.erb, .html, .css, .scss, .js, .json, .yml, .rb, .md

# Blocked (download only)
.png, .jpg, .woff, .pdf, .zip
```

### 3. Automatic Backups

Before any destructive operation:
- **Save**: Creates version in database
- **Delete**: Creates backup in `tmp/theme_backups/`
- **Rename**: Original file is backed up

### 4. Version Audit Trail

Every change is tracked:
- Who made the change
- When it was made
- What was changed
- File size

---

## API Reference

### ThemeFileManager

```ruby
# Initialize
manager = ThemeFileManager.new('scandiedge')

# List files
files = manager.list_files
tree = manager.file_tree

# Read file
content = manager.read_file('views/layouts/application.html.erb')

# Write file
manager.write_file('views/layouts/application.html.erb', new_content)

# Create file
manager.create_file('views/shared/_new.html.erb', '')

# Delete file
manager.delete_file('views/shared/_old.html.erb')

# Rename file
manager.rename_file('old.html.erb', 'new.html.erb')

# Search
results = manager.search('render partial')

# Versions
versions = manager.file_versions('views/layouts/application.html.erb')
manager.restore_version(version_id)
```

---

## File Structure

```
app/themes/[theme_name]/
├── config.yml                 # Theme configuration
├── theme.rb                   # Theme initialization
├── README.md                  # Documentation
├── assets/
│   ├── stylesheets/
│   │   └── theme.css
│   └── javascripts/
│       └── theme.js
├── views/
│   ├── layouts/
│   │   └── application.html.erb
│   ├── shared/
│   │   ├── _header.html.erb
│   │   └── _footer.html.erb
│   └── components/
│       ├── _card.html.erb
│       └── _button.html.erb
└── helpers/
    └── theme_helper.rb
```

All files in this structure are editable via the Theme Editor.

---

## Examples

### Example 1: Edit Header

1. Navigate to `views/shared/_header.html.erb`
2. Modify the navigation menu
3. Save with `Cmd+S`
4. Preview changes

### Example 2: Add Custom CSS

1. Click "New File"
2. Path: `assets/stylesheets/custom.css`
3. Add your CSS:
   ```css
   .custom-button {
     background: var(--se-ocean);
     color: white;
     padding: 1rem 2rem;
     border-radius: 6px;
   }
   ```
4. Save file
5. Include in layout

### Example 3: Search & Replace

1. Click "Search in Files"
2. Search for: `old-class-name`
3. Click each result
4. Use Find/Replace to update

### Example 4: Restore Previous Version

1. Make changes to a file
2. Save (creates version)
3. Click "Versions" button
4. Click "Restore" on desired version
5. Confirm restoration

---

## Tips & Tricks

### 1. Use Format Button

Before saving, click "Format" to clean up your code:
- Proper indentation
- Consistent spacing
- Organized attributes

### 2. Multi-cursor for Bulk Changes

Change multiple lines at once:
1. Hold `Alt` and click lines
2. Type to edit all simultaneously

### 3. Code Folding

Collapse sections you're not working on:
1. Click the arrow next to line numbers
2. Or use `Cmd+Option+[`

### 4. Quick File Switching

Use keyboard:
1. Press `Cmd+P` (command palette)
2. Type file name
3. Press Enter to open

### 5. Check Version History

Review what changed:
1. Open Versions panel
2. Compare timestamps
3. Restore if needed

---

## Coming Soon

### Planned Features

- [ ] **Diff View**: Side-by-side comparison of versions
- [ ] **Syntax Validation**: Pre-save ERB/Ruby syntax check
- [ ] **RuboCop Integration**: Auto-lint Ruby files
- [ ] **Live Preview**: Split-screen live reloading
- [ ] **Collaborative Editing**: Multiple users (conflict detection)
- [ ] **Code Snippets**: Pre-defined code templates
- [ ] **Emmet Support**: HTML abbreviations
- [ ] **Git Integration**: Commit directly from editor
- [ ] **Theme Scaffolding**: Generate new themes
- [ ] **Component Library**: Drag-drop components

---

## Comparison: GrapesJS vs Monaco Editor

| Feature | GrapesJS (Visual) | Monaco Editor (Code) |
|---------|-------------------|----------------------|
| **Use Case** | Page layout, drag-drop | Theme files, code editing |
| **User Level** | Non-technical users | Developers |
| **Output** | HTML/CSS components | Full theme files |
| **Learning Curve** | Easy | Moderate |
| **Flexibility** | Limited to blocks | Full code control |
| **Best For** | Quick layouts | Custom development |

**Use both:**
- **GrapesJS** for page content and layouts
- **Monaco Editor** for theme development and customization

---

## FAQ

### Q: Can I edit the active theme?

**A**: Yes, but it's safer to:
1. Create a child theme
2. Edit the child theme
3. Test before activating

### Q: What happens if I break the theme?

**A**: You can:
1. Restore from version history
2. Restore from backup (`tmp/theme_backups/`)
3. Restore from Git (if committed)
4. Deactivate theme and use default

### Q: Can I edit multiple files at once?

**A**: Not simultaneously, but you can:
1. Open file, make changes, save
2. Switch to next file
3. Repeat

### Q: Are changes immediate?

**A**: 
- Development: Restart server to see changes
- Production: Changes are immediate (be careful!)

### Q: Can I undo changes?

**A**: Yes, use Monaco's undo (`Cmd+Z`) or restore a previous version.

---

## Resources

- **Monaco Editor**: https://microsoft.github.io/monaco-editor/
- **Monaco API**: https://microsoft.github.io/monaco-editor/api/index.html
- **WordPress Theme Editor**: Inspiration for this feature
- **VS Code**: Same editor engine

---

## Access

- **URL**: http://localhost:3000/admin/theme_editor
- **Menu**: Admin → Appearance → Theme Editor
- **Permission**: Administrators only

---

**Version**: 1.0.0  
**Last Updated**: October 2025  
**Status**: Production Ready

---

*Built with Monaco Editor - The editor that powers VS Code! 🚀*



