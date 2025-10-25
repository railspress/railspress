# Write Page Command Palette - Fully Database-Driven

## Overview

Create a completely database-driven command palette with unified search. ALL keyboard shortcuts are stored in the database - zero hardcoding. The Stimulus controller is a pure execution engine.

## Core Architecture

**Database-Driven**: Every keyboard shortcut (including Cmd+K to open palette) is stored in the `shortcuts` table with `keybinding`, `action_type`, and `action_value` columns.

**Global vs Context**: Shortcuts have a `shortcut_set` column:
- `global`: Shows in all palettes (dashboard, posts, pages, write, etc.)
- `write`: Only shows in write page palette
- `admin`: Only shows in admin pages palette

**Unified Search**: Single authenticated endpoint `/admin/search/autocomplete` searches across posts, pages, taxonomies, and users.

## Database Changes

### Migration 1: Add shortcut_set column

**File**: `db/migrate/[timestamp]_add_shortcut_set_to_shortcuts.rb`

```ruby
class AddShortcutSetToShortcuts < ActiveRecord::Migration[7.0]
  def change
    add_column :shortcuts, :shortcut_set, :string, default: 'global'
    add_index :shortcuts, :shortcut_set
  end
end
```

### Migration 2: Add keybinding column

**File**: `db/migrate/[timestamp]_add_keybinding_to_shortcuts.rb`

```ruby
class AddKeybindingToShortcuts < ActiveRecord::Migration[7.0]
  def change
    add_column :shortcuts, :keybinding, :string
    add_index :shortcuts, :keybinding
  end
end
```

### Update Shortcut Model

**File**: `app/models/shortcut.rb`

```ruby
class Shortcut < ApplicationRecord
  belongs_to :tenant
  
  validates :shortcut_set, inclusion: { in: %w[global write admin] }
  validates :keybinding, uniqueness: { scope: [:tenant_id, :shortcut_set], allow_nil: true }
  
  # Returns global shortcuts + context-specific shortcuts
  scope :for_set, ->(set) { where(shortcut_set: ['global', set]) }
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, name: :asc) }
  scope :with_keybinding, -> { where.not(keybinding: nil) }
end
```

## Unified Search API

### Search Controller

**File**: `app/controllers/admin/search_controller.rb` (new)

```ruby
class Admin::SearchController < Admin::BaseController
  # GET /admin/search/autocomplete?q=query&types=posts,pages
  def autocomplete
    query = params[:q]
    types = params[:types]&.split(',') || %w[posts pages taxonomies users]
    
    results = {
      posts: [],
      pages: [],
      taxonomies: [],
      users: []
    }
    
    if query.present?
      results[:posts] = search_posts(query) if types.include?('posts')
      results[:pages] = search_pages(query) if types.include?('pages')
      results[:taxonomies] = search_taxonomies(query) if types.include?('taxonomies')
      results[:users] = search_users(query) if types.include?('users')
    end
    
    render json: results
  end
  
  private
  
  def search_posts(query)
    Post.where(post_type: 'post')
        .where("title LIKE ? OR content LIKE ?", "%#{query}%", "%#{query}%")
        .limit(5)
        .order(updated_at: :desc)
        .map { |p| post_json(p) }
  end
  
  def search_pages(query)
    Post.where(post_type: 'page')
        .where("title LIKE ?", "%#{query}%")
        .limit(5)
        .order(updated_at: :desc)
        .map { |p| page_json(p) }
  end
  
  def search_taxonomies(query)
    Term.where("name LIKE ?", "%#{query}%")
        .limit(5)
        .order(name: :asc)
        .map { |t| taxonomy_json(t) }
  end
  
  def search_users(query)
    User.where("name LIKE ? OR email LIKE ?", "%#{query}%", "%#{query}%")
        .limit(5)
        .order(name: :asc)
        .map { |u| user_json(u) }
  end
  
  def post_json(post)
    {
      id: post.id,
      title: post.title || 'Untitled',
      type: 'post',
      url: edit_admin_post_path(post),
      status: post.status,
      updated_at: post.updated_at
    }
  end
  
  def page_json(page)
    {
      id: page.id,
      title: page.title || 'Untitled',
      type: 'page',
      url: edit_admin_page_path(page),
      status: page.status,
      updated_at: page.updated_at
    }
  end
  
  def taxonomy_json(term)
    {
      id: term.id,
      name: term.name,
      type: 'taxonomy',
      taxonomy: term.taxonomy,
      url: admin_term_path(term),
      count: term.posts.count
    }
  end
  
  def user_json(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      type: 'user',
      url: admin_user_path(user),
      role: user.role
    }
  end
end
```

## Shortcuts API

**File**: `app/controllers/admin/api/shortcuts_controller.rb` (new)

```ruby
class Admin::Api::ShortcutsController < Admin::BaseController
  # GET /admin/api/shortcuts?set=write
  def index
    set = params[:set] || 'admin'
    @shortcuts = Shortcut.active.for_set(set).ordered
    
    render json: { 
      shortcuts: @shortcuts.map { |s| shortcut_json(s) }
    }
  end
  
  private
  
  def shortcut_json(shortcut)
    {
      id: shortcut.id,
      name: shortcut.name,
      description: shortcut.description,
      action_type: shortcut.action_type,
      action_value: shortcut.action_value,
      icon: shortcut.icon,
      category: shortcut.category,
      keybinding: shortcut.keybinding,
      shortcut_set: shortcut.shortcut_set
    }
  end
end
```

## Command Palette Partial

**File**: `app/views/shared/_command_palette.html.erb` (new)

```erb
<div data-controller="command-palette" 
     data-command-palette-set-value="<%= shortcut_set %>"
     class="hidden">
  
  <!-- Backdrop -->
  <div data-command-palette-target="backdrop" 
       data-action="click->command-palette#closePalette"
       class="fixed inset-0 bg-black/50 z-50"></div>
  
  <!-- Modal -->
  <div data-command-palette-target="modal"
       class="fixed top-20 left-1/2 -translate-x-1/2 w-full max-w-2xl z-50 rounded-lg shadow-2xl"
       style="background: <%= theme[:bg_color] %>; border: 1px solid <%= theme[:border_color] %>">
    
    <!-- Search Input -->
    <div class="p-4 border-b" style="border-color: <%= theme[:border_color] %>">
      <div class="flex items-center gap-3">
        <svg class="w-5 h-5 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
        </svg>
        <input type="text"
               data-command-palette-target="search"
               data-action="input->command-palette#search keydown->command-palette#navigate"
               placeholder="Type a command or search..."
               class="w-full bg-transparent outline-none text-base"
               style="color: <%= theme[:text_color] %>">
      </div>
    </div>
    
    <!-- Results List -->
    <div data-command-palette-target="results" 
         class="max-h-96 overflow-y-auto">
      
      <!-- Shortcuts Section -->
      <div data-command-palette-target="shortcutsSection">
        <div class="px-4 py-2 text-xs uppercase font-semibold opacity-50">Commands</div>
        <div data-command-palette-target="shortcutsList"></div>
      </div>
      
      <!-- Posts Section -->
      <div data-command-palette-target="postsSection" class="hidden">
        <div class="px-4 py-2 text-xs uppercase font-semibold opacity-50">Posts</div>
        <div data-command-palette-target="postsList"></div>
      </div>
      
      <!-- Pages Section -->
      <div data-command-palette-target="pagesSection" class="hidden">
        <div class="px-4 py-2 text-xs uppercase font-semibold opacity-50">Pages</div>
        <div data-command-palette-target="pagesList"></div>
      </div>
      
      <!-- Taxonomies Section -->
      <div data-command-palette-target="taxonomiesSection" class="hidden">
        <div class="px-4 py-2 text-xs uppercase font-semibold opacity-50">Categories & Tags</div>
        <div data-command-palette-target="taxonomiesList"></div>
      </div>
      
      <!-- Users Section -->
      <div data-command-palette-target="usersSection" class="hidden">
        <div class="px-4 py-2 text-xs uppercase font-semibold opacity-50">Users</div>
        <div data-command-palette-target="usersList"></div>
      </div>
      
      <!-- Empty State -->
      <div data-command-palette-target="emptyState" class="hidden px-4 py-8 text-center opacity-50">
        <p>No results found</p>
      </div>
    </div>
    
    <!-- Footer -->
    <div class="px-4 py-3 border-t text-xs flex justify-between"
         style="border-color: <%= theme[:border_color] %>; color: <%= theme[:text_color] %>; opacity: 0.7;">
      <div class="flex gap-4">
        <span><kbd class="px-1.5 py-0.5 rounded" style="background: <%= theme[:border_color] %>">↑↓</kbd> Navigate</span>
        <span><kbd class="px-1.5 py-0.5 rounded" style="background: <%= theme[:border_color] %>">↵</kbd> Select</span>
        <span><kbd class="px-1.5 py-0.5 rounded" style="background: <%= theme[:border_color] %>">esc</kbd> Close</span>
      </div>
      <div class="opacity-50"><%= shortcut_set.titleize %> Palette</div>
    </div>
  </div>
</div>

<!-- Item Template -->
<template data-command-palette-target="itemTemplate">
  <div data-command-palette-target="item"
       data-action="click->command-palette#select mouseenter->command-palette#highlight"
       class="px-4 py-3 cursor-pointer flex items-center justify-between hover:opacity-90 transition-colors"
       style="color: <%= theme[:text_color] %>">
    <div class="flex items-center gap-3 flex-1 min-w-0">
      <span data-item-icon class="text-lg flex-shrink-0"></span>
      <div class="flex-1 min-w-0">
        <div data-item-name class="font-medium truncate"></div>
        <div data-item-description class="text-sm opacity-70 truncate"></div>
      </div>
    </div>
    <span data-item-keybinding class="text-xs px-2 py-1 rounded opacity-50 flex-shrink-0 ml-2"></span>
  </div>
</template>
```

## Stimulus Controller - Pure Execution Engine

**File**: `app/javascript/controllers/command_palette_controller.js` (new)

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal", "backdrop", "search", "results",
    "shortcutsList", "shortcutsSection",
    "postsList", "postsSection",
    "pagesList", "pagesSection",
    "taxonomiesList", "taxonomiesSection",
    "usersList", "usersSection",
    "emptyState", "item", "itemTemplate"
  ]
  
  static values = {
    set: String
  }
  
  connect() {
    this.shortcuts = []
    this.allItems = []
    this.selectedIndex = 0
    this.searchDebounce = null
    this.isOpen = false
    
    // Load shortcuts FIRST, then register keyboard listeners
    this.loadShortcuts().then(() => {
      this.registerKeyboardListeners()
    })
  }
  
  disconnect() {
    if (this.boundKeydownHandler) {
      document.removeEventListener('keydown', this.boundKeydownHandler)
    }
  }
  
  async loadShortcuts() {
    try {
      const response = await fetch(`/admin/api/shortcuts?set=${this.setValue}`)
      const data = await response.json()
      this.shortcuts = data.shortcuts
      console.log(`Loaded ${this.shortcuts.length} shortcuts for set: ${this.setValue}`)
      this.renderShortcuts()
    } catch (error) {
      console.error('Failed to load shortcuts:', error)
    }
  }
  
  registerKeyboardListeners() {
    this.boundKeydownHandler = this.handleGlobalKeydown.bind(this)
    document.addEventListener('keydown', this.boundKeydownHandler)
    console.log('Keyboard listeners registered')
  }
  
  handleGlobalKeydown(e) {
    // Don't intercept if typing in input/textarea (except when palette is open)
    if (!this.isOpen && (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA')) {
      return
    }
    
    // Convert event to keybinding string
    const keybinding = this.getKeybindingString(e)
    
    // Find matching shortcut in database
    const shortcut = this.shortcuts.find(s => s.keybinding === keybinding)
    
    if (shortcut) {
      e.preventDefault()
      this.executeAction(shortcut)
    }
  }
  
  getKeybindingString(e) {
    let key = e.key.toLowerCase()
    
    // Normalize special keys
    const keyMap = {
      ' ': 'space',
      'arrowup': 'up',
      'arrowdown': 'down',
      'arrowleft': 'left',
      'arrowright': 'right',
      'escape': 'esc',
      'enter': 'enter'
    }
    
    key = keyMap[key] || key
    
    // Build modifier prefix
    let modifiers = []
    if (e.metaKey || e.ctrlKey) modifiers.push('cmd')
    if (e.altKey) modifiers.push('alt')
    if (e.shiftKey) modifiers.push('shift')
    
    return modifiers.length > 0 ? `${modifiers.join('+')}+${key}` : key
  }
  
  executeAction(shortcut) {
    console.log('Executing shortcut:', shortcut.name)
    
    if (shortcut.action_type === 'navigate') {
      window.Turbo.visit(shortcut.action_value)
    } else if (shortcut.action_type === 'execute') {
      this.executeMethod(shortcut.action_value)
    }
  }
  
  executeMethod(methodName) {
    if (typeof this[methodName] === 'function') {
      this[methodName]()
    } else {
      console.warn(`Method ${methodName} not found in command palette controller`)
    }
  }
  
  // ============================================
  // ACTION METHODS (called from database)
  // ============================================
  
  openPalette() {
    this.isOpen = true
    this.element.classList.remove('hidden')
    this.searchTarget.value = ''
    this.searchTarget.focus()
    this.renderShortcuts()
    this.hideAllSections()
    this.shortcutsSectionTarget.classList.remove('hidden')
  }
  
  closePalette() {
    this.isOpen = false
    this.element.classList.add('hidden')
    this.searchTarget.value = ''
  }
  
  savePost() {
    const saveButton = document.querySelector('[data-action*="autosave#save"]')
    if (saveButton) {
      saveButton.click()
    } else {
      // Fallback: trigger form submit
      const form = document.querySelector('form[data-controller*="autosave"]')
      if (form) form.requestSubmit()
    }
  }
  
  toggleAISidebar() {
    const aiWidget = document.querySelector('[data-controller="ai-chat-widget"]')
    if (aiWidget) {
      window.dispatchEvent(new CustomEvent('toggle-ai-sidebar'))
    }
  }
  
  toggleRightSidebar() {
    const rightPanel = document.querySelector('[data-split-panels-target="right"]')
    if (rightPanel) {
      rightPanel.classList.toggle('hidden')
    }
  }
  
  previewPost() {
    const previewButton = document.querySelector('[data-action*="preview"]')
    if (previewButton) previewButton.click()
  }
  
  publishPost() {
    const statusSelect = document.querySelector('select[name="post[status]"]')
    if (statusSelect) {
      statusSelect.value = 'publish'
      this.savePost()
    }
  }
  
  // ============================================
  // SEARCH & RENDERING
  // ============================================
  
  async search(e) {
    const query = e.target.value.trim()
    
    if (!query) {
      this.renderShortcuts()
      this.hideAllSections()
      this.shortcutsSectionTarget.classList.remove('hidden')
      return
    }
    
    // Filter shortcuts locally
    this.filterShortcuts(query)
    
    // Debounce search API call
    clearTimeout(this.searchDebounce)
    this.searchDebounce = setTimeout(async () => {
      await this.searchContent(query)
    }, 300)
  }
  
  async searchContent(query) {
    try {
      const response = await fetch(
        `/admin/search/autocomplete?q=${encodeURIComponent(query)}`
      )
      const data = await response.json()
      
      // Render all results
      this.renderPosts(data.posts || [])
      this.renderPages(data.pages || [])
      this.renderTaxonomies(data.taxonomies || [])
      this.renderUsers(data.users || [])
      
      // Show/hide sections
      this.toggleSection(this.postsSectionTarget, data.posts?.length > 0)
      this.toggleSection(this.pagesSectionTarget, data.pages?.length > 0)
      this.toggleSection(this.taxonomiesSectionTarget, data.taxonomies?.length > 0)
      this.toggleSection(this.usersSectionTarget, data.users?.length > 0)
      
      // Show empty state if no results
      const hasResults = (data.posts?.length + data.pages?.length + 
                         data.taxonomies?.length + data.users?.length) > 0
      this.emptyStateTarget.classList.toggle('hidden', hasResults)
      
    } catch (error) {
      console.error('Search failed:', error)
    }
  }
  
  filterShortcuts(query) {
    const filtered = this.shortcuts.filter(s => 
      s.name.toLowerCase().includes(query.toLowerCase()) ||
      s.description?.toLowerCase().includes(query.toLowerCase())
    )
    this.renderShortcuts(filtered)
  }
  
  renderShortcuts(shortcuts = this.shortcuts) {
    this.shortcutsListTarget.innerHTML = ''
    shortcuts.forEach(shortcut => {
      const item = this.createItem({
        icon: shortcut.icon || '⚡',
        name: shortcut.name,
        description: shortcut.description,
        keybinding: shortcut.keybinding,
        data: shortcut
      })
      this.shortcutsListTarget.appendChild(item)
    })
    this.updateAllItems()
  }
  
  renderPosts(posts) {
    this.postsListTarget.innerHTML = ''
    posts.forEach(post => {
      const item = this.createItem({
        icon: '📄',
        name: post.title,
        description: `${post.status} • Updated ${this.timeAgo(post.updated_at)}`,
        keybinding: 'Post',
        data: { action_type: 'navigate', action_value: post.url }
      })
      this.postsListTarget.appendChild(item)
    })
    this.updateAllItems()
  }
  
  renderPages(pages) {
    this.pagesListTarget.innerHTML = ''
    pages.forEach(page => {
      const item = this.createItem({
        icon: '📃',
        name: page.title,
        description: `${page.status} • Updated ${this.timeAgo(page.updated_at)}`,
        keybinding: 'Page',
        data: { action_type: 'navigate', action_value: page.url }
      })
      this.pagesListTarget.appendChild(item)
    })
    this.updateAllItems()
  }
  
  renderTaxonomies(taxonomies) {
    this.taxonomiesListTarget.innerHTML = ''
    taxonomies.forEach(tax => {
      const item = this.createItem({
        icon: '🏷️',
        name: tax.name,
        description: `${tax.taxonomy} • ${tax.count} items`,
        keybinding: 'Tag',
        data: { action_type: 'navigate', action_value: tax.url }
      })
      this.taxonomiesListTarget.appendChild(item)
    })
    this.updateAllItems()
  }
  
  renderUsers(users) {
    this.usersListTarget.innerHTML = ''
    users.forEach(user => {
      const item = this.createItem({
        icon: '👤',
        name: user.name,
        description: `${user.email} • ${user.role}`,
        keybinding: 'User',
        data: { action_type: 'navigate', action_value: user.url }
      })
      this.usersListTarget.appendChild(item)
    })
    this.updateAllItems()
  }
  
  createItem({ icon, name, description, keybinding, data }) {
    const template = this.itemTemplateTarget.content.cloneNode(true)
    const item = template.querySelector('[data-command-palette-target="item"]')
    
    item.querySelector('[data-item-icon]').textContent = icon
    item.querySelector('[data-item-name]').textContent = name
    item.querySelector('[data-item-description]').textContent = description
    item.querySelector('[data-item-keybinding]').textContent = keybinding || ''
    item.dataset.itemData = JSON.stringify(data)
    
    return item
  }
  
  // ============================================
  // NAVIGATION
  // ============================================
  
  navigate(e) {
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      this.selectNext()
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      this.selectPrevious()
    } else if (e.key === 'Enter') {
      e.preventDefault()
      this.executeSelected()
    } else if (e.key === 'Escape') {
      e.preventDefault()
      this.closePalette()
    }
  }
  
  selectNext() {
    this.selectedIndex = Math.min(this.selectedIndex + 1, this.allItems.length - 1)
    this.updateSelection()
  }
  
  selectPrevious() {
    this.selectedIndex = Math.max(this.selectedIndex - 1, 0)
    this.updateSelection()
  }
  
  updateSelection() {
    this.allItems.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.style.background = 'var(--color-primary)'
        item.scrollIntoView({ block: 'nearest' })
      } else {
        item.style.background = 'transparent'
      }
    })
  }
  
  highlight(e) {
    const item = e.currentTarget
    this.selectedIndex = this.allItems.indexOf(item)
    this.updateSelection()
  }
  
  select(e) {
    const item = e.currentTarget
    this.selectedIndex = this.allItems.indexOf(item)
    this.executeSelected()
  }
  
  executeSelected() {
    const selectedItem = this.allItems[this.selectedIndex]
    if (!selectedItem) return
    
    const data = JSON.parse(selectedItem.dataset.itemData)
    this.executeAction(data)
    this.closePalette()
  }
  
  updateAllItems() {
    this.allItems = Array.from(this.element.querySelectorAll('[data-command-palette-target="item"]'))
    this.selectedIndex = 0
    this.updateSelection()
  }
  
  hideAllSections() {
    this.postsSectionTarget.classList.add('hidden')
    this.pagesSectionTarget.classList.add('hidden')
    this.taxonomiesSectionTarget.classList.add('hidden')
    this.usersSectionTarget.classList.add('hidden')
    this.emptyStateTarget.classList.add('hidden')
  }
  
  toggleSection(section, show) {
    section.classList.toggle('hidden', !show)
  }
  
  timeAgo(date) {
    const seconds = Math.floor((new Date() - new Date(date)) / 1000)
    if (seconds < 60) return 'just now'
    const minutes = Math.floor(seconds / 60)
    if (minutes < 60) return `${minutes}m ago`
    const hours = Math.floor(minutes / 60)
    if (hours < 24) return `${hours}h ago`
    const days = Math.floor(hours / 24)
    return `${days}d ago`
  }
}
```

## Seed Data - All Shortcuts in Database

**File**: `db/seeds/shortcuts.rb` (new)

```ruby
puts "Creating shortcuts..."

tenant = Tenant.first

# Global shortcuts (show everywhere)
[
  {
    name: 'Open Command Palette',
    description: 'Open command palette',
    action_type: 'execute',
    action_value: 'openPalette',
    icon: '⌘',
    category: 'system',
    shortcut_set: 'global',
    keybinding: 'cmd+k'
  },
  {
    name: 'Go to Dashboard',
    description: 'Navigate to admin dashboard',
    action_type: 'navigate',
    action_value: '/admin',
    icon: '🏠',
    category: 'navigation',
    shortcut_set: 'global',
    keybinding: 'cmd+shift+d'
  },
  {
    name: 'Go to Posts',
    description: 'Navigate to posts list',
    action_type: 'navigate',
    action_value: '/admin/posts',
    icon: '📝',
    category: 'navigation',
    shortcut_set: 'global',
    keybinding: 'cmd+shift+p'
  },
  {
    name: 'Go to Pages',
    description: 'Navigate to pages list',
    action_type: 'navigate',
    action_value: '/admin/pages',
    icon: '📃',
    category: 'navigation',
    shortcut_set: 'global',
    keybinding: 'cmd+shift+g'
  },
  {
    name: 'Go to Users',
    description: 'Navigate to users list',
    action_type: 'navigate',
    action_value: '/admin/users',
    icon: '👥',
    category: 'navigation',
    shortcut_set: 'global',
    keybinding: 'cmd+shift+u'
  }
].each do |data|
  Shortcut.find_or_create_by!(
    name: data[:name],
    shortcut_set: data[:shortcut_set],
    tenant: tenant
  ) do |s|
    s.assign_attributes(data)
    s.active = true
    s.position = 0
  end
end

# Write-specific shortcuts
[
  {
    name: 'Save Post',
    description: 'Save current post',
    action_type: 'execute',
    action_value: 'savePost',
    icon: '💾',
    category: 'content',
    shortcut_set: 'write',
    keybinding: 'cmd+s'
  },
  {
    name: 'Toggle AI Assistant',
    description: 'Show/hide AI sidebar',
    action_type: 'execute',
    action_value: 'toggleAISidebar',
    icon: '🤖',
    category: 'tools',
    shortcut_set: 'write',
    keybinding: 'cmd+i'
  },
  {
    name: 'Toggle Right Sidebar',
    description: 'Show/hide right sidebar',
    action_type: 'execute',
    action_value: 'toggleRightSidebar',
    icon: '📋',
    category: 'tools',
    shortcut_set: 'write',
    keybinding: 'cmd+b'
  },
  {
    name: 'New Post',
    description: 'Create a new post',
    action_type: 'navigate',
    action_value: '/admin/posts/new',
    icon: '➕',
    category: 'content',
    shortcut_set: 'write',
    keybinding: 'cmd+n'
  },
  {
    name: 'Preview Post',
    description: 'Preview current post',
    action_type: 'execute',
    action_value: 'previewPost',
    icon: '👁️',
    category: 'content',
    shortcut_set: 'write',
    keybinding: 'cmd+p'
  },
  {
    name: 'Publish Post',
    description: 'Publish current post',
    action_type: 'execute',
    action_value: 'publishPost',
    icon: '🚀',
    category: 'content',
    shortcut_set: 'write',
    keybinding: 'cmd+shift+enter'
  }
].each do |data|
  Shortcut.find_or_create_by!(
    name: data[:name],
    shortcut_set: data[:shortcut_set],
    tenant: tenant
  ) do |s|
    s.assign_attributes(data)
    s.active = true
    s.position = 0
  end
end

puts "✓ Shortcuts created"
```

## Routes

**File**: `config/routes.rb`

Add inside `namespace :admin do`:

```ruby
# Unified search endpoint
resource :search, only: [] do
  get :autocomplete, on: :collection
end

# Shortcuts API
namespace :api do
  resources :shortcuts, only: [:index]
end
```

## Integration

**File**: `app/views/layouts/write_fullscreen.html.erb`

Add before `</body>`:

```erb
<%= render 'shared/command_palette',
    shortcut_set: 'write',
    theme: {
      bg_color: 'var(--bg-primary)',
      text_color: 'var(--text-primary)',
      selected_bg: 'var(--color-primary)',
      border_color: 'var(--border-color)'
    } %>
```

## Testing Checklist

- [ ] Cmd+K opens command palette (from database)
- [ ] Cmd+S saves post (from database)
- [ ] Cmd+I toggles AI sidebar (from database)
- [ ] Cmd+B toggles right sidebar (from database)
- [ ] Cmd+N creates new post (from database)
- [ ] Cmd+P previews post (from database)
- [ ] Typing searches across posts, pages, taxonomies, users
- [ ] Results grouped by type
- [ ] Arrow keys navigate all results
- [ ] Enter executes selected item
- [ ] Escape closes palette
- [ ] Clicking backdrop closes palette
- [ ] Global shortcuts appear in palette
- [ ] Write-specific shortcuts appear in palette
- [ ] Keybindings display next to commands in palette

## Implementation Order

1. Run migrations (add shortcut_set, add keybinding)
2. Update Shortcut model with validations and scopes
3. Create Admin::SearchController
4. Create Admin::Api::ShortcutsController
5. Add routes
6. Create command_palette_controller.js
7. Create _command_palette.html.erb partial
8. Run seeds to populate shortcuts
9. Add partial to write_fullscreen.html.erb
10. Test all shortcuts work from database

