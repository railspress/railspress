// Command Palette Controller (CMD+I)
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "input", "results", "empty"]
  
  connect() {
    this.commands = []
    this.filteredCommands = []
    this.selectedIndex = 0
    
    // Load commands
    this.loadCommands()
    
    // Global keyboard listener
    document.addEventListener('keydown', this.handleGlobalKeyboard.bind(this))
  }
  
  disconnect() {
    document.removeEventListener('keydown', this.handleGlobalKeyboard.bind(this))
  }
  
  // Handle keyboard shortcut based on settings
  handleGlobalKeyboard(event) {
    // Get the configured shortcut (default to cmd+k)
    const shortcut = this.getShortcut()
    
    if (this.matchesShortcut(event, shortcut)) {
      event.preventDefault()
      this.open()
    }
  }
  
  // Get the configured shortcut from the page
  getShortcut() {
    // Check if there's a data attribute with the shortcut
    const shortcut = document.querySelector('[data-command-palette]')?.dataset.shortcut
    return shortcut || 'cmd+k'
  }
  
  // Check if the event matches the configured shortcut
  matchesShortcut(event, shortcut) {
    switch(shortcut) {
      case 'cmd+k':
        return event.metaKey && event.key === 'k'
      case 'ctrl+k':
        return event.ctrlKey && event.key === 'k'
      case 'cmd+shift+p':
        return event.metaKey && event.shiftKey && event.key === 'P'
      case 'ctrl+shift+p':
        return event.ctrlKey && event.shiftKey && event.key === 'P'
      case 'cmd+i':
        return event.metaKey && event.key === 'i'
      case 'ctrl+i':
        return event.ctrlKey && event.key === 'i'
      default:
        return event.metaKey && event.key === 'k' // fallback to cmd+k
    }
  }
  
  // Open command palette
  open() {
    const dialog = document.querySelector('[data-command-palette-target="dialog"]')
    const input = document.querySelector('[data-command-palette-target="input"]')
    
    if (dialog && input) {
      dialog.classList.remove('hidden')
      input.focus()
      input.value = ''
      this.search()
      
      // Prevent body scroll
      document.body.style.overflow = 'hidden'
    }
  }
  
  // Close command palette
  close() {
    const dialog = document.querySelector('[data-command-palette-target="dialog"]')
    if (dialog) {
      dialog.classList.add('hidden')
    }
    document.body.style.overflow = ''
  }
  
  // Handle keyboard in dialog
  handleKeyboard(event) {
    switch(event.key) {
      case 'Escape':
        event.preventDefault()
        this.close()
        break
      case 'ArrowDown':
        event.preventDefault()
        this.selectNext()
        break
      case 'ArrowUp':
        event.preventDefault()
        this.selectPrevious()
        break
      case 'Enter':
        event.preventDefault()
        this.execute()
        break
    }
  }
  
  // Search/filter commands
  search() {
    const input = document.querySelector('[data-command-palette-target="input"]')
    const query = input ? input.value.toLowerCase().trim() : ''
    
    if (query === '') {
      this.filteredCommands = this.commands
    } else {
      this.filteredCommands = this.commands.filter(cmd => 
        cmd.title.toLowerCase().includes(query) ||
        cmd.description.toLowerCase().includes(query) ||
        cmd.category.toLowerCase().includes(query) ||
        (cmd.keywords && cmd.keywords.some(k => k.toLowerCase().includes(query)))
      )
    }
    
    this.selectedIndex = 0
    this.render()
  }
  
  // Navigate selection
  selectNext() {
    if (this.selectedIndex < this.filteredCommands.length - 1) {
      this.selectedIndex++
      this.render()
      this.scrollToSelected()
    }
  }
  
  selectPrevious() {
    if (this.selectedIndex > 0) {
      this.selectedIndex--
      this.render()
      this.scrollToSelected()
    }
  }
  
  // Execute selected command
  execute() {
    const command = this.filteredCommands[this.selectedIndex]
    if (!command) return
    
    this.close()
    
    // Execute based on action type
    if (command.action === 'navigate') {
      window.location.href = command.url
    } else if (command.action === 'navigate_blank') {
      window.open(command.url, '_blank')
    } else if (command.action === 'function') {
      eval(command.function)
    }
  }
  
  // Click on command
  selectCommand(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.selectedIndex = index
    this.execute()
  }
  
  // Scroll selected into view
  scrollToSelected() {
    const results = document.querySelector('[data-command-palette-target="results"]')
    if (results) {
      const selected = results.querySelector('.command-item-selected')
      if (selected) {
        selected.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
      }
    }
  }
  
  // Render results
  render() {
    const results = document.querySelector('[data-command-palette-target="results"]')
    const empty = document.querySelector('[data-command-palette-target="empty"]')
    
    if (!results || !empty) return
    
    if (this.filteredCommands.length === 0) {
      results.classList.add('hidden')
      empty.classList.remove('hidden')
      return
    }
    
    results.classList.remove('hidden')
    empty.classList.add('hidden')
    
    // Group by category
    const grouped = this.groupByCategory(this.filteredCommands)
    
    let html = ''
    Object.keys(grouped).forEach(category => {
      html += `<div class="command-category">`
      html += `<div class="category-title">${category}</div>`
      
      grouped[category].forEach((cmd, i) => {
        const globalIndex = this.filteredCommands.indexOf(cmd)
        const isSelected = globalIndex === this.selectedIndex
        
        html += `
          <div class="command-item ${isSelected ? 'command-item-selected' : ''}" 
               data-index="${globalIndex}"
               data-action="click->command-palette#selectCommand">
            <div class="flex items-center flex-1">
              <div class="command-icon">+</div>
              <div class="flex-1">
                <div class="command-title">${cmd.title}</div>
                <div class="command-description">${cmd.description}</div>
              </div>
              <div class="command-action">Navigation</div>
            </div>
          </div>
        `
      })
      
      html += `</div>`
    })
    
    results.innerHTML = html
  }
  
  // Group commands by category
  groupByCategory(commands) {
    return commands.reduce((acc, cmd) => {
      if (!acc[cmd.category]) {
        acc[cmd.category] = []
      }
      acc[cmd.category].push(cmd)
      return acc
    }, {})
  }
  
  // Load all available commands
  async loadCommands() {
    // Load custom shortcuts from database
    let customShortcuts = []
    try {
      const response = await fetch('/admin/tools/shortcuts.json')
      if (response.ok) {
        const data = await response.json()
        customShortcuts = data.map(s => ({
          category: s.category ? s.category.charAt(0).toUpperCase() + s.category.slice(1) : 'Custom',
          icon: s.icon || '⚡',
          title: s.name,
          description: s.description || '',
          action: s.action_type,
          url: s.action_type === 'navigate' ? s.action_value : null,
          execute: s.action_type === 'execute' ? s.action_value : null,
          keywords: [s.name.toLowerCase()],
          shortcut: s.keybinding
        }))
      }
    } catch (error) {
      console.error('Failed to load custom shortcuts:', error)
    }
    
    // Merge custom shortcuts with default ones
    this.commands = [
      ...customShortcuts,
      
      // Navigation - matching screenshot exactly
      {
        category: 'NAVIGATION',
        icon: '+',
        title: 'Go to Inbox',
        description: 'Navigate to the conversations inbox',
        action: 'navigate',
        url: '/admin/inbox',
        keywords: ['inbox', 'conversations', 'messages']
      },
      {
        category: 'NAVIGATION',
        icon: '+',
        title: 'Go to Dashboard',
        description: 'Navigate to the admin dashboard',
        action: 'navigate',
        url: '/admin',
        keywords: ['dashboard', 'home', 'admin']
      },
      {
        category: 'NAVIGATION',
        icon: '+',
        title: 'Go to Quotes',
        description: 'View all quotes',
        action: 'navigate',
        url: '/admin/quotes',
        keywords: ['quotes', 'estimates', 'pricing']
      },
      {
        category: 'NAVIGATION',
        icon: '+',
        title: 'Go to Projects',
        description: 'View all projects',
        action: 'navigate',
        url: '/admin/projects',
        keywords: ['projects', 'work', 'tasks']
      },
      {
        category: 'NAVIGATION',
        icon: '+',
        title: 'Go to Analytics',
        description: 'View analytics and reports',
        action: 'navigate',
        url: '/admin/analytics',
        keywords: ['analytics', 'reports', 'stats']
      },
      
      // Content Management
      {
        category: 'CONTENT',
        icon: '+',
        title: 'All Posts',
        description: 'View and manage posts',
        action: 'navigate',
        url: '/admin/posts',
        keywords: ['posts', 'blog', 'articles']
      },
      {
        category: 'CONTENT',
        icon: '+',
        title: 'All Pages',
        description: 'View and manage pages',
        action: 'navigate',
        url: '/admin/pages',
        keywords: ['pages', 'static']
      },
      {
        category: 'CONTENT',
        icon: '+',
        title: 'Comments',
        description: 'Moderate comments',
        action: 'navigate',
        url: '/admin/comments',
        keywords: ['comments', 'moderation']
      },
      {
        category: 'CONTENT',
        icon: '+',
        title: 'Media Library',
        description: 'Browse uploaded files',
        action: 'navigate',
        url: '/admin/media',
        keywords: ['media', 'images', 'files', 'library']
      },
      
      // Organization
      {
        category: 'ORGANIZATION',
        icon: '+',
        title: 'Categories',
        description: 'Manage post categories',
        action: 'navigate',
        url: '/admin/categories',
        keywords: ['categories', 'taxonomy']
      },
      {
        category: 'ORGANIZATION',
        icon: '+',
        title: 'Tags',
        description: 'Manage post tags',
        action: 'navigate',
        url: '/admin/tags',
        keywords: ['tags', 'taxonomy']
      },
      {
        category: 'ORGANIZATION',
        icon: '+',
        title: 'Taxonomies',
        description: 'Custom taxonomies',
        action: 'navigate',
        url: '/admin/taxonomies',
        keywords: ['taxonomy', 'custom']
      },
      {
        category: 'ORGANIZATION',
        icon: '+',
        title: 'Menus',
        description: 'Manage navigation menus',
        action: 'navigate',
        url: '/admin/menus',
        keywords: ['menu', 'navigation']
      },
      
      // Appearance
      {
        category: 'APPEARANCE',
        icon: '+',
        title: 'Themes',
        description: 'Manage site themes',
        action: 'navigate',
        url: '/admin/themes',
        keywords: ['themes', 'appearance', 'design']
      },
      {
        category: 'APPEARANCE',
        icon: '+',
        title: 'Customize Theme',
        description: 'Visual theme editor',
        action: 'navigate',
        url: '/admin/template_customizer',
        keywords: ['customize', 'editor', 'grapesjs']
      },
      {
        category: 'APPEARANCE',
        icon: '+',
        title: 'Theme Editor',
        description: 'Edit theme files',
        action: 'navigate',
        url: '/admin/theme_editor',
        keywords: ['editor', 'code', 'files', 'monaco']
      },
      {
        category: 'APPEARANCE',
        icon: '+',
        title: 'Widgets',
        description: 'Manage widgets',
        action: 'navigate',
        url: '/admin/widgets',
        keywords: ['widgets', 'sidebar']
      },
      
      // Settings
      {
        category: 'SETTINGS',
        icon: '+',
        title: 'General Settings',
        description: 'Site configuration',
        action: 'navigate',
        url: '/admin/settings/general',
        keywords: ['settings', 'config', 'general']
      },
      {
        category: 'SETTINGS',
        icon: '+',
        title: 'White Label',
        description: 'Customize branding',
        action: 'navigate',
        url: '/admin/settings/white_label',
        keywords: ['branding', 'white label', 'logo']
      },
      {
        category: 'SETTINGS',
        icon: '+',
        title: 'Appearance',
        description: 'Customize colors and fonts',
        action: 'navigate',
        url: '/admin/settings/appearance',
        keywords: ['appearance', 'colors', 'fonts', 'theme']
      },
      {
        category: 'SETTINGS',
        icon: '+',
        title: 'Email Settings',
        description: 'Configure email',
        action: 'navigate',
        url: '/admin/settings/email',
        keywords: ['email', 'smtp', 'mail']
      },
      
      // System
      {
        category: 'SYSTEM',
        icon: '+',
        title: 'Users',
        description: 'View and manage users',
        action: 'navigate',
        url: '/admin/users',
        keywords: ['users', 'contacts', 'people']
      },
      {
        category: 'SYSTEM',
        icon: '+',
        title: 'Updates',
        description: 'Check for updates',
        action: 'navigate',
        url: '/admin/updates',
        keywords: ['updates', 'version', 'upgrade']
      },
      {
        category: 'SYSTEM',
        icon: '+',
        title: 'Webhooks',
        description: 'Manage webhooks',
        action: 'navigate',
        url: '/admin/webhooks',
        keywords: ['webhooks', 'api', 'integration']
      },
      {
        category: 'SYSTEM',
        icon: '+',
        title: 'Email Logs',
        description: 'View email history',
        action: 'navigate',
        url: '/admin/email_logs',
        keywords: ['email', 'logs', 'mail']
      }
    ]
    
    this.search()
  }
  
  // Render filtered results
  render() {
    if (this.filteredCommands.length === 0) {
      this.resultsTarget.classList.add('hidden')
      this.emptyTarget.classList.remove('hidden')
      this.emptyTarget.innerHTML = `
        <div class="text-center py-8">
          <div class="text-4xl mb-3">🔍</div>
          <div class="text-gray-400 text-sm">No commands found</div>
          <div class="text-gray-600 text-xs mt-1">Try a different search term</div>
        </div>
      `
      return
    }
    
    this.resultsTarget.classList.remove('hidden')
    this.emptyTarget.classList.add('hidden')
    
    const grouped = this.groupByCategory(this.filteredCommands)
    
    let html = ''
    Object.keys(grouped).forEach(category => {
      html += `
        <div class="mb-4">
          <div class="px-4 py-2 text-xs font-semibold text-gray-500 uppercase tracking-wider">
            ${category}
          </div>
      `
      
      grouped[category].forEach(cmd => {
        const globalIndex = this.filteredCommands.indexOf(cmd)
        const isSelected = globalIndex === this.selectedIndex
        
        html += `
          <div class="command-item ${isSelected ? 'command-item-selected' : ''}" 
               data-index="${globalIndex}"
               data-action="click->command-palette#selectCommand">
            <div class="flex items-center flex-1">
              <div class="command-icon">+</div>
              <div class="flex-1">
                <div class="command-title">${this.highlightMatch(cmd.title)}</div>
                <div class="command-description">${cmd.description}</div>
              </div>
              <div class="command-action">Navigation</div>
            </div>
          </div>
        `
      })
      
      html += `</div>`
    })
    
    results.innerHTML = html
  }
  
  // Highlight search matches
  highlightMatch(text) {
    const input = document.querySelector('[data-command-palette-target="input"]')
    const query = input ? input.value.toLowerCase().trim() : ''
    if (!query) return text
    
    const regex = new RegExp(`(${query})`, 'gi')
    return text.replace(regex, '<mark class="bg-yellow-400/30 text-white">$1</mark>')
  }
}

