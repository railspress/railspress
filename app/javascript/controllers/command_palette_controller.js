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
    // Try to call window function first
    if (typeof window[methodName] === 'function') {
      window[methodName]()
    } else if (typeof this[methodName] === 'function') {
      this[methodName]()
    } else {
      console.warn(`Method ${methodName} not found in window or command palette controller`)
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
    
    // Sort shortcuts: write-specific first (by id asc), then global (by id asc)
    const sortedShortcuts = shortcuts.sort((a, b) => {
      // First sort by shortcut_set: write first, then global
      if (a.shortcut_set === 'write' && b.shortcut_set === 'global') return -1
      if (a.shortcut_set === 'global' && b.shortcut_set === 'write') return 1
      
      // Within same set, sort by id ascending
      return a.id - b.id
    })
    
    sortedShortcuts.forEach(shortcut => {
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
        icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>',
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
        icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>',
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
        icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"/></svg>',
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
        icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>',
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
    
    item.querySelector('[data-item-icon]').innerHTML = icon
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
      e.stopPropagation()
      this.selectNext()
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      e.stopPropagation()
      this.selectPrevious()
    } else if (e.key === 'Enter') {
      e.preventDefault()
      e.stopPropagation()
      this.executeSelected()
    } else if (e.key === 'Escape') {
      e.preventDefault()
      e.stopPropagation()
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
        item.classList.add('selected')
        item.scrollIntoView({ block: 'nearest' })
      } else {
        item.classList.remove('selected')
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
