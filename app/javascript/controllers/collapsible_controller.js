import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collapsible"
export default class extends Controller {
  static targets = ["content", "icon"]
  static values = { open: Boolean }

  connect() {
    console.log("Collapsible controller connected")
    this.updateCollapsible()
  }

  toggle() {
    this.openValue = !this.openValue
  }

  openValueChanged() {
    this.updateCollapsible()
  }

  updateCollapsible() {
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
