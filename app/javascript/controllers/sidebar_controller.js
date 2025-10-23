import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sidebar"
export default class extends Controller {
  static targets = ["content", "toggleIcon"]
  static values = { collapsed: Boolean }

  connect() {
    console.log("Sidebar controller connected")
    // Ensure UI reflects initial state
    this.updateSidebar()
  }

  toggle() {
    this.collapsedValue = !this.collapsedValue
    this.updateSidebar()
  }

  collapsedValueChanged() {
    this.updateSidebar()
  }

  updateSidebar() {
    const contentEl = this.hasContentTarget ? this.contentTarget : null
    const toggleIconEl = this.hasToggleIconTarget ? this.toggleIconTarget : document.querySelector('[data-sidebar-target="toggleIcon"]')
    const rootContainer = this.element.closest('.h-screen.flex')

    if (this.collapsedValue) {
      if (rootContainer) {
        //rootContainer.classList.add('sidebar-collapsed')
      }
      // Collapse sidebar - show only tiny floating circle
      this.element.style.width = '0px'
      this.element.style.overflow = 'hidden'
      if (contentEl) {
        contentEl.style.opacity = '0'
        contentEl.style.pointerEvents = 'none'
      }
      
      // Update toggle icon - when closed, show '<' (point left)
      if (toggleIconEl) {
        toggleIconEl.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5"/>'
      }
      
      // Note: Toggle button is in the topbar, not in the sidebar element
      
      // Expand main content area to full width
      const mainContent = document.querySelector('.flex-1.flex.flex-col.overflow-hidden')
      if (mainContent) {
        mainContent.style.width = '100%'
        mainContent.style.maxWidth = '100%'
      }
      
      // Also expand the parent flex container
      const parentFlex = document.querySelector('.flex-1.flex.overflow-hidden')
      if (parentFlex) {
        parentFlex.style.width = '100%'
      }
    } else {
      if (rootContainer) {
        //rootContainer.classList.remove('sidebar-collapsed')
      }
      // Expand sidebar
      this.element.style.width = '20rem' // w-80 = 20rem
      this.element.style.overflow = 'auto'
      if (contentEl) {
        contentEl.style.opacity = '1'
        contentEl.style.pointerEvents = 'auto'
      }
      
      // Update toggle icon - when opened, show '>' (point right)
      if (toggleIconEl) {
        toggleIconEl.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5"/>'
      }
      
      // Note: Toggle button is in the topbar, not in the sidebar element
      
      // Restore main content area width
      const mainContent = document.querySelector('.flex-1.flex.flex-col.overflow-hidden')
      if (mainContent) {
        mainContent.style.width = ''
        mainContent.style.maxWidth = ''
      }
      
      // Restore the parent flex container
      const parentFlex = document.querySelector('.flex-1.flex.overflow-hidden')
      if (parentFlex) {
        parentFlex.style.width = ''
      }
    }
  }
}
