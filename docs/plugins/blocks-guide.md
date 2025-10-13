# Plugin Blocks System - Complete Guide

## Overview

The RailsPress Plugin Blocks system is similar to Shopify's App Blocks, allowing plugins to inject custom UI elements into admin pages (posts, pages, products, etc.) without modifying core views. This provides a flexible and extensible way to enhance the admin interface.

## Table of Contents

1. [Core Concepts](#core-concepts)
2. [Quick Start](#quick-start)
3. [Block Registration](#block-registration)
4. [Block Positions](#block-positions)
5. [Block Rendering](#block-rendering)
6. [View Helper Methods](#view-helper-methods)
7. [Real-World Examples](#real-world-examples)
8. [Best Practices](#best-practices)
9. [API Reference](#api-reference)

---

## Core Concepts

### What are Plugin Blocks?

Plugin Blocks are UI components that plugins can register to appear in specific locations throughout the RailsPress admin interface. They enable plugins to:

- Add sidebar widgets to post/page editors
- Add toolbar buttons for quick actions
- Display analytics or information panels
- Provide shortcuts to plugin features
- Integrate seamlessly with core content editing workflows

### Key Features

- **Location-based**: Blocks can target specific pages (posts, pages, products, etc.)
- **Position-aware**: Blocks can appear in different positions (sidebar, toolbar, header, footer)
- **Conditional rendering**: Blocks can use `can_render` logic to show/hide based on context
- **Isolated**: Each plugin's blocks are independent and don't interfere with others
- **Sortable**: Blocks have order priority for controlling display sequence

---

## Quick Start

### 1. Basic Block Registration

In your plugin's `initialize` method:

```ruby
class MyPlugin < Railspress::PluginBase
  plugin_name 'My Plugin'
  
  def initialize
    super
    register_my_blocks
  end
  
  private
  
  def register_my_blocks
    register_block(:my_sidebar_widget, {
      label: 'My Widget',
      description: 'A helpful widget',
      locations: [:post, :page],
      position: :sidebar,
      order: 10,
      partial: 'plugins/my_plugin/sidebar_widget'
    })
  end
end
```

### 2. Create the Partial

Create `app/views/plugins/my_plugin/_sidebar_widget.html.erb`:

```erb
<div class="bg-[#1a1a1a] border border-[#2a2a2a] rounded-lg p-4 mb-4">
  <h3 class="text-sm font-semibold text-white mb-3"><%= block[:label] %></h3>
  <p class="text-sm text-gray-400"><%= block[:description] %></p>
  
  <!-- Your custom UI here -->
  <div class="mt-3">
    <button class="w-full px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm rounded-lg">
      Do Something
    </button>
  </div>
</div>
```

### 3. Render Blocks in Views

Blocks are automatically rendered in post/page edit views via:

```erb
<%= render_plugin_blocks :post, position: :sidebar, record: @post %>
```

---

## Block Registration

### Registration Options

```ruby
register_block(key, options)
```

#### Parameters

- **key** (Symbol): Unique identifier for the block
- **options** (Hash): Configuration options

#### Options Hash

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `label` | String | No | Display name (defaults to titleized key) |
| `description` | String | No | Block description |
| `icon` | String | No | SVG icon or icon class |
| `locations` | Array<Symbol> | No | Where block appears (default: `[:post, :page]`) |
| `position` | Symbol | No | Block position (default: `:sidebar`) |
| `order` | Integer | No | Display order (default: `100`) |
| `partial` | String | No | Path to partial template |
| `render_proc` | Proc | No | Alternative to partial |
| `settings` | Hash | No | Block-specific settings schema |
| `can_render` | Proc | No | Conditional rendering logic |

### Full Example

```ruby
register_block(:analytics_dashboard, {
  label: 'Content Analytics',
  description: 'View performance metrics for this content',
  icon: '<svg>...</svg>',
  locations: [:post, :page, :product],
  position: :sidebar,
  order: 5,
  partial: 'plugins/analytics/dashboard',
  can_render: ->(context) {
    context[:current_user]&.admin? && 
    context[:record]&.published?
  }
})
```

---

## Block Positions

### Available Positions

| Position | Description | Use Case |
|----------|-------------|----------|
| `:sidebar` | Right sidebar | Widgets, info panels, actions |
| `:toolbar` | Top toolbar | Quick action buttons |
| `:header` | Page header | Notifications, alerts |
| `:footer` | Page footer | Additional info, help text |
| `:main` | Main content area | Inline content blocks |

### Position Characteristics

#### Sidebar (`:sidebar`)
- Most common position
- Appears on right side of editor
- Good for: widgets, analytics, checklists, tools
- Width: Fixed at 320px (w-80)

#### Toolbar (`:toolbar`)
- Compact, action-oriented
- Appears below page title
- Good for: action buttons, quick tools
- Should be minimal and focused

#### Header (`:header`)
- Prominent position
- Appears at top of page
- Good for: important notices, status indicators
- Use sparingly

#### Footer (`:footer`)
- Bottom of page
- Good for: help text, additional resources
- Less visible, use for supplementary content

#### Main (`:main`)
- Within main content flow
- Good for: inline tools, embedded functionality
- Most intrusive, use carefully

---

## Block Rendering

### Using Partials

Most common approach - create a partial view:

```ruby
register_block(:my_block, {
  partial: 'plugins/my_plugin/my_block',
  # ...other options
})
```

Partial receives:
- `block` - The block configuration hash
- All context variables (`:record`, `:current_user`, etc.)

```erb
<!-- app/views/plugins/my_plugin/_my_block.html.erb -->
<div class="plugin-block">
  <h3><%= block[:label] %></h3>
  <p>Editing: <%= record.title %></p>
  <p>User: <%= current_user.name %></p>
</div>
```

### Using Render Proc

For simple blocks or dynamic content:

```ruby
register_block(:simple_message, {
  render_proc: ->(context) {
    content_tag(:div, class: 'alert') do
      "You have #{context[:record].comments.count} comments"
    end
  },
  locations: [:post],
  position: :sidebar
})
```

### Conditional Rendering

Use `can_render` to control when blocks appear:

```ruby
register_block(:admin_only_tools, {
  partial: 'plugins/tools/admin_panel',
  can_render: ->(context) {
    context[:current_user]&.admin?
  }
})

# More complex example
register_block(:draft_reminders, {
  partial: 'plugins/reminders/draft_notice',
  can_render: ->(context) {
    record = context[:record]
    user = context[:current_user]
    
    record&.draft? && 
    user&.can_edit?(record) &&
    record.updated_at < 7.days.ago
  }
})
```

---

## View Helper Methods

### `render_plugin_blocks`

Renders all registered blocks for a location/position.

```erb
<%= render_plugin_blocks :post, position: :sidebar, record: @post %>
```

**Parameters:**
- `location` (Symbol): The content type (`:post`, `:page`, etc.)
- `position` (Symbol): Where to render (`:sidebar`, `:toolbar`, etc.)
- `**context` (Hash): Additional context to pass to blocks

**Example with custom context:**
```erb
<%= render_plugin_blocks :post, 
    position: :sidebar, 
    record: @post,
    editing_mode: true,
    show_advanced: current_user.admin? %>
```

### `plugin_blocks_present?`

Check if any blocks exist before rendering container:

```erb
<% if plugin_blocks_present?(:post, position: :sidebar, record: @post) %>
  <div class="sidebar-blocks">
    <%= render_plugin_blocks :post, position: :sidebar, record: @post %>
  </div>
<% end %>
```

### `render_plugin_block`

Render a specific block by key:

```erb
<%= render_plugin_block :ai_seo_analyzer, record: @post %>
```

---

## Real-World Examples

### Example 1: SEO Analyzer (Sidebar)

```ruby
class AiSeoPlugin < Railspress::PluginBase
  def initialize
    super
    register_blocks
  end
  
  private
  
  def register_blocks
    register_block(:seo_analyzer, {
      label: 'SEO Analyzer',
      description: 'AI-powered SEO analysis',
      icon: '<svg>...</svg>',
      locations: [:post, :page],
      position: :sidebar,
      order: 5,
      partial: 'plugins/ai_seo/analyzer',
      can_render: ->(ctx) { ctx[:record]&.persisted? }
    })
  end
end
```

Partial (`app/views/plugins/ai_seo/_analyzer.html.erb`):

```erb
<div class="bg-[#1a1a1a] border border-[#2a2a2a] rounded-lg p-4 mb-4"
     data-controller="seo-analyzer">
  <div class="flex items-start gap-3 mb-3">
    <%= block[:icon].html_safe %>
    <div class="flex-1">
      <h3 class="text-sm font-semibold text-white"><%= block[:label] %></h3>
      <p class="text-xs text-gray-400 mt-1"><%= block[:description] %></p>
    </div>
  </div>
  
  <!-- SEO Score -->
  <div class="flex items-center justify-between p-3 bg-[#0f0f0f] rounded mb-3">
    <span class="text-sm text-gray-300">SEO Score</span>
    <div class="flex items-center gap-2">
      <div class="w-16 h-2 bg-[#2a2a2a] rounded-full overflow-hidden">
        <div class="h-full bg-green-500" style="width: <%= calculate_seo_score(record) %>%"></div>
      </div>
      <span class="text-sm font-semibold text-green-500">
        <%= calculate_seo_score(record) %>/100
      </span>
    </div>
  </div>
  
  <!-- Generate Button -->
  <button type="button"
          class="w-full px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm rounded-lg"
          data-action="click->seo-analyzer#generate"
          data-record-id="<%= record.id %>"
          data-record-type="<%= record.class.name %>">
    Generate SEO
  </button>
</div>

<% content_for :javascript do %>
  <script>
    function calculateSeoScore(record) {
      // Your SEO scoring logic
      return 75;
    }
  </script>
<% end %>
```

### Example 2: Quick Actions (Toolbar)

```ruby
register_block(:quick_actions, {
  label: 'Quick Actions',
  locations: [:post],
  position: :toolbar,
  order: 1,
  render_proc: ->(context) {
    record = context[:record]
    content_tag(:div, class: 'flex gap-2') do
      [
        link_to('Preview', preview_path(record), 
                class: 'btn-secondary', target: '_blank'),
        link_to('Duplicate', duplicate_path(record), 
                class: 'btn-secondary', method: :post),
        link_to('Schedule', schedule_path(record), 
                class: 'btn-secondary', data: { turbo_frame: 'modal' })
      ].join.html_safe
    end
  }
})
```

### Example 3: Version History (Sidebar)

```ruby
register_block(:version_history, {
  label: 'Version History',
  description: 'View and restore previous versions',
  locations: [:post, :page],
  position: :sidebar,
  order: 20,
  partial: 'plugins/versioning/history',
  can_render: ->(ctx) {
    ctx[:record]&.persisted? && ctx[:record]&.versions&.any?
  }
})
```

Partial:

```erb
<div class="bg-[#1a1a1a] border border-[#2a2a2a] rounded-lg p-4 mb-4">
  <h3 class="text-sm font-semibold text-white mb-3">Version History</h3>
  
  <div class="space-y-2">
    <% record.versions.last(5).reverse.each do |version| %>
      <div class="flex items-center justify-between p-2 bg-[#0f0f0f] rounded text-xs">
        <div>
          <div class="text-white"><%= version.event.titleize %></div>
          <div class="text-gray-400"><%= time_ago_in_words(version.created_at) %> ago</div>
        </div>
        <%= link_to 'Restore', restore_version_path(record, version),
            class: 'text-indigo-400 hover:text-indigo-300',
            method: :post,
            data: { confirm: 'Restore this version?' } %>
      </div>
    <% end %>
  </div>
  
  <%= link_to 'View All Versions', versions_path(record),
      class: 'block mt-3 text-center text-sm text-indigo-400 hover:text-indigo-300' %>
</div>
```

### Example 4: Social Sharing Preview (Main)

```ruby
register_block(:social_preview, {
  label: 'Social Sharing Preview',
  description: 'See how your content looks on social media',
  locations: [:post, :page],
  position: :main,
  order: 100,
  partial: 'plugins/social/preview',
  can_render: ->(ctx) { ctx[:record]&.published? }
})
```

---

## Best Practices

### 1. Use Appropriate Positions

- **Sidebar**: Most plugin blocks belong here
- **Toolbar**: Only for quick, single-click actions
- **Header/Footer**: Use sparingly for important notifications
- **Main**: Avoid unless essential to content editing

### 2. Conditional Rendering

Always use `can_render` to:
- Check user permissions
- Verify required data exists
- Respect user preferences
- Check plugin settings

```ruby
can_render: ->(ctx) {
  ctx[:current_user]&.admin? &&
  ctx[:record]&.persisted? &&
  plugin.get_setting('feature_enabled', true)
}
```

### 3. Order Management

Use logical ordering:
- 1-10: Critical/primary actions
- 11-50: Standard functionality
- 51-100: Supplementary features
- 100+: Low priority or informational

### 4. Styling Consistency

Follow RailsPress admin theme:

```erb
<!-- Container -->
<div class="bg-[#1a1a1a] border border-[#2a2a2a] rounded-lg p-4 mb-4">
  <!-- Title -->
  <h3 class="text-sm font-semibold text-white mb-3">Title</h3>
  
  <!-- Content -->
  <div class="space-y-2 text-sm text-gray-400">
    <!-- Your content -->
  </div>
  
  <!-- Button -->
  <button class="w-full px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm rounded-lg">
    Action
  </button>
</div>
```

### 5. Performance

- Keep blocks lightweight
- Lazy-load data when possible
- Cache expensive computations
- Use Stimulus controllers for interactivity

### 6. Error Handling

Blocks are wrapped in error handlers. Use try/rescue for risky operations:

```erb
<% begin %>
  <%= render_api_data(record) %>
<% rescue => e %>
  <div class="text-red-400 text-xs">
    Unable to load data
  </div>
<% end %>
```

---

## API Reference

### Railspress::PluginBlocks

#### Class Methods

##### `.register(key, options)`

Register a new block.

**Parameters:**
- `key` (Symbol): Unique block identifier
- `options` (Hash): Block configuration

**Returns:** Hash of block configuration

##### `.unregister(key)`

Remove a registered block.

**Parameters:**
- `key` (Symbol): Block identifier

##### `.get(key)`

Get a specific block configuration.

**Parameters:**
- `key` (Symbol): Block identifier

**Returns:** Hash or nil

##### `.for_location(location, position: nil, context: {})`

Get all blocks for a location/position.

**Parameters:**
- `location` (Symbol): Content type
- `position` (Symbol, optional): Block position
- `context` (Hash, optional): Rendering context

**Returns:** Array of block configurations

##### `.render(key, context:, view_context:)`

Render a specific block.

**Parameters:**
- `key` (Symbol): Block identifier
- `context` (Hash): Rendering context
- `view_context` (ActionView::Base): View context

**Returns:** String (HTML)

##### `.render_all(location, position:, context:, view_context:)`

Render all blocks for a location/position.

**Parameters:**
- `location` (Symbol): Content type
- `position` (Symbol): Block position
- `context` (Hash): Rendering context
- `view_context` (ActionView::Base): View context

**Returns:** String (HTML)

##### `.clear!`

Clear all registered blocks (for testing).

### PluginBase Methods

#### `#register_block(key, options)`

Instance method to register blocks from within a plugin.

**Parameters:**
- `key` (Symbol): Block identifier
- `options` (Hash): Block configuration

Automatically adds `plugin_name` to options.

#### `#unregister_block(key)`

Unregister a block.

#### `#blocks`

Get all blocks registered by this plugin.

**Returns:** Hash

---

## Testing

### RSpec Example

```ruby
RSpec.describe 'Plugin Blocks' do
  let(:plugin) { MyPlugin.new }
  
  before { Railspress::PluginBlocks.clear! }
  
  it 'registers blocks' do
    expect(Railspress::PluginBlocks.get(:my_block)).to be_present
  end
  
  it 'renders blocks' do
    html = Railspress::PluginBlocks.render(
      :my_block,
      context: { record: post },
      view_context: view_context
    )
    expect(html).to include('My Block')
  end
  
  it 'respects can_render' do
    blocks = Railspress::PluginBlocks.for_location(
      :post,
      position: :sidebar,
      context: { current_user: guest }
    )
    expect(blocks).to be_empty
  end
end
```

---

## Troubleshooting

### Block Not Appearing

1. Check registration is happening in `initialize`
2. Verify `locations` includes target page type
3. Check `can_render` logic
4. Ensure partial path is correct
5. Look for errors in Rails logs

### Styling Issues

1. Use browser DevTools to inspect
2. Verify Tailwind classes are correct
3. Check z-index and positioning
4. Ensure no CSS conflicts

### Performance Problems

1. Profile block rendering time
2. Move expensive logic to Stimulus controllers
3. Cache database queries
4. Consider lazy-loading content

---

## Advanced Topics

### Dynamic Block Registration

Register blocks based on settings:

```ruby
def register_blocks
  if get_setting('show_analytics', true)
    register_block(:analytics, { ... })
  end
  
  if get_setting('show_seo', true)
    register_block(:seo, { ... })
  end
end
```

### Context-Aware Blocks

Change block behavior based on context:

```erb
<% if editing_mode %>
  <%= render 'edit_mode_ui' %>
<% else %>
  <%= render 'view_mode_ui' %>
<% end %>
```

### Inter-Block Communication

Use Stimulus events:

```javascript
// Block A
this.dispatch('dataChanged', { detail: { id: 123 } })

// Block B
connect() {
  this.element.addEventListener('dataChanged', this.handleDataChange)
}
```

---

## Resources

- **Examples**: See `lib/plugins/ai_seo/ai_seo.rb` for a complete implementation
- **Core Code**: `lib/railspress/plugin_blocks.rb`
- **Helper**: `app/helpers/plugin_blocks_helper.rb`
- **Plugin API**: `lib/railspress/plugin_base.rb`

---

## Summary

The Plugin Blocks system provides a powerful, Shopify-like way for plugins to extend the RailsPress admin interface. By following this guide and best practices, you can create professional, well-integrated plugins that enhance the content editing experience.

Key takeaways:
- Use `:sidebar` position for most blocks
- Always include `can_render` logic
- Follow styling conventions
- Keep blocks focused and performant
- Test thoroughly

Happy plugin building! 🚀



