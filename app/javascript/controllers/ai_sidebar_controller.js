import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static values = { collapsed: Boolean }

  connect() {
    // Load saved state from localStorage
    const savedState = localStorage.getItem('editor-ai-sidebar-collapsed')
    if (savedState !== null) {
      this.collapsedValue = savedState === 'true'
    }
    this.updateSidebar()
  }

  toggle() {
    this.collapsedValue = !this.collapsedValue
    this.updateSidebar()
    
    // Save state to localStorage
    localStorage.setItem('editor-ai-sidebar-collapsed', this.collapsedValue)
    
    // Dispatch event for split-panels controller
    window.dispatchEvent(new CustomEvent('split-panels:toggle-left', {
      detail: { collapsed: this.collapsedValue }
    }))
  }

  collapsedValueChanged() {
    this.updateSidebar()
  }

  updateSidebar() {
    const contentEl = this.contentTarget
    
    if (this.collapsedValue) {
      // Collapse sidebar
      contentEl.style.opacity = '0'
      contentEl.style.pointerEvents = 'none'
    } else {
      // Expand sidebar
      contentEl.style.opacity = '1'
      contentEl.style.pointerEvents = 'auto'
      
      // Dispatch event to notify chat widget to scroll
      this.element.dispatchEvent(new CustomEvent('scroll-chat-widget', {
        bubbles: true
      }))
    }
  }
}

