import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sidebar"
export default class extends Controller {
  static targets = ["content", "toggleIcon"]
  static values = { collapsed: Boolean }

  connect() {
    console.log("Sidebar controller connected")
    // Load saved state from localStorage
    const savedState = localStorage.getItem('editor-right-sidebar-collapsed')
    if (savedState !== null) {
      this.collapsedValue = savedState === 'true'
    }
    // Ensure UI reflects initial state
    this.updateSidebar()

    window.togglePostSidebar = () => {
      this.toggle()
    }
  }
  

  toggle() {
    this.collapsedValue = !this.collapsedValue
    this.updateSidebar()
    
    // Save state to localStorage
    localStorage.setItem('editor-right-sidebar-collapsed', this.collapsedValue)
    
    // Dispatch event for split-panels controller
    window.dispatchEvent(new CustomEvent('split-panels:toggle-right', {
      detail: { collapsed: this.collapsedValue }
    }))
  }

  collapsedValueChanged() {
    this.updateSidebar()
  }

  updateSidebar() {
    const contentEl = this.hasContentTarget ? this.contentTarget : null
    const toggleIconEl = this.hasToggleIconTarget ? this.toggleIconTarget : document.querySelector('[data-sidebar-target="toggleIcon"]')

    if (this.collapsedValue) {
      // Collapse sidebar
      if (contentEl) {
        contentEl.style.opacity = '0'
        contentEl.style.pointerEvents = 'none'
      }
      
      // Update toggle icon - when closed, show '<' (point left)
      if (toggleIconEl) {
        toggleIconEl.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5"/>'
      }
    } else {
      // Expand sidebar
      if (contentEl) {
        contentEl.style.opacity = '1'
        contentEl.style.pointerEvents = 'auto'
      }
      
      // Update toggle icon - when opened, show '>' (point right)
      if (toggleIconEl) {
        toggleIconEl.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5"/>'
      }
    }
  }
}
