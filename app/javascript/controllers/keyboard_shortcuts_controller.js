import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["helpPanel"]
  
  connect() {
    this.setupKeyboardHandlers()
  }
  
  disconnect() {
    // Cleanup is handled by removing event listeners automatically
  }
  
  setupKeyboardHandlers() {
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.boundHandleKeydown)
  }
  
  handleKeydown(event) {
    // Show shortcuts help with ?
    if (event.key === '?' && !event.target.matches('input, textarea')) {
      event.preventDefault()
      this.toggleHelp()
    }
    
    // Close help with Escape
    if (event.key === 'Escape') {
      this.hideHelp()
    }
  }
  
  toggleHelp() {
    if (this.hasHelpPanelTarget) {
      this.helpPanelTarget.classList.toggle('hidden')
    }
  }
  
  hideHelp() {
    if (this.hasHelpPanelTarget) {
      this.helpPanelTarget.classList.add('hidden')
    }
  }
}




