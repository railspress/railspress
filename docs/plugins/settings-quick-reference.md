# Plugin Settings Schema - Quick Reference

**One-page cheat sheet for creating plugin settings**

---

## 🚀 Basic Setup

```ruby
class MyPlugin < Railspress::PluginBase
  plugin_name 'My Plugin'
  
  settings_schema do
    section 'Settings' do
      text 'api_key', 'API Key', required: true
      checkbox 'enabled', 'Enable', default: true
    end
  end
end
```

**Result**: Automatic admin UI at `/admin/plugins/:id/settings`

---

## 📋 Field Types

### Text Input
```ruby
text 'key', 'Label',
  required: true,
  placeholder: 'Enter...',
  default: 'value'
```

### Textarea
```ruby
textarea 'content', 'Content',
  rows: 6,
  placeholder: 'Long text...'
```

### Number
```ruby
number 'count', 'Count',
  min: 1,
  max: 100,
  step: 1,
  default: 10
```

### Checkbox
```ruby
checkbox 'enabled', 'Enable Feature',
  default: true
```

### Select Dropdown
```ruby
select 'theme', 'Theme',
  [
    ['Light', 'light'],
    ['Dark', 'dark']
  ],
  default: 'light'
```

### Radio Buttons
```ruby
radio 'size', 'Size',
  [
    ['Small', 'sm'],
    ['Large', 'lg']
  ],
  default: 'sm'
```

### Email
```ruby
email 'contact', 'Email',
  required: true,
  placeholder: 'user@example.com'
```

### URL
```ruby
url 'webhook', 'Webhook URL',
  placeholder: 'https://...'
```

### Color Picker
```ruby
color 'primary', 'Primary Color',
  default: '#3B82F6'
```

### WYSIWYG Editor
```ruby
wysiwyg 'message', 'Welcome Message',
  editor: 'trix'
```

### Code Editor
```ruby
code 'custom_css', 'Custom CSS',
  language: 'css'
```

---

## 🔧 Common Options

```ruby
# For all fields:
required: true              # Required field
description: 'Help text'   # Help text below
default: 'value'            # Default value
placeholder: 'Hint...'      # Placeholder

# Number fields:
min: 0                      # Minimum
max: 100                    # Maximum
step: 1                     # Increment

# Textarea:
rows: 6                     # Height

# Code:
language: 'css'             # Syntax
```

---

## 📦 Multiple Sections

```ruby
settings_schema do
  section 'General' do
    text 'api_key', 'API Key'
  end
  
  section 'Display' do
    color 'color', 'Color'
    number 'items', 'Items'
  end
  
  section 'Advanced' do
    code 'css', 'Custom CSS'
  end
end
```

---

## 💾 Access Settings

```ruby
# In plugin methods:
get_setting('api_key')              # Get value
get_setting('count', 10)            # With default
has_setting?('api_key')             # Check exists
settings                            # All settings hash
```

---

## ✅ Validation

```ruby
# Auto-validated:
text 'key', 'Key', required: true   # Must be present
number 'age', 'Age', min: 18        # Must be >= 18
email 'email', 'Email'              # Must be valid email
url 'url', 'URL'                    # Must be valid URL
```

---

## 🎯 Complete Example

```ruby
class MyPlugin < Railspress::PluginBase
  plugin_name 'My Plugin'
  plugin_version '1.0.0'
  
  settings_schema do
    section 'API Configuration' do
      email 'admin_email', 'Admin Email',
        required: true,
        default: 'admin@example.com'
      
      text 'api_key', 'API Key',
        required: true,
        placeholder: 'sk_live_...'
      
      url 'api_endpoint', 'API Endpoint',
        default: 'https://api.example.com'
    end
    
    section 'Display Settings' do
      checkbox 'enabled', 'Enable Plugin',
        default: true
      
      color 'primary_color', 'Primary Color',
        default: '#3B82F6'
      
      number 'max_items', 'Max Items',
        min: 1,
        max: 100,
        default: 10
      
      select 'layout', 'Layout',
        [['Grid', 'grid'], ['List', 'list']],
        default: 'grid'
    end
    
    section 'Advanced' do
      textarea 'custom_message', 'Custom Message',
        rows: 4
      
      code 'custom_css', 'Custom CSS',
        language: 'css'
    end
  end
  
  # Use settings in your plugin
  def initialize
    super
    
    if get_setting('enabled', true)
      register_features
    end
  end
  
  private
  
  def register_features
    api_key = get_setting('api_key')
    max_items = get_setting('max_items', 10)
    
    # Your plugin logic using settings
  end
end
```

---

## 🎨 UI Preview

Settings automatically render as:

```
┌─────────────────────────────────────┐
│ Section Title                       │
│ Section description text            │
├─────────────────────────────────────┤
│                                     │
│ Field Label                         │
│ [____________input_____________]    │
│ Help text here                      │
│                                     │
│ Another Field                       │
│ [____________input_____________]    │
│                                     │
└─────────────────────────────────────┘
```

**Styled with Tailwind CSS dark mode support!**

---

## ⚡ Benefits

✅ **Auto UI Generation** - No manual forms  
✅ **Auto Validation** - Built-in rules  
✅ **Type Safety** - Field type checking  
✅ **Consistent Design** - Tailwind styled  
✅ **Dark Mode** - Automatic support  
✅ **Easy Access** - Simple getter methods  

---

**Full guide**: `PLUGIN_SETTINGS_SCHEMA_GUIDE.md`

*RailsPress Plugin Settings Schema v1.0.0*



