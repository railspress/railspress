import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal", "backdrop", "search", "results", "footer",
    "localList", "localSection",
    "postsList", "postsSection",
    "pagesList", "pagesSection",
    "taxonomiesList", "taxonomiesSection",
    "usersList", "usersSection",
    "emptyState", "item", "itemTemplate"
  ]
  
  static values = {
    searchSelectors: Array,
    targetElement: String,
    editorController: String
  }
  
  connect() {
    this.allItems = []
    this.selectedIndex = 0
    this.searchDebounce = null
    this.isOpen = false
    this.highlightedElements = []
    
    // Expose toggle function globally
    window.toggleQuickSearch = () => {
      if (this.isOpen) {
        this.close()
      } else {
        this.open()
      }
    }
  }
  
  disconnect() {
    delete window.toggleQuickSearch
    this.clearHighlights()
  }
  
  open() {
    this.isOpen = true
    this.element.classList.remove('hidden')
    this.positionModal()
    this.searchTarget.value = ''
    this.searchTarget.focus()
    this.hideResults()
  }
  
  close() {
    this.isOpen = false
    this.element.classList.add('hidden')
    this.searchTarget.value = ''
    this.hideResults()
    this.clearHighlights()
  }
  
  positionModal() {
    if (this.targetElementValue) {
      const targetEl = document.querySelector(this.targetElementValue)
      if (targetEl) {
        const rect = targetEl.getBoundingClientRect()
        this.modalTarget.style.position = 'fixed'
        this.modalTarget.style.top = `${rect.bottom + 8}px`
        this.modalTarget.style.left = `${rect.left}px`
      }
    } else {
      // Default center positioning
      this.modalTarget.style.position = 'fixed'
      this.modalTarget.style.top = '20%'
      this.modalTarget.style.left = '50%'
      this.modalTarget.style.transform = 'translateX(-50%)'
    }
  }
  
  hideResults() {
    this.resultsTarget.classList.add('hidden')
    this.footerTarget.classList.add('hidden')
    this.localSectionTarget.classList.add('hidden')
    this.postsSectionTarget.classList.add('hidden')
    this.pagesSectionTarget.classList.add('hidden')
    this.taxonomiesSectionTarget.classList.add('hidden')
    this.usersSectionTarget.classList.add('hidden')
    this.emptyStateTarget.classList.add('hidden')
  }
  
  async search(e) {
    const query = e.target.value.trim()
    
    if (!query) {
      this.hideResults()
      this.clearHighlights()
      return
    }
    
    // Show results container
    this.resultsTarget.classList.remove('hidden')
    this.footerTarget.classList.remove('hidden')
    
    // Search local content first if selectors provided
    let localResults = []
    if (this.searchSelectorsValue && this.searchSelectorsValue.length > 0) {
      localResults = await this.searchLocal(query)
      this.renderLocalResults(localResults)
      this.toggleSection(this.localSectionTarget, localResults.length > 0)
    }
    
    // Debounce API search
    clearTimeout(this.searchDebounce)
    this.searchDebounce = setTimeout(async () => {
      await this.searchContent(query)
    }, 300)
  }
  
  async searchLocal(query) {
    this.clearHighlights()
    const results = []
    const queryLower = query.toLowerCase()
    
    // Try to search using specified editor controller if provided
    if (this.editorControllerValue) {
      const editorEl = document.querySelector(`[data-controller*="${this.editorControllerValue}"]`)
      if (editorEl) {
        try {
          const controller = this.application.getControllerForElementAndIdentifier(editorEl, this.editorControllerValue)
          if (controller && typeof controller.getText === 'function') {
            const fullText = await controller.getText()
            if (fullText && fullText.toLowerCase().includes(queryLower)) {
              const index = fullText.toLowerCase().indexOf(queryLower)
              const context = fullText.substring(Math.max(0, index - 30), Math.min(fullText.length, index + query.length + 30))
              
              results.push({
                element: editorEl,
                text: context,
                selector: 'Editor Content',
                fullText: fullText
              })
              
              // Highlight matches in all editor blocks
              this.highlightInEditor(query)
            }
          } else {
            console.error(`[QuickSearch] Controller '${this.editorControllerValue}' does not expose getText() method`)
          }
        } catch (error) {
          console.error(`[QuickSearch] Failed to access editor controller '${this.editorControllerValue}':`, error)
        }
      }
    }
    
    // Fallback/additional selector-based search
    this.searchSelectorsValue.forEach(selector => {
      const elements = document.querySelectorAll(selector)
      
      elements.forEach(el => {
        const text = el.textContent || el.value || ''
        const textLower = text.toLowerCase()
        
        if (textLower.includes(queryLower)) {
          const index = textLower.indexOf(queryLower)
          const context = text.substring(Math.max(0, index - 30), Math.min(text.length, index + query.length + 30))
          
          results.push({
            element: el,
            text: text,
            selector: selector,
            fullText: text
          })
          
          // Highlight in the element
          this.highlightText(el, query)
        }
      })
    })
    
    return results
  }
  
  highlightInEditor(query) {
    // Highlight matches in all editor blocks
    const editorBlocks = document.querySelectorAll('.ce-paragraph, .ce-header, .ce-block')
    editorBlocks.forEach(block => {
      const text = block.textContent || ''
      if (text.toLowerCase().includes(query.toLowerCase())) {
        this.highlightText(block, query)
      }
    })
  }
  
  highlightText(element, query) {
    const isInput = element.tagName === 'INPUT' || element.tagName === 'TEXTAREA'
    
    if (isInput) {
      // For inputs/textareas, we can't highlight but we track them
      this.highlightedElements.push({ element, originalValue: element.value })
    } else {
      // For regular elements, wrap matches in span
      const text = element.textContent
      const regex = new RegExp(`(${this.escapeRegex(query)})`, 'gi')
      const highlighted = text.replace(regex, '<span class="quick-search-highlight">$1</span>')
      
      this.highlightedElements.push({ element, originalHTML: element.innerHTML })
      element.innerHTML = highlighted
    }
  }
  
  clearHighlights() {
    this.highlightedElements.forEach(({ element, originalHTML, originalValue }) => {
      if (originalHTML !== undefined) {
        element.innerHTML = originalHTML
      } else if (originalValue !== undefined) {
        element.value = originalValue
      }
    })
    this.highlightedElements = []
  }
  
  escapeRegex(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  }
  
  renderLocalResults(results) {
    this.localListTarget.innerHTML = ''
    results.forEach(result => {
      const item = this.createItem({
        icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>',
        name: result.selector,
        description: result.text.trim(),
        data: { action_type: 'scroll', element: result.element }
      })
      this.localListTarget.appendChild(item)
    })
    this.updateAllItems()
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
      
      // Show empty state if no results at all
      const localResults = this.localListTarget.children.length
      const hasResults = localResults + (data.posts?.length || 0) + (data.pages?.length || 0) + 
                         (data.taxonomies?.length || 0) + (data.users?.length || 0) > 0
      this.emptyStateTarget.classList.toggle('hidden', hasResults)
      
    } catch (error) {
      console.error('Search failed:', error)
    }
  }
  
  renderPosts(posts) {
    this.postsListTarget.innerHTML = ''
    posts.forEach(post => {
      const item = this.createItem({
        icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>',
        name: post.title,
        description: `${post.status} • Updated ${this.timeAgo(post.updated_at)}`,
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
        data: { action_type: 'navigate', action_value: user.url }
      })
      this.usersListTarget.appendChild(item)
    })
    this.updateAllItems()
  }
  
  createItem({ icon, name, description, data }) {
    const template = this.itemTemplateTarget.content.cloneNode(true)
    const item = template.querySelector('[data-quick-search-target="item"]')
    
    item.querySelector('[data-item-icon]').innerHTML = icon
    item.querySelector('[data-item-name]').textContent = name
    item.querySelector('[data-item-description]').textContent = description
    item.dataset.itemData = JSON.stringify(data)
    
    return item
  }
  
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
      this.close()
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
    console.log(selectedItem)
    
    const data = JSON.parse(selectedItem.dataset.itemData)
    
    if (data.action_type === 'navigate') {
      window.Turbo.visit(data.action_value)
    } else if (data.action_type === 'scroll') {
      console.log(data.element)
      data.element.scrollIntoView({ behavior: 'smooth', block: 'center' })
      data.element.focus()
      this.close()
    }
  }
  
  updateAllItems() {
    this.allItems = Array.from(this.element.querySelectorAll('[data-quick-search-target="item"]'))
    this.selectedIndex = 0
    this.updateSelection()
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

