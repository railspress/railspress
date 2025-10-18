import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sidebar"
export default class extends Controller {
  static targets = ["content", "toggleIcon"]
  static values = { collapsed: Boolean }

  connect() {
    console.log("Sidebar controller connected")
  }

  toggle() {
    this.collapsedValue = !this.collapsedValue
    this.updateSidebar()
  }

  collapsedValueChanged() {
    this.updateSidebar()
  }

  updateSidebar() {
    if (this.collapsedValue) {
      // Collapse sidebar - show only tiny floating circle
      this.element.style.width = '0px'
      this.element.style.overflow = 'hidden'
      this.contentTarget.style.opacity = '0'
      this.contentTarget.style.pointerEvents = 'none'
      
      // Update toggle icon - arrow points right (to expand)
      this.toggleIconTarget.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5"/>'
      
      // Move toggle button to top-right corner
      const toggleButton = this.element.querySelector('button')
      if (toggleButton) {
        toggleButton.parentElement.style.position = 'fixed'
        toggleButton.parentElement.style.top = '1rem'
        toggleButton.parentElement.style.right = '1rem'
        toggleButton.parentElement.style.left = 'auto'
        toggleButton.parentElement.style.zIndex = '50'
      }
      
      // Expand main content area to full width
      const mainContent = document.querySelector('.flex-1.flex.flex-col.overflow-hidden')
      if (mainContent) {
        mainContent.style.width = '100%'
        mainContent.style.maxWidth = '100%'
      }
      
      // Expand title and editor container
      const titleContainer = document.querySelector('.max-w-4xl.mx-auto.px-8.py-12')
      if (titleContainer) {
        titleContainer.style.maxWidth = '100%'
        titleContainer.style.paddingLeft = '3rem'
        titleContainer.style.paddingRight = '3rem'
      }
    } else {
      // Expand sidebar
      this.element.style.width = '20rem' // w-80 = 20rem
      this.element.style.overflow = 'auto'
      this.contentTarget.style.opacity = '1'
      this.contentTarget.style.pointerEvents = 'auto'
      
      // Update toggle icon - arrow points left (to collapse)
      this.toggleIconTarget.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5"/>'
      
      // Restore toggle button position
      const toggleButton = this.element.querySelector('button')
      if (toggleButton) {
        toggleButton.parentElement.style.position = 'absolute'
        toggleButton.parentElement.style.top = '1rem'
        toggleButton.parentElement.style.right = 'auto'
        toggleButton.parentElement.style.left = '-0.75rem'
        toggleButton.parentElement.style.zIndex = '20'
      }
      
      // Restore main content area width
      const mainContent = document.querySelector('.flex-1.flex.flex-col.overflow-hidden')
      if (mainContent) {
        mainContent.style.width = ''
        mainContent.style.maxWidth = ''
      }
      
      // Restore title and editor container
      const titleContainer = document.querySelector('.max-w-4xl.mx-auto.px-8.py-12')
      if (titleContainer) {
        titleContainer.style.maxWidth = '64rem'
        titleContainer.style.paddingLeft = ''
        titleContainer.style.paddingRight = ''
      }
    }
  }
}
