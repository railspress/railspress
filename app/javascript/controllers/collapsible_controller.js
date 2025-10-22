import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collapsible"
export default class extends Controller {
  static targets = ["content", "icon"]
  static values = { 
    open: Boolean,
    sectionType: String,
    userId: String
  }

  connect() {
    console.log("Collapsible controller connected")
    
    // Load saved state from localStorage if available
    this.loadSavedState()
    
    // Initialize the open state
    this.updateCollapsible()
  }

  toggle() {
    this.openValue = !this.openValue
    this.saveState()
  }

  openValueChanged() {
    this.updateCollapsible()
  }

  loadSavedState() {
    if (this.hasSectionTypeValue && this.hasUserIdValue) {
      const savedState = localStorage.getItem(`sidebar-section-state-${this.userIdValue}-${this.sectionTypeValue}`)
      if (savedState !== null) {
        const isOpen = savedState === 'true'
        this.openValue = isOpen
        console.log(`Loaded saved state for ${this.sectionTypeValue}: ${isOpen}`)
      } else {
        // Use the default from data-collapsible-open-value
        const openValue = this.element.dataset.collapsibleOpenValue === 'true'
        this.openValue = openValue
        console.log(`Using default state for ${this.sectionTypeValue}: ${openValue}`)
      }
    } else {
      // Fallback to data attribute if no section type/user ID
      const openValue = this.element.dataset.collapsibleOpenValue === 'true'
      this.openValue = openValue
      console.log(`Using fallback state: ${openValue}`)
    }
  }

  saveState() {
    if (this.hasSectionTypeValue && this.hasUserIdValue) {
      localStorage.setItem(`sidebar-section-state-${this.userIdValue}-${this.sectionTypeValue}`, this.openValue.toString())
      console.log(`Saved state for ${this.sectionTypeValue}: ${this.openValue}`)
    }
  }

  updateCollapsible() {
    if (!this.hasContentTarget || !this.hasIconTarget) {
      console.log("Missing targets for collapsible")
      return
    }

    if (this.openValue) {
      // Open
      this.contentTarget.style.maxHeight = this.contentTarget.scrollHeight + 'px'
      this.contentTarget.style.opacity = '1'
      this.contentTarget.style.overflow = 'visible'
      this.iconTarget.style.transform = 'rotate(180deg)'
    } else {
      // Close
      this.contentTarget.style.maxHeight = '0px'
      this.contentTarget.style.opacity = '0'
      this.contentTarget.style.overflow = 'hidden'
      this.iconTarget.style.transform = 'rotate(0deg)'
    }
  }
}
