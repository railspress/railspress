import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static values = { collapsed: Boolean }

  connect() {
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
    const contentEl = this.contentTarget
    const mainContent = document.querySelector('.flex-1.flex.flex-col.overflow-hidden')
    
    if (this.collapsedValue) {
      // Collapse sidebar
      this.element.style.width = '0'
      this.element.style.overflow = 'hidden'
      contentEl.style.opacity = '0'
      contentEl.style.pointerEvents = 'none'
      
      // Expand main content
      if (mainContent) {
        mainContent.style.marginLeft = '0'
      }
    } else {
      // Expand sidebar
      this.element.style.width = '400px'
      this.element.style.overflow = 'auto'
      contentEl.style.opacity = '1'
      contentEl.style.pointerEvents = 'auto'
      
      // Push main content
      if (mainContent) {
        mainContent.style.marginLeft = '0'
      }
    }
  }
}

